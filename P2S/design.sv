module P2S (
    input  logic        SCLK,      // System clock (26.88 MHz)
    input  logic        FRAME,     // Frame signal to start transmission
    input   logic EN,
    input  logic        CLR,       // Asynchronous clear (active high)
    input  logic [39:0] PDATAIN_L,   // 40-bit parallel input (MSB-first: PDATAIN[39] = sign bit)
    input logic [39:0] PDATAIN_R,
    output logic        DATAOUT_L,   // Serial output (MSB-first)
    output logic        DATAOUT_R,
    output logic        OutReady   // High during 40-cycle transmission
);

    logic [39:0] shift_reg_l;
    logic [39:0] shift_reg_r;
    logic [5:0]  count;
    logic        shifting;
    logic        frame_d;

    always_ff @(posedge SCLK or posedge CLR) begin
        if (CLR) begin
            shift_reg_l <= 40'd0;
            shift_reg_r <= 40'd0;
            count     <= 6'd0;
            shifting  <= 1'b0;
            DATAOUT_L   <= 1'b0;
            DATAOUT_R <= 1'b0;
            frame_d   <= 1'b0;
        end else begin
            if (EN) begin
                frame_d <= FRAME;

                // Detect rising edge of FRAME
                if (FRAME && !frame_d && !shifting) begin
                    shift_reg_l <= PDATAIN_L;
                    shift_reg_r <= PDATAIN_R;
                    count     <= 6'd0;
                    shifting  <= 1'b1;
                    DATAOUT_L   <= PDATAIN_L[39];  // Output MSB first
                    DATAOUT_R <= PDATAIN_R[39];
                end else if (shifting) begin
                    count     <= count + 1;
                    shift_reg_l <= {shift_reg_l[38:0], 1'b0};  // Shift left
                    shift_reg_r <= {shift_reg_r[38:0], 1'b0};
                    DATAOUT_L   <= shift_reg_l[38];            // Next MSB
                    DATAOUT_R <= shift_reg_r[38];
                    if (count == 6'd39) begin
                        shifting <= 1'b0;
                    end
                end
            end
        end
    end

    assign OutReady = shifting;

endmodule
