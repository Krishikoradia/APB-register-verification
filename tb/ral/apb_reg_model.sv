class ctrl_reg extends uvm_reg;
  `uvm_object_utils(ctrl_reg)
  rand uvm_reg_field en, mode, cfg, rsvd;

  function new(string name = "ctrl_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    en   = uvm_reg_field::type_id::create("en");
    mode = uvm_reg_field::type_id::create("mode");
    cfg  = uvm_reg_field::type_id::create("cfg");
    rsvd = uvm_reg_field::type_id::create("rsvd");
    en.configure  (this, 1,  0, "RW", 0, 1'h0,  1, 1, 0);
    mode.configure(this, 2,  1, "RW", 0, 2'h0,  1, 1, 0);
    cfg.configure (this, 5,  3, "RW", 0, 5'h0,  1, 1, 0);
    rsvd.configure(this, 24, 8, "RO", 0, 24'h0, 1, 0, 0);
  endfunction
endclass

class status_reg extends uvm_reg;
  `uvm_object_utils(status_reg)
  rand uvm_reg_field ready, rsvd;

  function new(string name = "status_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    ready = uvm_reg_field::type_id::create("ready");
    rsvd  = uvm_reg_field::type_id::create("rsvd");
    ready.configure(this, 1,  0, "RO", 0, 1'h1,  1, 0, 0);
    rsvd.configure (this, 31, 1, "RO", 0, 31'h0, 1, 0, 0);
  endfunction
endclass

class data_reg extends uvm_reg;
  `uvm_object_utils(data_reg)
  rand uvm_reg_field data;

  function new(string name = "data_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    data = uvm_reg_field::type_id::create("data");
    data.configure(this, 32, 0, "RW", 0, 32'hFF, 1, 1, 0);
  endfunction
endclass

class int_status_reg extends uvm_reg;
  `uvm_object_utils(int_status_reg)
  rand uvm_reg_field ev, rsvd;

  function new(string name = "int_status_reg");
    super.new(name, 32, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    ev   = uvm_reg_field::type_id::create("ev");
    rsvd = uvm_reg_field::type_id::create("rsvd");
    ev.configure  (this, 4,  0, "W1C", 0, 4'h0,  1, 1, 0);
    rsvd.configure(this, 28, 4, "RO",  0, 28'h0, 1, 0, 0);
  endfunction
endclass

class apb_ral_block extends uvm_reg_block;
  `uvm_object_utils(apb_ral_block)
  rand ctrl_reg       ctrl;
  rand status_reg     status;
  rand data_reg       data;
  rand int_status_reg int_status;
  uvm_reg_map         default_map;

  function new(string name = "apb_ral_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction

  virtual function void build();
    ctrl = ctrl_reg::type_id::create("ctrl");
    ctrl.configure(this, null, "");
    ctrl.build();
    ctrl.add_hdl_path_slice("ctrl_q", 0, 8);

    status = status_reg::type_id::create("status");
    status.configure(this, null, "");
    status.build();
    status.add_hdl_path_slice("status_q", 0, 32);

    data = data_reg::type_id::create("data");
    data.configure(this, null, "");
    data.build();
    data.add_hdl_path_slice("data_q", 0, 32);

    int_status = int_status_reg::type_id::create("int_status");
    int_status.configure(this, null, "");
    int_status.build();
    int_status.add_hdl_path_slice("int_status_q", 0, 4);

    default_map = create_map("default_map", 'h0, 4, UVM_LITTLE_ENDIAN);
    default_map.add_reg(ctrl,       'h00, "RW");
    default_map.add_reg(status,     'h04, "RW");
    default_map.add_reg(data,       'h08, "RW");
    default_map.add_reg(int_status, 'h0C, "RW");

    add_hdl_path("tb_top.dut", "RTL");
    lock_model();
  endfunction
endclass