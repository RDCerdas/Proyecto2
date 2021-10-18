`timescale 1ns/1ps

`ifndef SCRIPT
    parameter pckg_sz = 16;
    parameter num_ntrfs = 4;
    parameter fifo_depth = 16;
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
   
    parameter bits = 1;
    parameter broadcast = {8{1'b1}};

    test #(.num_ntrfs(num_ntrfs), .pckg_sz(pckg_sz), .bits(bits), .fifo_depth(fifo_depth)) t0;
    router_if #(.num_ntrfs(num_ntrfs), .pckg_sz(pckg_sz)) _if(.clk(clk));

    always #5 clk = ~clk;
        
    router_bus_gnrtr #(.bits(bits), .num_ntrfs(num_ntrfs), .pckg_sz(pckg_sz), .broadcast(broadcast)) uut(
        .clk(_if.clk),
        .reset(_if.reset),
        .data_out_i_in(_if.data_out_i_in),
        .push(pndng_i_in.pndng_i_in),
        .pop(_if.pop),
        .popin(_if.popin),
        .pndng(_if.pndng),
        .data_out(_if.data_out)
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
