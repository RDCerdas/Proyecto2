class arreglo #(parameter pckg_sz = 16); //se agrega una clase de los parametros que se van a usar para la cola 
  bit [pckg_sz-1:0] Dato ; //dato con el destino/dato
  bit [8:0] enviado;		//dispositivo que envia
  int tiempo_lectura;		//tiempo de lectura del driver
      function new();
        this.tiempo_lectura=0;
        this.Dato = 0; 
        this.enviado=0;
    endfunction 

    function print(string tag);
	$display("[%g] %s  Tiempo Lectura = %g Enviado = %g Dato = %h", $time, tag, this.tiempo_lectura, this.enviado, this.Dato);
    endfunction

endclass 

class checkers #(parameter  pckg_sz = 40);
  trans_router #(.pckg_sz(pckg_sz)) transaction_driver;
  monitor_checker #(.pckg_sz(pckg_sz)) transaction_monitor;
  checker_scoreboard #(.pckg_sz(pckg_sz)) to_sb;
  monitor_checker_mbx i_monitor_checker_mbx;
  driver_checker_mbx i_driver_checker_mbx;
  checker_scoreboard_mbx i_checker_scoreboard_mbx;
  arreglo #(.pckg_sz(pckg_sz)) auxiliar;
  arreglo #(.pckg_sz(pckg_sz))temp;
  arreglo #(.pckg_sz(pckg_sz))cola[$]; //cola para que almacene transacciones del driver
  int latencia;
  int tamano;
  bit [pckg_sz-1:0] Dato;
  bit [8:0] destino;
  int timeout = 5000;
  
  function new();
   this.cola = {};
    this.temp=new;
    this.auxiliar=new;
  endfunction 
  
  
  task run;
   $display("[%g]  El checker fue inicializado",$time);
   forever begin
	   #5;
	   
	if(i_monitor_checker_mbx.try_get(transaction_monitor)) begin
    // revisar el caso de overflow
      foreach (transaction_monitor.overflow[i]) begin
        if(transaction_monitor.overflow[i] == 1) begin 
          Dato=transaction_monitor.data_overflow[i];
          foreach (cola[a]) begin
		  //$display("Dato = %h Cola = %h", Dato, cola[a].Dato);
             if (Dato[pckg_sz-9:0]==cola[a].Dato[pckg_sz-9:0]) begin //si el dato recibido por el monitor es igual al que envio el checker se realiza la transaccion al scoreboard
		           to_sb = new();
           	   to_sb.dato=Dato;
           	   to_sb.tiempo_escritura=0;
               to_sb.device_dest= Dato [pckg_sz-9:pckg_sz-16];
           	   to_sb.latencia=0;
           	   to_sb.tiempo_lectura=0;
           	   to_sb.completado = 0;
           	   to_sb.valido=0;
		           to_sb.reset = 0;
               to_sb.overflow=1;
           	   to_sb.device_env=cola[a].enviado;
           	   to_sb.print("Checker:Transaccion de Overflow Completada");
           	   i_checker_scoreboard_mbx.put(to_sb);
           	   tamano=1;
		           cola.delete(a);
		           break;
             end
           end
          if (tamano==0) begin//si el dato no se encontró se finaliza el test
           	 transaction_monitor.print("Checker: El dato recibido por el monitor no fue enviado por el driver");
         	   $finish(1);
           end
        end
        
      end
      foreach (transaction_monitor.valid[i]) begin
        if (transaction_monitor.valid[i]==1) begin//si la transaccion del monitor es valido entonces se procude a buscar el dato enviado por el driver
           Dato=transaction_monitor.dato[i];
           tamano=0;
           foreach (cola[a]) begin
		//$display("Dato = %h Cola = %h", Dato, cola[a].Dato);
             if (Dato[pckg_sz-9:0]==cola[a].Dato[pckg_sz-9:0]) begin //si el dato recibido por el monitor es igual al que envio el checker se realiza la transaccion al scoreboard
		           to_sb = new();
           	   latencia = transaction_monitor.tiempo_escritura - cola[a].tiempo_lectura;
           	   to_sb.dato=Dato;
           	   to_sb.tiempo_escritura=transaction_monitor.tiempo_escritura;
               to_sb.device_dest= Dato [pckg_sz-9:pckg_sz-16];
           	   to_sb.latencia=latencia;
           	   to_sb.tiempo_lectura=cola[a].tiempo_lectura;
           	   to_sb.completado = 1;
           	   to_sb.valido= 1;
		           to_sb.reset = 0;
               to_sb.overflow= 0;
           	   to_sb.device_env=cola[a].enviado;
           	   to_sb.print("Checker:Transaccion Completada");
           	   i_checker_scoreboard_mbx.put(to_sb);
           	   tamano=1;
		           cola.delete(a);
		           break;
             end
           end
          if (tamano==0) begin//si el dato no se encontró se finaliza el test
		 $error("Dato incorrecto");
           	 transaction_monitor.print("Checker: El dato recibido por el monitor no fue enviado por el driver");
         	 $finish(1);
           end
   	end
         end
       end
       // se recibe la transaccion del checker
       if(i_driver_checker_mbx.try_get(transaction_driver))begin
        transaction_driver.print("Checker: Se recibe trasacción desde el driver");
         foreach (transaction_driver.escribir[i]) begin
           if (transaction_driver.escribir[i]==1) begin//la transaccion que tenga el escribir en otro dispositivo  se analiza si es un broadcast o una escritura normal, en ambos casos se almacena la transaccion en la cola para su uso posterior
                if (transaction_driver.device_dest[i]==8'hFF) begin
                  for (int f=0; f<(15); f++) begin
                    temp = new();
                    temp.enviado=i;
                    temp.Dato=transaction_driver.packet[i];
                    temp.tiempo_lectura=transaction_driver.tiempo_lectura;
                    cola.push_back(temp);
                  end
              end else begin
                temp = new();
                temp.enviado=i;
                temp.Dato=transaction_driver.packet[i];
                temp.tiempo_lectura=transaction_driver.tiempo_lectura;
                cola.push_back(temp);
              end
           end
      end
         if (transaction_driver.reset==1) begin //en el caso de un reset de hace pop a los datos almacenados en el cola enviando las transacciones al scoroboard que fueron invalidados
        while(cola.size()>0) begin
          auxiliar=cola.pop_back;
          to_sb = new();
          to_sb.dato=auxiliar.Dato;
          to_sb.tiempo_escritura=0;
          to_sb.device_dest=auxiliar.Dato[pckg_sz-9:pckg_sz-16];
          to_sb.latencia=0;
          to_sb.tiempo_lectura=auxiliar.tiempo_lectura;
          to_sb.completado = 0;
          to_sb.valido=0;
          to_sb.reset = 1;
          to_sb.overflow = 0;
          to_sb.device_env=auxiliar.enviado;
          to_sb.print("Checker:Transaccion Completada");
          i_checker_scoreboard_mbx.put(to_sb);
          $display("Dato_abortado= %h, Dispositivo_que_envia = %h, Dispositivo que recibe= %h",auxiliar.Dato[pckg_sz-9:0],auxiliar.enviado,auxiliar.Dato[pckg_sz-1:pckg_sz-8]);
        end
      end
	  end

    foreach (cola[a]) begin
	    if(cola[a].tiempo_lectura+timeout < $time) begin
        //cola[a].print("Checker: Error timeout de dato");
        //$finish(1);
end
    end
  end
     endtask 
endclass 

