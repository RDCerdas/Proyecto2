class test #(parameter drvrs = 4, pckg_sz = 16, bits = 0, fifo_depth = 16);
    test_agent_mbx test_agent_mbx_inst;
    test_sb_mbx test_sb_mbx_inst;
    parameter num_transacciones = 25;
    parameter max_retardo = 7;
    test_agent #(.pckg_sz(pckg_sz), .drvrs(drvrs)) instruccion;
    
    virtual bus_if #(.drvrs(drvrs), .pckg_sz(pckg_sz), .bits(bits)) _if;

    ambiente #(.drvrs(drvrs), .pckg_sz(pckg_sz), .bits(bits), .fifo_depth(fifo_depth)) ambiente_inst;

    function new();
        test_agent_mbx_inst = new();
        test_sb_mbx_inst = new();
        ambiente_inst = new(test_agent_mbx_inst, test_sb_mbx_inst);
        ambiente_inst._if = _if;


    endfunction //new()

    task run;
        $display("[%g]  El Test fue inicializado",$time);
        // Inicialización del ambiente
        fork
            ambiente_inst.run();
        join_none

        // Definición de las partes de la prueba

        // Primera sección pruebas aleatorias y de caso de esquina
        instruccion = new();
      	instruccion.num_transacciones = 300;
      	instruccion.max_retardo = 15;
        instruccion.tipo_secuencia = sec_trans_aleatorias;
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada primera instruccion al agente transacciones_aleatorias",$time);

        instruccion = new();
        instruccion.num_transacciones = 20;
      	instruccion.retardo = 10;
        instruccion.tipo_secuencia = sec_trans_especificas;
        instruccion.enviar_dato_especifico(0, 'hAA, 'hff); //Broadcast en un dispositivo
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada segunda instruccion al agente broadcast 1 dispositivo",$time);



        instruccion = new();
        instruccion.num_transacciones = 20;
      	instruccion.retardo = 10;
        instruccion.tipo_secuencia = sec_trans_especificas;
        for(int i; i < drvrs; i++) begin
          instruccion.enviar_dato_especifico(i, 'hFF, 'hff); //Broadcast en todos los dispositivos
        end
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada tercera instruccion al agente broadcast en todos los canales",$time);

        instruccion = new();
      	instruccion.retardo = 10;
        instruccion.tipo_secuencia = trans_especifica;
        for(int i; i < drvrs; i++) begin
          instruccion.enviar_dato_especifico(i, 'h00, 'hff); //Broadcast con reset en todos los canales
        end
        instruccion.reset = 1;
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada cuarta instruccion al agente broadcast en todos con reset",$time);

        instruccion = new();
      	instruccion.retardo = 10;
        instruccion.tipo_secuencia = trans_especifica;
        instruccion.enviar_dato_especifico(0, 'h11, drvrs-1); //Envío con reset
        instruccion.reset = 1;
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada quinta instruccion al agente broadcast 1 dispositivo con reset",$time);

        instruccion = new();
      	instruccion.retardo = 10;
        instruccion.tipo_secuencia = trans_especifica;
        for(int i; i < drvrs; i++) begin
          if(i==0) instruccion.enviar_dato_especifico(i, 'h33, drvrs-1); //Escritura en todos los canales con reset
          else instruccion.enviar_dato_especifico(i, 'h00, 'h00); // Se envía desde todos los canales a cero
        end
        instruccion.reset = 1;
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada sexta instruccion al agente reset con escritura en todos",$time);

        instruccion = new();
        instruccion.num_transacciones = 5;
      	instruccion.retardo = 10;
        instruccion.tipo_secuencia = sec_trans_especificas;
        instruccion.enviar_dato_especifico(0, 'hAA, drvrs); //Broadcast en un dispositivo
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada septima instruccion 5 transacciones a dispositivo inválido",$time);

  // Finaliza primer seccion de pruebas
	#2000000;

  // Segunda sección
  // Cálculo de ancho de banda máximo
	test_sb_mbx_inst.put(reset_ancho_banda);


        instruccion = new();
        instruccion.num_transacciones = 300;
      	instruccion.max_retardo = 1;
        instruccion.tipo_secuencia = sec_escrituras_aleatorias;
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada octava instruccion al agente 300 escrituras en todos los canales",$time);

  // Fin de la tercer sección
	#2000000;
  test_sb_mbx_inst.put(append_csv_max_bw);

  // Tercera sección
  // Calculo de ancho de banda mínimo
	
	test_sb_mbx_inst.put(reset_ancho_banda);

        instruccion = new();
        instruccion.num_transacciones = 300;
      	instruccion.max_retardo = 1;
        instruccion.tipo_secuencia = sec_trans_especificas;
        instruccion.enviar_dato_especifico(0, 'h00, drvrs-1); //Se envía dato 0x00 hacia dispositivo drvrs-1
        test_agent_mbx_inst.put(instruccion);
        $display("[%g]  Test: Enviada novena instruccion 300 escrituras en un canal",$time);


  // Fin de la tercera instrucción
	#2000000;

	test_sb_mbx_inst.put(append_csv_min_bw);
	test_sb_mbx_inst.put(report_csv);
  test_sb_mbx_inst.put(retraso_promedio);

  // Se espera 100 ciclos antes de generar el reporte
	#100;
       
	$finish();
    endtask

endclass //test 
