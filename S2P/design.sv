module S2P (
    input  logic DCLK,      // Data Clock (768 kHz)
    input  logic SCLK,      // System Clock (26.88 MHz)
    input  logic clear,     // Active-low reset
    input  logic InputL,    // Serial input (MSB first)
    input  logic InputR,    // Serial input (MSB first)
    output logic [15:0] ParallelL,  // Parallel output
    output logic [15:0] ParallelR,  // Parallel output
    output logic ready       // High for 1 SCLK cycle when conversion is complete
);

    // Shift register and counter (DCLK domain)
    logic [3:0] count;      // 0-15 counter
    logic done_internal;    // Asserted in DCLK domain

    // Shift logic on negedge of DCLK
    always_ff @(negedge DCLK or posedge clear) begin
        if (clear) begin
            ParallelL <= 16'h0;
            ParallelR <= 16'h0;
            count <= 4'h0;
        end else begin
            ParallelL <= {ParallelL[14:0], InputL};
            ParallelR <= {ParallelR[14:0], InputR};
            count <= count + 1;
        end
    end

    // Assert done_internal when count=15 (DCLK domain)
    assign done_internal = (count == 4'd15);

    // Synchronize done_internal to SCLK domain (2-stage FF for metastability)
    logic done_sync1, done_sync2;
    always_ff @(posedge SCLK or posedge clear) begin
        if (clear) begin
            done_sync1 <= 0;
            done_sync2 <= 0;
        end else begin
            done_sync1 <= done_internal;
            done_sync2 <= done_sync1;
        end
    end

    // Generate one-cycle pulse on rising edge of done_sync2
    logic done_prev;
    always_ff @(posedge SCLK or posedge clear) begin
        if (clear) done_prev <= 0;
        else        done_prev <= done_sync2;
    end

    assign ready = done_sync2 & ~done_prev;  // One-cycle pulse

endmodule