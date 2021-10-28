`timescale 1ns/1ps

`include "Router_library.sv"

module wrapper #(parameter pckg_sz = 40, parameter fifo_depth = 4)(mesh_if _if);
    
    // Parametros fijos
    localparam ROWS = 4;
    localparam COLUMS = 4;
    localparam broadcast = {8{1'b1}};

    
    // DUT
    mesh_gnrtr #(.ROWS(ROWS), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .bdcst(broadcast), .fifo_depth(fifo_depth)) uut(
        .clk(_if.clk),
        .reset(_if.reset),
        .data_out_i_in(_if.data_out_i_in),
        .pndng_i_in(_if.pndng_i_in),
        .pop(_if.pop),
        .popin(_if.popin),
        .pndng(_if.pndng),
        .data_out(_if.data_out)
    );

    // FIFO overflow
    genvar rw;
    genvar clm;
    genvar nu;
    genvar conection_counter;

    wire [$clog2(fifo_depth):0] w_count [(ROWS*COLUMS*4)-1:0];
    wire w_push [(ROWS*COLUMS*4)-1:0];
    reg w_overflow [(ROWS*COLUMS*4)-1:0] = '{default:0};
    reg [pckg_sz-1:0] w_data [(ROWS*COLUMS*4)-1:0];


    // Se genera una señal de overflow usando el contador interno de cada fifo y el push
    generate
        for(rw = 1; rw <= ROWS; rw++) begin: _rw_wp_
            for (clm = 1; clm<=COLUMS; ++clm) begin: _clm_wp_
                for (nu = 0; nu<4; ++nu) begin: _nu_wp_
                    // Se asigna el contador y push de cada fifo a un wire local
                    assign w_count[nu+4*(clm-1)+16*(rw-1)] = uut._rw_[rw]._clm_[clm].rtr._nu_[nu].rtr_ntrfs_.fifo_out.count;
                    assign w_push[nu+4*(clm-1)+16*(rw-1)] = uut._rw_[rw]._clm_[clm].rtr._nu_[nu].rtr_ntrfs_.fifo_out.push;

                    // Logica de overflow con registro para almacenar dato de anterior ciclo
                    always@(posedge _if.clk) begin
                        if(w_push[nu+4*(clm-1)+16*(rw-1)] && (w_count[nu+4*(clm-1)+16*(rw-1)] == fifo_depth))begin
                            w_overflow[nu+4*(clm-1)+16*(rw-1)] <= 1'b1;
                        end 
			            else
			                w_overflow[nu+4*(clm-1)+16*(rw-1)] <= 1'b0;
			
                        w_data[nu+4*(clm-1)+16*(rw-1)] <= uut._rw_[rw]._clm_[clm].rtr._nu_[nu].rtr_ntrfs_.fifo_out.Dout;
		end
                   

                end
            end
        end
    endgenerate

    // Se conecta a la interfaz
    assign _if.w_overflow = w_overflow;
    assign _if.w_data_overflow = w_data;


endmodule
