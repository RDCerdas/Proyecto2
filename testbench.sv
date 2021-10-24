`timescale 1ns/1ps

`define DEBUG 1

parameter pckg_sz = 40;
parameter fifo_depth = 4;


`include "interface_transactions.sv"
`include "wrapper.sv"
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

    test1 #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) t0;
    mesh_if #(.pckg_sz(pckg_sz)) _if(.clk(clk));

    always #5 clk = ~clk;
        
    wrapper #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) uut_wrapper(
        ._if(_if)
    );

    initial begin
        clk = 0;
        t0 = new();
        t0._if = _if;
      	t0.ambiente_inst.driver_inst.vif = _if;
        t0.ambiente_inst.monitor_inst.vif = _if;
        fork
            t0.run();
        join_none
    end

    always@(posedge clk) begin
        if ($time > 10000000)begin
            $display("Test_bench: Tiempo límite de prueba en el test_bench alcanzado");
            $finish;
    end
  end

endmodule
