function startFunction() {
    # example: launch iperf3
    # if the first arg is "SERVER" then we start in server
    # mode, else in client mode
    if [ "X$1" = "XSERVER" ] ; then
        iperf3 -s -p $2 --logfile "/tmp/iperf.$2.log" --forceflush &
    else
        if [ "X$5" = "XREVERSE" ] ; then
            if [ "X$6" = "XUDP" ] ; then
                if [ -z "${7}" ] ; then
                    iperf3 -R -u -b 940M -c $1 -p $2 -t $3 -P $4 --logfile "/tmp/iperf.$2.log" --forceflush &
                else
                    iperf3 -R -u -b $7 -c $1 -p $2 -t $3 -P $4 --logfile "/tmp/iperf.$2.log" --forceflush &
                fi
            else
                iperf3 -R -c $1 -p $2 -t $3 -P $4 --logfile "/tmp/iperf.$2.log" --forceflush &
            fi
        else
            if [ "X$6" = "XUDP" ] ; then
                if [ -z "${7}" ] ; then
                    iperf3 -u -b 940M -c $1 -p $2 -t $3 -P $4 --logfile "/tmp/iperf.$2.log" --forceflush &
                else
                    iperf3 -u -b $7 -c $1 -p $2 -t $3 -P $4 --logfile "/tmp/iperf.$2.log" --forceflush &
                fi
            else
                iperf3 -c $1 -p $2 -t $3 -P $4 --logfile "/tmp/iperf.$2.log" --forceflush &
            fi
        fi
    fi
    # we add the PID of the started process to the LAST_PID list
    LAST_PID="$LAST_PID $!"
}

function stopFunction() {
    killall -s INT iperf3
    sleep 1
    killall iperf3
    LAST_PID=""
}

function initFunction() {
    killall iperf3
    LAST_PID=""
    rm /tmp/iperf*.log
}
