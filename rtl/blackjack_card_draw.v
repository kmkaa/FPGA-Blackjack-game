module card_draw (
    input wire clk,
    input wire reset,
    input wire draw_enable,         
    input wire [15:0] lfsr_out,      
    output reg [3:0] card_rank,
    output reg [4:0] value,
    output reg is_ace,
    output reg card_ready          
);
	 reg delivered;
    wire [3:0] raw_card_in;
    assign raw_card_in = (lfsr_out[3:0] % 4'd13) + 4'd1;

    wire [4:0] calculated_value;
    assign calculated_value = (raw_card_in == 4'd1)  ? 5'd11 :  
                             (raw_card_in >= 4'd10) ? 5'd10 :  
                             {1'b0, raw_card_in};           
	
    // In card_draw.v
	always @(posedge clk) begin
		if (reset || !draw_enable) begin
			card_rank  <= 4'd0;
			card_ready <= 1'b0;
			delivered  <= 1'b0;
		end
		else if (draw_enable && !delivered) begin
			if (lfsr_out >= 4'd1 && lfsr_out <= 4'd13) begin
				card_rank  <= lfsr_out;
				card_ready <= 1'b1;
            delivered  <= 1'b1;
        end else begin
            card_ready <= 1'b0; 
        end
		end else begin
        card_ready <= 1'b0;
    end
end

endmodule