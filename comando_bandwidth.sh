printf "Drivers,Fifo Depth,Max Bandwidth(Mbps)" > max_bandwidth.csv
printf "Drivers,Fifo Depth,Min Bandwidth(Mbps)" > min_bandwidth.csv
source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh

for pckg in  40 50  
	do
	for test in 2 3  	
	do
		for fifo in 4 8 16 32   
		do
			printf "\x60define SCRIPT 1 \n" > parameters.sv
			printf "parameter pckg_sz = %d;\nparameter test = %d;\n parameter fifo_depth=%d;\n" $pckg $test $fifo  >> parameters.sv
			vcs -Mupdate parameters.sv testbench.sv  -o salida  -full64 -sverilog  -kdb -debug_acc+all -debug_region+cell+encrypt -l log_test +lint=TFIPC-L -debug_acces+r -cm tgl+cond+assert
			./salida -cm tgl+cond+assert
			if $?; then
				printf "\n\n\n\n\nError in run pckg_sz=%d, test=%d, fifo_depth=%d\n\n\n\n" $pckg $test $fifo
				return 1
			fi
		done
	done
done

gnuplot -p min.gnuplot
gnuplot -p max.gnuplot
