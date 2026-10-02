module lfsr (
	input wire clk,
	input wire reset,
	output wire [3:0] lfsr_out
);
	reg [4:1] r; //4-bit shift reg
	
	wire feedback = r[4] ^ r[3]; //combinational logic xor gate
	
	always @(posedge clk) begin
		if (reset)
			r <= 4'hA; //chosen arbitually 
		else 
			r <= {r[3:1], feedback}; //shift left, feedback goes to bit 1
	end 
	
	assign lfsr_out = r[4:1];
	
endmodule
