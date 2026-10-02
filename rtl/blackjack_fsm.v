module blackjack_fsm (
    input wire clk,
    input wire reset,
    input wire deal_pulse,
    input wire hit_pulse,
    input wire stand_pulse,
	 
	 //input from wrapper module
	 input wire card_ready,
	 input wire [4:0] player_total,
	 input wire [4:0] dealer_total,
	 input wire player_bust,
	 input wire dealer_bust,
	 
	 output reg draw_enable,
	 output wire turn_select,
	 output reg [3:0] state_led,
	 output wire result_player_win,
	 output wire result_dealer_win,
	 output wire result_push
);

    localparam IDLE = 3'b000;
	 localparam DEAL_P1 = 3'b001;
	 localparam DEAL_D1 = 3'b010;
	 localparam DEAL_P2 = 3'b011;
	 localparam DEAL_D2 = 3'b100;
	 localparam PLAYER_TURN = 3'b101;
	 localparam DEALER_TURN = 3'b110;
	 localparam RESULT = 3'b111;
	 
    reg [2:0] state, next_state;
	 
	 assign turn_select = (state == DEAL_D1) || (state == DEAL_D2) || (state == DEALER_TURN);
	 
	 wire draw_request = (!draw_enable) && (
														  (state == DEAL_P1) ||
														  (state == DEAL_D1) ||
														  (state == DEAL_P2) ||
														  (state == DEAL_D2) ||
														  (state == PLAYER_TURN && hit_pulse) ||
														  (state == DEALER_TURN && dealer_total < 5'd17)
	 );
	 

    always @(*) begin
        next_state = state;

        case (state)
            IDLE: begin
                if (deal_pulse)
                    next_state = DEAL_P1;
            end 
				//each deal state holds card_draw lands a card, not timed cycles as LFSR can produce invalid ranks
				DEAL_P1: next_state = card_ready ? DEAL_D1 : DEAL_P1;
				DEAL_D1: next_state = card_ready ? DEAL_P2 : DEAL_D1;
				DEAL_P2: next_state = card_ready ? DEAL_D2 : DEAL_P2;
				DEAL_D2: next_state = card_ready ? PLAYER_TURN : DEAL_D2;
				
            PLAYER_TURN: begin
					 if (player_bust)
					     next_state = RESULT;   //Player busts go straight to result
					 else if (player_total == 5'd21) 
                    next_state = DEALER_TURN;
                else if (stand_pulse)
                    next_state = DEALER_TURN;
					 else 
						  next_state = PLAYER_TURN;
            end
            DEALER_TURN: begin
				  if (dealer_total >= 5'd17)
                next_state = RESULT;
				  else 
				    next_state = DEALER_TURN;
            end
            RESULT: begin
                next_state = RESULT;
            end
            default: begin
                next_state = IDLE;
            end 
        endcase
    end
	 
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            draw_enable <=1'b0;
        end
        else begin
            state <= next_state;
				if (card_ready)
					draw_enable <= 1'b0;
				else if (draw_request)
					draw_enable <= 1'b1;
        end
    end
	 
	 assign result_player_win = (state == RESULT) && !player_bust && (dealer_bust || (dealer_total < player_total));
	 assign result_dealer_win = (state == RESULT) && !dealer_bust && (player_bust || (player_total < dealer_total));
         assign result_push = (state == RESULT) && !player_bust && !dealer_bust && (player_total == dealer_total);
	 
	 always @(*) begin
        case (state)
            IDLE: state_led = 4'b0001;
            DEAL_D1, DEAL_P1, DEAL_P2, DEAL_D2, PLAYER_TURN: state_led = 4'b0010;
            DEALER_TURN: state_led = 4'b0100;
            RESULT: state_led = 4'b1000; 
            default: state_led = 4'b0001;
        endcase        
    end
endmodule
