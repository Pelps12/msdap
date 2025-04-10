# 1. Set root attributes
set_db hdl_error_on_blackbox true
set_db lp_insert_clock_gating  false
set_db use_tiehilo_for_const duplicate
#Genus use 8 CPU cores by default
#set_db max_cpus_per_server 2

# 2. Define corners
read_mmmc mmmc.tcl

# 3. Read libraries and SRAM macros
read_physical -lef { \
/proj/cad/library/asap7/asap7sc7p5t_27/techlef_misc/asap7_tech_4x_201209.lef \
/proj/cad/library/asap7/asap7sc7p5t_27/LEF/scaled/asap7sc7p5t_27_R_4x_201211.lef \
/proj/cad/library/asap7/asap7sc7p5t_27/LEF/scaled/asap7sc7p5t_27_L_4x_201211.lef \
/proj/cad/library/asap7/asap7sc7p5t_27/LEF/scaled/asap7sc7p5t_27_SL_4x_201211.lef \
/proj/cad/library/asap7/asap7sc7p5t_27/LEF/scaled/asap7sc7p5t_27_SRAM_4x_201211.lef \
/home/eng/t/txg150930/workspace/ASIC/Memory/lef/SRAM1RW128x12_x4.lef \
/home/eng/t/txg150930/workspace/ASIC/Memory/lef/SRAM1RW256x8_x4.lef \
/home/eng/t/txg150930/workspace/ASIC/Memory/lef/SRAM2RW16x8_x4.lef }

# 4. Read your Verilog files
read_hdl -sv { \
/home/013/o/om/oma190007/cad/msdap/design.sv \
/home/013/o/om/oma190007/cad/msdap/ALU/design.sv \
/home/013/o/om/oma190007/cad/msdap/Control/design.sv \
/home/013/o/om/oma190007/cad/msdap/Memory/design.sv \
/home/013/o/om/oma190007/cad/msdap/Misc/design.sv \
/home/013/o/om/oma190007/cad/msdap/P2S/design.sv \
/home/013/o/om/oma190007/cad/msdap/S2P/design.sv}
elaborate MSDAP
init_design -top MSDAP

# 5. Set design attributes
set_db root: .auto_ungroup none
set_units -capacitance 1.0pF
set_load_unit -picofarads 1
set_units -time 1.0ps
#Replace constant assignment with tie cells. E.g. "assign out1 = 1’b0"
#add_tieoffs -high TIEHIx1_ASAP7_75t_SL -low TIELOx1_ASAP7_75t_SL -max_fanout 1 -verbose

# 6. Exclude standard cells that may cause error
source set_dont_use.tcl
          
# 7. Synthesize the MSDAP design
syn_generic
syn_map
 
#set_db message:WSDF-201 .max_print 20

# 9. Save design
write_hdl > MSDAP_mapped.v
write_script > MSDAP_mapped.scr
write_sdc -view PVT_0P63V_100C.setup_view > MSDAP_mapped.sdc
write_sdf > MSDAP_mapped.sdf
write_design -innovus -hierarchical -gzip_files MSDAP

# 10. (Optional) Generate reports
exec mkdir -f reports
report_timing -max_paths 3 > reports/setup.rpt
report_power > reports/power.rpt
report_area > reports/area.rpt

quit
