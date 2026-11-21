class apb_coverage extends uvm_subscriber #(apb_item);
  `uvm_component_utils(apb_coverage)
  apb_item item;

  covergroup cg;
    option.per_instance = 1;

    cp_addr: coverpoint item.addr {
      bins ctrl     = {8'h00};
      bins status   = {8'h04};
      bins data     = {8'h08};
      bins int_stat = {8'h0C};
      bins unmapped = {8'h10, 8'h14};
    }

    cp_rw: coverpoint item.write {
      bins rd = {0};
      bins wr = {1};
    }

    // every address with both access types (includes writes to read-only STATUS)
    x_addr_rw: cross cp_addr, cp_rw;

    // CTRL fields, counted only on writes to CTRL
    cp_ctrl_en: coverpoint item.wdata[0]
      iff (item.write && item.addr == 8'h00);
    cp_ctrl_mode: coverpoint item.wdata[2:1]
      iff (item.write && item.addr == 8'h00);

    // INT_STATUS write-1-to-clear masks, counted only on writes to INT_STATUS
    cp_w1c_mask: coverpoint item.wdata[3:0]
      iff (item.write && item.addr == 8'h0C) {
      bins none = {4'h0};
      bins some = {[4'h1:4'hE]};
      bins all  = {4'hF};
    }

    // spacing between transfers
    cp_gap: coverpoint item.gap {
      bins back_to_back = {0};
      bins one_idle     = {1};
      bins long_idle    = {[2:$]};
    }
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function void write(apb_item t);
    item = t;
    cg.sample();
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("COV", $sformatf("cp_addr        = %0.2f%%", cg.cp_addr.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("cp_rw          = %0.2f%%", cg.cp_rw.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("x_addr_rw      = %0.2f%%", cg.x_addr_rw.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("cp_ctrl_en     = %0.2f%%", cg.cp_ctrl_en.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("cp_ctrl_mode   = %0.2f%%", cg.cp_ctrl_mode.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("cp_w1c_mask    = %0.2f%%", cg.cp_w1c_mask.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("cp_gap         = %0.2f%%", cg.cp_gap.get_inst_coverage()), UVM_NONE)
    `uvm_info("COV", $sformatf("FUNCTIONAL COVERAGE (whole covergroup) = %0.2f%%", cg.get_inst_coverage()), UVM_NONE)
  endfunction
endclass