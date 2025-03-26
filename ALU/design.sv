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
    output logic [39:0] accum_reg,        // 40-bit accumulator/shift register
    output logic output_en
);

//--------------------------------------------------------------
// Internal Signals
//--------------------------------------------------------------

logic [23:0] alu_result;       // Adder/subtractor result
logic [7:0] u_limit;           // Number of coefficients per Rj
logic [7:0] current_u_index;   // Coefficient counter for current Rj
logic accum_en, shift_en;      // Control signals from FSM
logic u_complete, rj_done, last_u;     // Status flags
logic first_rj;                // Flag to handle first Rj initialization

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
        accum_reg <= 40'h0;
    end else begin
        if (accum_en) begin
            accum_reg[39:16] <= alu_result;
        end else if (shift_en) begin
            accum_reg <= {accum_reg[39], accum_reg[39:1]};
        end
    end
end

//--------------------------------------------------------------
// Rj and Coefficient Tracking
//--------------------------------------------------------------
always_ff @(posedge clk or posedge clear) begin
    if (clear) begin
        current_u_index <= 8'h1;
        coeff_addr <= 8'h0;
        u_limit         <= 8'h0;
        rj_addr         <= 4'h0;
        first_rj        <= 1'b1; // Initialize first Rj flag
    end else begin
        if (shift_en) begin
            // Load new Rj after shift
                        rj_addr         <= rj_addr + 1;
            u_limit         <= rj_data;
            current_u_index <= 8'h1;


            first_rj        <= 1'b0;
        end else if (first_rj && accum_en) begin
            // Load first Rj on first accumulation cycle
            u_limit         <= rj_data;
            first_rj        <= 1'b0;
        end else if (accum_en) begin
            // Track coefficients for current Rj
            current_u_index <= current_u_index + 1;
            
            coeff_addr <= coeff_addr + 1;
            
        end
    end
end

//--------------------------------------------------------------
// Address Generation and Status Flags
//--------------------------------------------------------------
assign data_addr  = (current_data_addr - 1)- coeff_data[7:0];
//assign coeff_addr = current_u_index; // Increments during ACCUM
assign u_complete = (current_u_index == rj_data);
assign rj_done    = (rj_addr == 4'd15); // Terminate after 16 Rj entries
assign last_u = u_complete && coeff_addr == 'd511;

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
    ACCUM = 1,  // Accumulate coefficients
    SHIFT = 2,   // Shift after Rj completion
    FINAL_SHIFT = 3,
    DONE = 4
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
        INIT:  next_state = (enable) ? ACCUM : INIT;  // Start on enable
        ACCUM: begin
            if (u_complete) begin
                if(last_u) begin
                    next_state = FINAL_SHIFT;
                end
                else begin
                    next_state = SHIFT;
                end
            end
            else begin
                next_state = ACCUM;
            end
        end
        SHIFT: next_state = (rj_done) ? INIT : ACCUM; // Loop or terminate
        FINAL_SHIFT: next_state = DONE;
        DONE: next_state = DONE;
        default: next_state = INIT;
    endcase
end


//--------------------------------------------------------------
// Output Logic
//--------------------------------------------------------------
assign accum_en = (state == ACCUM); // Accumulate in ACCUM state
assign shift_en = (state == SHIFT) || (state == FINAL_SHIFT); // Shift in SHIFT state
assign output_en = (state == DONE);
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