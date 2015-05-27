#!/bin/bash

# This script performs maintenance functions on the running Tomcat Java process.
# It can trigger an immediate full GC based on an old % used trigger value

# Note that this script was written for demonstration purposes, and is not set up 
# for unattended operation.

# Todd Minnella, SOASTA, Inc.
# Last modified on 5/27/15

TOMCAT_HOME=/usr/share/tomcat8
JSTAT=jstat

# Take the first argument to be the trigger %
oldpcnttrigger=$1
if [ "$oldpcnttrigger" = "" ]; then
	oldpcnttrigger=100
fi

JAVA_PID=`pgrep -f -u tomcat /usr/lib/jvm/jre/bin/java`
echo "Java PID is $JAVA_PID"

RAW_JSTATS=`$JSTAT -gcutil $JAVA_PID | grep -v "S0"`
old_pcnt_used=`echo $RAW_JSTATS | cut -f4 -d" "`

integer_old_pcnt_used=`echo $old_pcnt_used | awk '{ printf ("%1.0f", $1) }'`

echo "Raw jstat output: $RAW_JSTATS"
echo ""
echo "Integer old_pcnt_used = ${integer_old_pcnt_used}%"
echo ""

if [ $integer_old_pcnt_used -gt $oldpcnttrigger ]; then
	echo "Current old % ($integer_old_pcnt_used) exceeds trigger % ($oldpcnttrigger)"
	echo "Triggering full GC..."
	jcmd $JAVA_PID GC.run
	echo "GC complete!"
fi
