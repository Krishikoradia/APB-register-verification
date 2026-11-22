# Register map

APB slave, 32-bit data, 8-bit address, zero wait states (`PREADY` always 1). Hardware interrupt events come in on `irq_event[3:0]`.

| Offset | Register | Access | Reset value | Fields |
|---|---|---|---|---|
| 0x00 | CTRL | RW | 0x00000000 | `en` [0] RW, `mode` [2:1] RW, `cfg` [7:3] RW, `rsvd` [31:8] RO (reads 0) |
| 0x04 | STATUS | RO | 0x00000001 | `ready` [0] RO (reset 1), `rsvd` [31:1] RO |
| 0x08 | DATA | RW | 0x000000FF | `data` [31:0] RW |
| 0x0C | INT_STATUS | W1C | 0x00000000 | `ev` [3:0] W1C (set by `irq_event`, cleared by writing 1), `rsvd` [31:4] RO |

- 4 registers, 9 fields in the RAL model.
- Writes to unmapped addresses are ignored. Reads of unmapped addresses return 0.
- If a hardware event and a software clear hit the same INT_STATUS bit in the same clock, the event wins.
