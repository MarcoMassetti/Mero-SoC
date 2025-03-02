 
sim :
	vlib work

	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/src/alu_control_unit.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/src/alu.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/src/byte_operation_unit.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/src/control_unit.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/src/register_file.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/src/cpu.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/src/memory_arbiter.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/src/cpu_top.v

	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/tb/ram.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/tb/ram_wrapper.v
	vlog /media/marco/Data_L/EDA/openlane2/my_designs/cpu/tb/cpu_top_tb.v
	
	vsim work.cpu_top_tb -do sim0.tcl
