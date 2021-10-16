//////////////////////////////////////////////////////////////
// Definici�n del tipo de transacciones posibles en la fifo //
//////////////////////////////////////////////////////////////

// Tipos de secuencias
typedef enum {trans_aleatoria, trans_especifica, sec_trans_aleatorias, sec_trans_especificas, sec_escrituras_aleatorias, escritura_aleatoria} tipo_sec;
// Operaciones en Scoreboard
typedef enum {retraso_promedio, reset_ancho_banda, report_csv, append_csv_min_bw, append_csv_max_bw} sb_transaction;


// Definicion de los paquetes
// Paquete agente-driver, driver-checker
class trans_bus #(parameter pckg_sz = 16, drvrs = 4);
    rand int retardo;   
    rand bit[pckg_sz-9:0] dato [drvrs-1:0];
  rand bit[7:0] device_dest [drvrs-1:0];
    rand bit escribir [drvrs-1:0];
    bit overflow [drvrs-1:0];
    rand bit reset;
    int tiempo_lectura;
    int max_retardo;


  // Constraint del retardo
    constraint const_retardo {retardo <= max_retardo; retardo> 0;}
  
  // Constraint de los dispositivos de destino
  constraint const_device_dest { foreach(device_dest[i]){device_dest[i] inside{[0:drvrs-1], {8{1'b1}}}; device_dest[i]!=i;}}

  // Probabilidad de reset
  constraint reset_prop {reset dist{0:=80, 1:=20};}

  // Probabilidad de escribir, para reducir que se produzca una gran cantida de reset
  constraint escribir_prop {foreach(escribir[i])escribir[i] dist{0:=70, 1:=30};}

  function new(int ret = 0, bit rst = 0, int max_retardo = 5);
      this.retardo = ret;
      for(int i = 0; i<drvrs; i++) begin
        this.overflow[i] = 0;
      end
      this.reset = rst;
      this.tiempo_lectura = 0;
      this.max_retardo = 5;
    
      foreach (dato[i]) begin
        this.dato[i] = 0;
        this.device_dest[i] = 0;
        this.escribir[i] = 0;
      end
    endfunction

    function clean();
      this.retardo = 0;
      for(int i = 0; i<drvrs; i++) begin
          this.dato[i] = 0; 
          this.escribir[i] = 0;
          this.overflow[i] = 0;
      end
      this.reset = 0;
      this.tiempo_lectura = 0;
    endfunction

    function void print(string tag);
      $display("[%g] %s Tiempo=%g Reset=%g Retardo=%g Dato=%p Destino=%p Escritura=%p Overflow=%p",$time,tag,tiempo_lectura,this.reset, this.retardo, this.dato, this.device_dest, this.escribir, this.overflow);
      
    endfunction
endclass


// Interfaz para conectar con el bus
interface bus_if #(parameter drvrs = 4, pckg_sz = 16, bits = 0) (input clk);
    logic reset;
    logic pndng[bits-1:0][drvrs-1:0];
    logic push[bits-1:0][drvrs-1:0];
    logic pop[bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_pop [bits-1:0][drvrs-1:0];
  logic [pckg_sz-1:0] D_push [bits-1:0][drvrs-1:0];
endinterface //bus_if 



// Paquete monitor-checker
class monitor_checker #(parameter pckg_sz = 16, drvrs = 4);
    bit [pckg_sz-1:0] dato [drvrs-1:0];
    bit valid [drvrs-1:0];
    int tiempo_escritura;

    function new();
        for(int i = 0; i<drvrs; i++) begin
          this.dato[i] = 0; 
          this.valid[i] = 0;
        end
        this.tiempo_escritura = 0;
    endfunction 
	
	function void print(string tag);
      $display("[%g] %s Tiempo=%g Dato=%p Valido=%p",$time,tag,tiempo_escritura, this.dato, this.valid);
      
    endfunction
endclass

// Definicion del paquete entre checker y scoreboard
class checker_scoreboard #(parameter pckg_sz = 16, drvrs = 4);
    int tiempo_escritura;
    int tiempo_lectura;
    int latencia;
    int device_dest;
    int device_env;
  	int valido;
  	int completado;
    bit [pckg_sz-1:0] dato;
    bit reset;

    function new(bit [pckg_sz-1:0] dto = 0, int t_escritura = 0, int t_lectura = 0, int lat = 0, int dev_env = 0, int dev_dest = 0);
      this.dato = dto;
      this.reset = 0;
      this.tiempo_escritura = t_escritura;
      this.tiempo_lectura = t_lectura;
      this.latencia = lat;
      this.device_env = dev_env;
      this.device_dest = dev_dest;
      this.completado=0;
      this.valido=0;
    endfunction

    function clean();
      this.completado=0;
      this.valido=0;
      this.dato = 0;
      this.tiempo_escritura = 0;
      this.tiempo_lectura = 0;
      this.latencia = 0;
      this.device_dest = 0;
      this.device_env = 0;
      this.reset = 0;
    endfunction
      function void print(string tag);
        $display("[%g] %s Dato=%h Destino=%g Fuente=%g reset=%g Valido=%g Completado=%g Escritura=%g Lectura=%g Latencia=%g", $time() ,tag ,this.dato,this.device_dest, this.device_env, this.reset, this.valido, this.completado, this.tiempo_escritura, this.tiempo_lectura, this.latencia);
      
    endfunction
endclass

class test_agent #(parameter pckg_sz = 16, drvrs = 4);
    tipo_sec  tipo_secuencia;
  bit [pckg_sz-9:0] spec_dato [drvrs-1:0];
    int retardo;
    bit spec_escribir [drvrs-1:0];
    bit [7:0] spec_device_dest [drvrs-1:0];
    int max_retardo;
    int num_transacciones;
    bit reset;

  function new(tipo_sec t_sec = trans_aleatoria, int ret = 0);
      this.tipo_secuencia = t_sec;
      this.retardo = ret;
      foreach(spec_dato[i]) begin
        spec_dato[i] = 0;
        spec_device_dest[i] = 0;
        spec_escribir[i] = 0;
      end
      this.max_retardo = 5;
      this.num_transacciones = 6;
      this.reset = 0;

      
    endfunction

  // Funcion para escribir desde y hasta canal deseado
  function void enviar_dato_especifico(int device_salida, bit [pckg_sz-9:0] dato, bit [7:0] device_dest);
    this.spec_dato[device_salida] = dato;
    this.spec_escribir[device_salida] = 1;
    this.spec_device_dest[device_salida] = device_dest;
  endfunction


endclass


// Definicion de las mailboxes

// Mailbox entre agente y driver
typedef mailbox #(trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs))) agent_driver_mbx;

// Mailbox entre driver y checker
typedef mailbox #(trans_bus #(.pckg_sz(pckg_sz), .drvrs(drvrs))) driver_checker_mbx;

// Mailbox entre monitor y checker
typedef mailbox #(monitor_checker #(.pckg_sz(pckg_sz), .drvrs(drvrs))) monitor_checker_mbx;

// Mailbow entre checker y scoreboard
typedef mailbox #(checker_scoreboard #(.pckg_sz(pckg_sz), .drvrs(drvrs))) checker_scoreboard_mbx;

// Mailbox entre agente y test
typedef mailbox #(test_agent #(.pckg_sz(pckg_sz), .drvrs(drvrs))) test_agent_mbx;

// Mailbox entre test y scoreboard
typedef mailbox #(sb_transaction) test_sb_mbx;
