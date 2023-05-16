#!/bin/bash

# a simple helper script I use to ping all nodes
# to see if they are up before I run the test
# scripts and playbooks

# Number of nodes
n=4

# Loop through each node
for i in $(seq 0 $n)
do
    if [ "$i" == "0" ] ; then
        hostname=server
    else
        hostname="node$i"
    fi
    # Generate IP addresses
    ip1="192.168.1.$((100 + i))"
    # Generate second IP address
    ip2="172.16.0.$((80 + i))"

    # Loop through each IP address
    for ip in "$ip1" "$ip2"
    do
        # Ping IP address and check if it's reachable
        if ping -c 1 $ip &> /dev/null
        then
            echo "$hostname ($ip): OK"
        else
            echo "$hostname ($ip): ***** NOK **** "
        fi
    done
done
