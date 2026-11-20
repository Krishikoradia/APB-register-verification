`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "apb_if.sv"
`include "apb_item.sv"
`include "apb_reg_model.sv"
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

class ral_model_test extends uvm_test;
  `uvm_component_utils(ral_model_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    apb_ral_block m;
    uvm_reg       regs[$];
    uvm_reg_field flds[$];
    phase.raise_objection(this);

    m = apb_ral_block::type_id::create("m");
    m.build();
    m.get_registers(regs);
    m.get_fields(flds);

    `uvm_info("RAL", $sformatf("registers=%0d fields=%0d", regs.size(), flds.size()), UVM_NONE)
    foreach (regs[i])
      `uvm_info("RAL", $sformatf("REG   %-11s addr=0x%02h reset=0x%08h",
                regs[i].get_name(), regs[i].get_address(), regs[i].get_reset()), UVM_NONE)
    foreach (flds[i])
      `uvm_info("RAL", $sformatf("FIELD %-11s.%-6s lsb=%0d bits=%0d access=%s reset=0x%0h",
                flds[i].get_parent().get_name(), flds[i].get_name(), flds[i].get_lsb_pos(),
                flds[i].get_n_bits(), flds[i].get_access(), flds[i].get_reset()), UVM_NONE)

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
    run_test("ral_model_test");
  end
endmodule