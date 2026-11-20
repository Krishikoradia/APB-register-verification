class apb_wr_rd_seq extends uvm_sequence #(apb_item);
  `uvm_object_utils(apb_wr_rd_seq)

  function new(string name = "apb_wr_rd_seq");
    super.new(name);
  endfunction

  task do_item(bit write, bit [7:0] addr, bit [31:0] wdata);
    apb_item t = apb_item::type_id::create("t");
    start_item(t);
    t.write = write; t.addr = addr; t.wdata = wdata;
    finish_item(t);
  endtask

  task body();
    do_item(1, 8'h00, 32'h0000_00A5);   // write CTRL
    do_item(0, 8'h00, 32'h0);           // read CTRL
    do_item(1, 8'h08, 32'h1234_5678);   // write DATA
    do_item(0, 8'h08, 32'h0);           // read DATA
    do_item(0, 8'h04, 32'h0);           // read STATUS
  endtask
endclass