#!/bin/bash

# #############################################
# The deployment script for the MU-MIMO
# test environment
# #############################################

# Let's install the necessary software
sudo apt update
sudo apt install wget ncat mosquitto-clients python3-pip openssh-server
sudo pip install ansible

# first download the MQTT orchestrator scripts from Marc's github
wget https://raw.githubusercontent.com/onemarcfifty/MQTT-Orchestrate/main/clientscript.sh -O clientscript.sh
wget https://raw.githubusercontent.com/onemarcfifty/MQTT-Orchestrate/main/orchestrate.sh  -O orchestrate.sh

# we also need the iperf.py and meter.py from the iperf3 GUI repo from Marc
wget https://raw.githubusercontent.com/onemarcfifty/iperf3-GUI/master/iperf.py -O servers/iperf.py
wget https://raw.githubusercontent.com/onemarcfifty/iperf3-GUI/master/meter.py -O servers/meter.py

# now we deploy the required software to the clients
ansible-playbook -l server:nodes ansible.deploy-infrastructure.yaml
