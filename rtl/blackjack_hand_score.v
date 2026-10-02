module hand_score (
    input wire clk,
    input wire reset,
    input wire [4:0] value,     
    input wire is_ace,
    input wire card_valid,
    output reg [4:0] total,
    output reg bust
);
    reg [2:0] soft_aces;

    reg [5:0] raw_sum;
    reg [2:0] raw_aces;
    reg [5:0] final_sum;
    reg [2:0] final_aces;

    always @(*) begin
        raw_sum  = total + (card_valid ? value : 5'd0);
        raw_aces = soft_aces + ((card_valid && is_ace) ? 3'd1 : 3'd0);

        if (raw_sum > 6'd21 && raw_aces >= 3'd3 && raw_sum > 6'd41) begin
            final_sum  = raw_sum - 6'd30;
            final_aces = raw_aces - 3'd3;
        end else if (raw_sum > 6'd21 && raw_aces >= 3'd2 && raw_sum > 6'd31) begin
            final_sum  = raw_sum - 6'd20; 
            final_aces = raw_aces - 3'd2;
        end else if (raw_sum > 6'd21 && raw_aces >= 3'd1) begin
            final_sum  = raw_sum - 6'd10;
            final_aces = raw_aces - 3'd1;
        end else begin
            final_sum  = raw_sum;
            final_aces = raw_aces;
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            total     <= 5'd0;
            soft_aces <= 3'd0;
            bust      <= 1'b0;
        end else if (card_valid) begin
            total     <= (final_sum > 6'd31) ? 5'd31 : final_sum[4:0];
            soft_aces <= final_aces;
            bust      <= (final_sum > 6'd21);
        end
    end
endmodule