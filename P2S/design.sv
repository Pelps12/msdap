module P2S (
    input  logic        SCLK,      // System clock (26.88 MHz)
    input  logic        FRAME,     // Frame signal to start transmission
    input   logic EN,
    input  logic        CLR,       // Asynchronous clear (active high)
    input  logic [39:0] PDATAIN,   // 40-bit parallel input (MSB-first: PDATAIN[39] = sign bit)
    output logic        DATAOUT,   // Serial output (MSB-first)
    output logic        OutReady   // High during 40-cycle transmission
);

    logic [39:0] shift_reg;
    logic [5:0]  count;
    logic        shifting;
    logic        frame_d;

    always_ff @(posedge SCLK or posedge CLR) begin
        if (CLR) begin
            shift_reg <= 40'd0;
            count     <= 6'd0;
            shifting  <= 1'b0;
            DATAOUT   <= 1'b0;
            frame_d   <= 1'b0;
        end else begin
            if (EN) begin
                frame_d <= FRAME;

                // Detect rising edge of FRAME
                if (FRAME && !frame_d && !shifting) begin
                    shift_reg <= PDATAIN;
                    count     <= 6'd0;
                    shifting  <= 1'b1;
                    DATAOUT   <= PDATAIN[39];  // Output MSB first
                end else if (shifting) begin
                    count     <= count + 1;
                    shift_reg <= {shift_reg[38:0], 1'b0};  // Shift left
                    DATAOUT   <= shift_reg[38];            // Next MSB
                    if (count == 6'd39) begin
                        shifting <= 1'b0;
                    end
                end
            end
        end
    end

    assign OutReady = shifting;

endmodule
