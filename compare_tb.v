//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 12/03/2025
// File Name: compare_tb.v
// Description: Testbench for compare.v module (Wordle comparison logic)
//              Vivado-compatible version (no SystemVerilog unpacked arrays)
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
//`default_nettype none

module compare_tb;

    // =========================================================================
    // Testbench Signals
    // =========================================================================
   
    // Inputs to UUT
    reg Clk_tb;
    reg RESET_tb;
    reg Start_tb;
    reg [4:0] guess0_tb, guess1_tb, guess2_tb, guess3_tb, guess4_tb;
    reg [4:0] answer0_tb, answer1_tb, answer2_tb, answer3_tb, answer4_tb;
   
    // Outputs from UUT
    wire q_I_tb;
    wire q_Green_tb;
    wire q_YorG_tb;
    wire [1:0] word_status0_tb, word_status1_tb, word_status2_tb, word_status3_tb, word_status4_tb;
    wire cmp_done_tb;
   
    // Testbench variables
    reg [5*8:1] state_string;  // 5 character state string for waveform display
    integer Clk_cnt, file_results;
    integer Start_clock_count, Clocks_taken;
    reg [3:0] test_number;
    reg [3:0] pass_count, fail_count;
   
    // Expected results for verification
    reg [1:0] expected_status0, expected_status1, expected_status2, expected_status3, expected_status4;
    reg test_passed;
   
    // Parameters
    localparam CLK_PERIOD = 20;
   
    // Color codes for display
    localparam [1:0] UNCHECKED = 2'b00;
    localparam [1:0] GREEN     = 2'b01;
    localparam [1:0] YELLOW    = 2'b10;
    localparam [1:0] GRAY      = 2'b11;

    // =========================================================================
    // Unit Under Test (UUT) Instantiation
    // =========================================================================
    compare UUT (
        .Clk(Clk_tb),
        .RESET(RESET_tb),
        .Start(Start_tb),
        .guess0(guess0_tb),
        .guess1(guess1_tb),
        .guess2(guess2_tb),
        .guess3(guess3_tb),
        .guess4(guess4_tb),
        .answer0(answer0_tb),
        .answer1(answer1_tb),
        .answer2(answer2_tb),
        .answer3(answer3_tb),
        .answer4(answer4_tb),
        .q_I(q_I_tb),
        .q_Green(q_Green_tb),
        .q_YorG(q_YorG_tb),
        .word_status0(word_status0_tb),
        .word_status1(word_status1_tb),
        .word_status2(word_status2_tb),
        .word_status3(word_status3_tb),
        .word_status4(word_status4_tb),
        .cmp_done(cmp_done_tb)
    );

    // =========================================================================
    // State String for Waveform Display
    // =========================================================================
    always @(*) begin
        case ({q_YorG_tb, q_Green_tb, q_I_tb})
            3'b001: state_string = "INI  ";
            3'b010: state_string = "GREEN";
            3'b100: state_string = "YORG ";
            default: state_string = "UNKN ";
        endcase
    end

    // =========================================================================
    // Clock Generator
    // =========================================================================
    initial begin : CLK_GENERATOR
        Clk_tb = 0;
        forever begin
            #(CLK_PERIOD/2) Clk_tb = ~Clk_tb;
        end
    end

    // =========================================================================
    // Reset Generator
    // =========================================================================
    initial begin : RESET_GENERATOR
        RESET_tb = 1;
        #(2 * CLK_PERIOD) RESET_tb = 0;
    end

    // =========================================================================
    // Clock Counter
    // =========================================================================
    initial begin : CLK_COUNTER
        Clk_cnt = 0;
        #(0.6 * CLK_PERIOD);  // Wait until a little after positive edge
        forever begin
            #(CLK_PERIOD) Clk_cnt <= Clk_cnt + 1;
        end
    end

    // =========================================================================
    // Main Stimulus
    // =========================================================================
    initial begin : STIMULUS
        file_results = $fopen("compare_tb_results.txt", "w");
        test_number = 0;
        pass_count = 0;
        fail_count = 0;
       
        // Initialize inputs
        Start_tb = 0;
        guess0_tb = 5'd0; guess1_tb = 5'd0; guess2_tb = 5'd0; guess3_tb = 5'd0; guess4_tb = 5'd0;
        answer0_tb = 5'd0; answer1_tb = 5'd0; answer2_tb = 5'd0; answer3_tb = 5'd0; answer4_tb = 5'd0;
       
        wait (!RESET_tb);    // Wait until reset is over
        @(posedge Clk_tb);   // Wait for a clock
       
        $fdisplay(file_results, " ");
        $fdisplay(file_results, "========================================");
        $fdisplay(file_results, " Compare Module Testbench Results");
        $fdisplay(file_results, "========================================");
        $fdisplay(file_results, " ");
        $display(" ");
        $display("========================================");
        $display(" Compare Module Testbench Results");
        $display("========================================");
       
        // =====================================================================
        // Test #1: Perfect match (all GREEN) - "HELLO" vs "HELLO"
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Perfect match - HELLO vs HELLO (expect all GREEN)", test_number);
        $display("\nTest #%0d: Perfect match - HELLO vs HELLO", test_number);
       
        expected_status0 = GREEN; expected_status1 = GREEN; expected_status2 = GREEN;
        expected_status3 = GREEN; expected_status4 = GREEN;
       
        // H=7, E=4, L=11, L=11, O=14
        run_comparison_test(
            5'd7, 5'd4, 5'd11, 5'd11, 5'd14,   // guess: HELLO
            5'd7, 5'd4, 5'd11, 5'd11, 5'd14    // answer: HELLO
        );
       
        // =====================================================================
        // Test #2: All wrong (all GRAY) - "ABCDE" vs "FGHIJ"
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: All wrong - ABCDE vs FGHIJ (expect all GRAY)", test_number);
        $display("\nTest #%0d: All wrong - ABCDE vs FGHIJ", test_number);
       
        expected_status0 = GRAY; expected_status1 = GRAY; expected_status2 = GRAY;
        expected_status3 = GRAY; expected_status4 = GRAY;
       
        run_comparison_test(
            5'd0, 5'd1, 5'd2, 5'd3, 5'd4,      // guess: ABCDE
            5'd5, 5'd6, 5'd7, 5'd8, 5'd9       // answer: FGHIJ
        );
       
        // =====================================================================
        // Test #3: Mixed - "WEARY" vs "REEDY" (GREEN, YELLOW, GRAY mix)
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Mixed colors - WEARY vs REEDY", test_number);
        $display("\nTest #%0d: Mixed colors - WEARY vs REEDY", test_number);
       
        // W=22, E=4, A=0, R=17, Y=24
        // R=17, E=4, E=4, D=3, Y=24
        expected_status0 = GRAY; expected_status1 = GREEN; expected_status2 = GRAY;
        expected_status3 = YELLOW; expected_status4 = GREEN;
       
        run_comparison_test(
            5'd22, 5'd4, 5'd0, 5'd17, 5'd24,   // guess: WEARY
            5'd17, 5'd4, 5'd4, 5'd3, 5'd24     // answer: REEDY
        );
       
        // =====================================================================
        // Test #4: All YELLOW - "ABCDE" vs "EABCD" (rotated)
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: All yellow - ABCDE vs EABCD (rotated)", test_number);
        $display("\nTest #%0d: All yellow - ABCDE vs EABCD", test_number);
       
        expected_status0 = YELLOW; expected_status1 = YELLOW; expected_status2 = YELLOW;
        expected_status3 = YELLOW; expected_status4 = YELLOW;
       
        run_comparison_test(
            5'd0, 5'd1, 5'd2, 5'd3, 5'd4,      // guess: ABCDE
            5'd4, 5'd0, 5'd1, 5'd2, 5'd3       // answer: EABCD
        );
       
        // =====================================================================
        // Test #5: Duplicate letters - "SPEED" vs "CREEP"
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Duplicate letters - SPEED vs CREEP", test_number);
        $display("\nTest #%0d: Duplicate letters - SPEED vs CREEP", test_number);
       
        // S=18, P=15, E=4, E=4, D=3
        // C=2, R=17, E=4, E=4, P=15
        expected_status0 = GRAY; expected_status1 = YELLOW; expected_status2 = GREEN;
        expected_status3 = GREEN; expected_status4 = GRAY;
       
        run_comparison_test(
            5'd18, 5'd15, 5'd4, 5'd4, 5'd3,    // guess: SPEED
            5'd2, 5'd17, 5'd4, 5'd4, 5'd15     // answer: CREEP
        );
       
        // =====================================================================
        // Test #6: First letter correct only - "HELLO" vs "HABIT"
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: First letter only - HELLO vs HABIT", test_number);
        $display("\nTest #%0d: First letter only - HELLO vs HABIT", test_number);
       
        // H=7, E=4, L=11, L=11, O=14
        // H=7, A=0, B=1, I=8, T=19
        expected_status0 = GREEN; expected_status1 = GRAY; expected_status2 = GRAY;
        expected_status3 = GRAY; expected_status4 = GRAY;
       
        run_comparison_test(
            5'd7, 5'd4, 5'd11, 5'd11, 5'd14,   // guess: HELLO
            5'd7, 5'd0, 5'd1, 5'd8, 5'd19      // answer: HABIT
        );
       
        // =====================================================================
        // Test #7: Tricky duplicate - "AABBB" vs "BBBAA"
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Tricky duplicate - AABBB vs BBBAA", test_number);
        $display("\nTest #%0d: Tricky duplicate - AABBB vs BBBAA", test_number);
       
        // Position 2: B matches B exactly -> GREEN
        expected_status0 = YELLOW; expected_status1 = YELLOW; expected_status2 = GREEN;
        expected_status3 = YELLOW; expected_status4 = YELLOW;
       
        run_comparison_test(
            5'd0, 5'd0, 5'd1, 5'd1, 5'd1,      // guess: AABBB
            5'd1, 5'd1, 5'd1, 5'd0, 5'd0       // answer: BBBAA
        );
       
        // =====================================================================
        // Test #8: Single letter repeated - "AAAAA" vs "AXXXX"
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Single match in repeats - AAAAA vs AXXXX", test_number);
        $display("\nTest #%0d: Single match in repeats - AAAAA vs AXXXX", test_number);
       
        // A=0, X=23
        expected_status0 = GREEN; expected_status1 = GRAY; expected_status2 = GRAY;
        expected_status3 = GRAY; expected_status4 = GRAY;
       
        run_comparison_test(
            5'd0, 5'd0, 5'd0, 5'd0, 5'd0,      // guess: AAAAA
            5'd0, 5'd23, 5'd23, 5'd23, 5'd23   // answer: AXXXX
        );
       
        // =====================================================================
        // Test #9: Yellow over-matching test - "XXXAA" vs "AXXXX"
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Yellow over-match test - XXXAA vs AXXXX", test_number);
        $display("\nTest #%0d: Yellow over-match test - XXXAA vs AXXXX", test_number);
       
        expected_status0 = YELLOW; expected_status1 = GREEN; expected_status2 = GREEN;
        expected_status3 = YELLOW; expected_status4 = GRAY;
       
        run_comparison_test(
            5'd23, 5'd23, 5'd23, 5'd0, 5'd0,   // guess: XXXAA
            5'd0, 5'd23, 5'd23, 5'd23, 5'd23   // answer: AXXXX
        );
       
        // =====================================================================
        // Test #10: Back-to-back tests without reset
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Back-to-back test (no reset) - WORLD vs WORDS", test_number);
        $display("\nTest #%0d: Back-to-back test (no reset) - WORLD vs WORDS", test_number);
       
        // W=22, O=14, R=17, L=11, D=3
        // W=22, O=14, R=17, D=3, S=18
        expected_status0 = GREEN; expected_status1 = GREEN; expected_status2 = GREEN;
        expected_status3 = GRAY; expected_status4 = YELLOW;
       
        run_comparison_test(
            5'd22, 5'd14, 5'd17, 5'd11, 5'd3,  // guess: WORLD
            5'd22, 5'd14, 5'd17, 5'd3, 5'd18   // answer: WORDS
        );
       
        // =====================================================================
        // Finish up
        // =====================================================================
        $fdisplay(file_results, " ");
        $fdisplay(file_results, "========================================");
        $fdisplay(file_results, "Test Summary: %0d passed, %0d failed out of %0d tests",
                  pass_count, fail_count, test_number);
        $fdisplay(file_results, "========================================");
        $fclose(file_results);
       
        $display("\n========================================");
        $display("Test Summary: %0d passed, %0d failed out of %0d tests",
                 pass_count, fail_count, test_number);
        $display("Inspect the text file compare_tb_results.txt");
        $display("Current Clock Count = %0d", Clk_cnt);
        $display("========================================\n");
       
        #(5 * CLK_PERIOD);
        $finish;
    end

    // =========================================================================
    // Task: Run a comparison test
    // =========================================================================
    task run_comparison_test;
        input [4:0] g0, g1, g2, g3, g4;  // Guess word
        input [4:0] a0, a1, a2, a3, a4;  // Answer word
       
        integer timeout_cnt;
       
        begin
            @(posedge Clk_tb);
            #2;
           
            // Set up the guess and answer
            guess0_tb = g0; guess1_tb = g1; guess2_tb = g2;
            guess3_tb = g3; guess4_tb = g4;
            answer0_tb = a0; answer1_tb = a1; answer2_tb = a2;
            answer3_tb = a3; answer4_tb = a4;
           
            @(posedge Clk_tb);
           
            // Generate Start pulse
            Start_tb = 1;
            Start_clock_count = Clk_cnt;
            @(posedge Clk_tb);
            Start_tb = 0;
           
            // Wait for comparison to complete (with timeout)
            timeout_cnt = 0;
            while (!cmp_done_tb && timeout_cnt < 100) begin
                @(posedge Clk_tb);
                timeout_cnt = timeout_cnt + 1;
            end
           
            if (timeout_cnt >= 100) begin
                $display("ERROR: Test #%0d TIMEOUT! state=%s I=%0d J=%0d",
                         test_number, state_string, UUT.I, UUT.J);
                $fdisplay(file_results, "ERROR: Test #%0d TIMEOUT!", test_number);
                fail_count = fail_count + 1;
            end
            else begin
                #5;
                Clocks_taken = Clk_cnt - Start_clock_count;
               
                // Verify results against expected
                test_passed = (word_status0_tb === expected_status0) &&
                              (word_status1_tb === expected_status1) &&
                              (word_status2_tb === expected_status2) &&
                              (word_status3_tb === expected_status3) &&
                              (word_status4_tb === expected_status4);
               
                // Display results
                display_results();
               
                if (test_passed) begin
                    $display("  RESULT: PASS");
                    $fdisplay(file_results, "  RESULT: PASS");
                    pass_count = pass_count + 1;
                end
                else begin
                    $display("  RESULT: FAIL");
                    $fdisplay(file_results, "  RESULT: FAIL");
                    fail_count = fail_count + 1;
                end
               
                $fdisplay(file_results, "  Clocks taken = %0d", Clocks_taken);
                $fdisplay(file_results, " ");
                $display("  Clocks taken = %0d", Clocks_taken);
            end
           
            // Wait a bit before next test
            #(2 * CLK_PERIOD);
        end
    endtask

    // =========================================================================
    // Task: Display comparison results
    // =========================================================================
    task display_results;
        reg [5*8:1] color_str0, color_str1, color_str2, color_str3, color_str4;
        reg [5*8:1] exp_str0, exp_str1, exp_str2, exp_str3, exp_str4;
       
        begin
            // Convert actual statuses to strings
            color_str0 = status_to_string(word_status0_tb);
            color_str1 = status_to_string(word_status1_tb);
            color_str2 = status_to_string(word_status2_tb);
            color_str3 = status_to_string(word_status3_tb);
            color_str4 = status_to_string(word_status4_tb);
           
            // Convert expected statuses to strings
            exp_str0 = status_to_string(expected_status0);
            exp_str1 = status_to_string(expected_status1);
            exp_str2 = status_to_string(expected_status2);
            exp_str3 = status_to_string(expected_status3);
            exp_str4 = status_to_string(expected_status4);
           
            $fdisplay(file_results, "  Pos | Guess | Answer | Got   | Expected | Match");
            $fdisplay(file_results, "  ----+-------+--------+-------+----------+------");
            $display("  Pos | Guess | Answer | Got   | Expected | Match");
            $display("  ----+-------+--------+-------+----------+------");
           
            // Position 0
            $fdisplay(file_results, "   0  |   %c   |   %c    | %s | %s  |  %s",
                      letter_to_char(guess0_tb), letter_to_char(answer0_tb),
                      color_str0, exp_str0, (word_status0_tb === expected_status0) ? "OK" : "X ");
            $display("   0  |   %c   |   %c    | %s | %s  |  %s",
                     letter_to_char(guess0_tb), letter_to_char(answer0_tb),
                     color_str0, exp_str0, (word_status0_tb === expected_status0) ? "OK" : "X ");
           
            // Position 1
            $fdisplay(file_results, "   1  |   %c   |   %c    | %s | %s  |  %s",
                      letter_to_char(guess1_tb), letter_to_char(answer1_tb),
                      color_str1, exp_str1, (word_status1_tb === expected_status1) ? "OK" : "X ");
            $display("   1  |   %c   |   %c    | %s | %s  |  %s",
                     letter_to_char(guess1_tb), letter_to_char(answer1_tb),
                     color_str1, exp_str1, (word_status1_tb === expected_status1) ? "OK" : "X ");
           
            // Position 2
            $fdisplay(file_results, "   2  |   %c   |   %c    | %s | %s  |  %s",
                      letter_to_char(guess2_tb), letter_to_char(answer2_tb),
                      color_str2, exp_str2, (word_status2_tb === expected_status2) ? "OK" : "X ");
            $display("   2  |   %c   |   %c    | %s | %s  |  %s",
                     letter_to_char(guess2_tb), letter_to_char(answer2_tb),
                     color_str2, exp_str2, (word_status2_tb === expected_status2) ? "OK" : "X ");
           
            // Position 3
            $fdisplay(file_results, "   3  |   %c   |   %c    | %s | %s  |  %s",
                      letter_to_char(guess3_tb), letter_to_char(answer3_tb),
                      color_str3, exp_str3, (word_status3_tb === expected_status3) ? "OK" : "X ");
            $display("   3  |   %c   |   %c    | %s | %s  |  %s",
                     letter_to_char(guess3_tb), letter_to_char(answer3_tb),
                     color_str3, exp_str3, (word_status3_tb === expected_status3) ? "OK" : "X ");
           
            // Position 4
            $fdisplay(file_results, "   4  |   %c   |   %c    | %s | %s  |  %s",
                      letter_to_char(guess4_tb), letter_to_char(answer4_tb),
                      color_str4, exp_str4, (word_status4_tb === expected_status4) ? "OK" : "X ");
            $display("   4  |   %c   |   %c    | %s | %s  |  %s",
                     letter_to_char(guess4_tb), letter_to_char(answer4_tb),
                     color_str4, exp_str4, (word_status4_tb === expected_status4) ? "OK" : "X ");
        end
    endtask

    // =========================================================================
    // Function: Convert status to string
    // =========================================================================
    function [5*8:1] status_to_string;
        input [1:0] status;
        begin
            case (status)
                UNCHECKED: status_to_string = "UNCHK";
                GREEN:     status_to_string = "GREEN";
                YELLOW:    status_to_string = "YELLW";
                GRAY:      status_to_string = "GRAY ";
                default:   status_to_string = "?????";
            endcase
        end
    endfunction

    // =========================================================================
    // Function: Convert 5-bit letter code to ASCII character
    // =========================================================================
    function [7:0] letter_to_char;
        input [4:0] letter_code;
        begin
            letter_to_char = "A" + letter_code;  // A=0, B=1, ..., Z=25
        end
    endfunction

endmodule