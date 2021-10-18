class base_test #(parameter num_ntrfs = 4, pckg_sz = 32, fifo_depth = 16);
    test_agent_mbx test_agent_mbx_inst;
    test_sb_mbx test_sb_mbx_inst;
    parameter num_transacciones = 25;
    parameter max_retardo = 7;
    test_agent #(.pckg_sz(pckg_sz), .num_ntrfs(num_ntrfs)) instruccion;
    
    virtual bus_if #(.num_ntrfs(num_ntrfs), .pckg_sz(pckg_sz), .bits(bits)) _if;

    ambiente #(.num_ntrfs(num_ntrfs), .pckg_sz(pckg_sz), .bits(bits), .fifo_depth(fifo_depth)) ambiente_inst;

    function new();
        test_agent_mbx_inst = new();
        test_sb_mbx_inst = new();
        ambiente_inst = new(test_agent_mbx_inst, test_sb_mbx_inst);
        ambiente_inst._if = _if;


    endfunction //new()

    task run();
        $display("[%g]  El Test fue inicializado",$time);
        // Inicialización del ambiente
        fork
            ambiente_inst.run();
        join_none
    endtask

endclass //base_test


class test1 #(parameter num_ntrfs = 4, pckg_sz = 32, fifo_depth = 16) extends base_test #(4, 32, 16);

    task run;
        super.run();
        // Definición de las partes de la prueba

        // Primera sección pruebas aleatorias y de caso de esquina
        instruccion = new();
      	instruccion.num_transacciones = 5;
      	instruccion.max_retardo = 15;
        instruccion.tipo_secuencia = sec_trans_aleatorias;
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada primera instruccion al agente transacciones_aleatorias",$time);


        // Finaliza primer seccion de pruebas
	      #20000;
	      $finish();
    endtask

endclass //test 
