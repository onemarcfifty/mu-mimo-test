#set terminal png
set terminal pngcairo enhanced font "Arial,36" size 1920,1080
set datafile separator " "
set xlabel "Interval"
set ylabel "Throughput (Mbits/sec)"

# ARG1 = Subfolder Name
set output ARG1."/plot1.png"
plot ARG1."/plot1/plot-5201.txt" using 1:2 with lines title "node1", \
     ARG1."/plot1/plot-5202.txt" using 1:2 with lines title "node2", \
     ARG1."/plot1/plot-5203.txt" using 1:2 with lines title "node3", \
     ARG1."/plot1/plot-5204.txt" using 1:2 with lines title "node4"
set output ARG1."/plot2.png"
plot ARG1."/plot2/plot-5201.txt" using 1:2 with lines title "node1", \
     ARG1."/plot2/plot-5202.txt" using 1:2 with lines title "node2", \
     ARG1."/plot2/plot-5203.txt" using 1:2 with lines title "node3", \
     ARG1."/plot2/plot-5204.txt" using 1:2 with lines title "node4"
set output ARG1."/plot3.png"
plot ARG1."/plot3/plot-5201.txt" using 1:2 with lines title "node1", \
     ARG1."/plot3/plot-5202.txt" using 1:2 with lines title "node2", \
     ARG1."/plot3/plot-5203.txt" using 1:2 with lines title "node3", \
     ARG1."/plot3/plot-5204.txt" using 1:2 with lines title "node4"

