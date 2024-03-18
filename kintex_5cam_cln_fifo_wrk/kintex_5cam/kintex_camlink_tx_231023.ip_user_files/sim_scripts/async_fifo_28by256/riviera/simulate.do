transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

asim +access +r +m+async_fifo_28by256  -L xpm -L fifo_generator_v13_2_8 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.async_fifo_28by256 xil_defaultlib.glbl

do {async_fifo_28by256.udo}

run 1000ns

endsim

quit -force
