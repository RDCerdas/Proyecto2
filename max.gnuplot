set datafile separator ','
set key autotitle columnhead
set ylabel "Fifo Depth"
set xlabel "Devices"

set dgrid3d 2,2

splot "max_bandwidth.csv" u 1:2:3 with lines 

set pointsize 40 

