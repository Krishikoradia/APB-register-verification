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
    int cyc  = 0;
    int last = -1;
    forever begin
      @(posedge vif.PCLK);
      cyc++;
      if (vif.PRESETn && vif.PSEL && vif.PENABLE && vif.PREADY) begin
        apb_item t = apb_item::type_id::create("t");
        t.addr  = vif.PADDR;
        t.write = vif.PWRITE;
        t.wdata = vif.PWDATA;
        t.rdata = vif.PRDATA;
        // a back-to-back transfer completes every 2 clocks, so gap = clocks between completions minus 2
        t.gap   = (last < 0) ? 5 : (cyc - last - 2);
        last    = cyc;
        if (t.write)
          `uvm_info("MON", $sformatf("WRITE addr=0x%02h data=0x%08h gap=%0d", t.addr, t.wdata, t.gap), UVM_NONE)
        else
          `uvm_info("MON", $sformatf("READ  addr=0x%02h data=0x%08h gap=%0d", t.addr, t.rdata, t.gap), UVM_NONE)
        ap.write(t);
      end
    end
  endtask
endclass