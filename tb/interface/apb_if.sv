interface apb_if (input logic PCLK, input logic PRESETn);
  logic        PSEL = 0;
  logic        PENABLE = 0;
  logic        PWRITE = 0;
  logic [7:0]  PADDR = 0;
  logic [31:0] PWDATA = 0;
  logic [31:0] PRDATA;
  logic        PREADY;
  logic [3:0]  irq_event = 0;
endinterface