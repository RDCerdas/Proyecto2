`timescale 1ns/1ps

`ifndef SCRIPT
    parameter pckg_sz = 40;
    parameter num_ntrfs = 4;
    parameter fifo_depth = 16;
    parameter ROWS = 4;
    parameter COLUMS = 4;
`endif

`include "Router_library.sv"
`include "interface_transactions.sv"
`include "monitor.sv"
`include "driver.sv"
`include "agent.sv"
`include "checker.sv"
`include "scoreboard.sv"
`include "ambiente.sv"
`include "test.sv"



module test_bench;
    reg clk;
   
    parameter broadcast = {8{1'b1}};

    router_if #(.num_ntrfs(num_ntrfs), .pckg_sz(pckg_sz)) _if(.clk(clk));

    always #5 clk = ~clk;
        
    mesh_gnrtr #(.ROWS(num_ntrfs), .COLUMS(COLUMS), .pckg_sz(pckg_sz), .broadcast(broadcast), .fifo_depth(fifo_depth)) uut(
        .clk(_if.clk),
        .reset(_if.reset),
        .data_out_i_in(_if.data_out_i_in),
        .pndng_i_in(_if.pndng_i_in),
        .pop(_if.pop),
        .popin(_if.popin),
        .pndng(_if.pndng),
        .data_out(_if.data_out)
    );

    wire connection [63:0];

    genvar i;

    generate;
        for(int i = 0; i<2; i++) begin
            assign conection = uut.router_bus_gnrtr_clm_[i].clk;
        end
    endgenerate


endmodule
