class apb_driver extends uvm_driver #(apb_item);
  `uvm_component_utils(apb_driver)
  virtual apb_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("DRV", "no vif")
  endfunction

  task run_phase(uvm_phase phase);
    wait (vif.PRESETn === 1'b1);
    @(posedge vif.PCLK);
    forever begin
      seq_item_port.get_next_item(req);
      drive(req);
      seq_item_port.item_done();
    end
  endtask

  task drive(apb_item t);
    // setup phase
    vif.PSEL <= 1; vif.PENABLE <= 0;
    vif.PWRITE <= t.write; vif.PADDR <= t.addr; vif.PWDATA <= t.wdata;
    @(posedge vif.PCLK);
    // access phase
    vif.PENABLE <= 1;
    @(posedge vif.PCLK);
    while (!vif.PREADY) @(posedge vif.PCLK);
    t.rdata = vif.PRDATA;
    // done
    vif.PSEL <= 0; vif.PENABLE <= 0;
    if (t.write)
      `uvm_info("DRV", $sformatf("WRITE addr=0x%02h data=0x%08h", t.addr, t.wdata), UVM_NONE)
    else
      `uvm_info("DRV", $sformatf("READ  addr=0x%02h data=0x%08h", t.addr, t.rdata), UVM_NONE)
  endtask
endclass