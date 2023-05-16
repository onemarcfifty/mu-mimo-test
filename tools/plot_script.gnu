set datafile separator ","
set xlabel "Time"
set ylabel "Throughput"
set xdata time
set timefmt "%H:%M:%S"
set format x "%H:%M:%S"
#plot ARG1 using (timecolumn(1,"%H:%M:%S")):2 with lines title "Throughput"
plot "./RouterTests/WAX206-STOCK/TestC/results-test1.csv" using (timecolumn(1,"%H:%M:%S")):2 with lines title "Throughput"
