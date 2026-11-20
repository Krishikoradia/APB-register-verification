`timescale 1ns/1ps
`include "uvm_macros.svh"
import uvm_pkg::*;
`include "apb_if.sv"
`include "apb_item.sv"

class item_test extends uvm_test;
  `uvm_component_utils(item_test)

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    apb_item item;
    phase.raise_objection(this);
    repeat (5) begin
      item = apb_item::type_id::create("item");
      if (!item.randomize()) `uvm_error("ITEM", "randomize failed")
      `uvm_info("ITEM", $sformatf("addr=0x%02h write=%0b wdata=0x%08h",
                                  item.addr, item.write, item.wdata), UVM_NONE)
    end
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

  initial run_test("item_test");
endmodule