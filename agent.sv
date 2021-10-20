class agent #(parameter pckg_sz = 40, num_ntrfs = 4);
  agent_driver_mbx i_agent_driver_mbx;           // Mailbox del agente al driver
  test_agent_mbx i_test_agent_mbx;
  int num_transacciones;                 // Número de transacciones para las funciones del agente
  int max_retardo; 
  test_agent #(.pckg_sz(pckg_sz), .num_ntrfs(num_ntrfs)) instruccion;      // para guardar la última instruccion leída
  trans_router #(.pckg_sz(pckg_sz), .num_ntrfs(num_ntrfs)) transaccion;
   
  function new();
  endfunction

  task run;
    $display("[%g]  El Agente fue inicializado",$time);
    forever begin
      #1
      if(i_test_agent_mbx.num() > 0)begin
        $display("[%g]  Agente: se recibe instruccion",$time);
        i_test_agent_mbx.get(instruccion);
        this.num_transacciones = instruccion.num_transacciones;
        this.max_retardo = instruccion.max_retardo;
        // Case para realizar las diferentes instrucciones
        case(instruccion.tipo_secuencia)
          trans_aleatoria: begin  // Esta instrucción genera una única instruccion aleatoria
            transaccion = new();
            transaccion.max_retardo = this.max_retardo;
            transaccion.randomize();
            transaccion.print("Agente: transacción creada");
            i_agent_driver_mbx.put(transaccion);
          end

          trans_especifica: begin // Esta instruccion genera una instruccion con los datos dados
            transaccion = new();
            foreach(instruccion.spec_dato[i]) begin
              transaccion.dato[i] = instruccion.spec_dato[i];
              transaccion.escribir[i] = instruccion.spec_escribir[i];
              transaccion.device_dest[i] = instruccion.spec_device_dest[i];
            end
            transaccion.retardo = instruccion.retardo;
            transaccion.reset = instruccion.reset;
            transaccion.print("Agente: transacción creada");
            i_agent_driver_mbx.put(transaccion);

          end

          sec_trans_especificas: begin // Esta instruccion genera una secuencia de instrucciones identicas
            for(int i=0; i<this.num_transacciones;i++) begin
              transaccion = new();
              foreach(instruccion.spec_dato[i]) begin
                transaccion.dato[i] = instruccion.spec_dato[i];
                transaccion.escribir[i] = instruccion.spec_escribir[i];
                transaccion.device_dest[i] = instruccion.spec_device_dest[i];
              end
              transaccion.retardo = instruccion.retardo;
              transaccion.reset = instruccion.reset;
              transaccion.print("Agente: transacción creada");
              i_agent_driver_mbx.put(transaccion);
            end
          end

          sec_trans_aleatorias: begin // Esta instrucción genera una secuencia de instrucciones aleatorias
            for(int i=0; i<this.num_transacciones;i++) begin 
              transaccion = new();
              transaccion.max_retardo = this.max_retardo;
              transaccion.randomize();
              transaccion.print("Agente: transacción creada");
              i_agent_driver_mbx.put(transaccion);
            end
          end

          sec_escrituras_aleatorias: begin // Esta instruccion genera escrituras en todos los canales con datos aleatorios
            for(int i=0; i<this.num_transacciones;i++) begin 
              transaccion = new();
              transaccion.max_retardo = this.max_retardo;
              transaccion.randomize();
              transaccion.reset = 0;
              foreach(transaccion.escribir[i]) transaccion.escribir[i] = 1;
              transaccion.print("Agente: transacción creada");
              i_agent_driver_mbx.put(transaccion);
            end          

          end

          escritura_aleatoria: begin // Esta instrucción hace una escritura aleatoria en todos los canales
            transaccion = new();
            transaccion.max_retardo = this.max_retardo;
            transaccion.randomize();
            transaccion.reset = 0;
            foreach(transaccion.escribir[i]) transaccion.escribir[i] = 1;
            transaccion.print("Agente: transacción creada");
            i_agent_driver_mbx.put(transaccion);
          end

        endcase
      end
    end
  endtask
endclass
