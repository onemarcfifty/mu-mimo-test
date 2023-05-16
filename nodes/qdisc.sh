# this script is for nodes that don't have a second WIFI interface
# for the MQTT backbone.
# As we will have congestion on the Wifi during tests, we need
# to prioritize TCP traffic (i.e. MQTT) over UDP (iperf3).

# Delete the filters
tc filter del dev enp0s3 parent 1: protocol ip prio 1
tc filter del dev enp0s3 parent 1: protocol ip prio 2
tc qdisc del dev enp0s3 root

# Create a root qdisc using PRIO
tc qdisc add dev enp0s3 root handle 1: prio
# Create a higher priority band for TCP traffic
tc qdisc add dev enp0s3 parent 1:1 handle 10: sfq perturb 10
# Create a lower priority band for UDP traffic
tc qdisc add dev enp0s3 parent 1:2 handle 20: sfq perturb 10
# Assign TCP traffic to the higher priority band
tc filter add dev enp0s3 protocol ip parent 1: prio 1 u32 match ip protocol 6 0xff flowid 1:1
# Assign UDP traffic to the lower priority band
tc filter add dev enp0s3 protocol ip parent 1: prio 2 u32 match ip protocol 17 0xff flowid 1:2
