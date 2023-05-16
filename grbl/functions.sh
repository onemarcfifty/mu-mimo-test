function startFunction() {
    # launch the python grbl controller on 
    # serial port $2 and execute G-Code File $1

    #python3 grbl_control.py -f $1 -p $2
    #RESULTCODE=$?
    #return $RESULTCODE

    python3 grbl_control.py -f $1 -p $2 &
    LAST_PID="$LAST_PID $!"
}

function stopFunction() {
    kill "$LAST_PID"
    LAST_PID=""
}
