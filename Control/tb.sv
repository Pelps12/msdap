module tb_Control();
    // Inputs
    logic clk;
    logic start;
    logic frame;
    logic reset_n = 1;
    logic data_clear_complete;
    logic rj_count_done;
    logic coeff_count_done;
    logic s2p_done;
    logic conv_done;
    logic all_zeros;
    
    // Outputs
    logic mem_clear;
    logic data_count_restart;
    logic data_count_enable;
    logic data_clear;
    logic in_ready;
    logic rj_wr_en;
    logic coeff_wr_en;
    logic s2p_clear;
    logic data_wr_en;
    logic rj_count_restart;
    logic rj_count_enable;
    logic coeff_count_restart;
    logic coeff_count_enable;
    logic alu_en;
    logic alu_clear;
    logic p2s_load;
    logic p2s_clear;

    Control uut (.*);

    // Clock generation
    always #5 clk = ~clk;

    // State names for reporting
    string state_names[9] = '{
        "INIT",
        "WAIT_FOR_RJ", 
        "READING_RJ",
        "WAIT_FOR_COEFF",
        "READING_COEFF",
        "WAITING_FOR_DATA",
        "WORKING",
        "CLEARING",
        "SLEEPING"
    };

    task print_state;
        $display("Time: %0t, State: %s", $time, state_names[uut.state]);
    endtask

    initial begin
        $dumpfile("control_tb.vcd");
        $dumpvars(0, tb_Control);
        
        // Initialize inputs
        clk = 0;
        start = 0;
        frame = 0;
        reset_n = 1;
        data_clear_complete = 0;
        rj_count_done = 0;
        coeff_count_done = 0;
        s2p_done = 0;
        conv_done = 0;
        all_zeros = 0;

        // Reset sequence
        #10;
        start = 1;
        #10;
        start = 0;
        

    
        @(posedge clk);

        // Test 2: RJ reading sequence
        frame = 1;
        @(posedge clk);
        frame = 0;
        
        rj_count_done = 1;
        @(posedge clk);
        rj_count_done = 0;

        // Test 3: Coefficient reading sequence
        frame = 1;
        @(posedge clk);
        frame = 0;
        
        
        coeff_count_done = 1;
        @(posedge clk);
        coeff_count_done = 0;

        // Test 4: Data processing sequence
        frame = 1;
        @(posedge clk);
        frame = 0;
        

        // Test 5: Clear sequence
        reset_n = 0;
        @(posedge clk);
        
        @(posedge clk);
        reset_n = 1;


        // Test 6: Sleep sequence
        frame = 1;
        @(posedge clk);
        frame = 0;
        all_zeros = 1;
        @(posedge clk);
        
        
        all_zeros = 0;
        @(posedge clk);
        $finish;
    end

/*     task assert_state(input int expected, string message);
        if (uut.state !== expected) begin
            $error("State error: Expected %s(%0d), Got %s(%0d) - %s",
                   state_names[expected], expected,
                   state_names[uut.state], uut.state, message);
            $finish;
        end
        print_state();
    endtask */

    initial begin
        $dumpfile("tb.vcd");
        $dumpvars(0, tb_Control);
    end
endmodule