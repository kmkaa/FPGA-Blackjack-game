FPGA Blackjack game

Hardware implemented single player Blackjack game designed in Verilog for DE1SOC

- Game engine: FSM controlling initial dealing, player actions and dealer auto draw rules and automated hand comparisons
- Ace reduction- Converts soft Aces from 11 to 1 points when sum exceeds 21
- Psuedo random Card generation: LFSR with module arithmetic and valid rank logic  sampling random cards from values 1-13
- Hardware interface: 20 bit shift register debouncers and rising edge detectors on active low push buttons to eliminate switch bounce and accidental multi draws. 7 segment display for player and dealer scores with LEDs indicating turns and outcomes

Testing and verifications- Built a test bench for each module to verify its work. Ran using Modelsim

Game rules implementation
- Card Scoring: Ranks 2-10 are face value. Ranks 11, 12, 13 are jack, queen and king all count as 10. Rank 1 is ace defaulting to 11
- Ace Reduction- of a hand scores over 21, any aces counting as 11 are reduced to 1
- Dealer rule: Dealer hits on any score below 17 and stand on 17 or higher
- Win conditions: If player > 21 then player busts, dealer wins
		  Dealer > 21 then dealer busts, player wins
		  Both <= 21 then higher score wins. If tie goes into a push
