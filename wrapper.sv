`timescale 1ns/1ps

`include "Router_library.sv"

module wrapper #(parameter pckg_sz = 40, parameter fifo_depth = 4)(mesh_if _if);
    
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
    reg w_overflow [(ROWS*COLUMS*4)-1:0];
    wire [pckg_sz-1:0] w_data [(ROWS*COLUMS*4)-1:0];

    generate
        conection_counter = 0;
        for(rw = 1; rw <= ROWS; rw++) begin: _rw_wp_
            for (clm = 1; clm<COLUMS; ++clm) begin: _clm_wp_
                for (nu = 0; nu<4; ++nu) begin: _nu_wp_
                    assign w_count[conection_counter] = uut._rw_[rw]._clm_[clm].rtr._nu_[nu].rtr_ntrfs.fifo_out.count;
                    assign w_push[conection_counter] = uut._rw_[rw]._clm_[clm].rtr._nu_[nu].rtr_ntrfs.fifo_out.push;
                    assign w_data[conection_counter] = uut._rw_[rw]._clm_[clm].rtr._nu_[nu].rtr_ntrfs.fifo_out.Dout;

                    always@(posedge w_push[conection_counter])begin
                        if(w_count[conection_counter] == fifo_depth)begin
                            w_overflow[conection_counter] <= 1'b1;
                        end 
                    end

                    conection_counter++;
                end
            end
        end
    endgenerate


endmodule