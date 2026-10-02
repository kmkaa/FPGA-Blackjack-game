module card_value (
	input wire [3:0] card_rank,
	output reg [4:0] value,
	output reg is_ace
);

	always @(*) begin
		case (card_rank)
			4'd1: begin value = 5'd11; is_ace = 1'b1; end
			4'd2: begin value = 5'd2; is_ace = 1'b0; end
			4'd3: begin value = 5'd3; is_ace = 1'b0; end
			4'd4: begin value = 5'd4; is_ace = 1'b0; end
			4'd5: begin value = 5'd5; is_ace = 1'b0; end
			4'd6: begin value = 5'd6; is_ace = 1'b0; end
			4'd7: begin value = 5'd7; is_ace = 1'b0; end
			4'd8: begin value = 5'd8; is_ace = 1'b0; end
			4'd9: begin value = 5'd9; is_ace = 1'b0; end
			4'd10: begin value = 5'd10; is_ace = 1'b0; end
			4'd11: begin value = 5'd10; is_ace = 1'b0; end
			4'd12: begin value = 5'd10; is_ace = 1'b0; end
			4'd13: begin value = 5'd10; is_ace = 1'b0; end
			default: begin value = 5'd0; is_ace = 1'b0; end //invalid default case
		endcase
	end 
endmodule