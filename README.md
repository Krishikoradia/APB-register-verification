# APB Register Block Verification using SystemVerilog and UVM RAL

A UVM testbench that verifies a small APB slave register block (4 registers, 9 fields). The testbench was built step by step: directed test, then UVM agent and scoreboard, then UVM RAL (register model, adapter, predictor, built-in reset and bit-bash sequences), then functional coverage and SVA protocol checks, then bug injection, and finally code coverage.

Every number in this README comes from a real simulation run. The logs are in [`results/`](results/). Simulator: Siemens Questa 2025.2 (QuestaSim-64 `qrun`) with UVM 1.2, run on EDA Playground.

Author: Krishi Koradia

## Results at a glance

| Metric | Result | Evidence |
|---|---|---|
| Registers / fields in the RAL model | 4 registers, 9 fields | `results/step4b_ral_model.log` |
| Functional coverage | **100.00%** (29 of 29 covergroup bins) | `results/coverage_report.log` |
| Code coverage, statement | 100.00% (17 / 17) | `results/coverage_report.log` |
| Code coverage, branch | 100.00% (16 / 16) | `results/coverage_report.log` |
| Code coverage, condition | 100.00% (4 / 4) | `results/coverage_report.log` |
| Code coverage, expression | 100.00% (3 / 3) | `results/coverage_report.log` |
| Code coverage, toggle | **71.71%** (251 / 350) | `results/coverage_report.log` |
| SVA protocol assertions | 5,552 passes, 0 failures; 8 of 9 assertion bins hit; 2 of 2 cover directives hit | `results/coverage_report.log` |
| Scoreboard (regression, golden DUT) | 367 read checks, 0 mismatches | `results/golden_run.log` |
| APB transfers in one regression run | 727 driven and monitored | `results/coverage_report.log` |
| UVM errors / fatals (golden DUT) | 0 / 0 | `results/golden_run.log` |
| Injected bugs caught | **7 of 8** | `results/bug*.log` |

Code coverage is measured on the DUT only (`apb_reg_block`). The simulator's overall "Total coverage" line (95.07%) is a plain average over coverage types, so the types are listed separately above.

## DUT register map

APB slave, 32-bit data, 8-bit address, zero wait states (`PREADY` is always 1). Hardware interrupt events enter through a 4-bit `irq_event` input. Writes to unmapped addresses are ignored and reads of unmapped addresses return 0.

| Offset | Register | Access | Reset value | Fields |
|---|---|---|---|---|
| 0x00 | CTRL | RW | 0x00000000 | `en` [0] RW, `mode` [2:1] RW, `cfg` [7:3] RW, `rsvd` [31:8] RO (reads 0) |
| 0x04 | STATUS | RO | 0x00000001 | `ready` [0] RO (reset 1), `rsvd` [31:1] RO |
| 0x08 | DATA | RW | 0x000000FF | `data` [31:0] RW |
| 0x0C | INT_STATUS | W1C | 0x00000000 | `ev` [3:0] W1C (set by `irq_event`, cleared by writing 1), `rsvd` [31:4] RO |

If a hardware event and a software clear hit the same INT_STATUS bit in the same clock, the event wins, so no interrupt is lost.

## Testbench architecture

```
                      regression_test (uvm_test)
                                 |
                              apb_env
   +--------------+--------------+----------------+----------------------+
   |              |              |                |                      |
apb_agent   apb_scoreboard  apb_coverage   uvm_reg_predictor    RAL model + adapter
 |- sequencer    ^              ^                ^               (apb_ral_block)
 |- driver       |              |                |
 '- monitor -----+--------------+----------------+   (analysis port, apb_item)

 driver and monitor <--- apb_if (interface) ---> DUT: apb_reg_block
                                                    ^
                                      bind ---------+--- apb_sva (8 assertions, 2 covers)
```

| Component | File | Role |
|---|---|---|
| Interface | `tb/interface/apb_if.sv` | APB signals plus `irq_event` |
| Sequence item | `tb/uvm/apb_item.sv` | address, read/write, data, idle cycles; constrained to 4 mapped and 2 unmapped addresses |
| Sequences | `tb/uvm/apb_sequences.sv` | directed write/read sequence, random sequence |
| Driver / monitor / agent | `tb/uvm/apb_driver.sv`, `apb_monitor.sv`, `apb_agent.sv` | drives the APB setup and access phases, observes completed transfers, measures the gap between transfers |
| Scoreboard | `tb/uvm/apb_scoreboard.sv` | reference model of all registers (RW, RO, W1C rules), checks every read |
| RAL | `tb/ral/apb_reg_model.sv`, `apb_reg_adapter.sv` | register model, bus adapter; predictor connected in `apb_env.sv` |
| Functional coverage | `tb/coverage/apb_coverage.sv` | covergroup sampled from the monitor |
| Assertions | `tb/assertions/apb_sva.sv` | APB protocol checks, attached with `bind` |
| Tests and top | `tb/uvm/tb_top.sv` | all tests and the top module |
| Step 1 test | `tb/directed_tb.sv` | standalone directed testbench (no UVM) |

### What the regression test runs

`regression_test` runs four things in one simulation (15,525 ns):

1. UVM built-in **register reset test** (reads every register and compares with the RAL reset values).
2. UVM built-in **bit-bash test** (writes and reads every bit of every field using the access type from the model).
3. **200 random transfers** (random read/write, 4 mapped plus 2 unmapped addresses, 0 to 2 idle cycles between transfers).
4. **Interrupt scenario** with 6 checks: hardware sets bits, W1C clears one bit, writing 0 clears nothing, and a hardware event in the same clock as a software clear.

### SVA checks

`PENABLE` only with `PSEL`; setup phase always followed by access phase; address, direction and write data stable from setup to access; stable while not ready; `PENABLE` low after a completed transfer; zero-wait-state `PREADY`; control signals never X or Z; read data never X or Z on reads. Two cover properties count back-to-back and spaced transfers (655 and 72 in the regression).

### Functional coverage

Address (4 registers plus unmapped), read/write, address crossed with read/write, CTRL `en` and `mode` values on writes, INT_STATUS write mask (none, some, all), and the gap between transfers (back-to-back, one idle, two or more idle).

## How to run on EDA Playground

1. Open EDA Playground and log in (commercial simulators need an account).
2. Set **Testbench + Design** to SystemVerilog/Verilog, **UVM / OVM** to UVM 1.2, **Tools & Simulators** to Siemens Questa 2025.2.
3. Paste `rtl/apb_reg_block.sv` into the right box (`design.sv`) and `tb/uvm/tb_top.sv` into the left box (`testbench.sv`).
4. Add each remaining file with the **+** button, using exactly these names: `apb_if.sv`, `apb_item.sv`, `apb_reg_model.sv`, `apb_reg_adapter.sv`, `apb_driver.sv`, `apb_monitor.sv`, `apb_sequences.sv`, `apb_agent.sv`, `apb_scoreboard.sv`, `apb_coverage.sv`, `apb_sva.sv`, `apb_env.sv`.
5. Plain regression run: Compile Options `-timescale 1ns/1ns`, Run Options `-voptargs=+acc=npr`. The last line of `tb_top.sv` selects the test (`regression_test`).
6. Coverage run: Compile Options `-timescale 1ns/1ns +cover=bcesft+apb_reg_block`, Run Options `-voptargs=+acc=npr -coverage`, tick **Use run.do Tcl file** and paste the contents of [`docs/run.do`](docs/run.do). `tb_top.sv` calls `$stop` after the test so the coverage reports print.
7. Bug run: add one switch to the Compile Options, for example `-timescale 1ns/1ns +define+BUG3_W1C_NO_CLEAR`. The switches are listed below and live in `rtl/apb_reg_block.sv`.

The step 1 testbench runs on its own: put `rtl/apb_reg_block.sv` in the design box, `tb/directed_tb.sv` in the testbench box and set UVM to None.

## Bug injection

The DUT has eight switchable bugs (`bugs/` has a note per bug). Each bug was run against the full regression and the logs are in `results/`. A bug counts as caught if the run reports a `UVM_ERROR`.

| # | Switch | Bug | Caught | Checks that fired | Scoreboard mismatches / UVM_ERROR total |
|---|---|---|---|---|---|
| 1 | `BUG1_RESET_VALUE` | DATA resets to 0x00 instead of 0xFF | Yes | scoreboard, on the first DATA read (85 ns) | 1 / 2 |
| 2 | `BUG2_RO_WRITABLE` | read-only STATUS can be written | Yes | scoreboard and UVM bit-bash test | 51 / 115 |
| 3 | `BUG3_W1C_NO_CLEAR` | INT_STATUS never clears | Yes | scoreboard and interrupt scenario | 4 / 8 |
| 4 | `BUG4_ADDR_DECODE` | upper address bits ignored, so 0x10 aliases 0x00 and 0x14 aliases 0x04 | Yes | scoreboard (unmapped-address reads) | 43 / 43 |
| 5 | `BUG5_CTRL_BIT7_STUCK` | CTRL bit 7 stuck at 0 | Yes | scoreboard and UVM bit-bash test | 12 / 14 |
| 6 | `BUG6_W1C_CLEARS_ON_ZERO` | write-1-to-clear mask inverted | Yes | scoreboard and interrupt scenario | 3 / 6 |
| 7 | `BUG7_HW_SET_LOST_ON_CLEAR` | hardware event lost when it arrives in the same clock as a software clear | Yes | scoreboard and interrupt scenario | 1 / 2 |
| 8 | `BUG8_IRQ3_IGNORED` | hardware event on INT_STATUS bit 3 ignored | **No** | none | 0 / 0 |

**Result: 7 of 8 injected bugs caught.**

None of the SVA assertions failed on any bug. This is expected, because these are register-behavior bugs and the assertions check the bus protocol.

**Why bug 8 was missed:** the interrupt scenario only raises hardware events on bits 0 and 2, and the random traffic never drives `irq_event`, so bit 3 is never exercised. The toggle coverage report shows the same hole independently: `irq_event[3]`, `hw_ev[3]` and `int_status_q[3]` never toggled (and the same for bit 1).

## Coverage details

| Type | Hit / Total | Coverage |
|---|---|---|
| Statement | 17 / 17 | 100.00% |
| Branch | 16 / 16 | 100.00% |
| Condition | 4 / 4 | 100.00% |
| Expression | 3 / 3 | 100.00% |
| Toggle | 251 / 350 | 71.71% |

The 99 missed toggle bins fall into two groups.

- **By design (66 bins):** `status_q` (64 bins) never changes because STATUS is a read-only register, and `PREADY` (2 bins) is always 1 because the DUT has no wait states.
- **Testbench gaps (33 bins):** interrupt bits 1 and 3 never raised (12 bins), `PADDR` and decoded address bits 0 to 1 and 5 to 7 never changed because only word-aligned addresses up to 0x14 are driven (20 bins), and `PRESETn` was never asserted again after the start of the run (1 bin).

The coverage report shows 1 of 9 assertion bins not hit. The assertion `a_stable_until_ready` can never trigger on this DUT because `PREADY` is always 1.

## What I would improve

- Raise interrupt events on all four bits and re-run the eight bugs. Bug 8 and the toggle report both point at this gap.
- Add wait states (`PREADY` low) and `PSLVERR` to the DUT so the wait-state assertions and the `PREADY` toggles are exercised.
- Apply a reset in the middle of a test to check reset behavior with data in the registers.
- Drive unaligned and higher addresses to exercise the full address decode.
- Document coverage exclusions for the constant signals (STATUS bits and `PREADY`).
- The eight bugs were chosen by me, the same person who wrote the testbench, so they reflect my own expectations. A second reviewer or an automated mutation tool would give a less biased bug set.
- Run several random seeds and merge the coverage databases.

## Repository layout

```
apb-register-verification/
  README.md
  .gitignore
  rtl/            apb_reg_block.sv (DUT with bug switches)
  tb/
    directed_tb.sv
    interface/    apb_if.sv
    uvm/          item, sequences, driver, monitor, agent, scoreboard, env, tb_top (tests)
    ral/          apb_reg_model.sv, apb_reg_adapter.sv
    coverage/     apb_coverage.sv
    assertions/   apb_sva.sv
  bugs/           one note per injected bug
  results/        one log per build step, golden_run.log, bug logs, coverage_report.log, coverage_summary.png
  docs/           register_map.md, testbench_block_diagram.md, run.do
```
