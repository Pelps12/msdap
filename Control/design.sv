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
    output logic mem_clear,
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
    output logic p2s_clear,
    output logic p2s_en
);
    
    typedef enum
    {
        INIT  = 0,
        WAIT_FOR_RJ = 1,
        READING_RJ = 2,
        WAIT_FOR_COEFF = 3,
        READING_COEFF = 4,
        WAITING_FOR_DATA = 5,
        WORKING = 6,
        CLEARING = 7,
        SLEEPING = 8
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
                next_state = WAIT_FOR_RJ;
            end
            WAIT_FOR_RJ: begin
                if (frame) begin
                    next_state = READING_RJ;
                end
            end
            READING_RJ: begin
                if (rj_count_done) begin
                    next_state = WAIT_FOR_COEFF;
                end
            end
            WAIT_FOR_COEFF: begin
                if (frame) begin
                    next_state = READING_COEFF;
                end            
            end
            READING_COEFF: begin
                if (coeff_count_done) begin
                    next_state = WAITING_FOR_DATA;
                end
            end
            WAITING_FOR_DATA: begin
                if (frame) begin
                    next_state = WORKING;
                end
                else if(~reset_n) begin
                    next_state = CLEARING;
                end
                else begin
                    next_state = state;
                end
            end
            WORKING: begin
                if (~reset_n) begin
                    next_state = CLEARING;
                end
                else if(all_zeros) begin
                    next_state = SLEEPING;
                end
                else begin
                    next_state = state;
                end
            end
            CLEARING: begin
                next_state = WAITING_FOR_DATA;
            end
            SLEEPING: begin
                if(~all_zeros) begin
                    next_state = WORKING;
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
        mem_clear = 0;

        case (state)
            INIT: begin
                //Could be one signal as opposed to three
                data_count_restart = 1;
                rj_count_restart = 1;
                coeff_count_restart = 1;
                mem_clear = 1;
                s2p_clear = 1;
                p2s_clear = 1;
                alu_clear = 1;   
            end
            WAIT_FOR_RJ: begin
                in_ready = 1;
            end
            READING_RJ: begin
                in_ready = 1;
                rj_count_enable = 1;
                rj_wr_en = 1;
            end
            WAIT_FOR_COEFF: begin
                in_ready = 1;
            end
            READING_COEFF: begin
                in_ready = 1;
                coeff_count_enable = 1;
                coeff_wr_en = 1;
            end
            WAITING_FOR_DATA: begin
                in_ready = 1;
            end
            WORKING: begin
                in_ready = 1;
                data_count_enable = 1;
                data_wr_en = 1;
                alu_en = 1;
                p2s_en = 1;
            end
            
        endcase
    end
endmodule