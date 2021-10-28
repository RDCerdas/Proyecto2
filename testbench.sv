`timescale 1ns/1ps


parameter pckg_sz = 50;
parameter fifo_depth = 4;
parameter test = 3;


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
   
    test1_1 #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) t1_1;
    test1_2 #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) t1_2;
    test1_3 #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) t1_3;
    test2_1 #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) t2_1;
    test2_2 #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) t2_2;

    mesh_if #(.pckg_sz(pckg_sz)) _if(.clk(clk));

    always #5 clk = ~clk;
        
    wrapper #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) uut_wrapper(
        ._if(_if)
    );

    initial begin
        clk = 0;
        case (test)
        1: begin
            t1_1 = new();
            t1_1._if = _if;
            t1_1.ambiente_inst.driver_inst.vif = _if;
            t1_1.ambiente_inst.monitor_inst.vif = _if;
            fork
                t1_1.run();
            join_none
        end

        2: begin
            t1_2 = new();
            t1_2._if = _if;
            t1_2.ambiente_inst.driver_inst.vif = _if;
            t1_2.ambiente_inst.monitor_inst.vif = _if;
            fork
                t1_2.run();
            join_none
        end

        3: begin
            t1_3 = new();
            t1_3._if = _if;
            t1_3.ambiente_inst.driver_inst.vif = _if;
            t1_3.ambiente_inst.monitor_inst.vif = _if;
            fork
                t1_3.run();
            join_none
        end

        4: begin
            t2_1 = new();
            t2_1._if = _if;
            t2_1.ambiente_inst.driver_inst.vif = _if;
            t2_1.ambiente_inst.monitor_inst.vif = _if;
            fork
                t2_1.run();
            join_none
        end

        5: begin
            t2_2 = new();
            t2_2._if = _if;
            t2_2.ambiente_inst.driver_inst.vif = _if;
            t2_2.ambiente_inst.monitor_inst.vif = _if;
            fork
                t2_2.run();
            join_none
        end
            
        endcase

    end

    always@(posedge clk) begin
        if ($time > 10000000)begin
            $display("Test_bench: Tiempo límite de prueba en el test_bench alcanzado");
            $finish;
    end
  end

genvar i;
generate;
    for (i=0; i<16; ++i) begin:_assert_
        Pendings_i: assert property (@(posedge _if.clk) _if.reset |-> ##[0:4] !_if.pndng_i_in[i])
            else $error("Pending not zero after reset");
        Pendings_o: assert property (@(posedge _if.clk) _if.reset |-> ##[0:4] !_if.pndng[i])
            else $error("Pending not zero after reset");   
    end
endgenerate


endmodule
