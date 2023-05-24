set terminal pngcairo enhanced font "Arial,36" size 1920,1080
set datafile separator ","
set xlabel "Interval"
set ylabel "Throughput (Mbits/sec)"
set xdata time
set timefmt "%H:%M:%S"
set format x "%S"
set key bottom right
threshold=400

set output ARG1."/plot1.png"
plot    ARG1."/iperf3-5201.csv" using ($0+1):(column(2) >= threshold ? column(2) : 1/0) with lines lw 3 title "SWITCH", \
        ARG1."/iperf3-5202.csv" using ($0+36):(column(2) >= threshold ? column(2) : 1/0) with lines lw 3 title "NAT"
#plot    ARG1."/iperf3-5201.csv" using (timecolumn(1,"%H:%M:%S")):(column(2) >= threshold ? column(2) : 1/0) with lines title "5201", \
#        ARG1."/iperf3-5202.csv" using (timecolumn(1,"%H:%M:%S")):(column(2) >= threshold ? column(2) : 1/0) with lines title "5202"
        #, \
        #ARG1."/iperf3-5203.csv" using (timecolumn(1,"%H:%M:%S")):2 with lines title "5203"

set output ARG1."/plot2.png"
set xrange [1:35]
# Plot the first set of data
plot    ARG1."/iperf3-5201.csv" using ($0+1):(column(2) >= threshold ? column(2) : 1/0) with lines lw 3 title "SWITCH", \
        ARG1."/iperf3-5202.csv" using ($0+1):(column(2) >= threshold ? column(2) : 1/0) with lines lw 5 title "NAT"

set output ARG1."/plot3.png"
set xrange [1:35]
# Plot the first set of data
plot    ARG1."/iperf3-5201.csv" using ($0+1):(column(2) >= threshold ? column(2) : 1/0) smooth cspline with lines lw 3 title "SWITCH", \
        ARG1."/iperf3-5202.csv" using ($0+1):(column(2) >= threshold ? column(2) : 1/0) smooth cspline with lines lw 5 title "NAT"
