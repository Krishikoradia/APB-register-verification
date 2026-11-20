`timescale 1ns/1ps
module tb;

  logic        PCLK = 0;
  logic        PRESETn;
  logic        PSEL = 0, PENABLE = 0, PWRITE = 0;
  logic [7:0]  PADDR = 0;
  logic [31:0] PWDATA = 0;
  logic [31:0] PRDATA;
  logic        PREADY;
  logic [3:0]  irq_event = 0;

  int errors = 0;

  apb_reg_block dut (.*);

  always #5 PCLK = ~PCLK;

  task automatic apb_write(input [7:0] addr, input [31:0] data);
    @(posedge PCLK);
    PSEL <= 1; PENABLE <= 0; PWRITE <= 1; PADDR <= addr; PWDATA <= data;
    @(posedge PCLK);
    PENABLE <= 1;
    @(posedge PCLK);
    PSEL <= 0; PENABLE <= 0; PWRITE <= 0;
  endtask

  task automatic apb_read(input [7:0] addr, output [31:0] data);
    @(posedge PCLK);
    PSEL <= 1; PENABLE <= 0; PWRITE <= 0; PADDR <= addr;
    @(posedge PCLK);
    PENABLE <= 1;
    @(posedge PCLK);
    data = PRDATA;
    PSEL <= 0; PENABLE <= 0;
  endtask

  task automatic check(input string name, input [31:0] got, input [31:0] exp);
    if (got === exp)
      $display("PASS: %-28s got=0x%08h", name, got);
    else begin
      $display("FAIL: %-28s got=0x%08h exp=0x%08h", name, got, exp);
      errors++;
    end
  endtask

  logic [31:0] rd;

  initial begin
    PRESETn = 0;
    repeat (3) @(posedge PCLK);
    PRESETn = 1;

    apb_read(8'h00, rd); check("CTRL reset",       rd, 32'h0000_0000);
    apb_read(8'h04, rd); check("STATUS reset",     rd, 32'h0000_0001);
    apb_read(8'h08, rd); check("DATA reset",       rd, 32'h0000_00FF);
    apb_read(8'h0C, rd); check("INT_STATUS reset", rd, 32'h0000_0000);

    apb_write(8'h00, 32'h0000_00A5); apb_read(8'h00, rd);
    check("CTRL write/read", rd, 32'h0000_00A5);
    apb_write(8'h08, 32'h1234_5678); apb_read(8'h08, rd);
    check("DATA write/read", rd, 32'h1234_5678);

    apb_write(8'h04, 32'hFFFF_FFFF); apb_read(8'h04, rd);
    check("STATUS write ignored", rd, 32'h0000_0001);

    @(posedge PCLK); irq_event <= 4'b0101;
    @(posedge PCLK); irq_event <= 4'b0000;
    apb_read(8'h0C, rd); check("INT_STATUS set by hw", rd, 32'h0000_0005);
    apb_write(8'h0C, 32'h0000_0001); apb_read(8'h0C, rd);
    check("INT_STATUS W1C clears bit0", rd, 32'h0000_0004);

    $display("-----------------------------------");
    if (errors == 0) $display("DIRECTED TEST PASSED");
    else             $display("DIRECTED TEST FAILED: %0d errors", errors);
    $finish;
  end

endmodule