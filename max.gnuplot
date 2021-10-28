set datafile separator ','
set key autotitle columnhead
set ylabel "Max bandwidth (Mbps)"
set xlabel "Fifo depth"

plot "max_bandwidth.csv" u 1:2 with lines 

set pointsize 40 

