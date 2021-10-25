//////////////////////////////////////////////////////////////
// Definici�n del tipo de transacciones posibles en la fifo //
//////////////////////////////////////////////////////////////

// Tipos de secuencias
typedef enum {trans_aleatoria, trans_especifica, sec_trans_aleatorias, sec_trans_especificas, sec_escrituras_aleatorias, escritura_aleatoria} tipo_sec;
// Operaciones en Scoreboard
typedef enum {retraso_promedio, reset_ancho_banda, report_csv, append_csv_min_bw, append_csv_max_bw} sb_transaction;


// Definicion de los paquetes
// Paquete agente-driver, driver-checker
class trans_router #(parameter pckg_sz = 40);
    rand int retardo;  
    rand bit modo [16-1:0] = '{default:0};
    rand bit[pckg_sz-18:0] dato [16-1:0];
    rand bit[7:0] device_dest [16-1:0];
    rand bit escribir [16-1:0];
    bit overflow [16-1:0];
    bit [pckg_sz-1:0] packet [16-1:0];
    rand bit reset;
    int tiempo_lectura;
    int max_retardo;


  // Constraint del retardo
  constraint const_retardo {retardo <= max_retardo; retardo> 0;}
  
  // Constraint de los dispositivos de destino
  constraint const_device_dest { foreach(device_dest[i]){device_dest[i] inside{[0:16-1], {8{1'b1}}}; device_dest[i]!=i;}}

  // Probabilidad de reset
  constraint reset_prop {reset dist{0:=80, 1:=00};}

  // Probabilidad de escribir, para reducir que se produzca una gran cantida de reset
  constraint escribir_prop {foreach(escribir[i])escribir[i] dist{0:=70, 1:=30};}

  function new(int ret = 0, bit rst = 0, int max_retardo = 5);
      this.retardo = ret;
      for(int i = 0; i<16; i++) begin
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
      for(int i = 0; i<16; i++) begin
          this.dato[i] = 0; 
          this.escribir[i] = 0;
          this.overflow[i] = 0;
      end
      this.reset = 0;
      this.tiempo_lectura = 0;
    endfunction

    function void print(string tag);
      $display("[%g] %s Tiempo=%g Reset=%g Retardo=%g \nDato=%p \nDestino=%p \nEscritura=%p \nOverflow=%p",$time,tag,tiempo_lectura,this.reset, this.retardo, this.dato, this.device_dest, this.escribir, this.overflow);
      
    endfunction
endclass


// Interfaz para conectar con el bus
interface mesh_if #(parameter pckg_sz = 40) (input clk);
    logic reset;
    logic pndng[16-1:0];
    logic pndng_i_in[16-1:0];
    logic pop[16-1:0];
    logic popin[16-1:0];
    logic [pckg_sz-1:0] data_out[16-1:0];
    logic [pckg_sz-1:0] data_out_i_in[16-1:0];

    logic w_overflow[64-1:0];
    logic [pckg_sz-1:0] w_data_overflow[64-1:0];
endinterface //mesh_if 



// Paquete monitor-checker
class monitor_checker #(parameter pckg_sz = 40);
    bit [pckg_sz-1:0] dato [16-1:0];
    bit valid [16-1:0];
    int tiempo_escritura;
    bit overflow[64-1:0];
    bit data_overflow[64-1:0];

    function new();
        for(int i = 0; i<16; i++) begin
          this.dato[i] = 0; 
          this.valid[i] = 0;
          this.overflow[i]=0;
          this.data_overflow[i]=0;
        end
        this.tiempo_escritura = 0;
    endfunction 
	
	function void print(string tag);
      $display("[%g] %s Tiempo=%g \nDato=%p \nValido=%p \nOverflow=%p \nData_Overflow=%p",$time,tag,tiempo_escritura, this.dato, this.valid, this.overflow, this.data_overflow);
      
    endfunction
endclass

// Definicion del paquete entre checker y scoreboard
class checker_scoreboard #(parameter pckg_sz = 40);
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

class test_agent #(parameter pckg_sz = 40);
    tipo_sec  tipo_secuencia;
    bit [pckg_sz-18:0] spec_dato [16-1:0];
    int retardo;
    bit spec_escribir [16-1:0];
    bit [7:0] spec_device_dest [16-1:0];
    int max_retardo;
    int num_transacciones = 10;
    bit spec_modo [16-1:0] = '{default:4};
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
      this.reset = 0;

      
    endfunction

  // Funcion para escribir desde y hasta canal deseado
  function void enviar_dato_especifico(int device_salida, bit [pckg_sz-9:0] dato, bit modo, bit [7:0] device_dest);
    this.spec_dato[device_salida] = dato;
    this.spec_escribir[device_salida] = 1;
    this.spec_modo[device_salida] = modo;
    this.spec_device_dest[device_salida] = device_dest;
  endfunction


endclass


// Definicion de las mailboxes

// Mailbox entre agente y driver
typedef mailbox #(trans_router #(.pckg_sz(pckg_sz))) agent_driver_mbx;

// Mailbox entre driver y checker
typedef mailbox #(trans_router #(.pckg_sz(pckg_sz))) driver_checker_mbx;

// Mailbox entre monitor y checker
typedef mailbox #(monitor_checker #(.pckg_sz(pckg_sz))) monitor_checker_mbx;

// Mailbow entre checker y scoreboard
typedef mailbox #(checker_scoreboard #(.pckg_sz(pckg_sz))) checker_scoreboard_mbx;

// Mailbox entre agente y test
typedef mailbox #(test_agent #(.pckg_sz(pckg_sz))) test_agent_mbx;

// Mailbox entre test y scoreboard
typedef mailbox #(sb_transaction) test_sb_mbx;
