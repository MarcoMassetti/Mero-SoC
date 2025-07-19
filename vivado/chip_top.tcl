# Create project for Arty S7-25 board
create_project chip_top ./runs/chip_top -part xc7s25csga324-1
set_property board_part digilentinc.com:arty-s7-25:part0:1.1 [current_project]

# Add verilog defines used in rtl
set_property verilog_define {FPGA} [current_fileset]

# Add constraint file
add_files -fileset constrs_1 -norecurse ./sources/Arty-S7-25.xdc

# Add design files
add_files -norecurse {../src/design/cpu/cpu_interface_ctrl.v ../src/design/uart_ctrl/uart_ctrl.v ../src/design/cpu/byte_operation_unit.v ../src/design/uart_ctrl/axi_uart_ctrl.v ../src/design/axi_blocks/axi_interconnect.v ../src/design/spi_ctrl/axi_spi_mst.v ../src/design/axi_blocks/axi_ram_wrapper.v ../src/design/spi_ctrl/spi_boot_ctrl.v ../src/design/axi_blocks/axi_2_hs.v ../src/design/spi_ctrl/spi_mst.v ../src/design/axi_blocks/hs_2_axi.v ../src/design/cpu/register_file.v ../src/design/cpu/control_unit.v ../src/design/cpu/alu.v ../src/design/cpu/cpu.v ../src/design/fifos/sync_fifo.v ../src/design/ram_macro/sky130_sram_2kbyte_1rw_32x512_8.v ../src/design/cpu/alu_control_unit.v ../src/design/cpu/axi_cpu_interface_ctrl.v ../src/design/chip_top.v}

# Add SRAM initialization file
add_files -norecurse ./sources/software.txt
set_property file_type {Memory Initialization Files} [get_files  ./sources/software.txt]

# Add simulation files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse ../src/testbench/chip_top_tb.v

# Update compile order
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Run synthesis
launch_runs synth_1 -jobs 8
wait_on_run synth_1

# Run implementation and bitstream generation
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1

# Write FLASH configuration file (append software binary file to the bitstream)
write_cfgmem  -format bin -size 2 -interface SPIx4 -loadbit {up 0x00000000 "./runs/chip_top/chip_top.runs/impl_1/chip_top.bit" } -loaddata {up 0x00130000 "./sources/software.bin" } -force -file "./runs/chip_top/chip_top.runs/impl_1/chip_top.bin"

# Program FLASH
#open_hw_manager
#connect_hw_server -url localhost:3121 -allow_non_jtag
#current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210352BDEA4CA]
#set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilent/210352BDEA4CA]
#open_hw_target
#set_property PROGRAM.FILE {./runs/chip_top/chip_top.runs/impl_1/chip_top.bit} [get_hw_devices xc7s25_0]
#current_hw_device [get_hw_devices xc7s25_0]
#refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7s25_0] 0]
#create_hw_cfgmem -hw_device [get_hw_devices xc7s25_0] -mem_dev [lindex [get_cfgmem_parts {s25fl128sxxxxxx0-spi-x1_x2_x4}] 0]
#set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#set_property PROGRAM.FILES [list "./runs/chip_top/chip_top.runs/impl_1/chip_top.bin" ] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices xc7s25_0] 0]]
#startgroup 
#create_hw_bitstream -hw_device [lindex [get_hw_devices xc7s25_0] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices xc7s25_0] 0]]; program_hw_devices [lindex [get_hw_devices xc7s25_0] 0]; refresh_hw_device [lindex [get_hw_devices xc7s25_0] 0];
#endgroup
