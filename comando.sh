source /mnt/vol_NFS_rh003/estudiantes/archivos_config/synopsys_tools.sh
vcs -Mupdate testbench.sv  -o salida  -full64 -sverilog  -kdb -debug_acc+all -debug_region+cell+encrypt -l log_test +lint=TFIPC-L -debug_acces+r -pvalue+fifo_depth=4+pckg_sz=40 -cm tgl+cond
./salida
