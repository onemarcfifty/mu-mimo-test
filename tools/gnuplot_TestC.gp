#set terminal png
set terminal pngcairo enhanced font "Arial,36" size 1920,1080
set datafile separator " "
set xlabel "Interval"
set ylabel "Throughput (Mbits/sec)"
set key bottom right


# Plot only one line
if (ARGC == 1) {
    set output ARG1.".png"
    plot ARG1 using 1:2 with lines title "Throughput"
}

# plot two lines in one
if (ARGC == 3) {
    set output ARG3
    plot ARG1 using 1:2 with lines title "Throughput node1", \
         ARG2 using 1:2 with lines title "Throughput node2"
}

set output