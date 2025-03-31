module tb_memory_modules();
    // Clock
    logic clk;
    logic rst_n;

    // Rj Memory signals
    logic rj_wr_en_l, rj_wr_en_r;
    logic [3:0] rj_addr_l, rj_addr_r;
    logic [15:0] rj_data_in_l, rj_data_in_r;
    logic [15:0] rj_data_out_l, rj_data_out_r;

    // Coefficients Memory signals
    logic coeff_wr_en_l, coeff_wr_en_r;
    logic [8:0] coeff_addr_l, coeff_addr_r;
    logic [15:0] coeff_data_in_l, coeff_data_in_r;
    logic [15:0] coeff_data_out_l, coeff_data_out_r;

    // Data Memory FIFO signals
    logic data_wr_en_l, data_wr_en_r;
    logic [3:0] read_offset_l, read_offset_r;
    logic [15:0] data_in_l, data_in_r;
    logic [15:0] data_out_l, data_out_r;

    // Instantiate modules
    rj_memory rj_mem (
        .clk(clk),
        .rj_wr_en_l(rj_wr_en_l),
        .rj_wr_en_r(rj_wr_en_r),
        .rj_addr_l(rj_addr_l),
        .rj_addr_r(rj_addr_r),
        .rj_data_in_l(rj_data_in_l),
        .rj_data_in_r(rj_data_in_r),
        .rj_data_out_l(rj_data_out_l),
        .rj_data_out_r(rj_data_out_r)
    );

    coefficients_memory coeff_mem (
        .clk(clk),
        .coeff_wr_en_l(coeff_wr_en_l),
        .coeff_wr_en_r(coeff_wr_en_r),
        .coeff_addr_l(coeff_addr_l),
        .coeff_addr_r(coeff_addr_r),
        .coeff_data_in_l(coeff_data_in_l),
        .coeff_data_in_r(coeff_data_in_r),
        .coeff_data_out_l(coeff_data_out_l),
        .coeff_data_out_r(coeff_data_out_r)
    );

    data_memory_fifo data_fifo (
        .clk(clk),
        .rst_n(rst_n),
        .data_wr_en_l(data_wr_en_l),
        .data_wr_en_r(data_wr_en_r),
        .read_offset_l(read_offset_l),
        .read_offset_r(read_offset_r),
        .data_in_l(data_in_l),
        .data_in_r(data_in_r),
        .data_out_l(data_out_l),
        .data_out_r(data_out_r)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        // Initialize signals
        rst_n = 0;
        
        // Rj Memory signals
        rj_wr_en_l = 0;
        rj_wr_en_r = 0;
        rj_addr_l = 0;
        rj_addr_r = 0;
        rj_data_in_l = 0;
        rj_data_in_r = 0;
        
        // Coefficients Memory signals
        coeff_wr_en_l = 0;
        coeff_wr_en_r = 0;
        coeff_addr_l = 0;
        coeff_addr_r = 0;
        coeff_data_in_l = 0;
        coeff_data_in_r = 0;
        
        // Data FIFO signals
        data_wr_en_l = 0;
        data_wr_en_r = 0;
        read_offset_l = 0;
        read_offset_r = 0;
        data_in_l = 0;
        data_in_r = 0;

        // Release reset
        @(posedge clk) rst_n = 1;

        // Test Rj Memory
        $display("Testing Rj Memory");
        // Write to Left channel
        for (int i = 0; i < 16; i++) begin
            @(posedge clk) begin
                rj_wr_en_l = 1;
                rj_addr_l = i;
                rj_data_in_l = 16'hA000 + i;
            end
        end

        // Write to Right channel
        for (int i = 0; i < 16; i++) begin
            @(posedge clk) begin
                rj_wr_en_r = 1;
                rj_addr_r = i;
                rj_data_in_r = 16'hB000 + i;
            end
        end

        // Read back Rj Memory
        @(posedge clk) begin
            rj_wr_en_l = 0;
            rj_wr_en_r = 0;
        end
        for (int i = 0; i < 16; i++) begin
            @(posedge clk) begin
                rj_addr_l = i;
                rj_addr_r = i;
                #1 $display("Rj_L[%0d] = 0x%h, Rj_R[%0d] = 0x%h", 
                    i, rj_data_out_l, i, rj_data_out_r);
            end
        end

        // Test Coefficients Memory
        $display("Testing Coefficients Memory");
        // Write to Left channel
        for (int i = 0; i < 512; i += 50) begin
            @(posedge clk) begin
                coeff_wr_en_l = 1;
                coeff_addr_l = i;
                coeff_data_in_l = 16'hC000 + i;
            end
        end

        // Write to Right channel
        for (int i = 0; i < 512; i += 50) begin
            @(posedge clk) begin
                coeff_wr_en_r = 1;
                coeff_addr_r = i;
                coeff_data_in_r = 16'hD000 + i;
            end
        end

        // Read back Coefficients Memory
        @(posedge clk) begin
            coeff_wr_en_l = 0;
            coeff_wr_en_r = 0;
        end
        for (int i = 0; i < 512; i += 50) begin
            @(posedge clk) begin
                coeff_addr_l = i;
                coeff_addr_r = i;
                #1 $display("Coeff_L[%0d] = 0x%h, Coeff_R[%0d] = 0x%h", 
                    i, coeff_data_out_l, i, coeff_data_out_r);
            end
        end

        // Test Data Memory FIFO
        $display("Testing Data Memory FIFO");
        
        // Write some data to Left channel
        for (int i = 0; i < 10; i++) begin
            @(posedge clk) begin
                data_wr_en_l = 1;
                data_in_l = 16'hC000 + i;
            end
        end

        // Write some data to Right channel
        for (int i = 0; i < 10; i++) begin
            @(posedge clk) begin
                data_wr_en_l = 0;
                data_wr_en_r = 1;
                data_in_r = 16'hD000 + i;
            end
        end



        // Test relative read for Left channel
        @(posedge clk) begin
            data_wr_en_l = 0;
            data_wr_en_r = 0;
            read_offset_l = 2;
            #1 $display("Left channel read with offset 2: 0x%h", data_out_l);
        end

        // Test relative read for Right channel
        @(posedge clk) begin
            data_wr_en_r = 0;
            read_offset_r = 5;
            #1 $display("Right channel read with offset 5: 0x%h", data_out_r);
        end

        // Wraparound test
        $display("Testing Wraparound");
        for (int i = 0; i < 256; i++) begin
            @(posedge clk) begin
                data_wr_en_l = 1;
                data_in_l = 16'hE000 + i;
            end
        end

        // Read near the end
        @(posedge clk) begin
            data_wr_en_l = 0;
            read_offset_l = 10;
            #1 $display("Left channel read near end with offset 10: 0x%h", data_out_l);
        end

        // End simulation
        #20 $finish;
    end

    // Waveform dump
    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_memory_modules);
    end
endmodule