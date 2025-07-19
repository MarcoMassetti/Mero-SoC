
## Clock Signal (100 MHz)
set_property -dict { PACKAGE_PIN R2    IOSTANDARD SSTL135 } [get_ports { clk_i }];
create_clock -add -name sys_clk_pin -period 10.000  [get_ports { clk_i }];

## SPI timing constrainins (25 MHz SCK)
# Create generated clock
create_generated_clock -name spi_clk -divide_by 4 -source [get_ports clk_i]  [get_ports spi_sck_o]
# Correct input edges
set_multicycle_path -from spi_clk -to [get_clocks {sys_clk_pin}] -end -setup 2
set_multicycle_path -from spi_clk -to [get_clocks {sys_clk_pin}] -end -hold 3
# Correct output edges
set_multicycle_path -from [get_clocks {sys_clk_pin}] -to spi_clk -start -hold 3
set_multicycle_path -from [get_clocks {sys_clk_pin}] -to spi_clk -start -setup 2
# Set input delays
set_input_delay -clock spi_clk -max 1 [get_ports spi_miso_i]
set_input_delay -clock spi_clk -min 0 [get_ports spi_miso_i]
#Set output delays
set_output_delay -clock spi_clk -max 1 [get_ports spi_cs_no]
set_output_delay -clock spi_clk -min 0 [get_ports spi_cs_no]
set_output_delay -clock spi_clk -max 1 [get_ports spi_mosi_o]
set_output_delay -clock spi_clk -min 0 [get_ports spi_mosi_o]

## Asynchronous domain crossing between system_clk (100 MHz) and ddr_clk (81 MHz)
set_clock_groups -name async_sys_ddr -asynchronous -group {sys_clk_pin} -group [get_clocks -of_objects [get_pins inst_ddr_ctrl/u_mig_7series_0_mig/u_ddr3_infrastructure/gen_mmcm.mmcm_i/CLKFBOUT]]

## Boot Source Switches
set_property -dict { PACKAGE_PIN H14   IOSTANDARD LVCMOS33 } [get_ports { boot_source_i[0] }];
set_property -dict { PACKAGE_PIN H18   IOSTANDARD LVCMOS33 } [get_ports { boot_source_i[1] }];

## USB-UART Interface
set_property -dict { PACKAGE_PIN R12   IOSTANDARD LVCMOS33 } [get_ports { tx_o }];
set_property -dict { PACKAGE_PIN V12   IOSTANDARD LVCMOS33 } [get_ports { rx_i }];

## SPI Header (not only used to debug and to keep spi_sck_o signal as an output of chip_top)
#set_property -dict { PACKAGE_PIN H16   IOSTANDARD LVCMOS33 } [get_ports { spi_cs_no   }];
#set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { spi_mosi_o }];
#set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { spi_miso_s }];
set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { spi_sck_o  }];

## Reset button
set_property -dict { PACKAGE_PIN C18   IOSTANDARD LVCMOS33 } [get_ports { rst_ni }];

## Quad SPI Flash
## The SCK clock signal is driven using the STARTUPE2 primitive
set_property -dict { PACKAGE_PIN M13   IOSTANDARD LVCMOS33 } [get_ports { spi_cs_no }];
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { spi_mosi_o }];
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { spi_miso_i }];
set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { wp_no }];
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { hold_no }];

## Configuration options, can be used for all designs
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

## SW3 is assigned to a pin M5 in the 1.35v bank. This pin can also be used as
## the VREF for BANK 34. To ensure that SW3 does not define the reference voltage
## and to be able to use this pin as an ordinary I/O the following property must
## be set to enable an internal VREF for BANK 34. Since a 1.35v supply is being
## used the internal reference is set to half that value (i.e. 0.675v). Note that
## this property must be set even if SW3 is not used in the design.
set_property INTERNAL_VREF 0.675 [get_iobanks 34]
