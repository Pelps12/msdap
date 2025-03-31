module ALU (
    input  logic clk,          // System clock (SCLK)
    input  logic enable,       // Enable ALU operation
    input  logic clear,        // Active-high clear/reset
    input  logic [7:0] current_data_addr,
    input  logic [15:0] data,  // Input data (from Data Memory)
    input  logic [15:0] coeff_data, // Coefficient (from Coefficient Memory)
    input  logic [7:0] rj_data,// Rj value (from Rj Memory)
    output logic [7:0] data_addr, // Data Memory address (LSBs of coeff)
    output logic [8:0] coeff_addr, // Coefficient Memory address
    output logic [3:0] rj_addr,    // Rj Memory address
    output logic [39:0] result_reg,        // 40-bit accumulator/shift register
    output logic output_en
);

//--------------------------------------------------------------
// Internal Signals
//--------------------------------------------------------------
logic [39:0] accum_reg;
logic [23:0] alu_result;       // Adder/subtractor result
logic [7:0] u_limit;           // Number of coefficients per Rj
logic [8:0] current_u_index;   // Coefficient counter for current Rj
logic accum_en, shift_en;      // Control signals from FSM
logic u_complete, rj_done, last_u;     // Status flags
logic first_rj;                // Flag to handle first Rj initialization

assign accum_en = enable;

assign u_limit = rj_data;

assign shift_en = current_u_index == u_limit;

assign data_addr = current_data_addr - coeff_data[7:0];


//--------------------------------------------------------------
// Control FSM (Manages accumulation and shift states)
//--------------------------------------------------------------
ALU_Control control (
    .clk(clk),
    .clear(clear),
    .enable(enable),
    .u_complete(u_complete),
    .last_u(last_u),
    .rj_done(rj_done),
    .accum_en(accum_en),
    .shift_en(shift_en),
    .output_en(output_en)
);

//--------------------------------------------------------------
// Adder/Subtractor (24-bit with sign extension)
//--------------------------------------------------------------
Adder adder (
    .operand1(accum_reg[39:16]),
    .operand2(data),
    .sub(coeff_data[8]),
    .result(alu_result)
);

//--------------------------------------------------------------
// Accumulator and Shift Logic
//--------------------------------------------------------------
always_ff @(posedge clk or posedge clear) begin
    if (clear) begin
        accum_reg = 40'h0;
    end else begin
        if (accum_en && ~output_en) begin
            accum_reg[39:16] = alu_result;
            if (shift_en) begin
                accum_reg = {accum_reg[39], accum_reg[39:1]};
            end
        end

        if (output_en) begin
            accum_reg = 0;
        end
    end
end


always_ff @( posedge clk, posedge clear ) begin
    if (clear) begin
        coeff_addr <= 8'h0;
    end
    else begin
        if (~output_en && enable) begin
            coeff_addr <= coeff_addr + 1;

            u_complete = coeff_addr == 9'd511;
        end
    end
end

always_ff @(posedge clk, posedge clear ) begin
    if (clear) begin
        current_u_index <= 1;
        rj_addr <= 0;
    end
    else begin
        if (~output_en && enable) begin
            if (u_limit == current_u_index) begin
                current_u_index <= 1;
                rj_addr <= rj_addr + 1;
            end
            else begin
                current_u_index <= current_u_index + 1;
            end
        end
    end
end

always_ff @( posedge clk ) begin
    if(output_en) begin
        result_reg = accum_reg;
    end
end

endmodule

module ALU_Control (
    input  logic clk,
    input  logic clear,
    input  logic enable,
    input  logic u_complete,  // All coefficients processed for current Rj
    input  logic rj_done,     // All Rj entries processed\
    input  logic last_u,
    output logic accum_en,    // Enable accumulation
    output logic shift_en,     // Enable shift
    output logic output_en
);

//--------------------------------------------------------------
// State Definitions
//--------------------------------------------------------------
//One clock cycle could be saved
typedef enum {
    INIT = 0,   // Idle state
    WORKING = 1
} state_e;

state_e state, next_state;

//--------------------------------------------------------------
// State Transitions
//--------------------------------------------------------------
always_ff @(posedge clk or posedge clear) begin
    if (clear) state <= INIT;
    else       state <= next_state;
end

always_comb begin
    case (state)
        INIT:  next_state = (enable) ? WORKING : INIT;  // Start on enable
        WORKING: next_state = WORKING;
        default: next_state = INIT;
    endcase
end

always_comb begin
    output_en = 0;
    case (state)
        WORKING: begin
            if (u_complete) begin
                output_en = 1;
            end
        end
        default: begin
        end
    endcase
end

endmodule

module Adder (
    input  logic [23:0] operand1, // Upper 24 bits of accumulator
    input  logic [15:0] operand2, // Input data (sign-extended)
    input  logic sub,             // Subtract if coefficient MSB=1
    output logic [23:0] result    // Result to accumulator
);

//--------------------------------------------------------------
// Sign-Extend Input Data to 24 Bits
//--------------------------------------------------------------
logic [23:0] sign_ext_data;
assign sign_ext_data = {{8{operand2[15]}}, operand2}; // 16 → 24 bits

//--------------------------------------------------------------
// Addition/Subtraction Logic
//--------------------------------------------------------------
always_comb begin
    if (sub) result = operand1 - sign_ext_data; // Subtract
    else     result = operand1 + sign_ext_data; // Add
end

endmodule