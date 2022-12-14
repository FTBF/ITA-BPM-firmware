# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "BUSY_SIGNAL" -parent ${Page_0}
  set BUSY_TIME [ipgui::add_param $IPINST -name "BUSY_TIME" -parent ${Page_0}]
  set_property tooltip {Busy Time in ns} ${BUSY_TIME}
  set CLOCK_PERIOD [ipgui::add_param $IPINST -name "CLOCK_PERIOD" -parent ${Page_0}]
  set_property tooltip {Clock Period in ns} ${CLOCK_PERIOD}


}

proc update_PARAM_VALUE.BUSY_SIGNAL { PARAM_VALUE.BUSY_SIGNAL } {
	# Procedure called to update BUSY_SIGNAL when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BUSY_SIGNAL { PARAM_VALUE.BUSY_SIGNAL } {
	# Procedure called to validate BUSY_SIGNAL
	return true
}

proc update_PARAM_VALUE.BUSY_TIME { PARAM_VALUE.BUSY_TIME } {
	# Procedure called to update BUSY_TIME when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.BUSY_TIME { PARAM_VALUE.BUSY_TIME } {
	# Procedure called to validate BUSY_TIME
	return true
}

proc update_PARAM_VALUE.CLOCK_PERIOD { PARAM_VALUE.CLOCK_PERIOD } {
	# Procedure called to update CLOCK_PERIOD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CLOCK_PERIOD { PARAM_VALUE.CLOCK_PERIOD } {
	# Procedure called to validate CLOCK_PERIOD
	return true
}

proc update_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_ADDR_WIDTH { PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to update C_S_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S_AXI_DATA_WIDTH { PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.N_REG { PARAM_VALUE.N_REG } {
	# Procedure called to update N_REG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N_REG { PARAM_VALUE.N_REG } {
	# Procedure called to validate N_REG
	return true
}


proc update_MODELPARAM_VALUE.BUSY_SIGNAL { MODELPARAM_VALUE.BUSY_SIGNAL PARAM_VALUE.BUSY_SIGNAL } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BUSY_SIGNAL}] ${MODELPARAM_VALUE.BUSY_SIGNAL}
}

proc update_MODELPARAM_VALUE.BUSY_TIME { MODELPARAM_VALUE.BUSY_TIME PARAM_VALUE.BUSY_TIME } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.BUSY_TIME}] ${MODELPARAM_VALUE.BUSY_TIME}
}

proc update_MODELPARAM_VALUE.CLOCK_PERIOD { MODELPARAM_VALUE.CLOCK_PERIOD PARAM_VALUE.CLOCK_PERIOD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CLOCK_PERIOD}] ${MODELPARAM_VALUE.CLOCK_PERIOD}
}

proc update_MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH PARAM_VALUE.C_S_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH PARAM_VALUE.C_S_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.N_REG { MODELPARAM_VALUE.N_REG PARAM_VALUE.N_REG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N_REG}] ${MODELPARAM_VALUE.N_REG}
}

