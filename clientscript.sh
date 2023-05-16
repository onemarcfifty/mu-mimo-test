#!/bin/bash

# ####################################
# MQTT Orchestrate
# Client side script
# ####################################

# include the global options
. ./global.config

# include the group/client specific script
. ./functions.sh 

# the first parameter to the script is the subtopic to listen on
MY_TOPIC=$1

# publish_mqtt feeds back the current status into the STATUS subtopic
# the status will be retained
function publish_mqtt() {
  mosquitto_pub -q 2 -r -h $MQTT_SERVER -t $MQTT_TOPIC/$MY_TOPIC/STATUS -m "$1"
}

# SendFile is used to send a file using ncat to an arbitrary socket
function sendFile {
  FILENAME=$1
  RECEIVER_IP=$2
  RECEIVER_PORT=$3
  cat $FILENAME | ncat $RECEIVER_IP $RECEIVER_PORT
  #ncat $RECEIVER_IP $RECEIVER_PORT < <(cat $FILENAME)
  if [ "XTRUNCATE" = "X$4" ] ; then
    truncate -s 0 "$FILENAME"
  fi
}

# the function action() is called whenever something is received over MQTT
function action() {
  #COMMAND=$( echo "$1" |cut -d ' ' -f1 )
  COMMAND=$1
  publish_mqtt "Command $COMMAND received"
  shift
  case "$COMMAND" in
    "START")
      publish_mqtt "PARAM-$1-$2-$3-$4-$5-$6-$7-$8"
      startFunction $@
      publish_mqtt "STARTED"
      ;;
    "STOP")
      stopFunction $@
      publish_mqtt "STOPPED"
      ;;
    "SENDFILE")
      publish_mqtt "SENDING FILE"
      sendFile $@
      publish_mqtt "SENT FILE"
      ;;
    "TERMINATE")
      # Terminate the program when the line contains "TERMINATE"
      publish_mqtt "TERMINATED"
      killall mosquitto_sub
      rm $fifo
      exit 0
      ;;
    *)
      # Do something for any other line
      ;;
  esac
}

fifo=mosquitto_sub_fifo$MY_TOPIC
mkfifo $fifo
mosquitto_sub -h $MQTT_SERVER -t $MQTT_TOPIC/$MY_TOPIC/COMMAND >$fifo &
initFunction
publish_mqtt "ALIVE"

# infinite loop
while true ; do
  read LINE < $fifo
  echo "*** $LINE"
  action $LINE
done
