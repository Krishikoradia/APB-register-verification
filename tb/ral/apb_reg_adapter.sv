class apb_reg_adapter extends uvm_reg_adapter;
  `uvm_object_utils(apb_reg_adapter)

  function new(string name = "apb_reg_adapter");
    super.new(name);
    supports_byte_enable = 0;
    provides_responses   = 0;
  endfunction

  virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
    apb_item t = apb_item::type_id::create("t");
    t.write = (rw.kind == UVM_WRITE);
    t.addr  = rw.addr[7:0];
    t.wdata = rw.data;
    return t;
  endfunction

  virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
    apb_item t;
    if (!$cast(t, bus_item)) `uvm_fatal("ADAPT", "cast failed")
    rw.kind   = t.write ? UVM_WRITE : UVM_READ;
    rw.addr   = t.addr;
    rw.data   = t.write ? t.wdata : t.rdata;
    rw.status = UVM_IS_OK;
  endfunction
endclass