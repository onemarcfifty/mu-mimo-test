function startFunction() {
    # example: launch iperf3
    # if the first arg is "SERVER" then we start in server
    # mode, else in client mode
    if [ "X$1" = "XSERVER" ] ; then
        iperf3 -s -p $2 --logfile "/tmp/iperf.$2.log" &
    else
        iperf3 -c $1 -p $2 -t $3 -P $4 &
    fi
    # we add the PID of the started process to the LAST_PID list
    LAST_PID="$LAST_PID $!"
}

function stopFunction() {
    kill "$LAST_PID"
    LAST_PID=""
}
