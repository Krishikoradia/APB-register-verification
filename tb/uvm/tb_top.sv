`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "apb_if.sv"
`include "apb_item.sv"
`include "apb_driver.sv"
`include "apb_monitor.sv"
`include "apb_sequences.sv"

class mon_test extends uvm_test;
  `uvm_component_utils(mon_test)
  uvm_sequencer #(apb_item) sqr;
  apb_driver  drv;
  apb_monitor mon;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sqr = uvm_sequencer#(apb_item)::type_id::create("sqr", this);
    drv = apb_driver::type_id::create("drv", this);
    mon = apb_monitor::type_id::create("mon", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(sqr.seq_item_export);
  endfunction

  task run_phase(uvm_phase phase);
    apb_wr_rd_seq seq;
    phase.raise_objection(this);
    seq = apb_wr_rd_seq::type_id::create("seq");
    seq.start(sqr);
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
    run_test("mon_test");
  end
endmodule