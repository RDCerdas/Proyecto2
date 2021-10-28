set datafile separator ','
set key autotitle columnhead
set ylabel "Min bandwidth (Mbps)"
set xlabel "Fifo depth"


plot "min_bandwidth.csv" u 1:2 with lines 

set pointsize 40 

