`timescale 1ns/1ps

module tb_card_draw;
    reg clk, reset, draw_enable;
    wire [3:0] lfsr_out;
    wire [3:0] card_rank;
    wire       card_ready;

    reg [3:0] prev_lfsr_value;
    reg [3:0] expected_rank;
    reg       expected_ready;

    integer errors = 0;
    integer checks = 0;
    integer i;

    // wire the two DUTs together exactly as they'll be wired in the real design
    lfsr u_lfsr (
        .clk(clk),
        .reset(reset),
        .lfsr_out(lfsr_out)
    );

    card_draw u_card_draw (
        .clk(clk),
        .reset(reset),
        .lfsr_out(lfsr_out),
        .draw_enable(draw_enable),
        .card_rank(card_rank),
        .card_ready(card_ready)
    );

    initial begin
        clk = 0;
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

    initial begin
        reset = 1;
        draw_enable = 0;
        @(negedge clk);
        reset = 0;
        @(negedge clk);

        check("card_rank after reset", card_rank, 0);
        check("card_ready after reset", card_ready, 0);

        expected_rank  = 4'd0;   // golden model's belief of what card_rank should hold
        expected_ready = 1'b0;

        // Drive draw_enable in a pattern that covers both asserted and
        // deasserted stretches, running long enough (40 cycles > 15-state
        // LFSR period) to cross every possible LFSR value, including the
        // invalid 14/15 states, multiple times in different enable phases.
        for (i = 0; i < 40; i = i + 1) begin
            // capture the LFSR value as it stands right now -- this is
            // exactly what card_draw's next decision will actually see
            prev_lfsr_value = lfsr_out;

            draw_enable = (i % 3 != 0);   // enabled 2 out of every 3 cycles

            @(negedge clk);   // let the next posedge happen, land on the following negedge

            // golden reference model: same rule the RTL is supposed to follow
            if (draw_enable && prev_lfsr_value >= 4'd1 && prev_lfsr_value <= 4'd13) begin
                expected_rank  = prev_lfsr_value;
                expected_ready = 1'b1;
            end else begin
                expected_ready = 1'b0;
                // expected_rank intentionally unchanged -- hold behavior
            end

            check("card_rank matches reference model", card_rank, expected_rank);
            check("card_ready matches reference model", card_ready, expected_ready);
            check("card_rank never lands on 14 or 15", (card_rank == 14 || card_rank == 15), 1'b0);
        end

        // ---- mid-sequence reset ----
        reset = 1;
        @(negedge clk);
        reset = 0;
        @(negedge clk);
        check("card_rank after mid-sequence reset", card_rank, 0);
        check("card_ready after mid-sequence reset", card_ready, 0);

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
