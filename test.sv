class base_test #(parameter pckg_sz = 40, fifo_depth = 4);
    test_agent_mbx test_agent_mbx_inst;
    test_sb_mbx test_sb_mbx_inst;
    parameter num_transacciones = 25;
    parameter max_retardo = 7;
    test_agent #(.pckg_sz(pckg_sz)) instruccion;
    
    virtual mesh_if #(.pckg_sz(pckg_sz)) _if;

    ambiente #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) ambiente_inst;

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


class test1 #(parameter pckg_sz = 40, fifo_depth = 4) extends base_test #(40, 4);

    task run;
        super.run();
        // Definición de las partes de la prueba
        // Primera sección pruebas aleatorias y de caso de esquina
        instruccion = new();
      	instruccion.retardo = 20;
        instruccion.tipo_secuencia = trans_especifica;
        instruccion.reset = 0;
        for (int i=0; i<16; ++i) begin
            if(i==15)
                enviar_dato_especifico(i, i, 0);
            else begin
                enviar_dato_especifico(i, i, i+1);
            end
        end
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada primera instruccion al agente transacciones_aleatorias",$time);


        // Finaliza primer seccion de pruebas
	      #20000;
	      $finish();
    endtask

endclass //test 
