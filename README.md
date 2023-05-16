## mu-mimo-test

I am using the scripts and tools in this repo to automate Wi-fi Router tests. When I test a Wi-fi Router, I want to know the following things:

- (A) is it phoning home (before I consent)?
- (A) is it phoning home (after I consent)?
- (B) Ethernet performance on the switch (no routing)
- (B) Ethernet performance over the Router (NAT performance)
- (C) Maximum Wi-fi burst rate (one Wi-fi client)
- (D) Wi-fi Performance with multiple Nodes (MU-MIMO tests)

(The letters indicate the test scenario)

For this, I have created a script `runtest.sh` that conducts the tests automatically. You can call it with at least two parameters: 

- the Test scenario (A-E, see above)
- the name of the test, e.g. the name of the router

### How does it work?

#### Test A - (is it phoning home?)

This test will run tcpdump using ssh on the default gateway and log all packets going from the examined Router to the Internet for later analysis. The Output of the tcpdump is piped back over ssh. You just need to make sure that the Interface connected to the examined Router does not use the Router as a Gateway, because in this case the client might "pollute" the tests on the Gateway.

#### Tests B-E

The following scripts (i.e. Scenarios B,C,D,E) will first run an Ansible Playbook `ansible.deploy.yaml` to deploy necessary software, scripts etc. to the participating nodes. The scripts, tools, files need to be placed in a subdirectory that corresponds to the Ansible group name of the participating node (e.g. servers, nodes...) as defined in the `ansible.inventory.yaml` Inventory File.

For the Wi-fi Tests, I am using my [MQTT Orchestrator](https://github.com/onemarcfifty/MQTT-Orchestrate) to coordinate actions over all participating nodes. For this, the `clientscript.sh` and `global.config` files are copied to the remote node, and the client script is then exeuted there by the Ansible Playbook

#### Test B - (Ethernet Performance)

This test runs the [iperf3 GUI](https://github.com/onemarcfifty/iperf3-GUI) on the `server` node (which is connected to both the WAN and LAN port of the Router). For this, we run the GUI over X11 forwarding (ssh -XY) on the server and display it locally. It then executes iperf3 in client mode on the control node, first in Upload mode to the LAN address of the Server, then in Download mode, then the same two tests to the WAN address of the Router.

In fact, I set the WAN address of the router to be `10.50.50.1` for all tests, the Server WAN address to `10.50.50.2` and the LAN network to `192.168.1.0/24` - this way, the Router can only go to the Server node on the WAN side, there is no Internet connection.

Last but not least, the Script will execute a rrul (Real time Response Under Load) test using flent ("Buffer Bloat" test, QoS test)

#### Test C - (Wi-Fi burst test)

In this test scenario I am seeking to get the maximum performance of the Wi-Fi interface for one connected node. Similar to the previous test, I run the iperf3 GUI on the server and then use the MQTT Orchestrator to run the playbook `wifitest1.txt` which basically runs iperf3 on the remote nodes in various combinations and finally uploads the iperf3 log files to the control node.

#### Test D - (Wi-Fi MU-MIMO test)

The test setup is similar to the previous test, just the scenario this time is to test the performance of the Wi-Fi with multiple clients connected to it. We are launching 4 instances of iperf3 on the server and the local control node and then run the playbook `wifitest2.txt` using the Orchestrator. The playbook is duplicated by the script, all Occurences of "UDP" are replaced by "TCP" and then the playbook runs a second time (in order to see if there are different behaviors between UDP and TCP).

#### Test E - (Real Life Wi-Fi MU-MIMO test with moving targets)

This scenario essentially runs the same tests like the previous one, just - this time two nodes are MOVING! For this I use a [grbl controller](https://github.com/grbl/grbl) on an Arduino which is connected to a Raspberry Pi (the `grbl-controller` node) and to two NEMA 23 Stepper motors which in turn move two of the Wi-fi clients over two 5m (15 feet) long ramps while the tests run.

The purpose of this test is to see if the beamforming code on the Router adapts to targets in motion. Also, while the targets are moving, the obstacles in the way (Walls) cause additional radio wave attenuation.

### Analyzing the results

All results will be put into a subfolder structure `RouterTests/(Router Name)/Test[A-E]/` - for Test A, there's two pcap files (`noconsent.pcap` and `consent.pcap`) which contain the captured data before and after consent. these logs can be analyzed using `Wireshark`. 

For all tests that run iperf3, there will be a distinct csv file containing the timestamp and the measured throughput for each port we ran iperf3 on. These results can be plotted with `gnuplot` or the like. Some example gnuplot scripts are in the `tools` subfolder.

For test scenarios running flent, the flent test results are packed in a gzip file. They can be plotted with the `flent` tool using the `--gui` parameter for example.

## Test Progress

At the moment I am testing the following Wi-Fi Routers:

- The XIAOMI AX3200
- The XIAOMI REDMI AX6000
- The XIAOMI AX3600 AIOT
- The Banana Pi R3
- The TP-Link OMADA EAP225 Outdoor V3
- The TP-Link OMADA EAP615 Wall
- The Linksys MR8300
- The Netgear WAX206

All these routers are supported by OpenWrt. Hence the test sequence will be:

1. Conduct all tests (A-E) with Stock Firmware
2. Flash OpenWrt on all devices
3. Redo all tests with OpenWrt.

There will - of course - be videos about this [on my YouTube Channel](https://www.youtube.com/c/onemarcfifty);-)

