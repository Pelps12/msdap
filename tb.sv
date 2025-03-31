`timescale 1ns / 1ps

module tb_MSDAP;
    // Inputs
    logic SCLK;        // System Clock (26.88 MHz)
    logic DCLK;        // Data Clock (768 kHz)
    logic Start;       // Initializes processing
    logic Reset_n;     // Active-low reset
    logic Frame;       // Frame synchronization
    logic InputL;      // Left channel serial input
    logic InputR;      // Right channel serial input

    // Outputs
    logic OutputL;     // Left channel serial output (40-bit)
    logic OutputR;     // Right channel serial output (40-bit)
    logic InReady;     // Input ready signal
    logic OutReady;    // Output ready signal

    // Test data arrays
    logic [15:0] rjL [0:15], rjR [0:15];
    logic [15:0] coeffL[0:511], coeffR[0:511];
    logic [15:0] dataL[0:2299], dataR[0:2299];

    parameter sclk_period = 40;
    parameter dclk_period = 1302; //data clock period 1302ns = 768kHz

    // Instantiate MSDAP
    MSDAP uut (.*);

    // Clock generation
    initial begin
        SCLK = 0;
        forever #(sclk_period/2) SCLK = ~SCLK;  // 26.88 MHz
    end

    // Data Clock (gated by InReady)
    initial begin
        DCLK = 0;
        forever begin
            if (InReady) #(dclk_period/2) DCLK = ~DCLK;
            else begin
                DCLK = 0;
                @(posedge InReady);
            end
        end
    end

    // Timeout
    initial begin
        #100_000_000;
        $display("Timeout!");
        $finish;
    end

    // Initialize test data
    initial begin
        $readmemh("rj_in.hex", rjL);
        $readmemh("rj_in.hex", rjR);
        $readmemh("coeff.hex", coeffL);
        $readmemh("coeff.hex", coeffR);
        $readmemh("data.hex", dataL);
        $readmemh("data.hex", dataR);
    end

    // Test sequence
    initial begin
        // Shared variables
        logic [39:0] captured_outputL, expected_outputL;
        integer bit_count = 0;
        logic capture_done = 0;

        // Initialize
        Start = 0;
        Reset_n = 1;
        
        Frame = 0;
        InputL = 0;
        InputR = 0;

        // Start processing
        Start = 1;
        #100;
        Start = 0;

        // Fork input transmission and output capture
        fork
            // ----------------------------
            // Input Transmission Process
            // ----------------------------
            begin
                // Send Rj values
                for (int j = 0; j < 16; j++) send_frame(rjL[j], rjR[j]);
                
                // Send coefficients
                for (int j = 0; j < 512; j++) send_frame(coeffL[j], coeffR[j]);
                
                // Send input data
                for (int j = 0; j < 60; j++) send_frame(dataL[j], dataR[j]);
            end

            begin
                #12000000;
                Reset_n = 0;
                #10;
                Reset_n = 1;

            end

            // ----------------------------
            // Output Capture Process
            // ----------------------------
            begin
                wait(OutReady); // Wait for first output
                $display("\n--- Starting output capture ---");
                
                for (int  j= 0; j < 60; j++) begin
                    //$display("%d", j);
                    capture_done = 0;
                    while(!capture_done) begin
                        wait(OutReady);
                        //$display("HERRE");
                        @(posedge SCLK) begin
                            if (OutReady && (bit_count < 40)) begin
                                captured_outputL[39 - bit_count] = OutputL;
                                bit_count++;
                                //$display("Captured bit %0d: %b", bit_count, OutputL);
                                
                                if (bit_count == 40) begin
                                    capture_done = 1;
                                    bit_count = 0;
                                    $display("%x", captured_outputL);
                                end
                            end
                        end
                    end
                end
            end
        join



        #3000 $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_MSDAP);
    end

    // Task to send 16-bit frames
    task send_frame(input [15:0] left_data, right_data);
        wait (InReady);
        @(posedge DCLK);
        Frame = 1;
        InputL = left_data[15];
        InputR = right_data[15];
        
        for (int i = 14; i >= 0; i--) begin
            @(posedge DCLK);
            Frame = 0;
            InputL = left_data[i];
            InputR = right_data[i];
        end
    endtask

endmodule