# UART TX/RX

A parameterized 8N1 UART transceiver in Verilog with a `16x` oversampling receiver and baud rate generator. I built this as my starting point into serial communication protocols.

## How It Works

- `rtl/baud_generator.v` — Generates `tx_enb` and `16x` oversampled `rx_enb` enable ticks from `clk` and `rst` (defaults to `125 MHz` clock and `115,200` baud).
- `rtl/uart_tx.v` — FSM (`IDLE`, `START`, `DATA`, `STOP`) that shifts out 8 data bits LSB-first with start/stop framing and asserts `tx_busy` while active.
- `rtl/uart_rx.v` — Synchronizes incoming `rx` through two flip-flops, verifies the start bit mid-window, shifts in 8 data bits at 16-tick intervals, and flags `rx_valid` or `rx_frame_error` on the stop bit.
- `rtl/uart_top.v` — Ties the baud generator, transmitter, and receiver together.

## Verification

`tb/tb_uart_top.v` checks the design across a few scenarios:
- Sending all `256` possible 8-bit values (`0x00`–`0xFF`) in loopback.
- Random idle gaps between transfers.
- Forced frames with `±3%` baud rate timing skew, short line glitches, and bad stop bits (checking `rx_frame_error`).

## Repo Layout

- `rtl/` — `baud_generator.v`, `uart_tx.v`, `uart_rx.v`, and `uart_top.v`.
- `tb/tb_uart_top.v` — Self-checking testbench.
