# Testbench block diagram

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

- The **sequencer** hands `apb_item` objects to the **driver**, which drives the APB setup and access phases on `apb_if`.
- The **monitor** watches `apb_if`, rebuilds each completed transfer as an `apb_item` and publishes it on its analysis port.
- The **scoreboard** (reference model of all registers), the **coverage collector** and the **RAL predictor** all listen to that port.
- The **RAL model** and **adapter** let tests and the UVM built-in sequences (reset test, bit-bash test) access registers by name instead of by address.
- `apb_sva` is attached to the DUT with `bind` and checks the APB protocol on every clock.
