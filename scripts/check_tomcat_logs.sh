#!/bin/bash

# This script checks Tomcat's serverlog and reports key metrics to AWS
# CloudWatch.  This script uses an IAM server role with cloudwatch:PutMetricData
# access allowed.

# Note that this script was written for demonstration purposes, and will need
# to be modified for the specific application log it will be monitoring.

# Todd Minnella, SOASTA, Inc.
# Last modified on 5/27/15

# Sample crontab entry follows:
# * * * * * tomcat nice ~tomcat/check_tomcat_logs.sh

# Update this if it changes 
TOMCAT_HOME=/usr/share/tomcat8

# Fill in your log file name here
applog=$TOMCAT_HOME/FILL_IN_LOG_NAME_HERE

# On a heavily trafficked server, this may need to be increased
maxloglinesperminute=100000

# Fill in the CloudWatch namespace and region for the metrics here
cwnamespace=FILL_IN_NAMESPACE_HERE
cwregion=FILL_IN_CW_REGION_HERE

errorandexit () { echo "ERROR: $1; exiting!"; exit 1; }

instanceid=`curl -m 15 -s http://169.254.169.254/latest/meta-data/instance-id`
if [ "$instanceid" = "" ]; then
	instanceid="unknown"
fi

tempfile=`mktemp --suffix=checktomcatlogs`

# This script is designed to run every minute, and needs to handle midnight
# The lines below may need to be modified to account for local log rotation practices.
if [ `date "+%R"` = "00:00" ]; then
	# -22 hours returns the previous day even on the 23 hour DST change day
	yestdate=`date -d "-22 hours" "+%Y-%m-%d"`
	serverlog=$applog.$yestdate
else
	todaydate=`date "+%Y-%m-%d"`
	serverlog=$applog
fi

if [ ! -f $serverlog ]; then
	errorandexit "$serverlog doesn't exist"
fi

searchstring=^`date -d "1 minute ago" "+%Y-%m-%d %R"`
metrictime=`date -d "1 minute ago" -u "+%FT%TZ"`
tail -$maxloglinesperminute $serverlog | grep "$searchstring" > $tempfile
# The grep below searches for messages that begin like this: 2015-05-27 17:38:16,604 INFO
info=`grep -c '[0-9]\{3\} INFO  ' $tempfile`
error=`grep -c '[0-9]\{3\} ERROR ' $tempfile`

# Application specific strings - customize these to count specific strings.
selfcheckok=`grep -c '[0-9]\{3\} INFO  \[localhost-startStop-1\] \[ContextListener\] Application initialized.' $tempfile`
upload=`grep -c '[0-9]\{3\} INFO  .* \[UploadScheduler\$UploadTask\] Successfully uploaded file' $tempfile`

# Customize the below with your MetricNames as appropriate.
read -d '' metricjson << ENDJSON || true
{
  "Namespace": "$cwnamespace",
  "MetricData": [
    {
      "Dimensions": [
        {
          "Name": "InstanceId",
          "Value": "$instanceid"
        }
      ],
      "MetricName": "INFOLogLines",
      "Timestamp": "$metrictime",
      "Value": $info,
      "Unit": "Count"
    },
    {
      "Dimensions": [
        {
          "Name": "InstanceId",
          "Value": "$instanceid"
        }
      ],
      "MetricName": "ERRORLogLines",
      "Timestamp": "$metrictime",
      "Value": $error,
      "Unit": "Count"
    },
    {
      "Dimensions": [
        {
          "Name": "InstanceId",
          "Value": "$instanceid"
        }
      ],
      "MetricName": "SELFCHECKOKLogLines",
      "Timestamp": "$metrictime",
      "Value": $selfcheckok,
      "Unit": "Count"
    },
    {
      "Dimensions": [
        {
          "Name": "InstanceId",
          "Value": "$instanceid"
        }
      ],
      "MetricName": "UPLOADLogLines",
      "Timestamp": "$metrictime",
      "Value": $upload,
      "Unit": "Count"
    }
  ]
}
ENDJSON

# Publish log metrics to AWS CloudWatch
aws cloudwatch put-metric-data --region $cwregion --cli-input-json "$metricjson"
rm $tempfile
