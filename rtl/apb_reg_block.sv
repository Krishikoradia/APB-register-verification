module apb_reg_block (
  input  logic        PCLK,
  input  logic        PRESETn,
  input  logic        PSEL,
  input  logic        PENABLE,
  input  logic        PWRITE,
  input  logic [7:0]  PADDR,
  input  logic [31:0] PWDATA,
  output logic [31:0] PRDATA,
  output logic        PREADY,
  input  logic [3:0]  irq_event
);

  localparam logic [7:0] ADDR_CTRL       = 8'h00;
  localparam logic [7:0] ADDR_STATUS     = 8'h04;
  localparam logic [7:0] ADDR_DATA       = 8'h08;
  localparam logic [7:0] ADDR_INT_STATUS = 8'h0C;

  logic [7:0]  ctrl_q;
  logic [31:0] status_q;
  logic [31:0] data_q;
  logic [3:0]  int_status_q;

  logic        wr_en;
  logic [3:0]  clear_mask;
  logic [3:0]  hw_ev;
  logic [7:0]  addr_dec;

  assign PREADY = 1'b1;
  assign wr_en  = PSEL && PENABLE && PWRITE;

  // ---------------- address decode ----------------
`ifdef BUG4_ADDR_DECODE
  assign addr_dec = {4'h0, PADDR[3:0]};      // BUG 4: upper address bits ignored
`else
  assign addr_dec = PADDR;
`endif

  // ---------------- hardware interrupt events ----------------
`ifdef BUG8_IRQ3_IGNORED
  assign hw_ev = {1'b0, irq_event[2:0]};     // BUG 8: event on bit 3 ignored
`else
  assign hw_ev = irq_event;
`endif

  // ---------------- W1C clear mask ----------------
`ifdef BUG3_W1C_NO_CLEAR
  assign clear_mask = 4'h0;                  // BUG 3: never clears
`elsif BUG6_W1C_CLEARS_ON_ZERO
  assign clear_mask = (wr_en && addr_dec == ADDR_INT_STATUS) ? ~PWDATA[3:0] : 4'h0;  // BUG 6: inverted
`else
  assign clear_mask = (wr_en && addr_dec == ADDR_INT_STATUS) ? PWDATA[3:0] : 4'h0;
`endif

  // ---------------- write side ----------------
  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      ctrl_q       <= 8'h00;
      status_q     <= 32'h0000_0001;
`ifdef BUG1_RESET_VALUE
      data_q       <= 32'h0000_0000;         // BUG 1: wrong reset value
`else
      data_q       <= 32'h0000_00FF;
`endif
      int_status_q <= 4'h0;
    end else begin
      if (wr_en) begin
        case (addr_dec)
`ifdef BUG5_CTRL_BIT7_STUCK
          ADDR_CTRL: ctrl_q <= {1'b0, PWDATA[6:0]};   // BUG 5: bit 7 stuck at 0
`else
          ADDR_CTRL: ctrl_q <= PWDATA[7:0];
`endif
          ADDR_DATA: data_q <= PWDATA;
`ifdef BUG2_RO_WRITABLE
          ADDR_STATUS: status_q <= PWDATA;            // BUG 2: read-only register is writable
`endif
          default: ;
        endcase
      end

`ifdef BUG7_HW_SET_LOST_ON_CLEAR
      int_status_q <= (int_status_q & ~clear_mask) | (hw_ev & ~clear_mask);  // BUG 7: set lost on same-clock clear
`else
      int_status_q <= (int_status_q & ~clear_mask) | hw_ev;
`endif
    end
  end

  // ---------------- read side ----------------
  always_comb begin
    PRDATA = 32'h0;
    if (PSEL && !PWRITE) begin
      case (addr_dec)
        ADDR_CTRL:       PRDATA = {24'h0, ctrl_q};
        ADDR_STATUS:     PRDATA = status_q;
        ADDR_DATA:       PRDATA = data_q;
        ADDR_INT_STATUS: PRDATA = {28'h0, int_status_q};
        default:         PRDATA = 32'h0;
      endcase
    end
  end

endmodule