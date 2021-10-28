class score_board #(parameter pckg_sz = 40);
  
  checker_scoreboard_mbx i_checker_scoreboard_mbx;
  test_sb_mbx i_test_sb_mbx;
  checker_scoreboard #(.pckg_sz(pckg_sz)) transaccion_entrante;
  checker_scoreboard #(.pckg_sz(pckg_sz)) scoreboard[$]; //cola usada para almacenar las transacciones recibidas por el scoreboard
  checker_scoreboard #(.pckg_sz(pckg_sz)) auxiliar_trans;
  shortreal retardo_promedio;
  sb_transaction orden;
  int tamano_sb = 0;
  int transacciones_completadas = 0; 
  int transacciones_completados_bw = 0;
  int retardo_total = 0;
  int tiempo_inicial_bw = 0;
  int tiempo_final_bw = 0;
  int reset_bw = 0;
  int m_matches = 0;
  int m_misses = 0;
int report_csv_file;
int file_min_bw;
int file_max_bw;
    task run;
    $display("[%g] El Score Board fue inicializado",$time);
    forever begin
      #5
      if(i_checker_scoreboard_mbx.num()>0)begin //se reciben todas transacciones recibidas por el checker
        i_checker_scoreboard_mbx.get(transaccion_entrante);
        transaccion_entrante.print("Score Board: transacción recibida desde el checker");
        if(transaccion_entrante.completado) begin //se va acumulando el retardo total y el  numero de transacciones
          retardo_total = retardo_total + transaccion_entrante.latencia;
          transacciones_completadas++;
          transacciones_completados_bw++;
          tiempo_final_bw = transaccion_entrante.tiempo_escritura;
          m_matches++;
          if(reset_bw) begin
            tiempo_inicial_bw = transaccion_entrante.tiempo_lectura;
            reset_bw = 0;
          end
        end
        else if ((transaccion_entrante.valido == 0)&&(transaccion_entrante.overflow == 0)) begin
          m_misses++;
        end
        scoreboard.push_back(transaccion_entrante);
      end else begin 
        if(i_test_sb_mbx.num()>0)begin //se reciben las transacciones del test para generar los diferentes reportes 
          i_test_sb_mbx.get(orden);
          case(orden)
            retardo_promedio: begin //reporte para el retador promedio
              $display("Score Board: Recibida Orden Retardo_Promedio");
              retardo_promedio = retardo_total/transacciones_completadas;
              $display("\n###################\n");
              $display("Misses = %d", m_misses);
              $display("Matches = %d", m_matches);
              $display("\n###################\n");
              $display("[%g] Score board: el retardo promedio es: %0.3f", $time, retardo_promedio);
            end
            report_csv: begin //reporte csv con todas las transacciones realizadas
              $display("Score Board: Recibida Orden Reporte");
              tamano_sb = this.scoreboard.size();
              
              report_csv_file = $fopen("report.csv", "w");
              $fwrite(report_csv_file, "Dato,Destino,Fuente,Reset,Valido,Overflow,Completado,Escritura,Lectura,Latencia\n");

              for(int i=0;i<tamano_sb;i++) begin
                auxiliar_trans = scoreboard.pop_front; //se hace pop de la cola con las transacciones recibidas
                auxiliar_trans.print("SB_Report:");
                $fwrite(report_csv_file, "%0h, %0h, %0g, %0g, %0g, %0g, %0g, %0g, %0g, %0g\n",auxiliar_trans.dato,auxiliar_trans.device_dest, auxiliar_trans.device_env, auxiliar_trans.reset, auxiliar_trans.valido, auxiliar_trans.overflow, auxiliar_trans.completado, auxiliar_trans.tiempo_escritura, auxiliar_trans.tiempo_lectura, auxiliar_trans.latencia);
              end

              $fclose(report_csv_file);
            end
            
            reset_ancho_banda: begin //reset para medir el ancho de banda 
              reset_bw = 1;
              transacciones_completados_bw = 0;

	      tiempo_inicial_bw = 0;
              tiempo_final_bw = 0;
            end
            append_csv_min_bw: begin //se genera reporte con el ancho de banda min
              
              file_min_bw = $fopen("min_bandwidth.csv", "a");
              $fwrite(file_min_bw, "\n%0d,%0.3f", fifo_depth, (transacciones_completados_bw*pckg_sz*1000)/(tiempo_final_bw-tiempo_inicial_bw));
	            $fclose(file_min_bw);
            end
            append_csv_max_bw: begin //se genera reporte con el ancho de banda max
              file_max_bw = $fopen("max_bandwidth.csv", "a");
              $fwrite(file_max_bw, "\n%0d,%0.3f", fifo_depth, (transacciones_completados_bw*pckg_sz*1000)/(tiempo_final_bw-tiempo_inicial_bw));
              $fclose(file_max_bw);
            end
          endcase
       end
      end
    end
  endtask
  
endclass
