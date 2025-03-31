module S2P (
    input  logic DCLK,      // Data Clock (768 kHz)
    input  logic clear,     // Active-low reset
    input  logic InputL,    // Serial input (MSB first)
    input  logic InputR,    // Serial input (MSB first)
    output logic [15:0] ParallelL,  // Parallel output
    output logic [15:0] ParallelR,  // Parallel output
    output logic valid       // High for 1 SCLK cycle when conversion is complete
);

    // Shift register and counter (DCLK domain)
    logic [3:0] count;      // 0-15 counter
    logic done_internal;    // Asserted in DCLK domain

    // Shift logic on negedge of DCLK
    always_ff @(negedge DCLK or posedge clear) begin
        if (clear) begin
            ParallelL <= 16'h0;
            ParallelR <= 16'h0;
            count <= 4'd0;
            valid = 0;
        end else begin
            ParallelL <= {ParallelL[14:0], InputL};
            ParallelR <= {ParallelR[14:0], InputR};
            count <= count + 1;
            valid = 0;
            if(count == 4'd15) begin
                valid = 1;
            end
        end
    end

    //assign valid = count == 4'd15;

endmodule