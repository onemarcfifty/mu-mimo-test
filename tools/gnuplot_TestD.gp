#set terminal png
set terminal pngcairo enhanced font "Arial,36" size 1920,1080
set datafile separator " "
set xlabel "Interval"
set ylabel "Throughput (Mbits/sec)"

# ARG1 = Subfolder Name

do for [i = 1:4] {
     plotDir = ARG1."/plot".i
     set output ARG1."/plot".i.".png"
     plot plotDir."/plot-5201.txt" using 1:2 with lines title "node1", \
          plotDir."/plot-5202.txt" using 1:2 with lines title "node2", \
          plotDir."/plot-5203.txt" using 1:2 with lines title "node3", \
          plotDir."/plot-5204.txt" using 1:2 with lines title "node4"
     set output ARG1."/plot".i."-bezier.png"
     plot plotDir."/plot-5201.txt" using 1:2 with lines smooth bezier title "node1", \
          plotDir."/plot-5202.txt" using 1:2 with lines smooth bezier title "node2", \
          plotDir."/plot-5203.txt" using 1:2 with lines smooth bezier title "node3", \
          plotDir."/plot-5204.txt" using 1:2 with lines smooth bezier title "node4"
}
