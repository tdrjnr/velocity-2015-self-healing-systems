#!/bin/bash

# This script performs maintenance functions on the running Tomcat Java process.
# It can trigger an immediate full GC based on an old % used trigger value

# This script can publish to SNS topics; it is designed to be run on a server with an 
# IAM server role granting access to sns:Publish and the region needs to be specified.

# This script should be tested, and customized if necessary, prior to use.

# Todd Minnella, SOASTA, Inc.
# Last modified on 5/27/15

# Add this to /etc/crontab as follows to have it trigger a full GC and wait a half hour between GCs:
#*/5 * * * * tomcat ~tomcat/trigger-gc.sh -g -o 50 -w 29 -q -r us-west-2 -s arn:aws:sns:us-west-2:aws_acct_id:warn

# Or run it like this to run immediately - these arguments are an example:
# ~tomcat/trigger-gc.sh -g -o 0 

TOMCAT_HOME=/usr/share/tomcat8
lockfile=$TOMCAT_HOME/trigger-gc.run
waitdir=$TOMCAT_HOME
waitfile=trigger-gc.alert
JSTAT=jstat

rm_lock () { if [ -f "$lockfile" ]; then rm $lockfile; fi }

usage () { echo "Usage: $0 -o old_%_threshold [-g (gcrequested)] [-d serverdescription] [-m mingcfree] [-s snswarntopicarn] [-a snsalerttopicarn] [-q (quiet)] [-r awsregion] [-v (verbose)] [-w waitbetweendumpsmin]" 1>&2; exit 1; } 

errorandexit () { echo "ERROR: $1; exiting!"; rm_lock; exit 1; }

# Publish to AWS SNS
publish_sns_warn () {
	if [ "$awsenabled" = "true" -a "$snswarntopicarn" != "" ]; then
		msg=$1
		timeout 15 aws sns publish --region $awsregion --topic-arn $snswarntopicarn --message "$msg" >/dev/null
		if [ $? -ne 0 -a "$quiet" != "true" ]; then echo "WARN: retval $? when attempting to publish to AWS SNS"; fi
	fi
}

publish_sns_alert () {
	if [ "$awsenabled" = "true" -a "$snsalerttopicarn" != "" ]; then
		msg=$1
		timeout 30 aws sns publish --region $awsregion --topic-arn $snsalerttopicarn --message "$msg" >/dev/null
		if [ $? -ne 0 -a "$quiet" != "true" ]; then echo "WARN: retval $? when attempting to publish to AWS SNS"; fi
	fi
}


info () { if [ "$verbose" = "true" ]; then echo "INFO: $1"; fi; }

warn () { publish_sns_warn "$1"; if [ "$quiet" != "true" ]; then echo "WARN: $1"; fi; }

alert () { publish_sns_alert "$1"; echo "ALERT: $1"; }

# Update this to set the appropriate command to trigger a Java full GC for your environment
trigger_gc () { jcmd $JAVA_PID GC.run >/dev/null; }

# Simple sig term handling
trap 'rm_lock; exit 1' TERM INT HUP

while getopts "a:d:gm:o:qr:s:w:v" args; do
	case "${args}" in
		a)
			snsalerttopicarn="${OPTARG}"
		;;
		d)
			serverdescription="${OPTARG}"
		;;
		g)
			gcrequested=true
		;;
		m)
			mingcfree="${OPTARG}"
		;;
		o)
			oldpcnttrigger="${OPTARG}"
		;;
		q)
			quiet=true
		;;
		r)
			awsregion="${OPTARG}"
		;;
		s)
			snswarntopicarn="${OPTARG}"
		;;
		v)
			verbose=true
		;;
		w)
			waitmin="${OPTARG}"
		;;
		*)
			usage
		;;
	esac
done

# Validate arguments and report the config (if in verbose mode)
if [ "$oldpcnttrigger" = "" ]; then
	echo "ERROR: -o old_%_threshold not set.  Use 0 for an immediate dump, or 100 for a dry run."
	usage
elif [ $oldpcnttrigger -lt 0 -a $oldpcnttrigger -gt 100 ]; then
	echo "ERROR: -o old_%_threshold not between 0 and 100.  Use 0 for an immediate dump, or 100 for a dry run."
	usage
fi

info "Quiet mode off"
info "Old % trigger set to ${oldpcnttrigger}%"
if [ "$gcrequested" == "true" ]; then
	info "Full GC enabled"
fi
if [ "$awsregion" != "" ]; then
	awsenabled=true
	info "AWS SNS notification enabled using region $awsregion"
fi

if [ "$waitmin" != "" ]; then
	if [ $waitmin -ge 0 ]; then
		info "Wait time of $waitmin minutes defined between GCs"
	fi
else
	waitmin=-1
fi	

if [ "$mingcfree" != "" ]; then
	info "Min GC Free % defined to be $mingcfree; less than the min will trigger an alert."
else
	mingcfree=-100
fi

host=`hostname --fqdn`
if [ "$host" = "" ]; then
	host=${HOSTNAME}`dnsdomainname`
	if [ "$host" = "" ]; then host=unknown; fi
fi
info "Hostname is $host"

if [ "$serverdescription" = "" ]; then
	serverdescription="Hostname $host"
else
	serverdescription="Hostname $host Description $serverdescription"
fi
info "Server Description is $serverdescription"

if [ -f $lockfile ]; then
	echo "ERROR: Temporary file $lockfile exists; exiting!"
	exit 1
else
	echo $$ > $lockfile
fi

if [ -f ${waitdir}/${waitfile} -a $waitmin -ge 0 ]; then
	# Check to see if the wait flag is older than threshold; if so, delete it and recheck
        if [ `find $waitdir -name $waitfile -mmin +$waitmin -print | wc -l` -gt 0 ]; then
		rm ${waitdir}/${waitfile}
	fi
# If the alert wait time is not set, delete the wait file
elif [ -f ${waitdir}/${waitfile} -a $waitmin -eq -1 ]; then
	rm ${waitdir}/${waitfile}
fi

JAVA_PID=`pgrep -f -u tomcat /usr/lib/jvm/jre/bin/java`
info "Java PID is $JAVA_PID"

if [ "$JAVA_PID" != "" ]; then
	RAW_JSTATS=`$JSTAT -gcutil $JAVA_PID | grep -v "S0"`
	old_pcnt_used=`echo $RAW_JSTATS | cut -f4 -d" "`
else
	errorandexit "Can't determine JAVA_PID"
fi

integer_old_pcnt_used=`echo $old_pcnt_used | awk '{ printf ("%1.0f", $1) }'`

info "Raw jstat output: $RAW_JSTATS"
info "Integer old_pcnt_used = ${integer_old_pcnt_used}%"

if [ $integer_old_pcnt_used -gt $oldpcnttrigger ]; then
	info "Current old % ($integer_old_pcnt_used) exceeds trigger % ($oldpcnttrigger)"
	if [ ! -f ${waitdir}/${waitfile} ]; then
		trigger=true
		if [ -d $waitdir ]; then
			echo "$0 script triggered; delete this file if it is stale - old % used is $integer_old_pcnt_used" > ${waitdir}/${waitfile}
		else
			info "Note - $waitdir not a directory; skipping waitfile write."			
		fi
	else
		info "Because alert wait file ($waitfile) exists, no GC will be triggered."
	fi
# Special handling for oldpcnttrigger=0 - take action whatever the current old % used
elif [ $oldpcnttrigger = 0 ]; then
	info "Current old % ($integer_old_pcnt_used) and trigger % is set to 0"
	trigger=true
fi

if [ "$trigger" == "true" ]; then
	date=`date "+%F-%H%M%S"`
	if [ "$gcrequested" == "true" ]; then
	        info "Would trigger full GC..."
		trigger_gc
 	        GC_RAW_JSTATS=`$JSTAT -gcutil $JAVA_PID | grep -v "S0"`
 		gc_old_pcnt_used=`echo $GC_RAW_JSTATS | cut -f4 -d" "`
 		gc_integer_old_pcnt_used=`echo $gc_old_pcnt_used | awk '{ printf ("%1.0f", $1) }'`
 		info "Pre GC old % used was $integer_old_pcnt_used"
 		info "Post GC old % used is $gc_integer_old_pcnt_used"
 		let gcdiff=integer_old_pcnt_used-gc_integer_old_pcnt_used
 		info "Full GC freed ${gcdiff}% of heap"
 		if [ $gcdiff -ge $mingcfree ]; then
 			warn "Full GC triggered on $serverdescription - Pre GC old % used was $integer_old_pcnt_used and Post GC old % used is $gc_integer_old_pcnt_used; Full GC freed ${gcdiff}% of heap."
 		else
 			alert "MinGCFree not achived after Full GC (min is $mingcfree); check for memory leak! Full GC triggered on $serverdescription - Pre GC old % used was $integer_old_pcnt_used and Post GC old % used is $gc_integer_old_pcnt_used; Full GC freed ${gcdiff}% of heap."
 		fi
	fi
fi

rm_lock
