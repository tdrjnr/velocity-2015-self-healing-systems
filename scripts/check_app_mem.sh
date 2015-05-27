#!/bin/bash

# This script collects Java stats from the running Tomcat process.  It reports those metrics to Datadog.

# Sample crontab entry follows; I offset the start time to minimize load at the start of the minute:
# * * * * * tomcat sleep 15; nice ~tomcat/check_platform_mem.sh

# Todd Minnella, SOASTA, Inc.
# Last modified on 5/27/15

# Define this prior to collecting metrics
ddapikey=FILL_IN_YOUR_KEY_HERE
metricdate=`date "+%s"`

# Update this if it changes (needed for cron job)
TOMCAT_HOME=/usr/share/tomcat8
JSTAT=/usr/bin/jstat

# Begin datadog metrics setup here
host=`hostname --fqdn`
if [ "$host" = "" ]; then
	host=${HOSTNAME}`dnsdomainname`
	if [ "$host" = "" ]; then host=unknown; fi
fi
# End datadog metrics setup here

errorandexit () { echo "ERROR: $1; exiting!"; exit 1; }

tempfile=`mktemp --suffix checkappmem`

JAVA_PID=`pgrep -f -u tomcat /usr/lib/jvm/jre/bin/java`

if [ "$JAVA_PID" != "" ]; then
	RAW_JSTATS=`timeout 30 $JSTAT -gcutil $JAVA_PID | grep -v "S0"`
	survivor_0_pcnt_used=`echo $RAW_JSTATS | cut -f1 -d" "`
	survivor_1_pcnt_used=`echo $RAW_JSTATS | cut -f2 -d" "`
	eden_pcnt_used=`echo $RAW_JSTATS | cut -f3 -d" "`
	old_pcnt_used=`echo $RAW_JSTATS | cut -f4 -d" "`
	permgen_pcnt_used=`echo $RAW_JSTATS | cut -f5 -d" "`
	young_gc_count=`echo $RAW_JSTATS | cut -f6 -d" "`
	young_gc_time=`echo $RAW_JSTATS | cut -f7 -d" "`
	full_gc_count=`echo $RAW_JSTATS | cut -f8 -d" "`
	full_gc_time=`echo $RAW_JSTATS | cut -f9 -d" "`
	total_gc_time=`echo $RAW_JSTATS | cut -f10 -d" "`
fi

if [ "$JAVA_PID" = "" -o "$RAW_JSTATS" = "" ]; then
        survivor_0_pcnt_used=0.0
        survivor_1_pcnt_used=0.0
        eden_pcnt_used=0.0
        old_pcnt_used=0.0
        permgen_pcnt_used=0.0
        young_gc_count=0
        young_gc_time=0
        full_gc_count=0
        full_gc_time=0
        total_gc_time=0
fi

cat > $tempfile << ENDJSON
{ "series" :
        [{"metric":"platform_survivor_0_pcnt_used",
          "points":[[$metricdate, $survivor_0_pcnt_used]],
          "type":"gauge",
          "host":"$host"},
        {"metric":"platform_survivor_1_pcnt_used",
          "points":[[$metricdate, $survivor_1_pcnt_used]],
          "type":"gauge",
          "host":"$host"},
        {"metric":"platform_eden_pcnt_used",
          "points":[[$metricdate, $eden_pcnt_used]],
          "type":"gauge",
          "host":"$host"},
        {"metric":"platform_old_pcnt_used",
          "points":[[$metricdate, $old_pcnt_used]],
          "type":"gauge",
          "host":"$host"},
        {"metric":"platform_permgen_pcnt_used",
          "points":[[$metricdate, $permgen_pcnt_used]],
          "type":"gauge",
          "host":"$host"},
        {"metric":"platform_young_gc_count",
          "points":[[$metricdate, $young_gc_count]],
          "type":"counter",
          "host":"$host"},
        {"metric":"platform_young_gc_time",
          "points":[[$metricdate, $young_gc_time]],
          "type":"gauge",
          "host":"$host"},
        {"metric":"platform_full_gc_count",
          "points":[[$metricdate, $full_gc_count]],
          "type":"counter",
          "host":"$host"},
        {"metric":"platform_full_gc_time",
          "points":[[$metricdate, $full_gc_time]],
          "type":"gauge",
          "host":"$host"},
        {"metric":"platform_total_gc_time",
          "points":[[$metricdate, $total_gc_time]],
          "type":"gauge",
          "host":"$host"}
        ]
    } 
ENDJSON
curl -s -S -m 45 -X POST -H "Content-type: application/json" --data @$tempfile "https://app.datadoghq.com/api/v1/series?api_key=$ddapikey" | grep -v '\"ok\"'

rm $tempfile
