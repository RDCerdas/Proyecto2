printf "Drivers,Fifo Depth,Max Bandwidth(Mbps)" > max_bandwidth.csv
printf "Drivers,Fifo Depth,Min Bandwidth(Mbps)" > min_bandwidth.csv
source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh

for pckg in  32  
	do
	for drvrs in 2 4 6 12 	
	do
		for fifo in 16 32 64 256 
		do
			printf "\x60define SCRIPT 1 \n" > parameters.sv
			printf "parameter pckg_sz = %d;\nparameter drvrs = %d;\n parameter fifo_depth=%d;\n" $pckg $drvrs $fifo  >> parameters.sv
			vcs -Mupdate parameters.sv testbench.sv  -o salida  -full64 -sverilog  -kdb -debug_acc+all -debug_region+cell+encrypt -l log_test +lint=TFIPC-L
			./salida
			if $?; then
				printf "\n\n\n\n\nError in run drvrs=%d, pckg_sz=%d, fifo_depth=%d\n\n\n\n" $pckg $drvrs $fifo
				return 1
			fi
		done
	done
done

gnuplot -p min.gnuplot
gnuplot -p max.gnuplot
