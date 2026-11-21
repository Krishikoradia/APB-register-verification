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
`include "apb_sva.sv"

bind apb_reg_block apb_sva u_apb_sva (.*);

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

class ral_builtin_test extends env_test;
  `uvm_component_utils(ral_builtin_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    uvm_reg_hw_reset_seq rst_seq;
    uvm_reg_bit_bash_seq bb_seq;
    phase.raise_objection(this);

    `uvm_info("RAL", "START built-in reset test", UVM_NONE)
    rst_seq = uvm_reg_hw_reset_seq::type_id::create("rst_seq");
    rst_seq.model = env.regmodel;
    rst_seq.start(null);
    `uvm_info("RAL", "DONE  built-in reset test", UVM_NONE)

    `uvm_info("RAL", "START built-in bit-bash test", UVM_NONE)
    bb_seq = uvm_reg_bit_bash_seq::type_id::create("bb_seq");
    bb_seq.model = env.regmodel;
    bb_seq.start(null);
    `uvm_info("RAL", "DONE  built-in bit-bash test", UVM_NONE)

    #50ns;
    phase.drop_objection(this);
  endtask
endclass

class ral_int_test extends env_test;
  `uvm_component_utils(ral_int_test)
  virtual apb_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("TEST", "no vif")
  endfunction

  // read INT_STATUS through RAL and compare with the expected value
  task check_int(string name, bit [3:0] exp);
    uvm_status_e   st;
    uvm_reg_data_t rd;
    env.regmodel.int_status.read(st, rd);
    if (rd[3:0] === exp)
      `uvm_info("INTR", $sformatf("PASS %-34s got=0x%0h", name, rd[3:0]), UVM_NONE)
    else
      `uvm_error("INTR", $sformatf("FAIL %-34s got=0x%0h exp=0x%0h", name, rd[3:0], exp))
  endtask

  // hardware raises interrupt events for one clock
  task pulse_irq(bit [3:0] mask);
    @(posedge vif.PCLK);
    vif.irq_event <= mask;
    @(posedge vif.PCLK);
    vif.irq_event <= 4'h0;
    repeat (2) @(posedge vif.PCLK);
    env.scb.hw_set(mask);
  endtask

  task int_scenario();
    uvm_status_e st;

    env.regmodel.int_status.write(st, 32'h0000_000F);
    check_int("clear all", 4'h0);

    pulse_irq(4'b0101);
    check_int("hw sets bits 0 and 2", 4'b0101);

    env.regmodel.int_status.write(st, 32'h0000_0001);
    check_int("W1C clears bit 0 only", 4'b0100);

    env.regmodel.int_status.write(st, 32'h0000_0000);
    check_int("writing 0 clears nothing", 4'b0100);

    // hardware event on bit 2 in the same clock as software clearing bit 2
    fork
      begin
        @(posedge vif.PCLK iff (vif.PSEL && !vif.PENABLE && vif.PWRITE && vif.PADDR == 8'h0C));
        vif.irq_event <= 4'b0100;
        @(posedge vif.PCLK);
        vif.irq_event <= 4'b0000;
      end
      env.regmodel.int_status.write(st, 32'h0000_0004);
    join
    #1ns;
    env.scb.hw_set(4'b0100);
    check_int("hw set wins over same-clock clear", 4'b0100);

    env.regmodel.int_status.write(st, 32'h0000_000F);
    check_int("clear all again", 4'h0);
  endtask

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    wait (vif.PRESETn === 1'b1);
    repeat (2) @(posedge vif.PCLK);
    int_scenario();
    #50ns;
    phase.drop_objection(this);
  endtask
endclass

class regression_test extends ral_int_test;
  `uvm_component_utils(regression_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    uvm_reg_hw_reset_seq rst_seq;
    uvm_reg_bit_bash_seq bb_seq;
    apb_rand_seq         rnd;
    phase.raise_objection(this);
    wait (vif.PRESETn === 1'b1);
    repeat (2) @(posedge vif.PCLK);

    `uvm_info("RAL", "START reset test", UVM_NONE)
    rst_seq = uvm_reg_hw_reset_seq::type_id::create("rst_seq");
    rst_seq.model = env.regmodel;
    rst_seq.start(null);

    `uvm_info("RAL", "START bit-bash test", UVM_NONE)
    bb_seq = uvm_reg_bit_bash_seq::type_id::create("bb_seq");
    bb_seq.model = env.regmodel;
    bb_seq.start(null);

    `uvm_info("RAL", "START random traffic (200 transfers)", UVM_NONE)
    rnd = apb_rand_seq::type_id::create("rnd");
    rnd.n = 200;
    rnd.start(env.agent.sequencer);

    `uvm_info("RAL", "START interrupt scenario", UVM_NONE)
    int_scenario();

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
    uvm_root::get().finish_on_completion = 0;   // do not call $finish at the end of the test
    run_test("regression_test");
    $stop;                                      // hand control back to run.do for the coverage reports
  end
endmodule