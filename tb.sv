`timescale 1ns / 1ps

`define RJ_SIZE 16
`define COEFF_SIZE 512
`define TB_DATA_SIZE 7000
`define FILE_SIZE 15056//3056(1000 data)//15056(all data)//16*2+512*2+7000*2

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
    logic [15:0] rjL [0:`RJ_SIZE-1], rjR [0:`RJ_SIZE-1];
    logic [15:0] coeffL[0:`TB_DATA_SIZE - 1], coeffR[0:`TB_DATA_SIZE - 1];
    logic [15:0] dataL[0:`TB_DATA_SIZE - 1], dataR[0:`TB_DATA_SIZE - 1];

    reg [15:0] fileInput [0:`FILE_SIZE - 1]; //Prepare space for holding data.in

    parameter sclk_period = 37.20238095;
    parameter dclk_period = 1302.083333; //data clock period 1302ns = 768kHz

    int fd;
    int i, j, out_count;

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
        #1_000_000_000;
        $display("Timeout!");
        $fclose(fd);
        $finish;
    end

    // Initialize test data
    initial begin
        $readmemh("data1.in",fileInput);//Input data1
        //$readmemh("/home/010/y/yx/yxf160330/CE6306/Final/datasets/data2.in",fileInput);
        j = 0;
        for(i = 0; i < `RJ_SIZE * 2; i=i+2) begin
            rjL[j] = fileInput[i];
            rjR[j] = fileInput[i + 1];
            $display("RjL and RjR at Number %d is %h and %h \n",i, rjL[j], rjR[j]); 
            j = j + 1;
        end
        j = 0;
        for(i = `RJ_SIZE * 2; i < `RJ_SIZE  * 2 + `COEFF_SIZE * 2; i=i+2) begin
            coeffL[j] = fileInput[i];
            coeffR[j] = fileInput[i + 1];
            $display("CoeffL and CoeffR at Number %d is %h and %h \n",j, coeffL[j], coeffR[j]); 
            j = j + 1;
        end
        j=0;
        for(i = `RJ_SIZE * 2 + `COEFF_SIZE * 2; i < `FILE_SIZE; i=i+2) begin
            dataL[j] = fileInput[i];
            dataR[j] = fileInput[i + 1];
            $display("DataL and DataR at Number %d is %h and %h \n", j, dataL[j], dataR[j]);
            j = j + 1;
        end 
    end

    // Test sequence
    initial begin
        // Shared variables
        logic [39:0] captured_outputL, expected_outputL;
        logic [39:0] captured_outputR, expected_outputR;
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
            fd = $fopen ("data.out", "w");
            if (fd)  $display("File was opened successfully : %0d", fd);
            else     $display("File was NOT opened successfully : %0d", fd);
            // ----------------------------
            // Input Transmission Process
            // ----------------------------
            begin
                // Send Rj values
                for (int j = 0; j < 16; j++) send_frame(rjL[j], rjR[j]);
                
                // Send coefficients
                for (int j = 0; j < 512; j++) send_frame(coeffL[j], coeffR[j]);
                
                // Send input data
                for (int j = 0; j < `TB_DATA_SIZE; j++) begin
                    send_frame(dataL[j], dataR[j]);
                    if(j == 3799) begin
                        Reset_n = 0;
                        #40;
                        Reset_n = 1;
                    end
                end
            end

/*             begin
                #12000000;
                Reset_n = 0;
                #10;
                Reset_n = 1;

            end */

            // ----------------------------
            // Output Capture Process
            // ----------------------------
            begin
                wait(OutReady); // Wait for first output
                
                for (out_count= 0; out_count < `TB_DATA_SIZE ; out_count++) begin
                    //$display("%d", j);
                    if (out_count == 3799) begin
                            $display("PLEASSSEEEEEE");
                    end
                    capture_done = 0;
                    while(!capture_done) begin
                        wait(OutReady);
                        //$display("HERRE");
                        @(posedge SCLK) begin
                            if (OutReady && (bit_count < 40)) begin
                                captured_outputL[39 - bit_count] = OutputL;
                                captured_outputR[39 - bit_count] = OutputR;
                                bit_count++;
                                //$display("Captured bit %0d: %b", bit_count, OutputL);
                                
                                if (bit_count == 40) begin
                                    capture_done = 1;
                                    bit_count = 0;
                                    $fdisplay(fd, "OutputL: %x; OutputR: %x", captured_outputL, captured_outputR);
                                end
                            end
                        end
                    end
                end

                $fclose(fd);
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