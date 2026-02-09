# AXI-Stream Width Converter (64↔512)

This repository contains **completed AXI-Stream width converter RTL modules**, supporting both **up-conversion (64 → 512)** and **down-conversion (512 → 64)**.  
The design is intended to be **reusable in SoC / FPGA data paths** and has been **integrated and tested with existing AXI IPs** in a block-design environment.

The focus of this project is **protocol correctness, backpressure handling, and clean datapath design**, rather than aggressive optimization.

---

## Features

- AXI-Stream compliant (core signals)
- Bidirectional width conversion:
  - **64-bit → 512-bit**
  - **512-bit → 64-bit**
- FIFO-based buffering for robust flow control
- Proper handling of:
  - `TVALID / TREADY`
  - `TDATA`
  - `TLAST`
- Bubble-free steady-state operation
- Single-clock design
- Feature complete

---

## Supported AXI-Stream Signals

| Signal  | Supported |
|-------|-----------|
| TVALID | ✅ |
| TREADY | ✅ |
| TDATA  | ✅ |
| TLAST  | ✅ |
| TKEEP  | ❌ |
| TSTRB  | ❌ |
| TUSER  | ❌ |
| TID    | ❌ |
| TDEST  | ❌ |

> **Note:** The module is intentionally scoped to the most commonly used AXI-Stream signals for datapath designs. Unsupported sideband signals can be added as future extensions.

---


---

## Architecture Overview

### 64 → 512 Converter
- Collects **8 consecutive 64-bit beats**
- Packs data **LSB-first** into a single 512-bit word
- Output `TVALID` asserted only when:
  - 8 beats are collected, **or**
  - `TLAST` arrives early
- Early `TLAST` handling:
  - Remaining bytes are **zero-padded**
- Internal FIFO ensures correct backpressure handling

**Latency**
- Minimum: 8 cycles  
- Worst case: 8 cycles  

**Throughput**
- One 512-bit beat per cycle in steady state (no bubbles)

---

### 512 → 64 Converter
- Slices each 512-bit beat into **8 consecutive 64-bit beats**
- Data transmitted **LSB-first**
- `TLAST` propagated on the final 64-bit beat
- FIFO decouples input and output handshaking

**Latency**
- Minimum: 8 cycles  
- Worst case: 8 cycles  

**Throughput**
- One 64-bit beat per cycle in steady state

---

## Flow Control & Backpressure

- Fully compliant `TREADY` / `TVALID` handshake
- Upstream is stalled when internal FIFO is full
- Downstream backpressure is handled without data loss
- Bubble-free operation under continuous data flow

---

## Parameterization

- Current implementation targets **fixed conversions (64↔512)**
- Designed with power-of-two ratios in mind
- Generic N:M parameterization is a possible future enhancement but is **not claimed** in the current version

---

## Verification

- **Testbench:** SystemVerilog
- **Verification style:** Directed, self-checking
- **Checks performed:**
  - Data integrity (`TDATA`)
  - Packet boundary correctness (`TLAST`)
  - Correct ordering and padding behavior
- **Simulator:** Vivado Simulator

> Self-checking logic automatically compares DUT output against an internally generated golden model and flags mismatches without waveform inspection.

---

## Synthesis

- Not synthesized yet
- Intended targets: FPGA datapath designs
- Resource and timing characterization planned as a future step

---

## Status

- ✅ Feature complete
- 🔧 Stable and reusable
- 🧪 Open for extension (parameterization, sideband signals)

---

## Intended Audience

- FPGA datapath engineers
- SoC / interconnect designers
- Engineers working with AXI-Stream–based systems

---

## Limitations

- No support for `TKEEP`, `TSTRB`, `TUSER`, `TID`, `TDEST`
- Fixed width ratios only
- Single-clock domain only

---

## Future Enhancements

- Randomized backpressure stress testing
- Full N:M width parameterization
- Support for additional AXI-Stream sideband signals
- Synthesis results and timing reports

---

## License

License not yet selected.
