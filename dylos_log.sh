#!/bin/ash 
# This script processes dylos serial output 
# into a log via temp file /tmp/dylos.data.latest
# root@airquality1:~# cat /bin/log-dylos.sh 
# 
# ----------------------------------------------

# This subroutine checks if /var/log/dylos symbolic link already exists 
# if not, it checks if dylos directory is created, if so it creates
# the link, otherwise it sends an error message.
# creates the link if 
# 

#if [ ! -h /var/log/dylos ]; then
#         if [ -d /mnt/sda1/dylos ]; then
#                 ln -s /mnt/sda1/dylos /var/log/dylos;
#         else
#           echo "sda1 not mounted or dylos directory not created";
#         fi;
#fi;

if [ ! -d /var/dylos ]; then
        mkdir /var/dylos;
fi;

if [ ! -h /var/log/dylos ]; then
     ln -s /var/dylos /var/log/dylos;
fi;

# This subroutine blanks the previous dylos.data log file, then 
# adds a timestamp and logs the incoming data line.
# assumes dylos data in the format: 
# "small_particle_integer"",""large_particle_integer""<cr>"
# Dylos comm is 9600, 8bits, 1stop and data is
# an average reading over a minute.

while [ -c /dev/ttyUSB0 ]; do
     #echo "Logging /dev/ttyUSB0..";
     cat /dev/null > /var/log/dylos/dylos.data;
     cat /dev/null > /tmp/dylos.data;
     cat /dev/null > /tmp/dylos.data.latest;
     cat /dev/ttyUSB0 | while read data; do
          if [ -n "$data" ]; then
                  echo "[ `date \"+%s\"`, $data ]," > /tmp/dylos.data.latest;
                  #cat /tmp/dylos.data.latest;
                  tail -n 3600 /var/log/dylos/dylos.data > /tmp/dylos.data ;
                  cat /tmp/dylos.data /tmp/dylos.data.latest > /var/log/dylos/dylos.data;
                  echo "`date -Iminutes`,$data" >> /var/log/dylos/airquality-`date -Idate`.log  ;
          fi;
     done;
done;
