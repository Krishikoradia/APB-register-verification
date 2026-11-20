`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "apb_if.sv"
`include "apb_item.sv"
`include "apb_reg_model.sv"
`include "apb_reg_adapter.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "apb_sequences.sv"
`include "apb_agent.sv"
`include "apb_scoreboard.sv"
`include "apb_env.sv"

class env_test extends uvm_test;
  `uvm_component_utils(env_test)
  apb_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = apb_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    apb_wr_rd_seq seq;
    phase.raise_objection(this);
    seq = apb_wr_rd_seq::type_id::create("seq");
    seq.start(env.agent.sequencer);
    #50ns;
    phase.drop_objection(this);
  endtask
endclass

class rand_test extends env_test;
  `uvm_component_utils(rand_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    apb_rand_seq seq;
    phase.raise_objection(this);
    seq = apb_rand_seq::type_id::create("seq");
    seq.n = 50;
    seq.start(env.agent.sequencer);
    #50ns;
    phase.drop_objection(this);
  endtask
endclass

class ral_access_test extends env_test;
  `uvm_component_utils(ral_access_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    uvm_status_e   st;
    uvm_reg_data_t rd;
    phase.raise_objection(this);

    env.regmodel.ctrl.write(st, 32'hA5);
    env.regmodel.ctrl.read (st, rd);
    #1ns;
    `uvm_info("RAL", $sformatf("CTRL read=0x%08h mirror=0x%08h",
              rd, env.regmodel.ctrl.get_mirrored_value()), UVM_NONE)

    env.regmodel.data.write(st, 32'hCAFE_1234);
    env.regmodel.data.read (st, rd);
    #1ns;
    `uvm_info("RAL", $sformatf("DATA read=0x%08h mirror=0x%08h",
              rd, env.regmodel.data.get_mirrored_value()), UVM_NONE)

    env.regmodel.status.read(st, rd);
    #1ns;
    `uvm_info("RAL", $sformatf("STATUS read=0x%08h", rd), UVM_NONE)

    #50ns;
    phase.drop_objection(this);
  endtask
endclass

module tb_top;
  logic PCLK = 0;
  logic PRESETn;
  always #5 PCLK = ~PCLK;

  apb_if vif (PCLK, PRESETn);

  apb_reg_block dut (
    .PCLK(PCLK), .PRESETn(PRESETn),
    .PSEL(vif.PSEL), .PENABLE(vif.PENABLE), .PWRITE(vif.PWRITE),
    .PADDR(vif.PADDR), .PWDATA(vif.PWDATA),
    .PRDATA(vif.PRDATA), .PREADY(vif.PREADY),
    .irq_event(vif.irq_event)
  );

  initial begin
    PRESETn = 0;
    repeat (3) @(posedge PCLK);
    PRESETn = 1;
  end

  initial begin
    uvm_config_db#(virtual apb_if)::set(null, "*", "vif", vif);
    run_test("ral_access_test");
  end
endmodule