class apb_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(apb_scoreboard)
  uvm_analysis_imp #(apb_item, apb_scoreboard) item_export;

  bit [31:0] exp_ctrl, exp_status, exp_data;
  bit [3:0]  exp_int;
  int        checks, fails;

  function new(string name, uvm_component parent);
    super.new(name, parent);
    item_export = new("item_export", this);
    exp_ctrl   = 32'h0;     // reset values from the register map
    exp_status = 32'h1;
    exp_data   = 32'hFF;
    exp_int    = 4'h0;
  endfunction

  // used later, when a test makes the hardware raise an interrupt event
  function void hw_set(bit [3:0] mask);
    exp_int = exp_int | mask;
  endfunction

  function void write(apb_item t);
    bit [31:0] exp;
    if (t.write) begin
      case (t.addr)
        8'h00:   exp_ctrl = t.wdata & 32'hFF;      // 8 bits only
        8'h08:   exp_data = t.wdata;
        8'h0C:   exp_int  = exp_int & ~t.wdata[3:0]; // W1C
        default: ;                                  // STATUS is RO, others ignored
      endcase
    end else begin
      case (t.addr)
        8'h00:   exp = exp_ctrl;
        8'h04:   exp = exp_status;
        8'h08:   exp = exp_data;
        8'h0C:   exp = {28'h0, exp_int};
        default: exp = 32'h0;
      endcase
      checks++;
      if (t.rdata !== exp) begin
        fails++;
        `uvm_error("SCB", $sformatf("READ MISMATCH addr=0x%02h got=0x%08h exp=0x%08h",
                                    t.addr, t.rdata, exp))
      end
    end
  endfunction

  function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("SCOREBOARD read checks=%0d mismatches=%0d", checks, fails), UVM_NONE)
  endfunction
endclass