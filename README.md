# Market Data Ingestion Engine

A hardware pipeline in SystemVerilog that ingests a simulated market-data byte stream, parses fixed-length records out of it, and stores them in an on-chip order book. Built as an RTL design + verification exercise, verified against a Python golden model with cocotb, and brought up on a Terasic DE0 (Cyclone III) FPGA.

**Stack:** SystemVerilog · cocotb · Python golden model · Icarus Verilog / Verilator · Quartus II 13.1

---

## How it works

A record arrives as a 13-byte packet on an 8-bit input, one byte per clock, qualified by a `valid` strobe. A multi-stage FSM watches the stream for a **start-of-packet marker** (`0xAA`), then reads three fixed-length 32-bit fields by counting bytes, and writes the assembled record into the order book.

### Packet format

| Byte(s) | Field        | Width  | Notes                     |
|---------|--------------|--------|---------------------------|
| 0       | Start marker | 8-bit  | `0xAA` — begins a record  |
| 1–4     | Stock ID     | 32-bit | big-endian                |
| 5–8     | Price        | 32-bit | big-endian                |
| 9–12    | Shares       | 32-bit | big-endian                |

The parser does **start-of-packet detection plus fixed-offset field extraction** — it locks onto the `0xAA` marker and then reads by byte count, rather than framing on delimiters.

### Dataflow

```
byte stream ──▶ parser (FSM) ──▶ order_book (RAM)
                    │                  ▲
              start-marker       write on record
              detection +        complete
              field parsing
```

---

## Modules

| File | Role |
|------|------|
| `parser.sv` | The core FSM. States `IDLE → READ_ID → READ_PRICE → READ_SHARES → PUSH2MEM`. Waits in `IDLE` for the `0xAA` marker, then shifts four bytes into each 32-bit field register, and pulses a write strobe when a record is complete. Also carries the design's SystemVerilog Assertions (see below). |
| `order_book.sv` | The order-book memory: a 256-entry store of `{price, shares, id}`, built as three 256×32 arrays so it infers **M9K block RAM** rather than flip-flops. Synchronous write, registered read, power-up zero initialisation. |
| `top_level.sv` | Connects `parser` and `order_book` into the full pipeline. This is the DUT for verification. |
| `packet_feeder.sv` | A hardware bring-up harness. A small ROM holds one fixed packet and plays it out one byte per clock after reset — the on-chip stand-in for the byte source, used to exercise the pipeline on the board. |
| `top_hw.sv` | The FPGA synthesis top for the DE0. Wires `packet_feeder` into the pipeline, inverts the active-low reset button, and maps a selected result byte onto the board LEDs (chosen via two slide switches). |

---

## Verification

The design is checked against a **Python golden model** using **cocotb**: the model parses each packet in software, and the hardware's stored fields are compared against it. Test packets use randomised payloads, plus directed edge cases:

- **Happy path** — a well-formed random packet parses and stores correctly.
- **No start marker** — a packet led by a non-`0xAA` byte is ignored (no leaked writes).
- **Reset mid-packet** — reset partway through leaves the order book clean.
- **Network pause** — `valid` de-asserts mid-packet and later resumes; parsing survives the gap.
- **False in-payload marker** — a `0xAA` planted inside the ID/price fields does *not* re-trigger framing once locked onto a record.

> The cocotb testbench and golden model (`test_system.py`) and the `Makefile` are added separately.

### SystemVerilog Assertions

Four concurrent assertions are embedded in `parser.sv` (inside a `// synthesis translate_off` block, so they run in simulation but are skipped by synthesis). They run under Verilator with `--assert`. Two guard the control path, two guard the write path:

| Assertion | Guarantees | Guards |
|-----------|------------|--------|
| `A_RESET_IDLE` | reset returns the FSM to `IDLE` next cycle | state-transition safety |
| `A_COUNTER_RANGE` | the byte counter never exceeds 3 (each field reads exactly 4 bytes) | state-transition safety |
| `A_WRITE_EN_SRC` | a write strobe can only originate from `PUSH2MEM` (checked via `$past`, since the strobe is a registered output) | order-book write integrity |
| `A_WRITE_PULSE` | the write strobe is a single-cycle pulse — one record, one write | order-book write integrity |

---

## Hardware bring-up

Synthesised in **Quartus II 13.1** for the **Terasic DE0** board (Altera Cyclone III `EP3C16F484C6N`, 15,408 LEs, 56 M9K blocks). The design fits comfortably (~1% logic) with the order book mapped to block RAM.

`packet_feeder` drives one fixed test packet through the pipeline after reset, and `top_hw` displays the parsed fields on the board's green LEDs, selectable byte-by-byte with the slide switches. This confirms the design **synthesises, fits the device, and operates on real silicon**; functional correctness across the full input space is established by the cocotb / golden-model / assertion work above.

### DE0 pin mapping (`top_hw`)

| Signal | Board | Pin |
|--------|-------|-----|
| `i_clk` | CLOCK_50 | PIN_G21 |
| `i_rst_n` | BUTTON0 | PIN_H2 |
| `i_sel[0]` | SW0 | PIN_J6 |
| `i_sel[1]` | SW1 | PIN_H5 |
| `o_led[7:0]` | LEDG0–7 | J1, J2, J3, H1, F2, E1, C1, C2 |

---

## Running the simulation

> Requires cocotb and a simulator (Icarus for functional tests; Verilator for assertion checking).

```bash
# functional tests (Icarus)
make

# functional tests + SVA checking (Verilator)
make SIM=verilator
```

*(Testbench and Makefile added with `test_system.py`.)*

---

## Repository layout

```
.
├── parser.sv          # parsing FSM + SVAs
├── order_book.sv      # order-book block RAM
├── top_level.sv       # pipeline (DUT)
├── packet_feeder.sv   # hardware bring-up stimulus
├── top_hw.sv          # DE0 synthesis top
├── test_system.py     # cocotb tests + golden model  (added next)
└── Makefile           # cocotb build                 (added next)
```

---

*Author: Rachit Ravi · [github.com/rachit-26](https://github.com/rachit-26)*