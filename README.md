# GCD with request/acknowledge handshake

A greatest-common-divisor circuit in VHDL: a controller FSM plus a small datapath, driven through a four-phase request/acknowledge handshake. Originally a university assignment, set up here to build with Quartus Prime Lite 16.1 and run on the Cyclone V GX Starter Kit.

- Computes `gcd(A, B)` for unsigned operands, 10 bits wide by default (generic `N`)
- Subtractive Euclid algorithm: one subtraction per clock cycle, no divider
- Four-phase req/ack handshake to load the operands and return the result
- 2-flip-flop input synchronizers on `req` and `reset`
- Makefile for the Quartus build, JTAG programming and GHDL simulation

## Interface

Top-level entity: `gcd` (`top.vhd`)

| Port    | Dir | Width | Description                                                        |
| ------- | --- | ----- | ------------------------------------------------------------------ |
| `clk`   | in  | 1     | System clock, constrained to 50 MHz in `gcd.sdc`                   |
| `reset` | in  | 1     | Synchronous reset, **active low**                                  |
| `req`   | in  | 1     | Handshake request, **active low**                                  |
| `AB`    | in  | `N`   | Operand bus, carries A first and then B                            |
| `ack`   | out | 1     | Handshake acknowledge, active high                                 |
| `C`     | out | `N`   | Result, only meaningful while `ack` is high in step 5 (see below)  |

Generic: `N` (positive, default 10) is the operand and result width in bits.

`req` and `reset` are inverted and passed through a 2-flip-flop synchronizer in the top level, so they can be driven straight from active-low push buttons. `AB` is not synchronized.

## Handshake protocol

One computation takes two handshakes: the first transfers A, the second transfers B and returns the result. "Assert" below means a logical request, which is a **low** level on the `req` pin.

| Step | Client                                  | Circuit                                              |
| ---- | --------------------------------------- | ---------------------------------------------------- |
| 1    | Put A on `AB`, assert `req`             |                                                      |
| 2    |                                         | Latches A, raises `ack`                              |
| 3    | Release `req`                           | Lowers `ack`                                         |
| 4    | Put B on `AB`, assert `req`             | Latches B and starts computing (`ack` stays low)     |
| 5    |                                         | Puts the result on `C` and raises `ack` when done    |
| 6    | Read `C`, release `req`                 | Lowers `ack`, returns to idle                        |

Notes:

- Hold `AB` stable while `req` is asserted, and for A until `ack` has dropped again in step 3.
- `C` only carries the result while `ack` is high in step 5. In every other phase it just shows `AB` or an intermediate value.
- Edge cases: `gcd(0, B) = B`, `gcd(A, 0) = A`, `gcd(0, 0) = 0`.

### Datapath (`datapath.vhd`)

Built from small generic components, instantiated in `gcd_datapath`:

- `c_mux`: selects either the operand bus `AB` or the ALU result as input to both registers
- `c_reg`: two N-bit registers (A and B) with load enables `LDA` and `LDB`
- `c_alu`: four functions selected by `FN`, plus the flags `Z` (result is zero) and `N` (borrow of `A - B`, i.e. A < B)
- `c_buffer`: drives the output `C`

| `FN`   | ALU result | Used for                                         |
| ------ | ---------- | ------------------------------------------------ |
| `00`   | `A - B`    | Comparing A and B (`Z`: A = B, `N`: A < B)       |
| `01`   | `B - A`    | Subtracting A from B                             |
| `10`   | `A`        | Testing A = 0, outputting A                      |
| `11`   | `B`        | Testing B = 0, outputting B                      |

### Controller (`fsm.vhd`)

| State       | What it does                                                            |
| ----------- | ----------------------------------------------------------------------- |
| `s_idle`    | Waits for the first request                                             |
| `s_loada`   | Loads A from `AB`, raises `ack`, waits for `req` to be released         |
| `s_waitb`   | Waits for the second request                                            |
| `s_loadb`   | Loads B from `AB`, tests A = 0                                          |
| `s_chkb`    | Tests B = 0                                                             |
| `s_comp`    | Compares A and B, subtracts B from A when A is larger                   |
| `s_compsub` | Subtracts A from B when B is larger                                     |
| `s_done`    | Result is A: puts it on `C`, raises `ack`, waits for `req` release      |
| `s_doneb`   | Result is B (A was 0): puts it on `C`, raises `ack`, waits for release  |

A synchronous reset returns the FSM to `s_idle`.

Run time depends on the operands. Each subtraction takes one clock cycle when A > B and two when A < B. The worst cases (one operand equal to 1) take on the order of 2^N cycles, roughly 20 to 40 microseconds at 50 MHz for N = 10.

## Repository layout

| File                 | Contents                                                              |
| -------------------- | --------------------------------------------------------------------- |
| `top.vhd`            | `gcd` top level: input synchronizers, FSM and datapath instances      |
| `fsm.vhd`            | `gcd_fsm` controller                                                  |
| `datapath.vhd`       | `c_buffer`, `c_mux`, `c_reg`, `c_alu`, `gcd_datapath`                 |
| `gcd.qpf`, `gcd.qsf` | Quartus project and settings (device `5CGXFC5C6F27C7`, VHDL-2008)     |
| `gcd.sdc`            | 50 MHz clock constraint                                               |
| `pins.tcl`           | Pin assignments, sourced from `gcd.qsf`                               |
| `Makefile`           | Build, program, simulate, clean                                       |

## Requirements

- Quartus Prime Lite 16.1 with `quartus_sh` and `quartus_pgm` on your `PATH`
- GNU make
- GHDL with VHDL-2008 support, for simulation
- A waveform viewer such as GTKWave to open the generated `.vcd`

## Build, program, simulate

```sh
make               # synthesis, fit, assemble, timing analysis -> output_files/gcd.sof
make prog          # program the board over JTAG
make prog CABLE=1  # pick a cable if several are attached (see jtagconfig)
make sim           # simulate with GHDL, waveform in build_sim/wave.vcd
make clean         # remove build artifacts
```

Makefile variables:

| Variable | Default | Meaning                                                              |
| -------- | ------- | -------------------------------------------------------------------- |
| `PROJ`   | `gcd`   | Quartus project name                                                 |
| `TB`     | `tb`    | Testbench entity and file name (`tb.vhd`)                            |
| `QFLAGS` | `--64bit` | Flags passed to the Quartus tools, set empty if one rejects them   |
| `CABLE`  | empty   | JTAG cable, empty means auto-detect                                  |
| `POS`    | empty   | JTAG chain position, only needed if the FPGA is not the first device |

`make sim` analyses every `*.vhd` file except the testbench, elaborates the testbench entity and runs it with `--std=08`. It expects the testbench in `tb.vhd` in the repository root. If a `tb.sv` is present instead, the Makefile simulates with Verilator 5+.

## Limitations

- Unsigned operands only, up to `2^N - 1`
- `AB` is not synchronized, so it must be held stable as described in the protocol notes
- The subtractive algorithm is simple, not fast: the cycle count grows with the size of the operands
