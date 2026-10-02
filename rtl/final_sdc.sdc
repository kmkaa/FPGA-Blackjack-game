#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3
#**************************************************************
# Create Clock
#**************************************************************
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# Include default clock uncertainty metrics for Cyclone V
derive_clock_uncertainty

# Ignore asynchronous I/O paths (buttons, switches, LEDs, HEX)
set_false_path -from [get_ports {KEY[*] SW[*]}]
set_false_path -to [get_ports {LEDR[*] HEX0[*] HEX1[*] HEX2[*] HEX3[*] HEX4[*] HEX5[*]}]