// Test base para declarar los componentes necesarios
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

// Test creados que heredan del base

// Prueba aleatoria
class test1_1 #(parameter pckg_sz = 40, fifo_depth = 4) extends base_test #(pckg_sz, fifo_depth);

    task run;
        super.run();
        // Definición de las partes de la prueba
        // Primera sección pruebas aleatorias y de caso de esquina
        instruccion = new();
      	instruccion.num_transacciones = 2000;
        instruccion.max_retardo = 30;
        instruccion.tipo_secuencia = sec_trans_aleatorias;
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviadas transacciones aleatorias",$time);


        // Finaliza primer seccion de pruebas
	      #2000000;

        test_sb_mbx_inst.put(report_csv);
        test_sb_mbx_inst.put(retraso_promedio);

        #100;
	$display("Finished test 1.1");
	      $finish();
    endtask

endclass //test1_1

// Prueba de ancho de banda mínimo
class test1_2 #(parameter pckg_sz = 40, fifo_depth = 4) extends base_test #(pckg_sz, fifo_depth);

    task run;
        super.run();

        // Reinicia calculo de ancho de banda
        test_sb_mbx_inst.put(reset_ancho_banda);
        #10;
        
        // Envío continuo de dispositivo 0 a 15
        instruccion = new();
      	instruccion.num_transacciones = 5000;
        instruccion.max_retardo = 1;
        instruccion.retardo = 1;
        instruccion.tipo_secuencia = sec_trans_especificas;
        instruccion.enviar_dato_especifico(0, 'hA, 0, 15);
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviadas transacciones en un dispositivo",$time);


        // Finaliza primer seccion de pruebas
	    #2000000;
      test_sb_mbx_inst.put(append_csv_min_bw);
      test_sb_mbx_inst.put(report_csv);
      test_sb_mbx_inst.put(retraso_promedio);

      #100;
      $display("Finished teset 1.2");
	    $finish();
    endtask

endclass //test1_2

// Prueba de ancho de banda máximo
class test1_3 #(parameter pckg_sz = 40, fifo_depth = 4) extends base_test #(pckg_sz, fifo_depth);

    task run;
        super.run();
        // Reinicia calculo de ancho de banda
        test_sb_mbx_inst.put(reset_ancho_banda);
        #10;

        // Envío de escritura en todos los dispositivos
        instruccion = new();
      	instruccion.num_transacciones = 500;
        instruccion.max_retardo = 1;
        instruccion.tipo_secuencia = sec_escrituras_aleatorias;
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviadas transacciones en todos los dispositivos",$time);


	    #2000000;
      test_sb_mbx_inst.put(append_csv_max_bw);
      test_sb_mbx_inst.put(report_csv);
      test_sb_mbx_inst.put(retraso_promedio);

      #100;
      $display("Finished test 1.3 %d", pckg_sz);
	    $finish();
    endtask

endclass //test1_3

class test2_1 #(parameter pckg_sz = 40, fifo_depth = 4) extends base_test #(pckg_sz, fifo_depth);

    task run;
        super.run();

        // Casos de esquina
        // Broadcast en todos los dispositivos
        instruccion = new();
      	instruccion.num_transacciones = 10;
        instruccion.retardo = 10;
        instruccion.tipo_secuencia = sec_trans_especificas;
        for (int i=0; i<16; ++i) begin
            // Broadcast en todos los dispositivos
            // Se alternan los modos de trabajo
            instruccion.enviar_dato_especifico(i, 'hFF, i%2, 'hff);
        end
        
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviadas transacciones en un dispositivo",$time);

        // Envío desde todos los dispositivos a dispositivo 0
        instruccion = new();
      	instruccion.num_transacciones = 10;
        instruccion.retardo = 10;
        instruccion.tipo_secuencia = sec_trans_especificas;
        for (int i=1; i<16; ++i) begin
            // Envío de todos los dispositivos hasta cero
            // Se alternan los modos de trabajo
            instruccion.enviar_dato_especifico(i, 'hAA, i%2, 0);
        end
        
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviadas transacciones en un dispositivo",$time);

        // Intrucción de broadcast anterior con reset
        instruccion = new();
      	instruccion.num_transacciones = 10;
        instruccion.retardo = 10;
        instruccion.tipo_secuencia = sec_trans_especificas;
        for (int i=0; i<16; ++i) begin
            // Broadcast en todos los dispositivos
            // Se alternan los modos de trabajo
            instruccion.enviar_dato_especifico(i, 'hFF, i%2, 'hff);
        end
        instruccion.reset = 1;

        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviadas transacciones en un dispositivo",$time);

        // Intrucción de envío de datos simultaneo anteriores con reset
        instruccion = new();
      	instruccion.num_transacciones = 10;
        instruccion.retardo = 10;
        instruccion.tipo_secuencia = sec_trans_especificas;
        for (int i=1; i<16; ++i) begin
            // Envío de todos los dispositivos hasta cero
            // Se alternan los modos de trabajo
            instruccion.enviar_dato_especifico(i, 'hAA, i%2, 0);
        end
        instruccion.reset = 1;

        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviadas transacciones en un dispositivo",$time);

        // Finaliza primer seccion de pruebas
	    #20000;
      test_sb_mbx_inst.put(report_csv);
      test_sb_mbx_inst.put(retraso_promedio);

      #100;
      $display("Finished test 2.1");
	    $finish();
    endtask

endclass //test2_1

class test2_2 #(parameter pckg_sz = 40, fifo_depth = 4) extends base_test #(pckg_sz, fifo_depth);

    task run;
        super.run();
        // Definición de las partes de la prueba
        // Primera sección pruebas aleatorias y de caso de esquina
        instruccion = new();
      	instruccion.num_transacciones = 400;
        instruccion.retardo = 10;
        instruccion.tipo_secuencia = sec_trans_especificas;
        for (int i=0; i<4; ++i) begin
            // Broadcast en todos los dispositivos
            // Se alternan los modos de trabajo
            instruccion.enviar_dato_especifico(i, i, 0 , 15);
        end
        for (int i=4; i<8; ++i) begin
            // Broadcast en todos los dispositivos
            // Se alternan los modos de trabajo
            instruccion.enviar_dato_especifico(i, i, 1 , 15);
        end
        
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviadas transacciones en un dispositivo",$time);

	    #2000000;
      test_sb_mbx_inst.put(report_csv);
      test_sb_mbx_inst.put(retraso_promedio);

      #100;
      $display("Finished test 2.2");
	    $finish();
    endtask

endclass //test2_2

