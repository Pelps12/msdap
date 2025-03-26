module P2S (
    input  logic        SCLK,      // System clock (26.88 MHz)
    input  logic        LOAD,      // Load 40-bit parallel data (active high)
    input  logic        CLR,       // Clear signal (active high)
    input  logic [39:0] PDATAIN,   // 40-bit parallel input (MSB-first: PDATAIN[0] = sign bit)
    output logic        DATAOUT,   // Serial output (MSB-first)
    output logic        OutReady   // High during 40-cycle transmission
);

    // Internal shift register and counter
    logic [39:0] shift_reg;  // MSB at shift_reg[0], LSB at shift_reg[39]
    logic [5:0]  count;      // Counts 0-39 (6 bits)

    always_ff @(posedge SCLK or posedge CLR) begin
        if (CLR) begin
            shift_reg <= 40'h0;
            count     <= 6'd40;  // Initialize to 40 (OutReady = 0)
        end else if (LOAD) begin
            // Load parallel data and start transmission
            shift_reg <= PDATAIN;
            count     <= 6'd0;   // Reset counter (OutReady = 1)
        end else if (count < 6'd40) begin
            // Shift right to transmit MSB-first
            shift_reg <= {shift_reg[38:0], 1'b0};
            count     <= count + 1;
        end
    end
    

    // Output logic
    assign DATAOUT = shift_reg[39];    // MSB (sign bit) first
    assign OutReady = (count < 6'd40); // High during 40-bit transmission

endmodule