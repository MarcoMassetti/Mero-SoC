
# Logging every signal, including register-file and sram
add log -r /*
add log sim:/chip_top_tb/DUT/inst_cpu/inst_register_file/registers
add log sim:/chip_top_tb/DUT/inst_ram_wrapper/inst_ram/mem

# Loading waves format only in wave file is present
if {[file exist wave.do]} {
	do wave.do
}

# Do not ask to close gui when finish is asserted by testbench
onfinish stop

# Run until testbench stops simulation
run -all
