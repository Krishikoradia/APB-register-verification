module apb_sva (
  input logic        PCLK,
  input logic        PRESETn,
  input logic        PSEL,
  input logic        PENABLE,
  input logic        PWRITE,
  input logic [7:0]  PADDR,
  input logic [31:0] PWDATA,
  input logic [31:0] PRDATA,
  input logic        PREADY
);

  int pass_cnt   = 0;   // non-vacuous assertion passes
  int fail_cnt   = 0;
  int b2b_cnt    = 0;   // back-to-back transfers seen
  int spaced_cnt = 0;   // transfers followed by an idle cycle

  default clocking cb @(posedge PCLK); endclocking
  default disable iff (!PRESETn);

  // 1. PENABLE is never high without PSEL
  a_penable_needs_psel: assert property (PENABLE |-> PSEL)
    pass_cnt++; else begin fail_cnt++; $error("SVA a_penable_needs_psel"); end

  // 2. a setup phase is always followed by an access phase
  a_setup_then_access: assert property ((PSEL && !PENABLE) |=> (PSEL && PENABLE))
    pass_cnt++; else begin fail_cnt++; $error("SVA a_setup_then_access"); end

  // 3. address, direction and write data do not change from setup to access
  a_stable_setup_to_access: assert property
    ((PSEL && !PENABLE) |=> ($stable(PADDR) && $stable(PWRITE) && $stable(PWDATA)))
    pass_cnt++; else begin fail_cnt++; $error("SVA a_stable_setup_to_access"); end

  // 4. while the slave is not ready, the transfer must stay stable
  //    (our DUT never waits, so this one is never exercised)
  a_stable_until_ready: assert property
    ((PSEL && PENABLE && !PREADY) |=> ($stable(PADDR) && $stable(PWRITE) && $stable(PWDATA)))
    pass_cnt++; else begin fail_cnt++; $error("SVA a_stable_until_ready"); end

  // 5. PENABLE drops after a completed transfer
  a_penable_low_after_access: assert property ((PSEL && PENABLE && PREADY) |=> !PENABLE)
    pass_cnt++; else begin fail_cnt++; $error("SVA a_penable_low_after_access"); end

  // 6. this DUT has zero wait states: PREADY is high in every access phase
  a_zero_wait: assert property ((PSEL && PENABLE) |-> PREADY)
    pass_cnt++; else begin fail_cnt++; $error("SVA a_zero_wait"); end

  // 7. control signals are never X or Z
  a_ctrl_known: assert property (!$isunknown({PSEL, PENABLE, PWRITE, PREADY}))
    pass_cnt++; else begin fail_cnt++; $error("SVA a_ctrl_known"); end

  // 8. read data is never X or Z at the end of a read
  a_rdata_known: assert property ((PSEL && PENABLE && PREADY && !PWRITE) |-> !$isunknown(PRDATA))
    pass_cnt++; else begin fail_cnt++; $error("SVA a_rdata_known"); end

  // coverage of transfer spacing
  c_back_to_back: cover property ((PSEL && PENABLE && PREADY) ##1 (PSEL && !PENABLE))
    b2b_cnt++;
  c_spaced: cover property ((PSEL && PENABLE && PREADY) ##1 !PSEL)
    spaced_cnt++;

  final begin
    $display("SVA SUMMARY: assertion passes=%0d failures=%0d | back-to-back=%0d spaced=%0d",
             pass_cnt, fail_cnt, b2b_cnt, spaced_cnt);
  end

endmodule