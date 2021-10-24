// Clase para emular los diferentes fifos de cada dispositivo
class driver_fifo #(parameter pckg_sz = 40, fifo_depth = 16);
    bit pop;
    bit pndng;
    bit overflow;
	  bit [pckg_sz-1:0] D_pop;
    bit [pckg_sz-1:0] emul_fifo [$];
    int identification;
    bit rst;


    function new(int ident);
        // Señales de control de la FIFO
        this.pop = 0;
        this.pndng = 0;
        this.overflow = 0;
        this.identification = ident;

    endfunction //new()

    // Función de actualización de los valores, se corre cada ciclo de reloj
    function void update();
    	this.overflow = 0;
      // Si hay señal de reset se vacía el fifo
      if(this.rst) begin
        emul_fifo.delete();

      // Si no hay reset
      end else begin
        if(pop) begin
            if(emul_fifo.size()==0) begin
              $warning("[%g] Underflow in device %d fifo happened", $time, this.identification);
            end else begin	
                emul_fifo.pop_front();
			      end
		    end
      end

      // Se actualiza pndng y D_out
      if(emul_fifo.size()==0) begin
          this.D_pop = 0;
          pndng = 0;
      end
      else
          this.D_pop = emul_fifo[0];

      // Actualización de overflow
      if (emul_fifo.size()==fifo_depth) begin
          this.overflow = 1;
      end

    endfunction

    // Función para guardar dato en fifo, toma en cuenta los overflows
    function void write(bit [pckg_sz-1:0] dato, bit escribir);
      if (escribir) begin
		    if (emul_fifo.size()==fifo_depth) begin
               this.overflow = 1;
              $warning("[%g] Overflow in device %d fifo happened", $time, this.identification);
        end else begin
        	emul_fifo.push_back(dato);
        	pndng = 1;
      	end
      end
    endfunction

endclass //driver_fifo




// Driver
class driver #(parameter pckg_sz = 40, fifo_depth = 4);
    virtual mesh_if #(.pckg_sz(pckg_sz)) vif;
    driver_fifo #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) drivers_fifo  [16];
    agent_driver_mbx i_agent_driver_mbx;
    driver_checker_mbx i_driver_checker_mbx;
    bit [pckg_sz-1:0] dato_temp [16];
  	int espera;
    int espera_total;
    bit reset_temp;
    int valid_transaction;

    function bit [pckg_sz-1:0] create_pkg(bit mode, bit [7:0] destino, bit [pckg_sz-18:0] dato);
      bit [pckg_sz-1:0] pkg;

      pkg[pckg_sz-1:pckg_sz-8] = 0;

      // Colocando rows y colummns
      if(destino <= 3) begin
        pkg[pckg_sz-9:pckg_sz-12] = 4-destino;
        pkg[pckg_sz-13:pckg_sz-16] = 5;
      end else if (destino <= 7) begin
        pkg[pckg_sz-9:pckg_sz-12] = 5;
        pkg[pckg_sz-13:pckg_sz-16] = 8-destino;
      end else if (destino <= 11) begin
        pkg[pckg_sz-9:pckg_sz-12] = 12-destino;
        pkg[pckg_sz-13:pckg_sz-16] = 0;
      end else if (destino <= 15) begin
        pkg[pckg_sz-9:pckg_sz-12] = 0;
        pkg[pckg_sz-13:pckg_sz-16] = 16-destino;        
      end else if (destino == {8{1'b1}}) begin
	pkg[pckg_sz-9:pckg_sz-16] = destino;
      end
      
      pkg[pckg_sz-17] = mode;
      pkg[pckg_sz-18:0] = dato;

      return pkg;
    endfunction

    task run();
      $display("[%g]  El driver fue inicializado",$time);
      foreach (drivers_fifo[i]) begin
        drivers_fifo[i] = new(i);
      end
      espera_total = 0;
	    espera = 0;
      reset_temp = 0;
      @(posedge vif.clk);
      vif.reset=1;
      @(posedge vif.clk);
		
      forever begin
        @(posedge vif.clk);
        valid_transaction = 0;
        // Actualización de todos los fifos
        foreach (drivers_fifo[i]) begin
          drivers_fifo[i].pop = vif.popin[i];
          drivers_fifo[i].rst = vif.reset;
          this.dato_temp[i] = vif.data_out_i_in[i];
          drivers_fifo[i].update();
          vif.data_out_i_in[i] = drivers_fifo[i].D_pop;
          vif.pndng_i_in[i] = drivers_fifo[i].pndng;
        end

        // Si hay un pop en 1 se genera transacción
        foreach (drivers_fifo[i]) begin 
          // Si hay algún pop
          if (vif.popin[i]) 
            valid_transaction = 1;
          // Detector de flancos
          // En caso de detectar flanco negativo en reset se crea transacción
          if (~vif.reset && reset_temp)
            valid_transaction = 1;
        end



        // En caso de que se detecte pop se hace transacción hacia checker 
        if(valid_transaction) begin
          trans_router #(.pckg_sz(pckg_sz)) transaction_checker;
          transaction_checker = new();
          // Se genera una transacción con la información de cada canal
          foreach (drivers_fifo[i]) begin
            transaction_checker.dato[i] = this.dato_temp[i][pckg_sz-9:0];
            transaction_checker.escribir[i] = this.vif.popin[i];
          end
            transaction_checker.tiempo_lectura = $time;
            transaction_checker.reset = reset_temp;
            transaction_checker.print("Driver: Transaccion enviada a Checker");
            i_driver_checker_mbx.put(transaction_checker);
        end

        // Variable temporal para detección de flancos del reset
        reset_temp = vif.reset;
        
  // Lógica no bloqueante para para implementar el retraso y recibir instrucciones del agente
	if(espera >= espera_total) begin
          trans_router #(.pckg_sz(pckg_sz)) transaction; 
          vif.reset = 0;
          espera = 0;
          if (i_agent_driver_mbx.try_get(transaction)) begin
            espera_total = transaction.retardo;
            transaction.print("Driver: Transaccion recibida");
            $display("Transacciones pendientes en el mbx agnt_drv = %g",i_agent_driver_mbx.num());
            vif.reset = transaction.reset;
            foreach (drivers_fifo[i]) drivers_fifo[i].write(
                    create_pkg(transaction.modo[i], transaction.device_dest[i], 
                    transaction.dato[i]), transaction.escribir[i]);
          end else begin
            espera_total = 0;
            vif.reset = 0;
          end
        end	


      
        espera = espera+1;

      end


    endtask
endclass //driver #parameter(parameter pckg_sz = 16, bits = 0)
