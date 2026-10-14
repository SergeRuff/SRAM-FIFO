iverilog -g2012                  ^
         -DDUALPORT_LATENCY_5    ^
         ../fifo_tb.sv           ^
         ../dff_fifo/fifo_dff.sv ^
         ../sram_fifo/*          ^
         ./*.sv
vvp a.out
