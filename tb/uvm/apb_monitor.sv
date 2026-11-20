class apb_monitor extends uvm_monitor;
  `uvm_component_utils(apb_monitor)
  virtual apb_if vif;
  uvm_analysis_port #(apb_item) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db#(virtual apb_if)::get(this, "", "vif", vif))
      `uvm_fatal("MON", "no vif")
  endfunction

  task run_phase(uvm_phase phase);
    forever begin
      @(posedge vif.PCLK);
      if (vif.PRESETn && vif.PSEL && vif.PENABLE && vif.PREADY) begin
        apb_item t = apb_item::type_id::create("t");
        t.addr  = vif.PADDR;
        t.write = vif.PWRITE;
        t.wdata = vif.PWDATA;
        t.rdata = vif.PRDATA;
        if (t.write)
          `uvm_info("MON", $sformatf("WRITE addr=0x%02h data=0x%08h", t.addr, t.wdata), UVM_NONE)
        else
          `uvm_info("MON", $sformatf("READ  addr=0x%02h data=0x%08h", t.addr, t.rdata), UVM_NONE)
        ap.write(t);
      end
    end
  endtask
endclass