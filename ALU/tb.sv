`timescale 1ns / 1ps

module tb_ALU;

    // Inputs
    logic clk;
    logic enable;
    logic clear, output_en;
    logic [15:0] data;
    logic [15:0] coeff_data;
    logic [7:0] rj_data;
    logic [39:0] accum_reg;

    // Outputs
    logic [7:0] data_addr;
    logic [8:0] coeff_addr;
    logic [3:0] rj_addr;

    // Memory arrays
    logic [15:0] data_mem [0:255];  // Data memory (256x16)
    logic [15:0] coeff_mem [0:511]; // Coefficient memory (512x16)
    logic [7:0] rj_mem [0:15];      // Rj memory (16x8)

    // Read data from memory
    assign data = data_mem[data_addr];
    assign coeff_data = coeff_mem[coeff_addr];
    assign rj_data = rj_mem[rj_addr];

    // Instantiate the ALU
    ALU uut (
        .clk(clk),
        .enable(enable),
        .clear(clear),
        .current_data_addr('d47),
        .data(data),
        .coeff_data(coeff_data),
        .rj_data(rj_data),
        .data_addr(data_addr),
        .coeff_addr(coeff_addr),
        .rj_addr(rj_addr),
        .output_en(output_en),
        .result_reg(accum_reg)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100 MHz clock
    end

    // Load memory files
    initial begin
        $readmemh("data.hex", data_mem);     // Load data memory
        $readmemh("coeff.hex", coeff_mem);   // Load coefficient memory
        $readmemh("rj_in.hex", rj_mem);         // Load Rj memory
    end

    // Test sequence
    initial begin
        // Initialize inputs
        enable = 0;
        clear = 1;
        #20 clear = 0;  // Release reset

        // Enable ALU
        enable = 1;

        
        

        // Wait for ALU to process
        #6000;

        // Display results
        $display("data_addr = 0x%h, coeff_addr = 0x%h, rj_addr = 0x%h",
                    data_addr, coeff_addr, rj_addr);
        

        // Disable ALU
        enable = 0;

        // End simulation
        #100 $finish;
    end
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_ALU);
    end

endmodule