#set terminal png
set terminal pngcairo enhanced font "Arial,36" size 1920,1080
set datafile separator " "
set xlabel "Interval"
set ylabel "Throughput (Mbits/sec)"
set key bottom right

sum(a, b, c) = a + b + c

do for [i = 1:4] {
     plotDir = ARG1."/plot".i
     set output plotDir."/plot_sum_bezier.png"

set grid linestyle 1 linecolor rgb "#888888" dashtype '-' linewidth 2
#set style line 2 dashtype 2

     set style circle radius 0.5
     plot plotDir."/join.txt" using 1:2 smooth bezier with points title "node1", \
          plotDir."/join.txt" using 1:3 smooth bezier with points title "node2", \
          plotDir."/join.txt" using 1:4 smooth bezier with points title "node3", \
          plotDir."/join.txt" using 1:(sum($2, $3, $4)) with lines smooth bezier lw 3 title "sum"

     set output plotDir."/plot_all_bezier.png"
     plot plotDir."/join.txt" using 1:2 with lines smooth bezier lw 3 title "node1", \
          plotDir."/join.txt" using 1:3 with lines smooth bezier lw 3 title "node2", \
          plotDir."/join.txt" using 1:4 with lines smooth bezier lw 3 title "node3"

     set output plotDir."/plot_node1.png"
     plot plotDir."/join.txt" using 1:2 with lines lw 3 title "node1"

     set output plotDir."/plot_nodes1_2.png"
     plot plotDir."/join.txt" using 1:2 with lines title "node1", \
          plotDir."/join.txt" using 1:3 with lines lw 3 title "node2"

     # if a second argument was given, then we compare the sums of STOCK to OWRT
     if (exists("ARG2")) {
          # the first Argument was OWRT
          if (strstrt(ARG1, "OWRT") > 0) {
               text1="OpenWrt"
               text2="Stock Firmware"
          } else {
               text2="OpenWrt"
               text1="Stock Firmware"
          }
          plotDir2 = ARG2."/plot".i
          set output plotDir."/plot_sum_Stock_vs_OpenWrt.png"
          plot plotDir."/join.txt"  using 1:(sum($2, $3, $4)) with lines smooth bezier lw 3 title text1, \
               plotDir2."/join.txt" using 1:(sum($2, $3, $4)) with lines smooth bezier lw 3 title text2
     }
}