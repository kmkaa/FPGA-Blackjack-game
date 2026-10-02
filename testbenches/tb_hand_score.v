`timescale 1ns/1ps

module tb_hand_score;
    reg  clk, reset, card_valid;
    reg  [3:0] card_rank;
    wire [4:0] value;
    wire       is_ace;
    wire [4:0] total;
    wire       bust;

    integer errors = 0;
    integer checks = 0;

    // wire the real modules together, same as they'll be wired in the real design
    card_value u_card_value (
        .card_rank(card_rank),
        .value(value),
        .is_ace(is_ace)
    );

    hand_score u_hand_score (
        .clk(clk),
        .reset(reset),
        .value(value),
        .is_ace(is_ace),
        .card_valid(card_valid),
        .total(total),
        .bust(bust)
    );

    initial begin
        clk        = 0;
        reset      = 1;   // known state from time 0, before anything else touches the DUT
        card_valid = 0;
        card_rank  = 4'd0;
        forever #10 clk = ~clk;
    end

    task check(input [319:0] name, input [31:0] actual, input [31:0] expected);
        begin
            checks = checks + 1;
            if (actual !== expected) begin
                errors = errors + 1;
                $display("FAIL [%0s]: expected=%0d actual=%0d", name, expected, actual);
            end else begin
                $display("PASS [%0s]: value=%0d", name, actual);
            end
        end
    endtask

    // deal one card into the hand: set the rank, pulse card_valid for one clock
    task deal_card(input [3:0] rank);
        begin
            card_rank = rank;
            @(negedge clk);
            card_valid = 1;
            @(negedge clk);
            card_valid = 0;
        end
    endtask

    task do_reset;
        begin
            reset      = 1;
            card_valid = 0;
            card_rank  = 4'd0;
            @(negedge clk);
            reset = 0;
            @(negedge clk);
        end
    endtask

    initial begin
        // ================================================================
        // SECTION 1 -- card_value coverage (combinational, no clock needed)
        // Since we skipped a standalone tb_card_value.v, this exhaustively
        // checks all 13 ranks + rank 0 directly against the doc's mapping,
        // completely independent of hand_score's clocked behavior.
        // ================================================================
        card_rank = 4'd0;  #1; check("rank 0 -> value 0, not ace",  {is_ace, value}, {1'b0, 5'd0});
        card_rank = 4'd1;  #1; check("rank 1 (Ace) -> value 11, is_ace", {is_ace, value}, {1'b1, 5'd11});
        card_rank = 4'd2;  #1; check("rank 2 -> value 2",  {is_ace, value}, {1'b0, 5'd2});
        card_rank = 4'd3;  #1; check("rank 3 -> value 3",  {is_ace, value}, {1'b0, 5'd3});
        card_rank = 4'd4;  #1; check("rank 4 -> value 4",  {is_ace, value}, {1'b0, 5'd4});
        card_rank = 4'd5;  #1; check("rank 5 -> value 5",  {is_ace, value}, {1'b0, 5'd5});
        card_rank = 4'd6;  #1; check("rank 6 -> value 6",  {is_ace, value}, {1'b0, 5'd6});
        card_rank = 4'd7;  #1; check("rank 7 -> value 7",  {is_ace, value}, {1'b0, 5'd7});
        card_rank = 4'd8;  #1; check("rank 8 -> value 8",  {is_ace, value}, {1'b0, 5'd8});
        card_rank = 4'd9;  #1; check("rank 9 -> value 9",  {is_ace, value}, {1'b0, 5'd9});
        card_rank = 4'd10; #1; check("rank 10 -> value 10", {is_ace, value}, {1'b0, 5'd10});
        card_rank = 4'd11; #1; check("rank 11 (Jack) -> value 10",  {is_ace, value}, {1'b0, 5'd10});
        card_rank = 4'd12; #1; check("rank 12 (Queen) -> value 10", {is_ace, value}, {1'b0, 5'd10});
        card_rank = 4'd13; #1; check("rank 13 (King) -> value 10",  {is_ace, value}, {1'b0, 5'd10});

        // ================================================================
        // SECTION 2 -- hand_score behavior, using the exact cases from the
        // original project doc, plus the derived worst-case ace correction
        // ================================================================

        // ---- 10 + 7 = 17 (no aces involved at all) ----
        do_reset;
        deal_card(4'd10);
        deal_card(4'd7);
        check("10+7 = 17", total, 17);
        check("10+7 not bust", bust, 1'b0);

        // ---- Ace + 9 = 20 (single soft ace, no correction needed) ----
        do_reset;
        deal_card(4'd1);
        deal_card(4'd9);
        check("A+9 = 20", total, 20);
        check("A+9 not bust", bust, 1'b0);

        // ---- continue same hand: Ace + 9 + 5 = 15 (one correction fires) ----
        deal_card(4'd5);   // 11+9+5=25 -> corrects -> 15
        check("A+9+5 = 15", total, 15);
        check("A+9+5 not bust", bust, 1'b0);

        // ---- King + Queen + 2 = 22 bust (no aces, straightforward bust) ----
        do_reset;
        deal_card(4'd13);
        deal_card(4'd12);
        deal_card(4'd2);
        check("K+Q+2 = 22", total, 22);
        check("K+Q+2 busts", bust, 1'b1);

        // ---- worst-case double ace correction ----
        // build a clean hand at 21 with exactly 1 soft ace outstanding, then
        // draw a second ace: 21+11=32, needs 2 correction stages -> 12
        do_reset;
        deal_card(4'd1);    // Ace -> 11
        deal_card(4'd10);   // +10 -> 21, 1 soft ace
        check("A+10 = 21 (setup)", total, 21);
        check("A+10 not bust (setup)", bust, 1'b0);

        deal_card(4'd1);    // second Ace: 21+11=32 -> 2 corrections -> 12
        check("A+10+A double-correction = 12", total, 12);
        check("A+10+A not bust", bust, 1'b0);

        // ---- summary ----
        $display("--------------------------------------------------");
        if (errors == 0)
            $display("ALL %0d CHECKS PASSED", checks);
        else
            $display("%0d OF %0d CHECKS FAILED", errors, checks);
        $display("--------------------------------------------------");

        $finish;
    end
endmodule