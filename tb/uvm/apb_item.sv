class apb_item extends uvm_sequence_item;
  rand bit [7:0]    addr;
  rand bit          write;
  rand bit [31:0]   wdata;
  rand int unsigned idle;     // idle cycles after this transfer (used by the driver)
  bit      [31:0]   rdata;
  int               gap;      // idle cycles before this transfer (measured by the monitor)

  constraint c_addr { addr inside {8'h00, 8'h04, 8'h08, 8'h0C, 8'h10, 8'h14}; }
  constraint c_idle { idle dist { 0 := 6, 1 := 3, 2 := 1 }; }

  `uvm_object_utils(apb_item)

  function new(string name = "apb_item");
    super.new(name);
  endfunction
endclass