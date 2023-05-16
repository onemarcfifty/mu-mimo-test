#!/bin/bash

# the main test script
# $1 - the test to run (A,B,C,D,E)
# $2 - the name of the test series (e.g. RouterABC)

SERVER_WAN_IP=10.50.50.2
SERVER_LAN_IP=192.168.1.100
SERVER_CONTROL_IP=192.168.139.119
SERVER_LAN_INTERFACE=enp3s0f1
SERVER_WIFI_INTERFACE=wlp2s0
LOCAL_IP=192.168.1.99

clear
echo "Running Test $1 for Subject $2"
echo
mkdir -p RouterTests/$2/Test$1

# ###################################
# Test A - is it phoning home ?
# take a tcpdump pcap on the gateway
# ###################################

if [ "XA" == "X$1" ] ; then
	cat <<-EOF
	IS IT PHONING HOME?
	===================

	Connect the USB Ethernet to Router LAN
	Connect VLAN 89 to Router WAN
	Now launching remote tcpdump on the gateway
	Switch on the Router and wait for Cloud Access Consent
	Then stop with CTRL-C 
	Re-connect and configure Router, then again CTRL-C
	EOF
	if [ "X" == "X$3" ]; then
		GATEWAY=$(ip route | grep default | cut -d ' ' -f 3)
	else
		GATEWAY=$3
	fi
	if [ "X" == "X$4" ]; then
		REMOTEIF=br-lan.89
	else
		REMOTEIF=$4
	fi
	# Now launch tcpdump on the Gateway and log packets before the consent message
	ssh $GATEWAY "sudo tcpdump -i $REMOTEIF -vv -w -"  >RouterTests/$2/Test$1/noconsent.pcap
	# Now launch tcpdump on the Gateway and log packets AFTER the consent message (if any)
	ssh $GATEWAY "sudo tcpdump -i $REMOTEIF -vv -w -"  >RouterTests/$2/Test$1/consent.pcap
	cat <<-EOF
	PREP FOR NEXT TEST
	==================

	Set the WAN interface of the Router to 10.50.50.1/24
	Set the LAN range to 192.168.1.0/24
	Connect Control Node  USB Ethernet     to Router LAN
	Connect Server        USB Ethernet     to Router WAN
	Connect Server        builtin Ethernet to ROUTER LAN
	Reboot the Router
	EOF

fi

# ###################################
# Test B - Wired speed test 
#          (switched and NATed)
# ###################################

# Spawn an iperf3 GUI remotely on the Server over ssh
# and keep track of the PID
function spawn_iperf_server() {
	SERVERINTERFACE=$1
	SERVERPORT=$2
	WINDOWTITLE=iperf${SERVERPORT}
	if [ $SERVERINTERFACE == $LOCAL_IP ]; then
		# the iperf shall run locally
		cd servers
		bash -c "cd /tmp ; python3 iperf.py -S -L -ip $SERVERINTERFACE -p $SERVERPORT -A -T $WINDOWTITLE" &
		sshPID="$sshPID $!"
		cd ..
	else
		# the iperf shall run remotely
		(ssh -F ssh-config -XY server "cd /tmp ; nohup python3 iperf.py -S -L -ip $SERVERINTERFACE -p $SERVERPORT -A -T $WINDOWTITLE &") >/dev/null 2>&1 &
		sshPID="$sshPID $!"
	fi
	echo "SPAWNED $sshPID"
}

# destroy the iperf3 Server GUIs remotely and kill the ssh processes
function destroy_iperf_server() {
	echo $sshPID
	kill $sshPID ; sshPID=
	ssh -F ssh-config server "killall python3 ; killall iperf3" >/dev/null 2>&1
	killall python3 ; killall iperf3
}

# grab the test results from the server with scp
function grab_iperf_results() {
	scp -rF ssh-config server:/tmp/iperf3-5201.csv RouterTests/$2/Test$1/
	scp -rF ssh-config server:/tmp/iperf3-5202.csv RouterTests/$2/Test$1/
	scp -rF ssh-config server:/tmp/iperf3-5203.csv RouterTests/$2/Test$1/
	scp -rF ssh-config server:/tmp/iperf3-5204.csv RouterTests/$2/Test$1/
}

if [ "XB" == "X$1" ] ; then
	cat <<-EOF
	WIRED SPEED TESTS
	=================

	Set the WAN interface of the Router to 10.50.50.1/24
	Set the LAN range to 192.168.1.0/24
	Connect Control Node  USB Ethernet     to Router LAN
	Connect Server        USB Ethernet     to Router WAN
	Connect Server        builtin Ethernet to ROUTER LAN
	iPerf3 GUI now starting on Server. 
	Press key when ready
	EOF
	read

	# First, we run the switch test
	echo "Switch Test"
	ansible-playbook -l servers ansible.deploy.yaml
	spawn_iperf_server $SERVER_LAN_IP 5201
	sleep 5
	wmctrl -r "iperf5201" -e "0,1921,0,-1,-1"	
	iperf3 -t 15 -c    $SERVER_LAN_IP -p 5201
	iperf3 -t 15 -R -c $SERVER_LAN_IP -p 5201
	destroy_iperf_server
	sleep 2

	if [ "XNONAT" != "X$3" ] ; then
		# and then the NAT test
		# We need a route to the WAN side of the device
		echo "adding route to the WAN side"
		sudo ip route add 10.50.50.0/24 via 192.168.1.1 >/dev/null 2>&1
		echo "NAT Test"
		spawn_iperf_server $SERVER_WAN_IP 5202
		sleep 5
		wmctrl -r "iperf5202" -e "0,1921,0,-1,-1"	
		iperf3 -t 15 -c    $SERVER_WAN_IP -p 5202
		iperf3 -t 15 -R -c $SERVER_WAN_IP -p 5202
		destroy_iperf_server
	fi

	echo "Now running Flent rrul tests for SWITCH - please wait"
	
	flent rrul -H $SERVER_LAN_IP -D RouterTests/$2/Test$1 -t SWITCH_Stock_NoQoS
	if [ "XNONAT" != "X$3" ] ; then
		echo "Now running Flent rrul tests for NAT - please wait"
		flent rrul -H $SERVER_WAN_IP -D RouterTests/$2/Test$1 -t NAT_Stock_NoQoS
		cat <<-EOF

		QoS/SQM/Bufferbloat test
		========================

		Please check if there are any QoS / SQM related settings in the Router GUI
		and enable them. 

		Press Enter when ready
		EOF
		read
		flent rrul -H $SERVER_WAN_IP -D RouterTests/$2/Test$1 -t NAT_Stock_With_QoS

		echo "deleting route to the WAN side"
		sudo ip route del 10.50.50.0/24 via 192.168.1.1 >/dev/null 2>&1
	fi

	# grab the test results from the server
#	scp -rF ssh-config server:/tmp/*.csv RouterTests/$2/Test$1/
	grab_iperf_results $1 $2
	cat <<-EOF

	PREP FOR NEXT TEST
	==================

	Create a Wifi SSID with the largest possible
	bandwidth called 1m50 on the Router
	Disconnect the Control Node from the router
	Power up the remote nodes and connect them to the Wifi
	EOF
fi


# ###################################
# Test C - Wireless speed tests
# ###################################


function destroyRoutes() {
	echo "Removing local and remote routes"
	# Let's switch off masquerading and ipv4 Forward on the server
	ssh -F ssh-config server "sudo sh -c 'echo 0 > /proc/sys/net/ipv4/ip_forward'"
	ssh -F ssh-config server "sudo sh -c 'iptables -t nat -D POSTROUTING -o $SERVER_LAN_INTERFACE -j MASQUERADE'"
	ssh -F ssh-config server "sudo sh -c 'iptables -t nat -D POSTROUTING -o $SERVER_WIFI_INTERFACE -j MASQUERADE'"

	# delete the local routes
#	sudo ip route del 192.168.1.0/24 via $SERVER_CONTROL_IP
#	sudo ip route del 10.50.50.0/24 via $SERVER_CONTROL_IP
}

function createRoutes() {
	destroyRoutes
	echo "Creating local route"
	sudo ip route add 10.50.50.0/24 via $SERVER_LAN_IP
	# we also need to tell the Server to forward ipv4 packets and
	# to masquerade packets on the LAN wire. We do not need masquerading on others
	# as connection to the local WAN interface will go to the INPUT chain
	ssh -F ssh-config server "sudo sh -c 'echo 1 > /proc/sys/net/ipv4/ip_forward'"
	ssh -F ssh-config server "sudo sh -c 'iptables -t nat -A POSTROUTING -o $SERVER_LAN_INTERFACE -j MASQUERADE'"
	ssh -F ssh-config server "sudo sh -c 'iptables -t nat -A POSTROUTING -o $SERVER_WIFI_INTERFACE -j MASQUERADE'"
}


if [ "XC" == "X$1" ] ; then
	killall orchestrate.sh; killall ncat ; 	killall python3 ; killall iperf3 ; killall mosquitto_pub ; killall mosquitto_sub
	clear
	cat <<-EOF
	WIRELESS SPEED TESTS (STATIC)
	=============================

	Create a Wifi SSID with the largest possible
	bandwidth called 1m50 on the Router
	Disconnect the Control Node from the router
	Power up the remote nodes and connect them to the Wifi
	Press any key when ready
	EOF
	read
	# create the local and remote routes for the test scenario
	createRoutes
	# deploy the scripts to the clients
	ansible-playbook -l server ansible.deploy.yaml
	# special case node1: It does not have an IOT Wifi interface and needs
	# to route over the test interface ;-(
	ssh -F ssh-config node1  "sudo ip route add 172.16.0.0/24 via 192.168.1.100"
	ssh -F ssh-config node1  "sudo /tmp/qdisc.sh"

	destroy_iperf_server
	spawn_iperf_server $SERVER_LAN_IP 5201
	ansible-playbook -l node2:node3 ansible.deploy.yaml
	sleep 2
	wmctrl -r "iperf5201" -e "0,1921,0,-1,-1"	

	# before we do the playbooks, let's do a quick iw scan "over the counter"
	ssh -F ssh-config node2 "sudo iw wlp3s0 scan" >RouterTests/$2/Test$1/iwscan_node2
	sudo iw wlp3s0 scan >RouterTests/$2/Test$1/iwscan_local
	# run the first playbook
	./orchestrate.sh -p playbooks/wifitest1.txt
	# destroy the iperf servers
	destroy_iperf_server
	# grab the results from the server
	mv results-test1.csv RouterTests/$2/Test$1/
	mv results*.log RouterTests/$2/Test$1/
	# Terminate all clients
	./orchestrate.sh -p playbooks/terminate_all.txt
	# destroy the Routes
	#destroyRoutes
fi	

# ###################################
# Test D - MU-MIMO tests
# ###################################

if [ "XD" == "X$1" ] ; then
	killall orchestrate.sh; killall ncat ; 	killall python3 ; killall iperf3 ; killall mosquitto_pub ; killall mosquitto_sub
	clear
	cat <<-EOF
	WIRELESS MU-MIMO TESTS, one Wifi5 Client
	========================================

	EOF
	# create the local and remote routes for the test scenario
	createRoutes
	ansible-playbook -l servers ansible.deploy.yaml
	destroy_iperf_server
	spawn_iperf_server $SERVER_LAN_IP 5201
	spawn_iperf_server $LOCAL_IP 5202
	spawn_iperf_server $SERVER_LAN_IP 5203
	spawn_iperf_server $LOCAL_IP 5204
	
	# deploy the scripts to the clients
	ansible-playbook -l nodes ansible.deploy.yaml
	sleep 2
	
	# position the windows nicely for video
	wmctrl -r "iperf5201" -e "0,1921,0,-1,-1"	
	wmctrl -r "iperf5202" -e "0,2521,0,-1,-1"	
	wmctrl -r "iperf5203" -e "0,3121,0,-1,-1"	
	wmctrl -r "iperf5204" -e "0,1921,670,-1,-1"	

	./orchestrate.sh -p playbooks/wifitest2.txt
	# grab the results from the server
	mv results*.csv RouterTests/$2/Test$1/
	mv results*.log RouterTests/$2/Test$1/
	cp /tmp/iperf3-5202.csv RouterTests/$2/Test$1/results-mimo-5202-wifi56-UDP.csv
	cp /tmp/iperf3-5204.csv RouterTests/$2/Test$1/results-mimo-5204-wifi56-UDP.csv
	cp playbooks/wifitest2.txt playbooks/wifitest2.tcp.txt
	sed -i s/UDP/TCP/g playbooks/wifitest2.tcp.txt
	echo "#################### TCP Version ###################"

	./orchestrate.sh -p playbooks/wifitest2.tcp.txt
	# grab the results from the server
	mv results*.csv RouterTests/$2/Test$1/
	mv results*.log RouterTests/$2/Test$1/
	cp /tmp/iperf3-5202.csv RouterTests/$2/Test$1/results-mimo-5202-wifi56-TCP.csv
	cp /tmp/iperf3-5204.csv RouterTests/$2/Test$1/results-mimo-5204-wifi56-TCP.csv

	# destroy the iperf servers
	destroy_iperf_server
	# Terminate all clients
	./orchestrate.sh -p playbooks/terminate_all.txt
	# destroy the Routes
	#destroyRoutes
fi	

# ###################################
# Test E - MU-MIMO tests
# ###################################

if [ "XE" == "X$1" ] ; then

	# Quick and dirty - kill all rogue processes on all nodes
	for i in node1 node2 server grbl node3 ; do ssh -F ssh-config $i "killall clientscript.sh ; killall iperf3 ; killall python3 ; killall ncat; killall mosquitto_pub ; killall mosquitto_sub" ; done
	killall orchestrate.sh; killall ncat ; 	killall python3 ; killall iperf3 ; killall mosquitto_pub ; killall mosquitto_sub
	clear

	cat <<-EOF
	WIRELESS MU-MIMO TESTS, with moving nodes
	=========================================

	EOF
	# create the local and remote routes for the test scenario

	# create the local and remote routes for the test scenario
	createRoutes
	# node1 has no route to the MQTT Server
	ssh -F ssh-config node1 "sudo ip route add 172.16.0.0/24 via $SERVER_LAN_IP"
	ssh -F ssh-config node1 "sudo bash -c '/tmp/qdisc.sh'"


	ansible-playbook -l servers ansible.deploy.yaml
	destroy_iperf_server
	spawn_iperf_server $SERVER_LAN_IP 5201
	spawn_iperf_server $SERVER_LAN_IP 5202
	spawn_iperf_server $LOCAL_IP 5203

	# deploy the scripts to the clients
	ansible-playbook -l node1:node2:node3:grbl ansible.deploy.yaml
	sleep 2
	
	# position the windows nicely for video
#	wmctrl -r "iperf5201" -e "0,1921,0,-1,-1"	
#	wmctrl -r "iperf5202" -e "0,2521,0,-1,-1"	
#	wmctrl -r "iperf5203" -e "0,3121,0,-1,-1"	

	wmctrl -r "iperf5201" -e "0,1,0,-1,-1"	
	wmctrl -r "iperf5202" -e "0,621,0,-1,-1"	
	wmctrl -r "iperf5203" -e "0,1221,0,-1,-1"	

	# duplicate the playbook for TCP 
	cp playbooks/wifitest3.txt playbooks/wifitest3.tcp.txt
	sed -i s/UDP/TCP/g playbooks/wifitest3.tcp.txt
	cp playbooks/wifitest4.txt playbooks/wifitest4.tcp.txt
	sed -i s/UDP/TCP/g playbooks/wifitest4.tcp.txt

	# ###### STATIC TESTS

	# center the nodes on the ramp
	./orchestrate.sh -p playbooks/centergrbl.txt
	# run the first playbook (static MU MIMO)
	./orchestrate.sh -p playbooks/wifitest3.txt
	mkdir -p RouterTests/$2/Test$1/static.udp
	mv results*.csv RouterTests/$2/Test$1/static.udp/
	mv results*.log RouterTests/$2/Test$1/static.udp/
	cp /tmp/iperf3-5203.csv RouterTests/$2/Test$1/static.udp/
	# the same with TCP
	./orchestrate.sh -p playbooks/wifitest3.tcp.txt
	mkdir -p RouterTests/$2/Test$1/static.tcp
	mv results*.csv RouterTests/$2/Test$1/static.tcp/
	mv results*.log RouterTests/$2/Test$1/static.tcp/
	cp /tmp/iperf3-5203.csv RouterTests/$2/Test$1/static.tcp/

	# ###### MOVING TESTS

	# zero the axes
	./orchestrate.sh -p playbooks/zerogrbl.txt
	# move the axes
	./orchestrate.sh -p playbooks/movegrbl.txt
	# run the first playbook (moving MU MIMO)
	./orchestrate.sh -p playbooks/wifitest4.txt
	mkdir -p RouterTests/$2/Test$1/moving.udp
	mv results*.csv RouterTests/$2/Test$1/moving.udp/
	mv results*.log RouterTests/$2/Test$1/moving.udp/
	cp /tmp/iperf3-5203.csv RouterTests/$2/Test$1/moving.udp/
	# the same with TCP
	# zero the axes
	./orchestrate.sh -p playbooks/zerogrbl.txt
	# move the axes
	./orchestrate.sh -p playbooks/movegrbl.txt
	./orchestrate.sh -p playbooks/wifitest4.tcp.txt
	mkdir -p RouterTests/$2/Test$1/moving.tcp
	mv results*.csv RouterTests/$2/Test$1/moving.tcp/
	mv results*.log RouterTests/$2/Test$1/moving.tcp/
	cp /tmp/iperf3-5203.csv RouterTests/$2/Test$1/moving.tcp/

	# zero the axes
	./orchestrate.sh -p playbooks/zerogrbl.txt

	# destroy the iperf servers
	destroy_iperf_server
	# shutdown the nodes
	./orchestrate.sh -p playbooks/terminate_all.txt
	# destroy the Routes
	#destroyRoutes
fi	
