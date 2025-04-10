# Time unit is ps
create_clock Dclk -name Dclk -period 1302000.0
create_clock Sclk -name Sclk -period 33333.3

set_clock_uncertainty 100.0 [get_clocks Dclk]
set_clock_uncertainty 100.0 [get_clocks Sclk]
set_clock_groups -asynchronous  -group { Dclk }
set_clock_groups -asynchronous  -group { Sclk }

