set terminal pngcairo enhanced font "Arial,36" size 1920,1080
set datafile separator ","
set xlabel "Interval"
set ylabel "Throughput (Mbits/sec)"
set xdata time
set timefmt "%H:%M:%S"
set format x "%S"
set key bottom right

set output ARG1."/plot1.png"
plot    ARG1."/iperf3-5201.csv" using (timecolumn(1,"%H:%M:%S")):2 with lines title "5201", \
        ARG1."/iperf3-5202.csv" using (timecolumn(1,"%H:%M:%S")):2 with lines title "5202"
        #, \
        #ARG1."/iperf3-5203.csv" using (timecolumn(1,"%H:%M:%S")):2 with lines title "5203"