module tb_serial_to_parallel_converter();
    // Testbench signals
    logic DCLK;
    logic clear, valid;
    logic InputL, InputR, InReady;
    logic [15:0] ParallelL, ParallelR;

    // Instantiate the Device Under Test (DUT)
    S2P dut (
        .DCLK(DCLK),
        .clear(clear),
        .InputL(InputL),
        .InputR(InputR),
        .ParallelL(ParallelL),
        .ParallelR(ParallelR),
        .valid(valid)
    );

// Data Clock (gated by InReady)
    initial begin
        DCLK = 0;
        forever begin
            if (InReady) #651.04 DCLK = ~DCLK;
            else begin
                DCLK = 0;
                @(posedge InReady);
            end
        end
    end

    // Test sequence
    initial begin
        // Initialize inputs
        clear = 0;
        InputL = 0;
        InputR = 0;
        InReady = 0;

        // Reset sequence
        #10 clear = 1;
        #10 clear = 0;

        // Test case 1: Shift in a known pattern for Left channel
        $display("Test Case 1: Shifting in test pattern");
        InReady = 1;
        // Pattern: 1010 1100 0011 0101 (binary)
        // Hexadecimal: 0xAC6B
        // Will shift in from MSB to LSB
        @(negedge DCLK) InputL = 1; // MSB (sign bit)
        @(negedge DCLK) InputL = 0;
        @(negedge DCLK) InputL = 1;
        @(negedge DCLK) InputL = 0;
        @(negedge DCLK) InputL = 1;
        @(negedge DCLK) InputL = 1;
        @(negedge DCLK) InputL = 0;
        @(negedge DCLK) InputL = 0;
        @(negedge DCLK) InputL = 0;
        @(negedge DCLK) InputL = 1;
        @(negedge DCLK) InputL = 1;
        @(negedge DCLK) InputL = 0;
        @(negedge DCLK) InputL = 1;
        @(negedge DCLK) InputL = 0;
        @(negedge DCLK) InputL = 1;
        @(negedge DCLK) InputL = 1;



        // Test case 2: Shift in a different pattern for Right channel
        $display("Test Case 2: Shifting in another test pattern");
        // Pattern: 0101 0011 1100 1010 (binary)
        // Hexadecimal: 0x53CA
        @(negedge DCLK) InputR = 0; // MSB (sign bit)
        @(negedge DCLK) InputR = 1;
        @(negedge DCLK) InputR = 0;
        @(negedge DCLK) InputR = 1;
        @(negedge DCLK) InputR = 0;
        @(negedge DCLK) InputR = 0;
        @(negedge DCLK) InputR = 1;
        @(negedge DCLK) InputR = 1;
        @(negedge DCLK) InputR = 1;
        @(negedge DCLK) InputR = 1;
        @(negedge DCLK) InputR = 0;
        @(negedge DCLK) InputR = 0;
        @(negedge DCLK) InputR = 1;
        @(negedge DCLK) InputR = 0;
        @(negedge DCLK) InputR = 1;
        @(negedge DCLK) InputR = 0;

        // Test case 3: Reset functionality
        $display("Test Case 3: Reset functionality");
        #10 clear = 0;
        #10 clear = 1;

        // Final checks
        #20 
        $display("Final ParallelL: 0x%h", ParallelL);
        $display("Final ParallelR: 0x%h", ParallelR);

        // End simulation
        #10 $finish;
    end

    // Optional: Waveform generation
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_serial_to_parallel_converter);
    end
endmodule