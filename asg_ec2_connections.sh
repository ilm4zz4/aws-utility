#!/bin/bash

# Copyright (c) 2021 Michele Rosellini

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

usage() {
   echo -e " 

Usage: bash $0 [ -a <string> -u <string> -t <string> ]

   -a : specify the name of autoscaling group

   -u : specify the user of ssh connection

   -k : specify ssh key file to establish the ssh connection

   -t : specify the type of IP address [public|private]

   -h : this help

   "
   exit 2 1>&2
   exit 1
}

# #Check Paramters
if [ "$#" -eq 0 ]; then
   usage
   exit 1
fi

while getopts "a:u:k:m:t:h" o; do
   case "${o}" in
   a)
      ASG=${OPTARG}
      ;;
   u)
      USER_NAME=${OPTARG}
      ;;
   k)
      KEY=${OPTARG}
      ;;
   t)
      TYPE=${OPTARG}
      ;;
   h)
      usage
      ;;
   *)
      usage
      ;;
   esac
done
shift $((OPTIND - 1))

AGGREGATOR="autoscaling describe-auto-scaling-groups --auto-scaling-group-name"
#echo "aws $AGGREGATOR $ASG | grep InstanceId | cut -d':' -f2 | sed 's/\"//g' | sed 's/[[:blank:]]//g'"
INSTANCE_IDs=$(aws $AGGREGATOR $ASG | grep InstanceId | cut -d':' -f2 | sed 's/\"//g' | sed 's/,//g' | sed 's/[[:blank:]]//g')

NUM_INSTANCE=`echo $INSTANCE_IDs | tr ' ' '\n' | wc -l | sed 's/ //g'`

if [ -z "$INSTANCE_IDs" ]; then
   echo ""
   echo "The AutoscalingGroup address is not valid o it is empty."
   echo ""
   exit 1
fi

NAME_TMUX_SESSION=$ASG
COUNT=0

TMUX_ALREADY_PRESENT=$(tmux ls | grep $NAME_TMUX_SESSION)
#Start tmux session in background if it doesn't exist
if [ "$TMUX_ALREADY_PRESENT" != "$ASG" ]; then
   tmux new -s $NAME_TMUX_SESSION -d
else
   tmux kill-section $NAME_TMUX_SESSION
fi

for id in $INSTANCE_IDs; do

   echo "Add $id to panel $((${COUNT}+1))/${NUM_INSTANCE}"

   if [ $COUNT -gt 0 ]; then
      tmux split-window -v -t $NAME_TMUX_SESSION
   fi

   #IP address to catch
   LABEL_ADDRESS="PrivateIpAddress"
   if [ "${TYPE}" == "public" ]; then
      LABEL_ADDRESS="PublicIpAddress"
   fi

   INSTANCE_ADDR=$(aws ec2 describe-instances --instance-ids $id | grep "\"$LABEL_ADDRESS\": \".*\"" | cut -d':' -f2 | sed 's/\"//g' | sed 's/,//g' | sed 's/[[:blank:]]//g')

   #Create tmux panel
   tmux send-keys -t $NAME_TMUX_SESSION:0.$COUNT "ssh -i ${KEY} ${USER_NAME}@${INSTANCE_ADDR}" C-m
   tmux select-layout -t $NAME_TMUX_SESSION tiled

   let COUNT+=1
done

tmux attach -t $NAME_TMUX_SESSION
