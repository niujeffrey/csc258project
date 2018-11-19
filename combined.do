# Set the working dir, where all compiled Verilog goes.
vlib work

# Compile all Verilog modules in mux.v to working dir;
# could also have multiple Verilog files.
# The timescale argument defines default time unit
# (used when no unit is specified), while the second number
# defines precision (all times are rounded to this value)
vlog -timescale 1ns/1ns brickbreaker.v ram256x18.v

# Load simulation using mux as the top level simulation module.
vsim -L altera_mf_ver BrickBreaker

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}
add wave -position end sim:/BrickBreaker/d0/*
add wave -position end sim:/BrickBreaker/c0/*

force {CLOCK_50} 0 0ns, 1 2ns -repeat 4ns
force {KEY[0]} 0
run 4ns
force {KEY[0]} 1
run 200ns
