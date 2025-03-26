/* verilator lint_off MULTITOP */

`include "Control/design.sv"
`include "Memory/design.sv"
`include "Misc/design.sv"
`include "S2P/design.sv"
`include "P2S/design.sv"
`include "ALU/design.sv"

module MSDAP (
    // Clock and Reset Inputs
    input logic SCLK,       // System Clock (26.88 MHz)
    input logic DCLK,       // Data Clock (768 kHz)
    
    // Control Inputs
    input logic Start,      // Initializes the processing operation
    input logic Reset_n,    // Resets the chip
    input logic Frame,      // Synchronization signal
    
    // Audio Input Signals
    input logic InputL,  // Left channel serial audio input (16-bit)
    input logic InputR,  // Right channel serial audio input (16-bit)
    
    // Audio Output Signals
    output logic  OutputL,  // Left channel processed audio output (40-bit)
    output logic  OutputR,  // Right channel processed audio output (40-bit)
    
    // Status Outputs
    output logic InReady,   // High when MSDAP is ready to accept new input
    output logic OutReady   // High when output data is ready to be transmitted
);
    // Internal signals and logic can be added here in future implementations

    logic [15:0] ParallelL, ParallelR;

    logic s2p_clear, s2p_ready, p2s_clear, all_zeros;

    logic data_count_restart, data_count_enable, 
    data_clear_complete, alu_en, alu_clear, p2s_load;

    // Rj Memory signals
    logic rj_wr_en;
    logic [3:0] rj_addr_l, rj_addr_r;
    logic [15:0] rj_data_in_l, rj_data_in_r;
    logic [15:0] rj_data_out_l, rj_data_out_r;

    // Coefficients Memory signals
    logic coeff_wr_en;
    logic [8:0] coeff_addr_l, coeff_addr_r;
    logic [15:0] coeff_data_in_l, coeff_data_in_r;
    logic [15:0] coeff_data_out_l, coeff_data_out_r;

    // Data Memory FIFO signals
    logic data_wr_en;
    logic [7:0] read_offset_l, read_offset_r;
    logic [15:0] data_in_l, data_in_r;
    logic [15:0] data_out_l, data_out_r;

    logic rj_count_restart, rj_count_done, rj_count_enable, rj_new_count_done,
    data_clear;

    logic [7:0] data_addr; //Useless will be synthesized out
    logic [3:0] rj_count, rj_new_count;

    logic coeff_count_restart, coeff_count_done, coeff_count_enable;
    logic [8:0] coeff_count;
    logic [39:0] accum_reg;

    logic frame_pulse, conv_done;

    Counter data_rc(
        .clk(SCLK),
        .restart(data_count_restart),
        .enable(data_count_enable),
        .done(data_clear_complete),
        .count(data_addr)
    );



    Offset_Counter #(.LIMIT('d15)) rj_counter_offset( 
        .clk(SCLK),
        .restart(rj_count_restart),
        .enable(rj_count_enable),
        .done(rj_count_done),
        .count(rj_count)
    );

    Offset_Counter #(.LIMIT('d511)) coeff_counter_offset( 
        .clk(SCLK),
        .restart(coeff_count_restart),
        .enable(coeff_count_enable),
        .done(coeff_count_done),
        .count(coeff_count)
    );

    FrameToSCLK synchronizer(
        .DCLK(DCLK),
        .SCLK(SCLK),
        .start(Start),
        .Frame(Frame),
        .FramePulse(frame_pulse)
    );


    S2P s2p (
        .DCLK(DCLK),
        .SCLK(SCLK),
        .clear(s2p_clear),
        .InputL(InputL),
        .InputR(InputR),
        .ParallelL(ParallelL),
        .ParallelR(ParallelR),
        .ready(s2p_ready)
    );

    rj_memory rj_mem (
        .clk(SCLK),
        .rj_wr_en_l(rj_wr_en),
        .rj_wr_en_r(rj_wr_en),
        .rj_addr_l(rj_wr_en ? rj_count: rj_addr_l),
        .rj_addr_r(rj_wr_en ? rj_count: rj_addr_r),
        .rj_data_in_l(ParallelL),
        .rj_data_in_r(ParallelR),
        .rj_data_out_l(rj_data_out_l),
        .rj_data_out_r(rj_data_out_r)
    );

    coefficients_memory coeff_mem (
        .clk(SCLK),
        .coeff_wr_en_l(coeff_wr_en),
        .coeff_wr_en_r(coeff_wr_en),
        .coeff_addr_l(coeff_wr_en ? coeff_count: coeff_addr_l),
        .coeff_addr_r(coeff_wr_en ? coeff_count: coeff_addr_r),
        .coeff_data_in_l(ParallelL),
        .coeff_data_in_r(ParallelR),
        .coeff_data_out_l(coeff_data_out_l),
        .coeff_data_out_r(coeff_data_out_r)
    );

    data_memory_fifo data_fifo (
        .clk(SCLK),
        .rst_n(Reset_n),
        .start(Start),
        .data_wr_en_l(data_wr_en),
        .data_wr_en_r(data_wr_en),
        .read_addr_l(read_offset_l),
        .read_addr_r(read_offset_r),
        .write_addr_l(data_addr),
        .write_addr_r(data_addr),
        .data_in_l(data_clear ? 0 : ParallelL),
        .data_in_r(data_clear ? 0 : ParallelR),
        .data_out_l(data_out_l),
        .data_out_r(data_out_r)
    );

    ALU alu(
        .clk(SCLK),
        .enable(alu_en),
        .clear(alu_clear),
        .current_data_addr(data_addr),
        .data(data_out_l),
        .coeff_data(coeff_data_out_l),
        .rj_data(rj_data_out_l),
        .data_addr(read_offset_l),
        .coeff_addr(coeff_addr_l),
        .rj_addr(rj_addr_l),
        .output_en(conv_done),
        .accum_reg(accum_reg)
    );

    P2S p2s (
        .SCLK(SCLK),
        .LOAD(p2s_load),
        .CLR(p2s_clear),
        .PDATAIN(accum_reg),
        .DATAOUT(OutputL),
        .OutReady(OutReady)
    );

    AllZerosDetector zero_detector(
        .clk(SCLK),
        .enable(data_wr_en),
        .clear(s2p_clear || InputL == 1),
        .dataL(ParallelL),
        .dataR(ParallelR),
        .all_zeros(all_zeros)
    );

    Control control(
        .clk(SCLK),
        .start(Start),
        .frame(Frame),
        .reset_n(Reset_n),
        .all_zeros(all_zeros),
        .data_count_restart(data_count_restart),
        .data_count_enable(data_count_enable),
        .data_clear(data_clear),
        .data_clear_complete(data_clear_complete),
        .rj_count_restart(rj_count_restart),
        .rj_count_enable(rj_count_enable),
        .rj_count_done(rj_count_done),
        .in_ready(InReady),
        .rj_wr_en(rj_wr_en),
        .coeff_wr_en(coeff_wr_en),
        .coeff_count_restart(coeff_count_restart),
        .coeff_count_enable(coeff_count_enable),
        .coeff_count_done(coeff_count_done),
        .data_wr_en(data_wr_en),
        .s2p_clear(s2p_clear),
        .s2p_done(s2p_ready),
        .alu_en(alu_en),
        .alu_clear(alu_clear),
        .p2s_load(p2s_load),
        .p2s_clear(p2s_clear),
        .conv_done(conv_done)
    );
    
    

    
    // Additional module instantiations and logic can be added here
endmodule