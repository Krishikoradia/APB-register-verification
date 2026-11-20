class apb_item extends uvm_sequence_item;
  rand bit [7:0]  addr;
  rand bit        write;
  rand bit [31:0] wdata;
  bit      [31:0] rdata;

  constraint c_addr { addr inside {8'h00, 8'h04, 8'h08, 8'h0C}; }

  `uvm_object_utils(apb_item)

  function new(string name = "apb_item");
    super.new(name);
  endfunction
endclass