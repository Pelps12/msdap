`timescale 1ns / 1ps

module tb_P2S();

    // Inputs
    logic SCLK;          // System clock (26.88 MHz)
    logic LOAD;         // LOAD synchronization
    logic CLR;           // Clear signal
    logic [39:0] PDATAIN; // 40-bit parallel input

    // Outputs
    logic DATAOUT;       // Serial output
    logic OutReady;      // Transmission status

    // Instantiate the P2S module
    P2S uut (
        .SCLK(SCLK),
        .LOAD(LOAD),
        .CLR(CLR),
        .PDATAIN(PDATAIN),
        .DATAOUT(DATAOUT),
        .OutReady(OutReady)
    );

    // Generate SCLK (26.88 MHz, period ≈ 37.2 ns)
    initial begin
        SCLK = 0;
        forever #18.6 SCLK = ~SCLK; // Half-period = 18.6 ns
    end

    // Test sequence
    initial begin
        // Initialize inputs
        CLR = 1;
        LOAD = 0;
        PDATAIN = 40'hA5A5A5A5A5; // Test pattern: alternating 1s and 0s (MSB=1)

        // Apply reset
        #100;
        CLR = 0;

        // Trigger LOAD to start transmission
        @(posedge SCLK);
        LOAD = 1;
        @(posedge SCLK);
        LOAD = 0;

        // Monitor transmission
        $display("Starting transmission...");
        for (int i = 0; i < 40; i++) begin
            @(negedge SCLK); // Check outputs at clock edge
            $display("Cycle %0d: DATAOUT = %b, OutReady = %b", i, DATAOUT, OutReady);

        end


        #100;

        $display("Transmission completed successfully!");
        $finish;
    end

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_P2S);
    end

endmodule