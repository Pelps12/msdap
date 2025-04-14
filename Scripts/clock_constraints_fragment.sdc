# Time unit is ps
create_clock DCLK -name Dclk -period 1302000.0
create_clock SCLK -name Sclk -period 33333.3

set_clock_uncertainty 100.0 [get_clocks DCLK]
set_clock_uncertainty 100.0 [get_clocks SCLK]
set_clock_groups -asynchronous  -group { DCLK }
set_clock_groups -asynchronous  -group { SCLK }

