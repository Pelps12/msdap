module Counter#(
    LIMIT = 8'd255,
    START = 8'd0
) (
    input logic clk,
    input logic restart,
    input logic enable,
    output logic done,
    output logic [$clog2(LIMIT)-1 : 0] count
);
logic first_cycle; // Flag to track the first cycle

assign done = count == LIMIT;

always_ff @( posedge clk, posedge restart ) begin : blockName
    if (restart) begin
        count <= START;
        first_cycle <= 1'b1;
    end
    else begin
        if(enable) begin
            if (first_cycle) begin
                first_cycle <= 1'b0; // After first cycle, start counting
            end else begin
                count <= count + 1;
            end
        end
        
    end
end
    
endmodule


module falling_edge_pulse (
    input  logic clk,
    input  logic signal_in,  // Input signal to detect falling edge
    output logic pulse_out   // Single-cycle pulse output
);
    logic signal_d; // Delayed version of signal_in

    always_ff @(posedge clk) begin
        signal_d <= signal_in; // Register previous value
    end

    assign pulse_out = signal_d & ~signal_in; // Detect falling edge
endmodule

module rising_edge_pulse (
    input  logic clk,
    input  logic signal_in,  // Input signal to detect rising edge
    output logic pulse_out   // Single-cycle pulse output
);
    logic signal_d; // Delayed version of signal_in

    always_ff @(posedge clk) begin
        signal_d <= signal_in; // Register previous value
    end

    assign pulse_out = ~signal_d & signal_in; // Detect rising edge
endmodule


module AllZerosDetector (
    input  logic clk,          // System clock
    input  logic clear,        // Clear/reset (active high)
    input  logic enable,        // Data valid signal (asserted when inputs are stable)
    input  logic [15:0] dataL, // Left channel data
    input  logic [15:0] dataR, // Right channel data
    output logic all_zeros     // Asserted after 800 consecutive zeros
);

    // Single counter for both channels
    logic [9:0] zero_count; // 10-bit counter (max 1024)

    always_ff @(posedge clk or posedge clear) begin
        if (clear) begin
            zero_count <= 10'h0;
            all_zeros  <= 1'b0;
        end else if (enable ) begin
            // Check both channels simultaneously
            if (dataL == 16'h0 && dataR == 16'h0) begin
                zero_count <= (zero_count == 10'd799) ? 10'd799 : zero_count + 1;
                all_zeros  <= (zero_count == 10'd799); // Assert at 800
            end else begin
                zero_count <= 10'h0;
                all_zeros  <= 1'b0;
            end
        end
    end

endmodule

