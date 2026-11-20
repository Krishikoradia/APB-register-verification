// Code your design here
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

  logic wr_en;
  logic [3:0] clear_mask;

  assign PREADY     = 1'b1;
  assign wr_en      = PSEL && PENABLE && PWRITE;
  assign clear_mask = (wr_en && PADDR == ADDR_INT_STATUS) ? PWDATA[3:0] : 4'h0;

  always_ff @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
      ctrl_q       <= 8'h00;
      status_q     <= 32'h0000_0001;
      data_q       <= 32'h0000_00FF;
      int_status_q <= 4'h0;
    end else begin
      if (wr_en) begin
        case (PADDR)
          ADDR_CTRL: ctrl_q <= PWDATA[7:0];
          ADDR_DATA: data_q <= PWDATA;
          default: ;
        endcase
      end
      int_status_q <= (int_status_q & ~clear_mask) | irq_event;
    end
  end

  always_comb begin
    PRDATA = 32'h0;
    if (PSEL && !PWRITE) begin
      case (PADDR)
        ADDR_CTRL:       PRDATA = {24'h0, ctrl_q};
        ADDR_STATUS:     PRDATA = status_q;
        ADDR_DATA:       PRDATA = data_q;
        ADDR_INT_STATUS: PRDATA = {28'h0, int_status_q};
        default:         PRDATA = 32'h0;
      endcase
    end
  end

endmodule