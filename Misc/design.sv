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



module Edge_Detector (
    input  logic clk,      // Clock signal
    input  logic restart,  // Asynchronous reset input
    input  logic enable,   // Enable signal to be edge-detected
    output logic done      // One-clock-cycle pulse when a rising edge is detected on enable
);

  // Register to hold previous value of enable
  logic prev_enable;

  // Synchronous logic: on every clock, update the previous enable state and generate pulse.
  always_ff @(posedge clk or posedge restart) begin
    if (restart) begin
      prev_enable <= 1'b0;
      done        <= 1'b0;
    end 
    else begin
      // Generate a pulse when enable transitions from 0 to 1
      done        <= (~prev_enable) & enable;
      prev_enable <= enable;
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
        end else begin
            // Check for non-zero in either channel (unconditionally)
            if (dataL != 16'h0 || dataR != 16'h0) begin
                zero_count <= 10'h0;
                all_zeros  <= 1'b0;
            end else if (enable) begin
                // Both channels are zero and enable is high: increment counter
                if (zero_count == 10'd799) begin
                    // Maintain count at 799 once reached
                    zero_count <= zero_count;
                    all_zeros  <= 1'b1;
                end else begin
                    zero_count <= zero_count + 1;
                    all_zeros  <= (zero_count + 1 == 10'd799);
                end
            end
            // else, enable is low and data is zero: do nothing (counter remains)
        end
    end

endmodule

module DCLKtoSCLKPulse (
    input  logic DCLK,      // Data clock (768 kHz)
    input  logic SCLK,      // System clock (26.88 MHz)
    input  logic start,     // Active-high reset (positive edge)
    input  logic Frame,     // Input frame signal (DCLK domain)
    output logic FramePulse // Output pulse (SCLK domain, 1 cycle)
);

    // DCLK Domain: Detect rising edge of Frame
    logic Frame_prev;
    logic Frame_rise;
    always_ff @(posedge DCLK or posedge start) begin
        if (start) Frame_prev <= 0;
        else       Frame_prev <= Frame;
    end
    assign Frame_rise = Frame & ~Frame_prev; // Rising edge detector

    // Toggle a flag on each Frame_rise (DCLK domain)
    logic toggle_dclk;
    always_ff @(posedge DCLK or posedge start) begin
        if (start) toggle_dclk <= 0;
        else if (Frame_rise) toggle_dclk <= ~toggle_dclk;
    end

    // Synchronize toggle_dclk to SCLK domain (2-stage FF)
    logic toggle_sclk1, toggle_sclk2;
    always_ff @(posedge SCLK or posedge start) begin
        if (start) begin
            toggle_sclk1 <= 0;
            toggle_sclk2 <= 0;
        end else begin
            toggle_sclk1 <= toggle_dclk;
            toggle_sclk2 <= toggle_sclk1;
        end
    end

    // Detect toggle edge in SCLK domain to generate pulse
    logic toggle_sclk_prev;
    always_ff @(posedge SCLK or posedge start) begin
        if (start) toggle_sclk_prev <= 0;
        else       toggle_sclk_prev <= toggle_sclk2;
    end
    assign FramePulse = (toggle_sclk2 != toggle_sclk_prev);

endmodule


module mask_two_pulses (
  input  logic rst_n,       // Active-low reset
  input  logic clear,       // Active-high clear
  input logic one_or_two,
  input  logic OutReady,    // Original "ready" signal
  output logic newOutReady // Masked-out "ready" that tracks OutReady after two pulses
);
     logic [1:0] count;  // Internal counter
  // COUNTER:
  //   - increments on posedge of OutReady
  //   - resets async on negedge of rst_n or posedge of clear
  //   - saturates at 2
  always_ff @(posedge OutReady or posedge clear or negedge rst_n or posedge one_or_two) begin
    if (!rst_n) begin
      count <= 2'b00;
    end
    else if (clear) begin
      count <= 2'b00;
    end
    else if(one_or_two) begin
        count <= 2'b01;
    end
    else begin
      if (count < 3) begin
        count <= count + 1'b1;
      end
      // If already 2, stay at 2
    end
  end

  // OUTPUT LOGIC:
  //   - If count == 2, pass OutReady directly (so newOutReady will follow both edges)
  //   - Otherwise, drive 0 (mask out the first two pulses entirely)
  assign newOutReady = (count == 3) ? OutReady : 1'b0;

endmodule