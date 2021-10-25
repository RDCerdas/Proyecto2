class monitor#(parameter pckg_sz = 40, fifo_depth = 4);
    virtual mesh_if #(.pckg_sz(pckg_sz)) vif;
    monitor_checker_mbx i_monitor_checker_mbx;
    bit push [16];                       // push de cada canal
    bit [pckg_sz-1:0] D_push [16];       // Valor de cada dato
    bit valid;                              // Variable para controlar generación de transacciones
    bit overflow[64];
    bit [pckg_sz-1] data_overflow[64];
    bit overflowout;
    bit count;
        bit pushtemp [16];                       
    bit [pckg_sz-1:0] D_pushtemp [16]; 

    function new();
        foreach(this.push[i]) begin
            this.push[i] = 0;
            this.D_push[i] = 0;
            this.pushtemp[i] = 0;
            this.D_pushtemp[i] = 0;            
            this.overflow[i]=0;
        end
    endfunction //new()

    task run();
        $display("[%g]  El monitor fue inicializado",$time);
        @(posedge vif.clk);

        forever begin
            // Actualización de cada valor
            for (j=0; j<3; j=j++) begin
                foreach(this.pushtemp[i]) begin
                    if (vif.pndng[i] == 1) begin
                        this.pushtemp[i] = vif.pndng[i];
                        this.D_pushtemp[i] = vif.data_out[i];
		                vif.pop[i] = 0;                
                    end
                end
                count = count + 1;
                @(posedge clk) ;
            end
            if (count >= 2) begin
                push = pushtemp;
                D_push = D_pushtemp;
                vif.pop[i] = 0;
            end
            // se revisa si se da overflows  
            foreach(this.overflow[j]) begin
                this.overflow[j] = vif.w_overflow[j];
                this.data_overflow[j] = vif.w_data_overflow[j];
            end
	    
            // si hay un overflow se crea la transaccion con el overflow y el dato
            foreach(this.overflow[i]) if(this.overflow[i]) overflowout = 1;
            if (overflowout) begin
                 monitor_checker #(.pckg_sz(pckg_sz)) transaction;
                transaction = new();
                foreach(this.overflow[i]) begin
                    transaction.overflow[i] = this.overflow[i];
                    transaction.data_overflow[i] = this.data_overflow[i];
                end
                transaction.print("Monitor: Transaccion enviada");
                i_monitor_checker_mbx.put(transaction);
            end
            // Si hay un push se crea transacción
            foreach(this.push[i]) begin
                if(this.push[i]) valid = 1;
                if(this.push[i]) vif.pop[i] = 1;
            end
 
            end
            if (valid) begin
                // Se genera transacción hacia checker
                monitor_checker #(.pckg_sz(pckg_sz)) transaction;
                transaction = new();
                foreach(this.push[i]) begin
                    transaction.valid[i] = this.push[i];
                    transaction.dato[i] = this.D_push[i];
                end
                transaction.tiempo_escritura = $time();
                transaction.print("Monitor: Transaccion enviada");
                i_monitor_checker_mbx.put(transaction);
            end        
            valid = 0;
            overflowout=0;
            @(posedge vif.clk);
        end

    endtask //runs 
endclass//monitor
