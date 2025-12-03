//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 12/03/2025
// File Name: word_format_tb.v
// Description: Testbench for word_format.v module (Wordle letter input)
//              Tests letter selection (UP/DOWN), position changes (LEFT/RIGHT),
//              and word confirmation (CENTER)
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

module word_format_tb;

    // =========================================================================
    // Testbench Signals
    // =========================================================================
   
    // Inputs to UUT
    reg Clk_tb;
    reg SCEN_tb;
    reg RESET_tb;
    reg Start_tb;
    reg UP_tb;
    reg DOWN_tb;
    reg LEFT_tb;
    reg RIGHT_tb;
    reg CENTER_tb;
   
    // Outputs from UUT
    wire q_I_tb;
    wire q_Let_tb;
    wire q_Pos_tb;
    wire [2:0] pos_tb;
    wire [4:0] word_array0_tb, word_array1_tb, word_array2_tb, word_array3_tb, word_array4_tb;
    wire DONE_tb;
   
    // Testbench variables
    reg [4*8:1] state_string;  // 4 character state string for waveform display
    integer Clk_cnt, file_results;
    integer Start_clock_count, Clocks_taken;
    reg [3:0] test_number;
    reg [3:0] pass_count, fail_count;
   
    // Expected results
    reg [4:0] expected_word0, expected_word1, expected_word2, expected_word3, expected_word4;
    reg test_passed;
   
    // Parameters
    localparam CLK_PERIOD = 20;

    // =========================================================================
    // Unit Under Test (UUT) Instantiation
    // =========================================================================
    word_format UUT (
        .Clk(Clk_tb),
        .SCEN(SCEN_tb),
        .RESET(RESET_tb),
        .Start(Start_tb),
        .UP(UP_tb),
        .DOWN(DOWN_tb),
        .LEFT(LEFT_tb),
        .RIGHT(RIGHT_tb),
        .CENTER(CENTER_tb),
        .q_I(q_I_tb),
        .q_Let(q_Let_tb),
        .q_Pos(q_Pos_tb),
        .pos(pos_tb),
        .word_array0(word_array0_tb),
        .word_array1(word_array1_tb),
        .word_array2(word_array2_tb),
        .word_array3(word_array3_tb),
        .word_array4(word_array4_tb),
        .DONE(DONE_tb)
    );

    // =========================================================================
    // State String for Waveform Display
    // =========================================================================
    always @(*) begin
        case ({q_Pos_tb, q_Let_tb, q_I_tb})
            3'b001: state_string = "INI ";
            3'b010: state_string = "LET ";
            3'b100: state_string = "POS ";
            default: state_string = "UNKN";
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
        file_results = $fopen("word_format_tb_results.txt", "w");
        test_number = 0;
        pass_count = 0;
        fail_count = 0;
       
        // Initialize inputs
        SCEN_tb = 0;
        Start_tb = 0;
        UP_tb = 0;
        DOWN_tb = 0;
        LEFT_tb = 0;
        RIGHT_tb = 0;
        CENTER_tb = 0;
       
        wait (!RESET_tb);    // Wait until reset is over
        @(posedge Clk_tb);   // Wait for a clock
       
        $fdisplay(file_results, " ");
        $fdisplay(file_results, "========================================");
        $fdisplay(file_results, " Word Format Module Testbench Results");
        $fdisplay(file_results, "========================================");
        $fdisplay(file_results, " ");
        $display(" ");
        $display("========================================");
        $display(" Word Format Module Testbench Results");
        $display("========================================");
       
        // =====================================================================
        // Test #1: Enter "AAAAA" (default, just confirm)
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Enter AAAAA (default, just confirm)", test_number);
        $display("\nTest #%0d: Enter AAAAA (default, just confirm)", test_number);
       
        expected_word0 = 5'd0; expected_word1 = 5'd0; expected_word2 = 5'd0;
        expected_word3 = 5'd0; expected_word4 = 5'd0;
       
        // Reset and start
        reset_module();
        send_start();
       
        // Just press CENTER to confirm default AAAAA
        press_button_scen(0, 0, 0, 0, 1);  // CENTER
       
        verify_and_report();
       
        // =====================================================================
        // Test #2: Enter "HELLO" - H=7, E=4, L=11, L=11, O=14
        // State machine behavior:
        // - In LetterChange: UP/DOWN changes letter, LEFT/RIGHT goes to PosChange
        // - In PosChange: LEFT/RIGHT changes position, UP/DOWN goes to LetterChange (no letter change)
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Enter HELLO", test_number);
        $display("\nTest #%0d: Enter HELLO", test_number);
       
        expected_word0 = 5'd7;  // H
        expected_word1 = 5'd4;  // E
        expected_word2 = 5'd11; // L
        expected_word3 = 5'd11; // L
        expected_word4 = 5'd14; // O
       
        reset_module();
        send_start();
       
        // Position 0: A -> H (press UP 7 times)
        repeat(7) press_button_scen(1, 0, 0, 0, 0);  // UP x7 (A->H)
       
        // Move to position 1: RIGHT goes to PosChange, then RIGHT again moves pos
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 0->1)
        // Go back to LetterChange
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange, no letter change!)
        // Position 1: A -> E (press UP 4 times)
        repeat(4) press_button_scen(1, 0, 0, 0, 0);  // UP x4 (A->E)
       
        // Move to position 2
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 1->2)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        // Position 2: A -> L (press UP 11 times)
        repeat(11) press_button_scen(1, 0, 0, 0, 0);  // UP x11 (A->L)
       
        // Move to position 3
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 2->3)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        // Position 3: A -> L (press UP 11 times)
        repeat(11) press_button_scen(1, 0, 0, 0, 0);  // UP x11 (A->L)
       
        // Move to position 4
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 3->4)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        // Position 4: A -> O (press UP 14 times)
        repeat(14) press_button_scen(1, 0, 0, 0, 0);  // UP x14 (A->O)
       
        // Confirm
        press_button_scen(0, 0, 0, 0, 1);  // CENTER
       
        verify_and_report();
       
        // =====================================================================
        // Test #3: Test DOWN wrap-around: A -> Z
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Test DOWN wrap A->Z (enter ZAAAA)", test_number);
        $display("\nTest #%0d: Test DOWN wrap A->Z (enter ZAAAA)", test_number);
       
        expected_word0 = 5'd25; // Z
        expected_word1 = 5'd0;  // A
        expected_word2 = 5'd0;  // A
        expected_word3 = 5'd0;  // A
        expected_word4 = 5'd0;  // A
       
        reset_module();
        send_start();
       
        // Position 0: A -> Z (press DOWN 1 time, should wrap)
        press_button_scen(0, 1, 0, 0, 0);  // DOWN
       
        // Confirm
        press_button_scen(0, 0, 0, 0, 1);  // CENTER
       
        verify_and_report();
       
        // =====================================================================
        // Test #4: Test UP wrap-around: Z -> A
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Test UP wrap Z->A", test_number);
        $display("\nTest #%0d: Test UP wrap Z->A", test_number);
       
        expected_word0 = 5'd0;  // A (wrapped from Z)
        expected_word1 = 5'd0;  // A
        expected_word2 = 5'd0;  // A
        expected_word3 = 5'd0;  // A
        expected_word4 = 5'd0;  // A
       
        reset_module();
        send_start();
       
        // Position 0: A -> Z (25 times) -> A (1 more time = 26 total)
        repeat(26) press_button_scen(1, 0, 0, 0, 0);  // UP x26
       
        // Confirm
        press_button_scen(0, 0, 0, 0, 1);  // CENTER
       
        verify_and_report();
       
        // =====================================================================
        // Test #5: Test LEFT wrap-around (position 0 -> 4)
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Test LEFT wrap pos 0->4 (enter AAAAZ)", test_number);
        $display("\nTest #%0d: Test LEFT wrap pos 0->4 (enter AAAAZ)", test_number);
       
        expected_word0 = 5'd0;  // A
        expected_word1 = 5'd0;  // A
        expected_word2 = 5'd0;  // A
        expected_word3 = 5'd0;  // A
        expected_word4 = 5'd25; // Z
       
        reset_module();
        send_start();
       
        // From position 0, press LEFT to go to PosChange state
        press_button_scen(0, 0, 1, 0, 0);  // LEFT (LetterChange->PosChange)
        press_button_scen(0, 0, 1, 0, 0);  // LEFT (pos 0->4, wrap around)
       
        // Press UP to go back to LetterChange state (doesn't change letter)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
       
        // Now at position 4 with letter 'A', need to get to 'Z' (25 UPs)
        repeat(25) press_button_scen(1, 0, 0, 0, 0);  // UP x25 (A->Z)
       
        // Confirm
        press_button_scen(0, 0, 0, 0, 1);  // CENTER
       
        verify_and_report();
       
        // =====================================================================
        // Test #6: Test RIGHT wrap-around (position 4 -> 0)
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Test RIGHT wrap pos 4->0", test_number);
        $display("\nTest #%0d: Test RIGHT wrap pos 4->0", test_number);
       
        expected_word0 = 5'd1;  // B
        expected_word1 = 5'd0;  // A
        expected_word2 = 5'd0;  // A
        expected_word3 = 5'd0;  // A
        expected_word4 = 5'd0;  // A
       
        reset_module();
        send_start();
       
        // Move right - first RIGHT goes to PosChange, subsequent RIGHTs move position
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 0->1)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 1->2)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 2->3)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 3->4)
       
        // Now wrap around: position 4 -> 0
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 4->0, wrap)
       
        // Go back to LetterChange (doesn't change letter)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
       
        // Now change letter A -> B
        press_button_scen(1, 0, 0, 0, 0);  // UP (A->B)
       
        // Confirm
        press_button_scen(0, 0, 0, 0, 1);  // CENTER
       
        verify_and_report();
       
        // =====================================================================
        // Test #7: Multiple words back-to-back (tests DONE flag clearing)
        // =====================================================================
        test_number = test_number + 1;
        $fdisplay(file_results, "Test #%0d: Back-to-back words (BBBBB then CCCCC)", test_number);
        $display("\nTest #%0d: Back-to-back words (BBBBB then CCCCC)", test_number);
       
        // First word: BBBBB
        reset_module();
        send_start();
       
        // Set position 0 to B
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 0: A->B)
        // Move to pos 1
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 0->1)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 1: A->B)
        // Move to pos 2
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 1->2)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 2: A->B)
        // Move to pos 3
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 2->3)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 3: A->B)
        // Move to pos 4
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 3->4)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 4: A->B)
        // Confirm first word
        press_button_scen(0, 0, 0, 0, 1);  // CENTER
       
        $display("  First word entered: %c%c%c%c%c",
                 letter_to_char(word_array0_tb), letter_to_char(word_array1_tb),
                 letter_to_char(word_array2_tb), letter_to_char(word_array3_tb),
                 letter_to_char(word_array4_tb));
       
        // Second word: CCCCC (without full reset, just Start again)
        // Note: Start resets pos to 0, but letters remain as BBBBB
        send_start();
       
        // pos 0: B->C
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 0: B->C)
        // Move to pos 1
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 0->1)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 1: B->C)
        // Move to pos 2
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 1->2)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 2: B->C)
        // Move to pos 3
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 2->3)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 3: B->C)
        // Move to pos 4
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (LetterChange->PosChange)
        press_button_scen(0, 0, 0, 1, 0);  // RIGHT (pos 3->4)
        press_button_scen(1, 0, 0, 0, 0);  // UP (PosChange->LetterChange)
        press_button_scen(1, 0, 0, 0, 0);  // UP (pos 4: B->C)
        // Confirm
        press_button_scen(0, 0, 0, 0, 1);  // CENTER
       
        expected_word0 = 5'd2; expected_word1 = 5'd2; expected_word2 = 5'd2;
        expected_word3 = 5'd2; expected_word4 = 5'd2;
       
        verify_and_report();
       
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
        $display("Inspect the text file word_format_tb_results.txt");
        $display("Current Clock Count = %0d", Clk_cnt);
        $display("========================================\n");
       
        #(5 * CLK_PERIOD);
        $finish;
    end

    // =========================================================================
    // Task: Reset the module
    // =========================================================================
    task reset_module;
        begin
            RESET_tb = 1;
            @(posedge Clk_tb);
            @(posedge Clk_tb);
            RESET_tb = 0;
            @(posedge Clk_tb);
        end
    endtask

    // =========================================================================
    // Task: Send Start pulse
    // =========================================================================
    task send_start;
        begin
            @(posedge Clk_tb);
            Start_tb = 1;
            @(posedge Clk_tb);
            Start_tb = 0;
            @(posedge Clk_tb);
        end
    endtask

    // =========================================================================
    // Task: Press a button with SCEN (simulates debounced button press)
    // =========================================================================
    task press_button_scen;
        input up, down, left, right, center;
        begin
            @(posedge Clk_tb);
            #2;
            UP_tb = up;
            DOWN_tb = down;
            LEFT_tb = left;
            RIGHT_tb = right;
            CENTER_tb = center;
            SCEN_tb = 1;  // Single clock enable
            @(posedge Clk_tb);
            #2;
            SCEN_tb = 0;
            UP_tb = 0;
            DOWN_tb = 0;
            LEFT_tb = 0;
            RIGHT_tb = 0;
            CENTER_tb = 0;
            @(posedge Clk_tb);
        end
    endtask

    // =========================================================================
    // Task: Verify results and report
    // =========================================================================
    task verify_and_report;
        begin
            // Check if DONE is set
            if (!DONE_tb) begin
                $display("  ERROR: DONE flag not set!");
                $fdisplay(file_results, "  ERROR: DONE flag not set!");
            end
           
            // Verify word matches expected
            test_passed = (word_array0_tb === expected_word0) &&
                          (word_array1_tb === expected_word1) &&
                          (word_array2_tb === expected_word2) &&
                          (word_array3_tb === expected_word3) &&
                          (word_array4_tb === expected_word4);
           
            // Display results
            $display("  Expected: %c%c%c%c%c",
                     letter_to_char(expected_word0), letter_to_char(expected_word1),
                     letter_to_char(expected_word2), letter_to_char(expected_word3),
                     letter_to_char(expected_word4));
            $display("  Got:      %c%c%c%c%c",
                     letter_to_char(word_array0_tb), letter_to_char(word_array1_tb),
                     letter_to_char(word_array2_tb), letter_to_char(word_array3_tb),
                     letter_to_char(word_array4_tb));
           
            $fdisplay(file_results, "  Expected: %c%c%c%c%c",
                      letter_to_char(expected_word0), letter_to_char(expected_word1),
                      letter_to_char(expected_word2), letter_to_char(expected_word3),
                      letter_to_char(expected_word4));
            $fdisplay(file_results, "  Got:      %c%c%c%c%c",
                      letter_to_char(word_array0_tb), letter_to_char(word_array1_tb),
                      letter_to_char(word_array2_tb), letter_to_char(word_array3_tb),
                      letter_to_char(word_array4_tb));
           
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
           
            $fdisplay(file_results, " ");
        end
    endtask

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