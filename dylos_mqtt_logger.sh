#!/bin/bash 

# This script processes dylos serial output 
# into a log and publishes an mqtt message to a broker
# 
# ----------------------------------------------

# Initialize variables


# Check if directories, linkds and files  already exist 
# if not, create them
if [ ! -d /var/log/dylos ]; then
      mkdir /var/log/dylos;
fi;

if [ ! -h /tmp/dylos.mqtt.pub ]; then
     touch /tmp/dylos.mqtt.pub;
fi;

if [ ! -h /tmp/dylos.data.latest ]; then
     touch /tmp/dylos.data.latest;
fi;

if [ ! -h /tmp/mqtt.payload ]; then
     touch /tmp/mqtt.payload ];
fi;

# This subroutine blanks the previous dylos.data log files,
# adds a timestamp and logs the incoming data line.
#
# assumes dylos data in the following format: 
# "all_particle_integer"",""small_particle_integer""<cr>"
# Dylos comm is 9600, 8bits, 1_stop_bit, the data is
# particle count averaged over a minute.
while [ -c /dev/ttyUSB0 ]; do
     #echo "Logging /dev/ttyUSB0..";
     cat /dev/ttyUSB0 | while read data; do
          if [ -n "$data" ]; then
                echo "`date \"+%s\"`,$data" > /tmp/dylos.data.latest;
		  echo "`date -Iminutes`,$data" >> /var/log/dylos/airquality-`date -Idate`.log  ;
                DF=$(echo "`date -Idate`");
                PCALL=$(echo $data |cut -f1 -d',');
                PCSM=$(echo $data |cut -f2 -d',');
                TIMESTAMP=$(echo "`date \"+%s\"`");
                TYPE="type"
                GWEUI="00-08-00-4A-4F-46"
                DEVEUI="00-08-80-80-00-01-1f-f9"
                SENSNAME="dylos1"
                APP="opennms"
                FMT="json"
                TYPE="airquality"
                MQTTTOPIC=$(echo "iot/type/mosquitto/gweui/$GWEUI/deveui/$DEVEUI/sensorname/$SENSNAME/app/$APP/fmt/$FMT/type/$TYPE")
                MQTTPAYLOAD=$(echo "{" \""gweui"\": \""$GWEUI"\", \""deveui"\": \""$DEVEUI"\", \""datetime"\": \""$DF"\", \""timestamp"\": "$TIMESTAMP", \""metrics"\": { \""allpart"\": "$PCALL", \""smpart"\": "$PCSM" } "}")
                echo "$MQTTTOPIC : $MQTTPAYLOAD" > /tmp/dylos.mqtt.pub;
                echo "$MQTTPAYLOAD" > /tmp/mqtt.payload;
                mosquitto_pub -h 63.231.197.29 -f /tmp/mqtt.payload -t $MQTTTOPIC;
          fi;
     done;
done;

# echo "dylos logging stopped"
