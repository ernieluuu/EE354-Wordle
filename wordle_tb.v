//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 12/03/2025
// File Name: wordle_tb.v
// Description: Testbench for wordle.v (main Wordle game state machine)
//              Uses force/release shortcuts to speed up testing
//              Robust version for Vivado XSim compatibility
//
// KEY FIX: The issue with Vivado was that after forcing DONE=1 and releasing it,
// the word_format module's internal state wasn't in sync, causing DONE to stay
// high or behave unpredictably. The fix is to:
// 1. Force word_format's state to INI (which clears DONE on next clock)
// 2. Wait extra cycles after release for proper synchronization
// 3. Explicitly force DONE=0 before releasing to ensure clean handoff
//////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps
`default_nettype none

module wordle_tb;

    // =========================================================================
    // Testbench Signals
    // =========================================================================
    
    // Inputs to UUT
    reg clk;
    reg reset;
    reg SCEN;
    reg Start;
    reg UP, DOWN, LEFT, RIGHT, CENTER;
    
    // Outputs from UUT
    wire [4:0] stored_word0, stored_word1, stored_word2, stored_word3, stored_word4;
    wire [4:0] guess_1_0, guess_1_1, guess_1_2, guess_1_3, guess_1_4;
    wire [4:0] guess_2_0, guess_2_1, guess_2_2, guess_2_3, guess_2_4;
    wire [4:0] guess_3_0, guess_3_1, guess_3_2, guess_3_3, guess_3_4;
    wire [4:0] guess_4_0, guess_4_1, guess_4_2, guess_4_3, guess_4_4;
    wire [4:0] guess_5_0, guess_5_1, guess_5_2, guess_5_3, guess_5_4;
    wire [4:0] guess_6_0, guess_6_1, guess_6_2, guess_6_3, guess_6_4;
    wire [1:0] g1_status0, g1_status1, g1_status2, g1_status3, g1_status4;
    wire [1:0] g2_status0, g2_status1, g2_status2, g2_status3, g2_status4;
    wire [1:0] g3_status0, g3_status1, g3_status2, g3_status3, g3_status4;
    wire [1:0] g4_status0, g4_status1, g4_status2, g4_status3, g4_status4;
    wire [1:0] g5_status0, g5_status1, g5_status2, g5_status3, g5_status4;
    wire [1:0] g6_status0, g6_status1, g6_status2, g6_status3, g6_status4;
    wire [2:0] current_guess;
    wire [3:0] game_state;
    wire [2:0] wf_pos;
    wire [4:0] wf_current_word0, wf_current_word1, wf_current_word2, wf_current_word3, wf_current_word4;
    
    // Testbench variables
    reg [4*8:1] state_string;
    integer file_results;
    integer test_number;
    integer pass_count, fail_count;
    integer timeout_counter;
    
    // Parameters
    localparam CLK_PERIOD = 20;
    localparam TIMEOUT_CYCLES = 1000;
    
    // State definitions (must match wordle.v)
    localparam 
        INI        = 4'b0000,
        P1_SET     = 4'b0001,
        RESET_WF_1 = 4'b0010,
        P2_GUESS   = 4'b0011,
        RESET_WF_2 = 4'b0100,
        CMP        = 4'b0101,
        RESET_CMP  = 4'b0110,
        WIN        = 4'b0111,
        LOSE       = 4'b1000;
    
    // Color codes
    localparam
        UNCHECKED = 2'b00,
        GREEN     = 2'b01,
        YELLOW    = 2'b10,
        GRAY      = 2'b11;

    // =========================================================================
    // Unit Under Test (UUT) Instantiation
    // =========================================================================
    wordle UUT (
        .clk(clk),
        .reset(reset),
        .SCEN(SCEN),
        .Start(Start),
        .UP(UP), .DOWN(DOWN), .LEFT(LEFT), .RIGHT(RIGHT), .CENTER(CENTER),
        .stored_word0(stored_word0), .stored_word1(stored_word1),
        .stored_word2(stored_word2), .stored_word3(stored_word3), .stored_word4(stored_word4),
        .guess_1_0(guess_1_0), .guess_1_1(guess_1_1), .guess_1_2(guess_1_2),
        .guess_1_3(guess_1_3), .guess_1_4(guess_1_4),
        .guess_2_0(guess_2_0), .guess_2_1(guess_2_1), .guess_2_2(guess_2_2),
        .guess_2_3(guess_2_3), .guess_2_4(guess_2_4),
        .guess_3_0(guess_3_0), .guess_3_1(guess_3_1), .guess_3_2(guess_3_2),
        .guess_3_3(guess_3_3), .guess_3_4(guess_3_4),
        .guess_4_0(guess_4_0), .guess_4_1(guess_4_1), .guess_4_2(guess_4_2),
        .guess_4_3(guess_4_3), .guess_4_4(guess_4_4),
        .guess_5_0(guess_5_0), .guess_5_1(guess_5_1), .guess_5_2(guess_5_2),
        .guess_5_3(guess_5_3), .guess_5_4(guess_5_4),
        .guess_6_0(guess_6_0), .guess_6_1(guess_6_1), .guess_6_2(guess_6_2),
        .guess_6_3(guess_6_3), .guess_6_4(guess_6_4),
        .g1_status0(g1_status0), .g1_status1(g1_status1), .g1_status2(g1_status2),
        .g1_status3(g1_status3), .g1_status4(g1_status4),
        .g2_status0(g2_status0), .g2_status1(g2_status1), .g2_status2(g2_status2),
        .g2_status3(g2_status3), .g2_status4(g2_status4),
        .g3_status0(g3_status0), .g3_status1(g3_status1), .g3_status2(g3_status2),
        .g3_status3(g3_status3), .g3_status4(g3_status4),
        .g4_status0(g4_status0), .g4_status1(g4_status1), .g4_status2(g4_status2),
        .g4_status3(g4_status3), .g4_status4(g4_status4),
        .g5_status0(g5_status0), .g5_status1(g5_status1), .g5_status2(g5_status2),
        .g5_status3(g5_status3), .g5_status4(g5_status4),
        .g6_status0(g6_status0), .g6_status1(g6_status1), .g6_status2(g6_status2),
        .g6_status3(g6_status3), .g6_status4(g6_status4),
        .current_guess(current_guess),
        .game_state(game_state),
        .wf_pos(wf_pos),
        .wf_current_word0(wf_current_word0), .wf_current_word1(wf_current_word1),
        .wf_current_word2(wf_current_word2), .wf_current_word3(wf_current_word3),
        .wf_current_word4(wf_current_word4)
    );

    // =========================================================================
    // State String for Waveform Display
    // =========================================================================
    always @(*) begin
        case (game_state)
            INI:        state_string = "INI ";
            P1_SET:     state_string = "P1ST";
            RESET_WF_1: state_string = "RWF1";
            P2_GUESS:   state_string = "P2GS";
            RESET_WF_2: state_string = "RWF2";
            CMP:        state_string = "CMP ";
            RESET_CMP:  state_string = "RCMP";
            WIN:        state_string = "WIN ";
            LOSE:       state_string = "LOSE";
            default:    state_string = "????";
        endcase
    end

    // =========================================================================
    // Clock Generator
    // =========================================================================
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // =========================================================================
    // Main Test Sequence
    // =========================================================================
    initial begin
        file_results = $fopen("wordle_tb_results.txt", "w");
        test_number = 0;
        pass_count = 0;
        fail_count = 0;
        
        // Initialize signals
        reset = 1;
        SCEN = 0;
        Start = 0;
        UP = 0; DOWN = 0; LEFT = 0; RIGHT = 0; CENTER = 0;
        
        $fdisplay(file_results, " ");
        $fdisplay(file_results, "========================================");
        $fdisplay(file_results, " Wordle Module Testbench Results");
        $fdisplay(file_results, "========================================");
        $fdisplay(file_results, " ");
        $display(" ");
        $display("========================================");
        $display(" Wordle Module Testbench Results");
        $display("========================================");
        
        // Release reset
        #(2 * CLK_PERIOD);
        reset = 0;
        #(CLK_PERIOD);
        
        // =====================================================================
        // Test #1: Win on first guess (HELLO vs HELLO)
        // =====================================================================
        test_number = test_number + 1;
        $display("\n=== Test #%0d: Win on first guess (HELLO vs HELLO) ===", test_number);
        $fdisplay(file_results, "Test #%0d: Win on first guess (HELLO vs HELLO)", test_number);
        
        // Start game
        send_start_pulse();
        
        // Wait for P1_SET state and set word using force/release
        wait_for_state(P1_SET);
        set_word_fast(5'd7, 5'd4, 5'd11, 5'd11, 5'd14);  // HELLO
        
        // Wait for P2_GUESS state and guess the same word
        wait_for_state(P2_GUESS);
        set_word_fast(5'd7, 5'd4, 5'd11, 5'd11, 5'd14);  // HELLO
        
        // Wait for WIN state
        wait_for_state(WIN);
        
        // Verify results
        if (g1_status0 == GREEN && g1_status1 == GREEN && g1_status2 == GREEN &&
            g1_status3 == GREEN && g1_status4 == GREEN) begin
            $display("  RESULT: PASS - All letters GREEN, WIN state reached");
            $fdisplay(file_results, "  RESULT: PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  RESULT: FAIL - Status: %b %b %b %b %b", 
                     g1_status0, g1_status1, g1_status2, g1_status3, g1_status4);
            $fdisplay(file_results, "  RESULT: FAIL");
            fail_count = fail_count + 1;
        end
        
        // Reset for next test
        reset = 1;
        #(2 * CLK_PERIOD);
        reset = 0;
        #(CLK_PERIOD);
        
        // =====================================================================
        // Test #2: Mixed colors (HELLO vs WORLD)
        // =====================================================================
        test_number = test_number + 1;
        $display("\n=== Test #%0d: Mixed colors test ===", test_number);
        $fdisplay(file_results, "Test #%0d: Mixed colors test", test_number);
        
        send_start_pulse();
        
        // P1 sets HELLO
        wait_for_state(P1_SET);
        set_word_fast(5'd7, 5'd4, 5'd11, 5'd11, 5'd14);  // HELLO
        
        // P2 guesses WORLD (W=22, O=14, R=17, L=11, D=3)
        wait_for_state(P2_GUESS);
        set_word_fast(5'd22, 5'd14, 5'd17, 5'd11, 5'd3);  // WORLD
        
        // Wait for comparison to complete (should go to RESET_WF_2 since not all green)
        wait_for_state(RESET_WF_2);
        
        $display("  Guess 1 status: %s %s %s %s %s",
                 status_to_str(g1_status0), status_to_str(g1_status1), 
                 status_to_str(g1_status2), status_to_str(g1_status3), status_to_str(g1_status4));
        $fdisplay(file_results, "  Guess 1 status: %s %s %s %s %s",
                  status_to_str(g1_status0), status_to_str(g1_status1), 
                  status_to_str(g1_status2), status_to_str(g1_status3), status_to_str(g1_status4));
        
        // Verify we moved to guess 2
        if (current_guess == 3'd2) begin
            $display("  RESULT: PASS - Moved to guess 2");
            $fdisplay(file_results, "  RESULT: PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  RESULT: FAIL - current_guess = %0d", current_guess);
            $fdisplay(file_results, "  RESULT: FAIL");
            fail_count = fail_count + 1;
        end
        
        // Reset for next test
        reset = 1;
        #(2 * CLK_PERIOD);
        reset = 0;
        #(CLK_PERIOD);
        
        // =====================================================================
        // Test #3: Lose after 6 wrong guesses
        // =====================================================================
        test_number = test_number + 1;
        $display("\n=== Test #%0d: Lose after 6 wrong guesses ===", test_number);
        $fdisplay(file_results, "Test #%0d: Lose after 6 wrong guesses", test_number);
        
        send_start_pulse();
        
        // P1 sets HELLO
        wait_for_state(P1_SET);
        set_word_fast(5'd7, 5'd4, 5'd11, 5'd11, 5'd14);  // HELLO
        
        // P2 guesses 6 wrong words (AAAAA each time)
        repeat(6) begin
            wait_for_state(P2_GUESS);
            set_word_fast(5'd0, 5'd0, 5'd0, 5'd0, 5'd0);  // AAAAA (all wrong)
        end
        
        // Wait for LOSE state
        wait_for_state(LOSE);
        
        if (game_state == LOSE && current_guess == 3'd6) begin
            $display("  RESULT: PASS - LOSE state reached after 6 guesses");
            $fdisplay(file_results, "  RESULT: PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  RESULT: FAIL - state=%s, current_guess=%0d", state_string, current_guess);
            $fdisplay(file_results, "  RESULT: FAIL");
            fail_count = fail_count + 1;
        end
        
        // Reset for next test
        reset = 1;
        #(2 * CLK_PERIOD);
        reset = 0;
        #(CLK_PERIOD);
        
        // =====================================================================
        // Test #4: Win on 3rd guess
        // =====================================================================
        test_number = test_number + 1;
        $display("\n=== Test #%0d: Win on 3rd guess ===", test_number);
        $fdisplay(file_results, "Test #%0d: Win on 3rd guess", test_number);
        
        send_start_pulse();
        
        // P1 sets CRANE (C=2, R=17, A=0, N=13, E=4)
        wait_for_state(P1_SET);
        set_word_fast(5'd2, 5'd17, 5'd0, 5'd13, 5'd4);  // CRANE
        
        // Guess 1: AUDIO (wrong)
        wait_for_state(P2_GUESS);
        set_word_fast(5'd0, 5'd20, 5'd3, 5'd8, 5'd14);  // AUDIO
        
        // Guess 2: TEARS (wrong)
        wait_for_state(P2_GUESS);
        set_word_fast(5'd19, 5'd4, 5'd0, 5'd17, 5'd18); // TEARS
        
        // Guess 3: CRANE (correct!)
        wait_for_state(P2_GUESS);
        set_word_fast(5'd2, 5'd17, 5'd0, 5'd13, 5'd4);  // CRANE
        
        // Wait for WIN
        wait_for_state(WIN);
        
        if (game_state == WIN && current_guess == 3'd3) begin
            $display("  RESULT: PASS - Won on guess 3");
            $fdisplay(file_results, "  RESULT: PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  RESULT: FAIL - state=%s, current_guess=%0d", state_string, current_guess);
            $fdisplay(file_results, "  RESULT: FAIL");
            fail_count = fail_count + 1;
        end
        
        // Reset for next test
        reset = 1;
        #(2 * CLK_PERIOD);
        reset = 0;
        #(CLK_PERIOD);
        
        // =====================================================================
        // Test #5: Restart game from WIN state
        // =====================================================================
        test_number = test_number + 1;
        $display("\n=== Test #%0d: Restart game from WIN state ===", test_number);
        $fdisplay(file_results, "Test #%0d: Restart game from WIN state", test_number);
        
        // First, win a game
        send_start_pulse();
        wait_for_state(P1_SET);
        set_word_fast(5'd0, 5'd0, 5'd0, 5'd0, 5'd0);  // AAAAA
        wait_for_state(P2_GUESS);
        set_word_fast(5'd0, 5'd0, 5'd0, 5'd0, 5'd0);  // AAAAA
        wait_for_state(WIN);
        
        // Now press Start to restart
        send_start_pulse();
        
        // Should go back to INI
        wait_for_state(INI);
        
        // Verify game reset
        if (game_state == INI && current_guess == 3'd1 && 
            g1_status0 == UNCHECKED && guess_1_0 == 5'd0) begin
            $display("  RESULT: PASS - Game restarted from WIN");
            $fdisplay(file_results, "  RESULT: PASS");
            pass_count = pass_count + 1;
        end else begin
            $display("  RESULT: FAIL");
            $fdisplay(file_results, "  RESULT: FAIL");
            fail_count = fail_count + 1;
        end
        
        // =====================================================================
        // Summary
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
        $display("========================================\n");
        
        #(5 * CLK_PERIOD);
        $finish;
    end

    // =========================================================================
    // Task: Send Start pulse
    // =========================================================================
    task send_start_pulse;
        begin
            @(posedge clk);
            Start = 1;
            @(posedge clk);
            Start = 0;
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Task: Wait for a specific state with timeout
    // =========================================================================
    task wait_for_state;
        input [3:0] target_state;
        begin
            timeout_counter = 0;
            while (game_state != target_state && timeout_counter < TIMEOUT_CYCLES) begin
                @(posedge clk);
                timeout_counter = timeout_counter + 1;
            end
            if (timeout_counter >= TIMEOUT_CYCLES) begin
                $display("  ERROR: Timeout waiting for state %b, current state = %s", 
                         target_state, state_string);
            end
            @(posedge clk); // One extra cycle for stability
        end
    endtask

    // =========================================================================
    // Task: Set word quickly using force/release on word_format
    // ROBUST VERSION for Vivado XSim:
    // 1. Forces all values including state
    // 2. Forces DONE=0 before final release to ensure clean state
    // 3. Uses more clock cycles for synchronization
    // =========================================================================
    task set_word_fast;
        input [4:0] w0, w1, w2, w3, w4;
        begin
            // Wait for state to stabilize after entering P1_SET or P2_GUESS
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            
            // Step 1: Force word values and set DONE=1 with state=INI
            // The INI state ensures that when we release, the state machine
            // will naturally clear DONE
            force UUT.wf_inst.word_array0 = w0;
            force UUT.wf_inst.word_array1 = w1;
            force UUT.wf_inst.word_array2 = w2;
            force UUT.wf_inst.word_array3 = w3;
            force UUT.wf_inst.word_array4 = w4;
            force UUT.wf_inst.DONE = 1'b1;
            force UUT.wf_inst.state = 3'b001;  // INI state
            
            // Let wordle.v see DONE=1 and capture the word
            @(posedge clk);
            @(posedge clk);
            
            // Step 2: Keep word values but set DONE=0 before releasing
            // This ensures DONE is cleanly low when we release
            force UUT.wf_inst.DONE = 1'b0;
            
            @(posedge clk);
            
            // Step 3: Release all forces
            release UUT.wf_inst.word_array0;
            release UUT.wf_inst.word_array1;
            release UUT.wf_inst.word_array2;
            release UUT.wf_inst.word_array3;
            release UUT.wf_inst.word_array4;
            release UUT.wf_inst.DONE;
            release UUT.wf_inst.state;
            
            // Step 4: Wait for system to stabilize
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    // =========================================================================
    // Function: Convert status to string
    // =========================================================================
    function [5*8:1] status_to_str;
        input [1:0] status;
        begin
            case (status)
                UNCHECKED: status_to_str = "UNCHK";
                GREEN:     status_to_str = "GREEN";
                YELLOW:    status_to_str = "YELLW";
                GRAY:      status_to_str = "GRAY ";
                default:   status_to_str = "?????";
            endcase
        end
    endfunction

    // =========================================================================
    // Function: Convert letter code to character
    // =========================================================================
    function [7:0] letter_to_char;
        input [4:0] code;
        begin
            letter_to_char = "A" + code;
        end
    endfunction

endmodule