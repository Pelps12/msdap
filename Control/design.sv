module Control (
    input logic clk,
    input logic start,
    input logic frame,
    input logic reset_n,
    input logic data_clear_complete,
    input logic rj_count_done,
    input logic coeff_count_done,
    input logic s2p_done,
    input logic conv_done,
    input logic all_zeros,
    output logic data_count_restart,
    output logic data_count_enable,
    output logic data_clear,
    output logic in_ready,
    output logic rj_wr_en,
    output logic coeff_wr_en,
    output logic s2p_clear,
    output logic data_wr_en,
    output logic rj_count_restart,
    output logic rj_count_enable,
    output logic coeff_count_restart,
    output logic coeff_count_enable,
    output logic alu_en,
    output logic alu_clear,
    output logic p2s_load,
    output logic p2s_clear
);
    
    typedef enum
    {
        INIT  = 0,
        RESETTING = 1,
        WAIT_FOR_RJ = 2,
        FIRST_FRAME = 3,
        READING_RJ = 4,
        WRITING_RJ = 5,
        WAIT_FOR_FRAME_END_RJ = 6,
        INCREMENT_RJ = 7,
        WAIT_FOR_COEFF = 8,
        READING_COEFF = 9,
        WRITING_COEFF = 10,
        WAIT_FOR_FRAME_END_COEFF = 11,
        INCREMENT_COEFF = 12,
        WAITING_FOR_DATA = 13,
        WRITE_DATA = 14,
        READ_CONV = 15,
        OUTPUT_CONV_DATA = 16,
        SLEEPING = 17,
        PRE_CLEAR = 18,
        CLEARING = 19
    } state_e;

    state_e state, next_state;
    always_ff @( posedge clk, posedge start ) begin : State_Change
        if (start) begin
            state <= INIT;
        end
        else begin
            state <= next_state;
        end
            
    end

    always_comb begin : Next_state
        case (state)
            INIT: begin
                next_state = RESETTING;
            end
            RESETTING: begin
                if (data_clear_complete) begin
                    next_state = WAIT_FOR_RJ;
                end
            end
            WAIT_FOR_RJ: begin
                if(frame) begin
                    next_state = FIRST_FRAME;
                end
            end
            FIRST_FRAME: begin
                if(!frame) begin
                    next_state = READING_RJ;
                end
            end
            READING_RJ: begin
                if (frame) begin
                    next_state = WRITING_RJ;
                end
            end
            WRITING_RJ: begin
                next_state = WAIT_FOR_FRAME_END_RJ;
            end
            WAIT_FOR_FRAME_END_RJ: begin
                if(!frame) begin
                    next_state = INCREMENT_RJ;
                end
            end
            INCREMENT_RJ: begin
                if (rj_count_done) begin
                    next_state = WAIT_FOR_COEFF;
                end
                else begin
                    next_state = READING_RJ;
                end
            end
            WAIT_FOR_COEFF: begin
                if (frame) begin
                    next_state = READING_COEFF;
                end
            end
            READING_COEFF: begin
                if(frame) begin
                    next_state = WRITING_COEFF;
                end
            end
            WRITING_COEFF: begin
                next_state = WAIT_FOR_FRAME_END_COEFF;
            end
            WAIT_FOR_FRAME_END_COEFF: begin
                if(!frame) begin
                    next_state = INCREMENT_COEFF;
                end
            end
            INCREMENT_COEFF: begin
                if (coeff_count_done) begin
                    next_state = WAITING_FOR_DATA;
                end
                else begin
                    next_state = READING_COEFF;
                end
            end
            WAITING_FOR_DATA: begin
                if (frame) begin
                    next_state = WRITE_DATA;
                end
            end
            WRITE_DATA: begin
                if(!reset_n) begin
                    next_state = PRE_CLEAR;
                end
                else if(all_zeros) begin
                    next_state = SLEEPING;
                end
                else begin
                    next_state = READ_CONV;
                end
            end
            READ_CONV: begin
                if(!reset_n) begin
                    next_state = PRE_CLEAR;
                end
                else begin
                    if(frame && conv_done) begin
                        next_state = OUTPUT_CONV_DATA;
                    end
                end

            end
            PRE_CLEAR: begin
                next_state = CLEARING;
            end
            CLEARING: begin
                if (data_clear_complete) begin
                    next_state = WAITING_FOR_DATA;
                end
            end
            OUTPUT_CONV_DATA: begin
                if(!reset_n) begin
                    next_state = PRE_CLEAR;
                end
                else begin
                    next_state = WRITE_DATA;
                end
            end
            SLEEPING: begin
                if(!all_zeros) begin
                    next_state = WRITE_DATA;
                end
            end

            default: begin
                next_state = state;
            end
        endcase
    end

    always_comb begin : Assign
        in_ready = 0;
        rj_wr_en = 0;
        coeff_wr_en = 0;
        data_wr_en = 0;
        s2p_clear = 0;
        data_count_enable = 0;
        data_clear = 0;
        data_count_restart = 0;
        rj_count_restart = 0;
        rj_count_enable = 0;
        coeff_count_restart = 0;
        coeff_count_enable = 0;
        alu_en = 0;
        alu_clear = 0;
        p2s_load = 0;
        p2s_clear = 0;

        case (state)
            INIT: begin
                //Could be one signal as opposed to three
                data_count_restart = 1;
                rj_count_restart = 1;
                coeff_count_restart = 1;
                s2p_clear = 1;
                p2s_clear = 1;
                
            end
            RESETTING: begin
                data_count_enable = 1;
                data_clear = 1;
                data_wr_en = 1;
            end
            WAIT_FOR_RJ: begin
                in_ready = 1;
            end
            READING_RJ: begin
                in_ready = 1;
                
            end
            FIRST_FRAME: begin
                in_ready = 1;
            end
            WRITING_RJ: begin
                in_ready = 1;
                rj_wr_en = 1;
            end
            WAIT_FOR_FRAME_END_RJ: begin
                in_ready = 1;
            end
            INCREMENT_RJ: begin
                in_ready = 1;
                rj_count_enable = 1;
            end
            WAIT_FOR_COEFF: begin
               in_ready = 1; 
            end
            READING_COEFF: begin
                in_ready = 1;
            end
            WRITING_COEFF: begin
                in_ready = 1;
                coeff_wr_en = 1;
            end
            WAIT_FOR_FRAME_END_COEFF: begin
                in_ready = 1;
            end
            INCREMENT_COEFF: begin
                in_ready = 1;
                coeff_count_enable = 1;
            end
            WAIT_FOR_COEFF: begin
               in_ready = 1; 
            end
            WAITING_FOR_DATA: begin
                in_ready = 1;
                coeff_count_restart = 1;
            end
            WRITE_DATA: begin
                in_ready = 1;
                data_wr_en = 1;
                data_count_enable = 1;
                alu_clear = 1;
            end
            READ_CONV: begin
                in_ready = 1;
                alu_en = 1;
            end
            OUTPUT_CONV_DATA: begin
                in_ready = 1;
                p2s_load = 1;
            end
            SLEEPING: begin
                in_ready = 1;
            end
            PRE_CLEAR: begin
                data_count_restart = 1;
                rj_count_restart = 1;
                coeff_count_restart = 1;
                s2p_clear = 1;
                p2s_clear = 1;
            end
            CLEARING: begin
                data_count_enable = 1;
                data_clear = 1;
                data_wr_en = 1;
            end
            default: begin
                
            end
        endcase
    end
endmodule