transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vmap -link {D:/kintex_5cam_cln_fifo_wrk/kintex_5cam/K7_verilog/K7_verilog.cache/compile_simlib/riviera}
vlib riviera/xpm
vlib riviera/fifo_generator_v13_2_8
vlib riviera/xil_defaultlib

vlog -work xpm  -incr -l xpm -l fifo_generator_v13_2_8 -l xil_defaultlib \
"D:/Vivado/2023.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"D:/Vivado/2023.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  -incr \
"D:/Vivado/2023.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work fifo_generator_v13_2_8  -incr -v2k5 -l xpm -l fifo_generator_v13_2_8 -l xil_defaultlib \
"../../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_8 -93  -incr \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_8  -incr -v2k5 -l xpm -l fifo_generator_v13_2_8 -l xil_defaultlib \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  -incr -v2k5 -l xpm -l fifo_generator_v13_2_8 -l xil_defaultlib \
"../../../../K7_verilog.gen/sources_1/ip/async_fifo/sim/async_fifo.v" \

vlog -work xil_defaultlib \
"glbl.v"

