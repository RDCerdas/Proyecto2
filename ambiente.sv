class ambiente #(parameter pckg_sz = 40, fifo_depth = 4);
     virtual mesh_if #(.pckg_sz(pckg_sz)) _if;

     // Instanciación de los dispositivos
     driver #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) driver_inst;
     agent #(.pckg_sz(pckg_sz)) agent_inst;
     monitor #(.pckg_sz(pckg_sz), .fifo_depth(fifo_depth)) monitor_inst;
     checkers #(.pckg_sz(pckg_sz)) checker_inst;
  	 score_board #(.pckg_sz(pckg_sz)) score_board_inst;
     // Instanciación de los mailbox
     agent_driver_mbx agent_driver_mbx_inst;
     driver_checker_mbx driver_checker_mbx_inst;
     monitor_checker_mbx monitor_checker_mbx_inst;
     checker_scoreboard_mbx checker_scoreboard_mbx_inst;
     test_agent_mbx test_agent_mbx_inst;

  function new(test_agent_mbx t_a_mbx, test_sb_mbx test_sb_mbx_i);
      // Instanciación de los mailboxes
      agent_driver_mbx_inst = new;
      driver_checker_mbx_inst = new;
      monitor_checker_mbx_inst = new;
      checker_scoreboard_mbx_inst = new;
       
      // Instanciación de los componentes
      driver_inst = new();
      agent_inst = new();
      monitor_inst = new();
    score_board_inst=new();
    checker_inst=new();

      // Conexion de las interfaces y los mailboces
      driver_inst.vif = _if;
      driver_inst.i_agent_driver_mbx = agent_driver_mbx_inst;
      driver_inst.i_driver_checker_mbx = driver_checker_mbx_inst;
      monitor_inst.i_monitor_checker_mbx = monitor_checker_mbx_inst;
      agent_inst.i_test_agent_mbx = t_a_mbx;
      agent_inst.i_agent_driver_mbx = agent_driver_mbx_inst;
    checker_inst.i_driver_checker_mbx=driver_checker_mbx_inst;
    checker_inst.i_monitor_checker_mbx=monitor_checker_mbx_inst;
    score_board_inst.i_checker_scoreboard_mbx=checker_scoreboard_mbx_inst;
    checker_inst.i_checker_scoreboard_mbx=checker_scoreboard_mbx_inst;
    score_board_inst.i_test_sb_mbx=test_sb_mbx_i;
       
       	

     endfunction

     virtual task run();
        $display("[%g]  El ambiente fue inicializado",$time);
        fork
            driver_inst.run();
            agent_inst.run();
           monitor_inst.run();
          checker_inst.run();
          score_board_inst.run();
        join_none
     endtask
endclass
