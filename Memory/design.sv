/* verilator lint_off MULTITOP */


// Rj Memory Module (Separate for Left and Right channels)
module rj_memory (
    input logic clk,
    input logic rj_wr_en_l,          // Write enable for Left channel
    input logic rj_wr_en_r,          // Write enable for Right channel
    input logic [3:0] rj_addr_l,     // Address for Left channel
    input logic [3:0] rj_addr_r,     // Address for Right channel
    input logic [15:0] rj_data_in_l, // Input data for Left channel
    input logic [15:0] rj_data_in_r, // Input data for Right channel
    output logic [15:0] rj_data_out_l,// Output data for Left channel
    output logic [15:0] rj_data_out_r // Output data for Right channel
);
    // Memory array: 16-bit x 16 entries x 2 channels
    logic [15:0] rj_mem_l [0:15];
    logic [15:0] rj_mem_r [0:15];

    // Write logic for Left channel
    always_ff @(posedge clk) begin
        if (rj_wr_en_l) begin
            rj_mem_l[rj_addr_l] <= rj_data_in_l;
            
            $display("Writing %x to Address: %d", rj_data_in_l, rj_addr_l);
            
            
        end
    end

    // Write logic for Right channel
    always_ff @(posedge clk) begin
        if (rj_wr_en_r) begin
            rj_mem_r[rj_addr_r] <= rj_data_in_r;
        end
    end

    // Read logic
    assign rj_data_out_l = rj_mem_l[rj_addr_l];
    assign rj_data_out_r = rj_mem_r[rj_addr_r];
endmodule

// Coefficients Memory Module (Separate for Left and Right channels)
module coefficients_memory (
    input logic clk,
    input logic coeff_wr_en_l,           // Write enable for Left channel
    input logic coeff_wr_en_r,           // Write enable for Right channel
    input logic [8:0] coeff_addr_l,      // Address for Left channel
    input logic [8:0] coeff_addr_r,      // Address for Right channel
    input logic [15:0] coeff_data_in_l,  // Input data for Left channel
    input logic [15:0] coeff_data_in_r,  // Input data for Right channel
    output logic [15:0] coeff_data_out_l,// Output data for Left channel
    output logic [15:0] coeff_data_out_r // Output data for Right channel
);
    // Memory array: 16-bit x 512 entries x 2 channels
    logic [15:0] coeff_mem_l [0:511];
    logic [15:0] coeff_mem_r [0:511];

    // Write logic for Left channel
    always_ff @(posedge clk) begin
        if (coeff_wr_en_l) begin
            coeff_mem_l[coeff_addr_l] <= coeff_data_in_l;
            
            $display("Writing %x to Address: %d", coeff_data_in_l, coeff_addr_l);
            
            
        end
    end

    // Write logic for Right channel
    always_ff @(posedge clk) begin
        if (coeff_wr_en_r) begin
            coeff_mem_r[coeff_addr_r] <= coeff_data_in_r;
        end
    end

    // Read logic
    assign coeff_data_out_l = coeff_mem_l[coeff_addr_l];
    assign coeff_data_out_r = coeff_mem_r[coeff_addr_r];
endmodule

module data_memory_fifo (
    input logic clk,
    input logic start,
    input logic rst_n,              // Active-low reset
    input logic clear,
    input logic data_wr_en_l,       // Write enable for Left channel
    input logic data_wr_en_r,       // Write enable for Right channel
    input logic [7:0] read_addr_l,// Read offset for Left channel
    input logic [7:0] read_addr_r,// Read offset for Right channel
    input logic [7:0] write_addr_l,// Write offset for Left channel
    input logic [7:0] write_addr_r,// Write offset for Right channel
    input logic [15:0] data_in_l,   // Input data for Left channel
    input logic [15:0] data_in_r,   // Input data for Right channel
    output logic [15:0] data_out_l, // Output data for Left channel
    output logic [15:0] data_out_r  // Output data for Right channel
);
    // Memory array: 16-bit x 256 entries x 2 channels
    logic [15:0] data_mem_l [0:255];
    logic [15:0] data_mem_r [0:255];

    // Write logic for Left channel
    always_ff @(posedge clk or negedge rst_n or posedge clear) begin
        if (clear || !rst_n) begin
            for (int i = 0; i < 256; i++) begin
                data_mem_l[i] <= 0;
            end
        end
        else if(data_wr_en_l) begin
            data_mem_l[write_addr_l] <= data_in_l;
            $display("Writing %x to Data Memory. Addr: %d", data_in_l, write_addr_l);
        end
    end

    // Write logic for Right channel
    always_ff @(posedge clk or negedge rst_n or posedge clear) begin
        if (clear || !rst_n) begin
            for (int i = 0; i < 256; i++) begin
                data_mem_r[i] <= 0;
            end
        end
        else if(data_wr_en_r) begin
            data_mem_r[write_addr_r] <= data_in_r;
        end
        
    end

    // Read logic
    assign data_out_l = data_mem_l[read_addr_l];
    assign data_out_r = data_mem_l[read_addr_l];
endmodule