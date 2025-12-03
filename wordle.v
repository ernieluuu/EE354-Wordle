`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 11/20/2025
// File Name: wordle.v 
// Description: Core Wordle game state machine
//////////////////////////////////////////////////////////////////////////////////
module wordle(
    input clk,
    input reset,
    
    // Player inputs (directly active buttons after debouncing from top)
    input SCEN,          // Single clock enable for button presses
    input Start,         // Start game button
    input UP,
    input DOWN,
    input LEFT,
    input RIGHT,
    input CENTER,        // Confirm selection
    
    // Game state outputs (for VGA rendering)
    output reg [4:0] stored_word [0:4],      // The secret word P1 set
    
    output reg [4:0] guess_1 [0:4],          // P2's guesses
    output reg [4:0] guess_2 [0:4],
    output reg [4:0] guess_3 [0:4],
    output reg [4:0] guess_4 [0:4],
    output reg [4:0] guess_5 [0:4],
    output reg [4:0] guess_6 [0:4],
    
    output reg [1:0] g1_status [0:4],        // Color status for each guess
    output reg [1:0] g2_status [0:4],
    output reg [1:0] g3_status [0:4],
    output reg [1:0] g4_status [0:4],
    output reg [1:0] g5_status [0:4],
    output reg [1:0] g6_status [0:4],
    
    output reg [2:0] current_guess,          // Which guess (1-6) we're on
    output [3:0] game_state,                 // Current state for debug/VGA
    output [2:0] wf_pos,                     // Current letter position (for UI cursor)
    output [4:0] wf_current_word [0:4]       // Current word being edited (for UI display)
);

    // =========================================================================
    // State Definitions
    // =========================================================================
    localparam 
        INI        = 4'b0000,    // Initial state - waiting to start
        P1_SET     = 4'b0001,    // Player 1 setting secret word
        RESET_WF_1 = 4'b0010,    // Reset word_format after P1 finishes
        P2_GUESS   = 4'b0011,    // Player 2 entering guess
        RESET_WF_2 = 4'b0100,    // Reset word_format after each P2 guess
        CMP        = 4'b0101,    // Comparing guess to answer
        RESET_CMP  = 4'b0110,    // Reset compare module before comparison
        WIN        = 4'b0111,    // Player 2 won
        LOSE       = 4'b1000;    // Player 2 lost (6 guesses used)
    
    // Color status codes (matching compare.v)
    localparam
        UNCHECKED = 2'b00,
        GREEN     = 2'b01,
        YELLOW    = 2'b10,
        GRAY      = 2'b11;

    // =========================================================================
    // Internal Signals
    // =========================================================================
    reg [3:0] state;
    
    // Word Format module control
    reg wf_start;
    reg wf_reset;
    reg wf_started;              // Flag to track if start pulse was sent
    wire wf_done;
    wire [2:0] wf_pos_out;
    wire [4:0] wf_word_out [0:4];
    wire q_I_wf, q_Let_wf, q_Pos_wf;
    
    // Compare module control  
    reg cmp_start;
    reg cmp_reset;
    reg cmp_started;             // Flag to track if start pulse was sent
    wire cmp_done;
    wire [1:0] cmp_word_status [0:4];
    wire q_I_cmp, q_Green_cmp, q_YorG_cmp;
    
    // Internal guess storage for compare module
    reg [4:0] current_guess_word [0:4];
    
    // Flag to detect all green (win condition)
    wire all_green;
    assign all_green = (cmp_word_status[0] == GREEN) && 
                       (cmp_word_status[1] == GREEN) && 
                       (cmp_word_status[2] == GREEN) && 
                       (cmp_word_status[3] == GREEN) && 
                       (cmp_word_status[4] == GREEN);

    // =========================================================================
    // Module Instantiations
    // =========================================================================
    
    word_format wf_inst (
        .Clk(clk),
        .SCEN(SCEN),
        .RESET(wf_reset),
        .Start(wf_start),
        .UP(UP),
        .DOWN(DOWN),
        .LEFT(LEFT),
        .RIGHT(RIGHT),
        .CENTER(CENTER),
        .q_I(q_I_wf),
        .q_Let(q_Let_wf),
        .q_Pos(q_Pos_wf),
        .pos(wf_pos_out),
        .word_array(wf_word_out),
        .DONE(wf_done)
    );
    
    compare cmp_inst (
        .Clk(clk),
        .SCEN(SCEN),
        .RESET(cmp_reset),
        .CENTER(CENTER),
        .Start(cmp_start),
        .guess(current_guess_word),
        .answer(stored_word),
        .q_I(q_I_cmp),
        .q_Green(q_Green_cmp),
        .q_YorG(q_YorG_cmp),
        .letter_status(),           // Not used at top level
        .word_status(cmp_word_status),
        .cmp_done(cmp_done)
    );

    // =========================================================================
    // Pass-through outputs for VGA
    // =========================================================================
    assign wf_pos = wf_pos_out;
    assign wf_current_word[0] = wf_word_out[0];
    assign wf_current_word[1] = wf_word_out[1];
    assign wf_current_word[2] = wf_word_out[2];
    assign wf_current_word[3] = wf_word_out[3];
    assign wf_current_word[4] = wf_word_out[4];
    assign game_state = state;

    // =========================================================================
    // Main State Machine
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INI;
            current_guess <= 3'd1;
            
            // Reset all stored data
            stored_word[0] <= 5'd0; stored_word[1] <= 5'd0; stored_word[2] <= 5'd0;
            stored_word[3] <= 5'd0; stored_word[4] <= 5'd0;
            
            guess_1[0] <= 5'd0; guess_1[1] <= 5'd0; guess_1[2] <= 5'd0;
            guess_1[3] <= 5'd0; guess_1[4] <= 5'd0;
            guess_2[0] <= 5'd0; guess_2[1] <= 5'd0; guess_2[2] <= 5'd0;
            guess_2[3] <= 5'd0; guess_2[4] <= 5'd0;
            guess_3[0] <= 5'd0; guess_3[1] <= 5'd0; guess_3[2] <= 5'd0;
            guess_3[3] <= 5'd0; guess_3[4] <= 5'd0;
            guess_4[0] <= 5'd0; guess_4[1] <= 5'd0; guess_4[2] <= 5'd0;
            guess_4[3] <= 5'd0; guess_4[4] <= 5'd0;
            guess_5[0] <= 5'd0; guess_5[1] <= 5'd0; guess_5[2] <= 5'd0;
            guess_5[3] <= 5'd0; guess_5[4] <= 5'd0;
            guess_6[0] <= 5'd0; guess_6[1] <= 5'd0; guess_6[2] <= 5'd0;
            guess_6[3] <= 5'd0; guess_6[4] <= 5'd0;
            
            g1_status[0] <= UNCHECKED; g1_status[1] <= UNCHECKED; g1_status[2] <= UNCHECKED;
            g1_status[3] <= UNCHECKED; g1_status[4] <= UNCHECKED;
            g2_status[0] <= UNCHECKED; g2_status[1] <= UNCHECKED; g2_status[2] <= UNCHECKED;
            g2_status[3] <= UNCHECKED; g2_status[4] <= UNCHECKED;
            g3_status[0] <= UNCHECKED; g3_status[1] <= UNCHECKED; g3_status[2] <= UNCHECKED;
            g3_status[3] <= UNCHECKED; g3_status[4] <= UNCHECKED;
            g4_status[0] <= UNCHECKED; g4_status[1] <= UNCHECKED; g4_status[2] <= UNCHECKED;
            g4_status[3] <= UNCHECKED; g4_status[4] <= UNCHECKED;
            g5_status[0] <= UNCHECKED; g5_status[1] <= UNCHECKED; g5_status[2] <= UNCHECKED;
            g5_status[3] <= UNCHECKED; g5_status[4] <= UNCHECKED;
            g6_status[0] <= UNCHECKED; g6_status[1] <= UNCHECKED; g6_status[2] <= UNCHECKED;
            g6_status[3] <= UNCHECKED; g6_status[4] <= UNCHECKED;
            
            // Reset module controls
            wf_reset <= 1'b1;
            cmp_reset <= 1'b1;
            wf_start <= 1'b0;
            cmp_start <= 1'b0;
            wf_started <= 1'b0;
            cmp_started <= 1'b0;
            
            // Reset internal guess word
            current_guess_word[0] <= 5'd0;
            current_guess_word[1] <= 5'd0;
            current_guess_word[2] <= 5'd0;
            current_guess_word[3] <= 5'd0;
            current_guess_word[4] <= 5'd0;
        end
        else begin
            // Default: deassert one-shot signals
            wf_reset <= 1'b0;
            cmp_reset <= 1'b0;
            wf_start <= 1'b0;
            cmp_start <= 1'b0;
            
            case (state)
                // ---------------------------------------------------------
                // INITIAL STATE: Wait for game to start
                // ---------------------------------------------------------
                INI: begin
                    if (Start) begin
                        state <= P1_SET;
                        wf_reset <= 1'b1;      // Reset word_format for fresh start
                        wf_started <= 1'b0;    // Clear started flag
                    end
                end
                
                // ---------------------------------------------------------
                // PLAYER 1 SET: P1 enters the secret word
                // ---------------------------------------------------------
                P1_SET: begin
                    // Pulse wf_start for exactly one cycle
                    if (!wf_started) begin
                        wf_start <= 1'b1;      // Single pulse
                        wf_started <= 1'b1;    // Mark that we've started
                    end
                    else begin
                        wf_start <= 1'b0;      // Keep low after pulse
                    end
                    
                    if (wf_done) begin
                        // Capture the word P1 set
                        stored_word[0] <= wf_word_out[0];
                        stored_word[1] <= wf_word_out[1];
                        stored_word[2] <= wf_word_out[2];
                        stored_word[3] <= wf_word_out[3];
                        stored_word[4] <= wf_word_out[4];
                        
                        // Go to reset state before P2's turn
                        state <= RESET_WF_1;
                        wf_reset <= 1'b1;      // Assert reset
                        current_guess <= 3'd1; // Initialize guess counter
                    end
                end
                
                // ---------------------------------------------------------
                // RESET_WF_1: Wait state after P1 finishes, before P2 starts
                // ---------------------------------------------------------
                RESET_WF_1: begin
                    wf_reset <= 1'b0;          // Deassert reset
                    wf_started <= 1'b0;        // Clear started flag for P2
                    state <= P2_GUESS;         // Now safe to continue
                end
                
                // ---------------------------------------------------------
                // PLAYER 2 GUESS: P2 enters a guess
                // ---------------------------------------------------------
                P2_GUESS: begin
                    // Issue 1 Fix: Pulse wf_start for exactly one cycle
                    if (!wf_started) begin
                        wf_start <= 1'b1;      // Single pulse
                        wf_started <= 1'b1;    // Mark that we've started
                    end
                    else begin
                        wf_start <= 1'b0;      // Keep low after pulse
                    end
                    
                    if (wf_done) begin
                        // Capture current guess into internal register for compare
                        current_guess_word[0] <= wf_word_out[0];
                        current_guess_word[1] <= wf_word_out[1];
                        current_guess_word[2] <= wf_word_out[2];
                        current_guess_word[3] <= wf_word_out[3];
                        current_guess_word[4] <= wf_word_out[4];
                        
                        // Store in the appropriate guess register for VGA display
                        case (current_guess)
                            3'd1: begin
                                guess_1[0] <= wf_word_out[0]; guess_1[1] <= wf_word_out[1];
                                guess_1[2] <= wf_word_out[2]; guess_1[3] <= wf_word_out[3];
                                guess_1[4] <= wf_word_out[4];
                            end
                            3'd2: begin
                                guess_2[0] <= wf_word_out[0]; guess_2[1] <= wf_word_out[1];
                                guess_2[2] <= wf_word_out[2]; guess_2[3] <= wf_word_out[3];
                                guess_2[4] <= wf_word_out[4];
                            end
                            3'd3: begin
                                guess_3[0] <= wf_word_out[0]; guess_3[1] <= wf_word_out[1];
                                guess_3[2] <= wf_word_out[2]; guess_3[3] <= wf_word_out[3];
                                guess_3[4] <= wf_word_out[4];
                            end
                            3'd4: begin
                                guess_4[0] <= wf_word_out[0]; guess_4[1] <= wf_word_out[1];
                                guess_4[2] <= wf_word_out[2]; guess_4[3] <= wf_word_out[3];
                                guess_4[4] <= wf_word_out[4];
                            end
                            3'd5: begin
                                guess_5[0] <= wf_word_out[0]; guess_5[1] <= wf_word_out[1];
                                guess_5[2] <= wf_word_out[2]; guess_5[3] <= wf_word_out[3];
                                guess_5[4] <= wf_word_out[4];
                            end
                            3'd6: begin
                                guess_6[0] <= wf_word_out[0]; guess_6[1] <= wf_word_out[1];
                                guess_6[2] <= wf_word_out[2]; guess_6[3] <= wf_word_out[3];
                                guess_6[4] <= wf_word_out[4];
                            end
                        endcase
                        
                        // Go to reset compare state before comparison
                        state <= RESET_CMP;
                        cmp_reset <= 1'b1;     // Assert reset for compare module
                    end
                end
                
                // ---------------------------------------------------------
                // RESET_CMP: Wait state to reset compare module before use
                // ---------------------------------------------------------
                RESET_CMP: begin
                    cmp_reset <= 1'b0;         // Deassert reset
                    cmp_started <= 1'b0;       // Clear started flag
                    state <= CMP;              // Now safe to compare
                end
                
                // ---------------------------------------------------------
                // COMPARE: Compare the guess to the answer
                // ---------------------------------------------------------
                CMP: begin
                    // Issue 1 Fix: Pulse cmp_start for exactly one cycle
                    if (!cmp_started) begin
                        cmp_start <= 1'b1;     // Single pulse
                        cmp_started <= 1'b1;   // Mark that we've started
                    end
                    else begin
                        cmp_start <= 1'b0;     // Keep low after pulse
                    end
                    
                    if (cmp_done) begin
                        // Store the comparison results in appropriate status register
                        case (current_guess)
                            3'd1: begin
                                g1_status[0] <= cmp_word_status[0];
                                g1_status[1] <= cmp_word_status[1];
                                g1_status[2] <= cmp_word_status[2];
                                g1_status[3] <= cmp_word_status[3];
                                g1_status[4] <= cmp_word_status[4];
                            end
                            3'd2: begin
                                g2_status[0] <= cmp_word_status[0];
                                g2_status[1] <= cmp_word_status[1];
                                g2_status[2] <= cmp_word_status[2];
                                g2_status[3] <= cmp_word_status[3];
                                g2_status[4] <= cmp_word_status[4];
                            end
                            3'd3: begin
                                g3_status[0] <= cmp_word_status[0];
                                g3_status[1] <= cmp_word_status[1];
                                g3_status[2] <= cmp_word_status[2];
                                g3_status[3] <= cmp_word_status[3];
                                g3_status[4] <= cmp_word_status[4];
                            end
                            3'd4: begin
                                g4_status[0] <= cmp_word_status[0];
                                g4_status[1] <= cmp_word_status[1];
                                g4_status[2] <= cmp_word_status[2];
                                g4_status[3] <= cmp_word_status[3];
                                g4_status[4] <= cmp_word_status[4];
                            end
                            3'd5: begin
                                g5_status[0] <= cmp_word_status[0];
                                g5_status[1] <= cmp_word_status[1];
                                g5_status[2] <= cmp_word_status[2];
                                g5_status[3] <= cmp_word_status[3];
                                g5_status[4] <= cmp_word_status[4];
                            end
                            3'd6: begin
                                g6_status[0] <= cmp_word_status[0];
                                g6_status[1] <= cmp_word_status[1];
                                g6_status[2] <= cmp_word_status[2];
                                g6_status[3] <= cmp_word_status[3];
                                g6_status[4] <= cmp_word_status[4];
                            end
                        endcase
                        
                        // Check win/lose conditions
                        if (all_green) begin
                            state <= WIN;
                        end
                        else if (current_guess == 3'd6) begin
                            state <= LOSE;
                        end
                        else begin
                            // Prepare for next guess
                            current_guess <= current_guess + 1;
                            state <= RESET_WF_2;
                            wf_reset <= 1'b1;  // Reset word_format for next guess
                        end
                    end
                end
                
                // ---------------------------------------------------------
                // RESET_WF_2: Wait state between P2 guesses
                // ---------------------------------------------------------
                RESET_WF_2: begin
                    wf_reset <= 1'b0;          // Deassert reset
                    wf_started <= 1'b0;        // Clear started flag for next guess
                    state <= P2_GUESS;         // Back to guessing
                end
                
                // ---------------------------------------------------------
                // WIN: Player 2 guessed correctly
                // ---------------------------------------------------------
                WIN: begin
                    // Game over - P2 wins
                    // Wait for Start button to reset and play again
                    if (Start) begin
                        // Reset everything for a new game
                        state <= INI;
                        current_guess <= 3'd1;
                        wf_started <= 1'b0;
                        cmp_started <= 1'b0;
                        
                        // Clear all guesses
                        guess_1[0] <= 5'd0; guess_1[1] <= 5'd0; guess_1[2] <= 5'd0;
                        guess_1[3] <= 5'd0; guess_1[4] <= 5'd0;
                        guess_2[0] <= 5'd0; guess_2[1] <= 5'd0; guess_2[2] <= 5'd0;
                        guess_2[3] <= 5'd0; guess_2[4] <= 5'd0;
                        guess_3[0] <= 5'd0; guess_3[1] <= 5'd0; guess_3[2] <= 5'd0;
                        guess_3[3] <= 5'd0; guess_3[4] <= 5'd0;
                        guess_4[0] <= 5'd0; guess_4[1] <= 5'd0; guess_4[2] <= 5'd0;
                        guess_4[3] <= 5'd0; guess_4[4] <= 5'd0;
                        guess_5[0] <= 5'd0; guess_5[1] <= 5'd0; guess_5[2] <= 5'd0;
                        guess_5[3] <= 5'd0; guess_5[4] <= 5'd0;
                        guess_6[0] <= 5'd0; guess_6[1] <= 5'd0; guess_6[2] <= 5'd0;
                        guess_6[3] <= 5'd0; guess_6[4] <= 5'd0;
                        
                        // Clear all statuses
                        g1_status[0] <= UNCHECKED; g1_status[1] <= UNCHECKED; g1_status[2] <= UNCHECKED;
                        g1_status[3] <= UNCHECKED; g1_status[4] <= UNCHECKED;
                        g2_status[0] <= UNCHECKED; g2_status[1] <= UNCHECKED; g2_status[2] <= UNCHECKED;
                        g2_status[3] <= UNCHECKED; g2_status[4] <= UNCHECKED;
                        g3_status[0] <= UNCHECKED; g3_status[1] <= UNCHECKED; g3_status[2] <= UNCHECKED;
                        g3_status[3] <= UNCHECKED; g3_status[4] <= UNCHECKED;
                        g4_status[0] <= UNCHECKED; g4_status[1] <= UNCHECKED; g4_status[2] <= UNCHECKED;
                        g4_status[3] <= UNCHECKED; g4_status[4] <= UNCHECKED;
                        g5_status[0] <= UNCHECKED; g5_status[1] <= UNCHECKED; g5_status[2] <= UNCHECKED;
                        g5_status[3] <= UNCHECKED; g5_status[4] <= UNCHECKED;
                        g6_status[0] <= UNCHECKED; g6_status[1] <= UNCHECKED; g6_status[2] <= UNCHECKED;
                        g6_status[3] <= UNCHECKED; g6_status[4] <= UNCHECKED;
                    end
                end
                
                // ---------------------------------------------------------
                // LOSE: Player 2 ran out of guesses
                // ---------------------------------------------------------
                LOSE: begin
                    // Game over - P2 loses
                    // Wait for Start button to reset and play again
                    if (Start) begin
                        // Reset everything for a new game
                        state <= INI;
                        current_guess <= 3'd1;
                        wf_started <= 1'b0;
                        cmp_started <= 1'b0;
                        
                        // Clear all guesses
                        guess_1[0] <= 5'd0; guess_1[1] <= 5'd0; guess_1[2] <= 5'd0;
                        guess_1[3] <= 5'd0; guess_1[4] <= 5'd0;
                        guess_2[0] <= 5'd0; guess_2[1] <= 5'd0; guess_2[2] <= 5'd0;
                        guess_2[3] <= 5'd0; guess_2[4] <= 5'd0;
                        guess_3[0] <= 5'd0; guess_3[1] <= 5'd0; guess_3[2] <= 5'd0;
                        guess_3[3] <= 5'd0; guess_3[4] <= 5'd0;
                        guess_4[0] <= 5'd0; guess_4[1] <= 5'd0; guess_4[2] <= 5'd0;
                        guess_4[3] <= 5'd0; guess_4[4] <= 5'd0;
                        guess_5[0] <= 5'd0; guess_5[1] <= 5'd0; guess_5[2] <= 5'd0;
                        guess_5[3] <= 5'd0; guess_5[4] <= 5'd0;
                        guess_6[0] <= 5'd0; guess_6[1] <= 5'd0; guess_6[2] <= 5'd0;
                        guess_6[3] <= 5'd0; guess_6[4] <= 5'd0;
                        
                        // Clear all statuses
                        g1_status[0] <= UNCHECKED; g1_status[1] <= UNCHECKED; g1_status[2] <= UNCHECKED;
                        g1_status[3] <= UNCHECKED; g1_status[4] <= UNCHECKED;
                        g2_status[0] <= UNCHECKED; g2_status[1] <= UNCHECKED; g2_status[2] <= UNCHECKED;
                        g2_status[3] <= UNCHECKED; g2_status[4] <= UNCHECKED;
                        g3_status[0] <= UNCHECKED; g3_status[1] <= UNCHECKED; g3_status[2] <= UNCHECKED;
                        g3_status[3] <= UNCHECKED; g3_status[4] <= UNCHECKED;
                        g4_status[0] <= UNCHECKED; g4_status[1] <= UNCHECKED; g4_status[2] <= UNCHECKED;
                        g4_status[3] <= UNCHECKED; g4_status[4] <= UNCHECKED;
                        g5_status[0] <= UNCHECKED; g5_status[1] <= UNCHECKED; g5_status[2] <= UNCHECKED;
                        g5_status[3] <= UNCHECKED; g5_status[4] <= UNCHECKED;
                        g6_status[0] <= UNCHECKED; g6_status[1] <= UNCHECKED; g6_status[2] <= UNCHECKED;
                        g6_status[3] <= UNCHECKED; g6_status[4] <= UNCHECKED;
                    end
                end
                
                // ---------------------------------------------------------
                // DEFAULT: Safety catch
                // ---------------------------------------------------------
                default: begin
                    state <= INI;
                end
            endcase
        end
    end

endmodule