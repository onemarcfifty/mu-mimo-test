#!/bin/bash

# include the global config
. ./global.config

# Default values for options
PLAYBOOK="playbook"

# run a playbook
function runPlayBook {

  # Loop over each line in the input file
  # we use File Descriptor 3 (STDERR+1)
  # to avoid problems with process substitution inside
  # the loop
  while read -r -u 3 line; do
    echo "Executing: $line"
    # Split the line into words
    words=($line)

    # Check the first word and perform the appropriate action
    case "${words[0]}" in
      "SEND")
        # Use mosquitto_pub to publish the rest of the line
        subTopic="${words[1]}"
        message="${line#SEND $subTopic }"  # Remove the "SEND " prefix
        mosquitto_pub -q 2 -h $MQTT_SERVER -t "$MQTT_TOPIC/$subTopic/COMMAND" -m "$message"
        ;;
      "WAIT")
        # Sleep for n seconds (n being the second word)
        seconds="${words[1]}"
        sleep "$seconds"
        ;;
      "WAITFOR")
        # Wait for a status of the specified node
        # Status messages will be retained, so no permanent listening required here
        subTopic="${words[1]}"
        expected_word="${words[2]}"
        message=""
        while [[ "$message" != *"$expected_word"* ]]; do
          message=$(mosquitto_sub -h $MQTT_SERVER -t "$MQTT_TOPIC/$subTopic/STATUS" -C 1)
          if [[ "$message" != *"$expected_word"* ]] ; then
            sleep 1
          fi
        done
        ;;
      "RECEIVE")
        # Use ncat to receive a file
        # first word is port number,
        # second word is filename
        portNumber="${words[1]}"
        outFile="${words[2]}"
        ncat -l $portNumber > $outFile & 
        ;;
      *)
        # Unknown command - print an error message and exit
        echo "Ignoring : $line"
        #exit 1
        ;;
    esac
  done 3< <(cat "$PLAYBOOK")
}

# Usage / Help function
function usage {
  echo "Usage: $0 [OPTIONS]"
  echo "  -h, --help        Show this help message"
  echo "  -d, --debug       Enable debug mode"
  echo "  -p, --playbook    Specify playbook file (default: playbook)"
  echo "  -a, --ansible     use Ansible Playbook to deploy"
  echo "  -s, --ssh         use ssh to deploy"
  echo "  -m, --mqttserver  specify an MQTT Server"
  echo "  -t, --mqtttopic   specify an MQTT Topic"
}

# Parse command line options
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) usage; exit ;;
    -d|--debug) DEBUG=true ;;
    -p|--playbook) PLAYBOOK="$2"; shift ;;
    -a|--ansible) USE_ANSIBLE=true; ANSIBLE_PLAYBOOK="$2"; shift ;;
    -m|--mqttserver) MQTT_SERVER="$2"; shift ;;
    -t|--mqtttopic) MQTT_TOPIC="$2"; shift ;;
    -s|--ssh) USE_SSH=true ;;
    *) echo "Unknown parameter passed: $1"; exit 1 ;;
  esac
  shift
done

if [[ "$DEBUG" = true ]]; then
  echo "Debug mode is ON"
  echo "Using playbook file: $PLAYBOOK"
  if [[ "$USE_ANSIBLE" = true ]]; then
    echo "Ansible will be used with Playbook $ANSIBLE_PLAYBOOK"
  fi
  echo "MQTT Server $MQTT_SERVER"
  echo "MQTT Topic  $MQTT_TOPIC"
  if [[ "$USE_SSH" = true ]]; then
    echo "ssh and scp will be used to deploy"
  fi
fi

if [[ "$USE_ANSIBLE" = true ]]; then
  # deploy the clientscripts to the nodes and start them
  ansible-playbook ansible.deploy.yaml
fi

if [[ "$USE_SSH" = true ]]; then
  # @@@ TODO @FIXME
  # deploy the clientscripts to the nodes with scp
  # start the scripts with ssh
  echo "ssh"
fi

if [ -f "$PLAYBOOK" ]; then
    runPlayBook
else 
    echo "Playbook $PLAYBOOK not found."
    exit 1
fi