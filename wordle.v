`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 11/20/2025
// File Name: wordle.v 
// Description: Core Wordle game state machine (Vivado-compatible version)
//////////////////////////////////////////////////////////////////////////////////
module wordle(
    input wire clk,
    input wire reset,
    
    // Player inputs (directly active buttons after debouncing from top)
    input wire SCEN,          // Single clock enable for button presses
    input wire Start,         // Start game button
    input wire UP,
    input wire DOWN,
    input wire LEFT,
    input wire RIGHT,
    input wire CENTER,        // Confirm selection
    
    // Game state outputs (for VGA rendering)
    // The secret word P1 set
    output reg [4:0] stored_word0,
    output reg [4:0] stored_word1,
    output reg [4:0] stored_word2,
    output reg [4:0] stored_word3,
    output reg [4:0] stored_word4,
    
    // P2's guesses (6 guesses x 5 letters)
    output reg [4:0] guess_1_0, guess_1_1, guess_1_2, guess_1_3, guess_1_4,
    output reg [4:0] guess_2_0, guess_2_1, guess_2_2, guess_2_3, guess_2_4,
    output reg [4:0] guess_3_0, guess_3_1, guess_3_2, guess_3_3, guess_3_4,
    output reg [4:0] guess_4_0, guess_4_1, guess_4_2, guess_4_3, guess_4_4,
    output reg [4:0] guess_5_0, guess_5_1, guess_5_2, guess_5_3, guess_5_4,
    output reg [4:0] guess_6_0, guess_6_1, guess_6_2, guess_6_3, guess_6_4,
    
    // Color status for each guess (6 guesses x 5 letters x 2 bits)
    output reg [1:0] g1_status0, g1_status1, g1_status2, g1_status3, g1_status4,
    output reg [1:0] g2_status0, g2_status1, g2_status2, g2_status3, g2_status4,
    output reg [1:0] g3_status0, g3_status1, g3_status2, g3_status3, g3_status4,
    output reg [1:0] g4_status0, g4_status1, g4_status2, g4_status3, g4_status4,
    output reg [1:0] g5_status0, g5_status1, g5_status2, g5_status3, g5_status4,
    output reg [1:0] g6_status0, g6_status1, g6_status2, g6_status3, g6_status4,
    
    output reg [2:0] current_guess,          // Which guess (1-6) we're on
    output wire [3:0] game_state,            // Current state for debug/VGA
    output wire [2:0] wf_pos,                // Current letter position (for UI cursor)
    // Current word being edited (for UI display)
    output wire [4:0] wf_current_word0,
    output wire [4:0] wf_current_word1,
    output wire [4:0] wf_current_word2,
    output wire [4:0] wf_current_word3,
    output wire [4:0] wf_current_word4
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
    wire [4:0] wf_word_out0, wf_word_out1, wf_word_out2, wf_word_out3, wf_word_out4;
    wire q_I_wf, q_Let_wf, q_Pos_wf;
    
    // Compare module control  
    reg cmp_start;
    reg cmp_reset;
    reg cmp_started;             // Flag to track if start pulse was sent
    wire cmp_done;
    wire [1:0] cmp_word_status0, cmp_word_status1, cmp_word_status2, cmp_word_status3, cmp_word_status4;
    wire q_I_cmp, q_Green_cmp, q_YorG_cmp;
    
    // Internal guess storage for compare module
    reg [4:0] current_guess_word0, current_guess_word1, current_guess_word2;
    reg [4:0] current_guess_word3, current_guess_word4;
    
    // Flag to detect all green (win condition)
    wire all_green;
    assign all_green = (cmp_word_status0 == GREEN) && 
                       (cmp_word_status1 == GREEN) && 
                       (cmp_word_status2 == GREEN) && 
                       (cmp_word_status3 == GREEN) && 
                       (cmp_word_status4 == GREEN);

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
        .word_array0(wf_word_out0),
        .word_array1(wf_word_out1),
        .word_array2(wf_word_out2),
        .word_array3(wf_word_out3),
        .word_array4(wf_word_out4),
        .DONE(wf_done)
    );
    
    compare cmp_inst (
        .Clk(clk),
        .RESET(cmp_reset),
        .Start(cmp_start),
        .guess0(current_guess_word0),
        .guess1(current_guess_word1),
        .guess2(current_guess_word2),
        .guess3(current_guess_word3),
        .guess4(current_guess_word4),
        .answer0(stored_word0),
        .answer1(stored_word1),
        .answer2(stored_word2),
        .answer3(stored_word3),
        .answer4(stored_word4),
        .q_I(q_I_cmp),
        .q_Green(q_Green_cmp),
        .q_YorG(q_YorG_cmp),
        .word_status0(cmp_word_status0),
        .word_status1(cmp_word_status1),
        .word_status2(cmp_word_status2),
        .word_status3(cmp_word_status3),
        .word_status4(cmp_word_status4),
        .cmp_done(cmp_done)
    );

    // =========================================================================
    // Pass-through outputs for VGA
    // =========================================================================
    assign wf_pos = wf_pos_out;
    assign wf_current_word0 = wf_word_out0;
    assign wf_current_word1 = wf_word_out1;
    assign wf_current_word2 = wf_word_out2;
    assign wf_current_word3 = wf_word_out3;
    assign wf_current_word4 = wf_word_out4;
    assign game_state = state;

    // =========================================================================
    // Main State Machine
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INI;
            current_guess <= 3'd1;
            
            // Reset all stored data
            stored_word0 <= 5'd0; stored_word1 <= 5'd0; stored_word2 <= 5'd0;
            stored_word3 <= 5'd0; stored_word4 <= 5'd0;
            
            guess_1_0 <= 5'd0; guess_1_1 <= 5'd0; guess_1_2 <= 5'd0;
            guess_1_3 <= 5'd0; guess_1_4 <= 5'd0;
            guess_2_0 <= 5'd0; guess_2_1 <= 5'd0; guess_2_2 <= 5'd0;
            guess_2_3 <= 5'd0; guess_2_4 <= 5'd0;
            guess_3_0 <= 5'd0; guess_3_1 <= 5'd0; guess_3_2 <= 5'd0;
            guess_3_3 <= 5'd0; guess_3_4 <= 5'd0;
            guess_4_0 <= 5'd0; guess_4_1 <= 5'd0; guess_4_2 <= 5'd0;
            guess_4_3 <= 5'd0; guess_4_4 <= 5'd0;
            guess_5_0 <= 5'd0; guess_5_1 <= 5'd0; guess_5_2 <= 5'd0;
            guess_5_3 <= 5'd0; guess_5_4 <= 5'd0;
            guess_6_0 <= 5'd0; guess_6_1 <= 5'd0; guess_6_2 <= 5'd0;
            guess_6_3 <= 5'd0; guess_6_4 <= 5'd0;
            
            g1_status0 <= UNCHECKED; g1_status1 <= UNCHECKED; g1_status2 <= UNCHECKED;
            g1_status3 <= UNCHECKED; g1_status4 <= UNCHECKED;
            g2_status0 <= UNCHECKED; g2_status1 <= UNCHECKED; g2_status2 <= UNCHECKED;
            g2_status3 <= UNCHECKED; g2_status4 <= UNCHECKED;
            g3_status0 <= UNCHECKED; g3_status1 <= UNCHECKED; g3_status2 <= UNCHECKED;
            g3_status3 <= UNCHECKED; g3_status4 <= UNCHECKED;
            g4_status0 <= UNCHECKED; g4_status1 <= UNCHECKED; g4_status2 <= UNCHECKED;
            g4_status3 <= UNCHECKED; g4_status4 <= UNCHECKED;
            g5_status0 <= UNCHECKED; g5_status1 <= UNCHECKED; g5_status2 <= UNCHECKED;
            g5_status3 <= UNCHECKED; g5_status4 <= UNCHECKED;
            g6_status0 <= UNCHECKED; g6_status1 <= UNCHECKED; g6_status2 <= UNCHECKED;
            g6_status3 <= UNCHECKED; g6_status4 <= UNCHECKED;
            
            // Reset module controls
            wf_reset <= 1'b1;
            cmp_reset <= 1'b1;
            wf_start <= 1'b0;
            cmp_start <= 1'b0;
            wf_started <= 1'b0;
            cmp_started <= 1'b0;
            
            // Reset internal guess word
            current_guess_word0 <= 5'd0;
            current_guess_word1 <= 5'd0;
            current_guess_word2 <= 5'd0;
            current_guess_word3 <= 5'd0;
            current_guess_word4 <= 5'd0;
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
                        stored_word0 <= wf_word_out0;
                        stored_word1 <= wf_word_out1;
                        stored_word2 <= wf_word_out2;
                        stored_word3 <= wf_word_out3;
                        stored_word4 <= wf_word_out4;
                        
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
                    // Pulse wf_start for exactly one cycle
                    if (!wf_started) begin
                        wf_start <= 1'b1;      // Single pulse
                        wf_started <= 1'b1;    // Mark that we've started
                    end
                    else begin
                        wf_start <= 1'b0;      // Keep low after pulse
                    end
                    
                    if (wf_done) begin
                        // Capture current guess into internal register for compare
                        current_guess_word0 <= wf_word_out0;
                        current_guess_word1 <= wf_word_out1;
                        current_guess_word2 <= wf_word_out2;
                        current_guess_word3 <= wf_word_out3;
                        current_guess_word4 <= wf_word_out4;
                        
                        // Store in the appropriate guess register for VGA display
                        case (current_guess)
                            3'd1: begin
                                guess_1_0 <= wf_word_out0; guess_1_1 <= wf_word_out1;
                                guess_1_2 <= wf_word_out2; guess_1_3 <= wf_word_out3;
                                guess_1_4 <= wf_word_out4;
                            end
                            3'd2: begin
                                guess_2_0 <= wf_word_out0; guess_2_1 <= wf_word_out1;
                                guess_2_2 <= wf_word_out2; guess_2_3 <= wf_word_out3;
                                guess_2_4 <= wf_word_out4;
                            end
                            3'd3: begin
                                guess_3_0 <= wf_word_out0; guess_3_1 <= wf_word_out1;
                                guess_3_2 <= wf_word_out2; guess_3_3 <= wf_word_out3;
                                guess_3_4 <= wf_word_out4;
                            end
                            3'd4: begin
                                guess_4_0 <= wf_word_out0; guess_4_1 <= wf_word_out1;
                                guess_4_2 <= wf_word_out2; guess_4_3 <= wf_word_out3;
                                guess_4_4 <= wf_word_out4;
                            end
                            3'd5: begin
                                guess_5_0 <= wf_word_out0; guess_5_1 <= wf_word_out1;
                                guess_5_2 <= wf_word_out2; guess_5_3 <= wf_word_out3;
                                guess_5_4 <= wf_word_out4;
                            end
                            3'd6: begin
                                guess_6_0 <= wf_word_out0; guess_6_1 <= wf_word_out1;
                                guess_6_2 <= wf_word_out2; guess_6_3 <= wf_word_out3;
                                guess_6_4 <= wf_word_out4;
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
                    // Pulse cmp_start for exactly one cycle
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
                                g1_status0 <= cmp_word_status0;
                                g1_status1 <= cmp_word_status1;
                                g1_status2 <= cmp_word_status2;
                                g1_status3 <= cmp_word_status3;
                                g1_status4 <= cmp_word_status4;
                            end
                            3'd2: begin
                                g2_status0 <= cmp_word_status0;
                                g2_status1 <= cmp_word_status1;
                                g2_status2 <= cmp_word_status2;
                                g2_status3 <= cmp_word_status3;
                                g2_status4 <= cmp_word_status4;
                            end
                            3'd3: begin
                                g3_status0 <= cmp_word_status0;
                                g3_status1 <= cmp_word_status1;
                                g3_status2 <= cmp_word_status2;
                                g3_status3 <= cmp_word_status3;
                                g3_status4 <= cmp_word_status4;
                            end
                            3'd4: begin
                                g4_status0 <= cmp_word_status0;
                                g4_status1 <= cmp_word_status1;
                                g4_status2 <= cmp_word_status2;
                                g4_status3 <= cmp_word_status3;
                                g4_status4 <= cmp_word_status4;
                            end
                            3'd5: begin
                                g5_status0 <= cmp_word_status0;
                                g5_status1 <= cmp_word_status1;
                                g5_status2 <= cmp_word_status2;
                                g5_status3 <= cmp_word_status3;
                                g5_status4 <= cmp_word_status4;
                            end
                            3'd6: begin
                                g6_status0 <= cmp_word_status0;
                                g6_status1 <= cmp_word_status1;
                                g6_status2 <= cmp_word_status2;
                                g6_status3 <= cmp_word_status3;
                                g6_status4 <= cmp_word_status4;
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
                        guess_1_0 <= 5'd0; guess_1_1 <= 5'd0; guess_1_2 <= 5'd0;
                        guess_1_3 <= 5'd0; guess_1_4 <= 5'd0;
                        guess_2_0 <= 5'd0; guess_2_1 <= 5'd0; guess_2_2 <= 5'd0;
                        guess_2_3 <= 5'd0; guess_2_4 <= 5'd0;
                        guess_3_0 <= 5'd0; guess_3_1 <= 5'd0; guess_3_2 <= 5'd0;
                        guess_3_3 <= 5'd0; guess_3_4 <= 5'd0;
                        guess_4_0 <= 5'd0; guess_4_1 <= 5'd0; guess_4_2 <= 5'd0;
                        guess_4_3 <= 5'd0; guess_4_4 <= 5'd0;
                        guess_5_0 <= 5'd0; guess_5_1 <= 5'd0; guess_5_2 <= 5'd0;
                        guess_5_3 <= 5'd0; guess_5_4 <= 5'd0;
                        guess_6_0 <= 5'd0; guess_6_1 <= 5'd0; guess_6_2 <= 5'd0;
                        guess_6_3 <= 5'd0; guess_6_4 <= 5'd0;
                        
                        // Clear all statuses
                        g1_status0 <= UNCHECKED; g1_status1 <= UNCHECKED; g1_status2 <= UNCHECKED;
                        g1_status3 <= UNCHECKED; g1_status4 <= UNCHECKED;
                        g2_status0 <= UNCHECKED; g2_status1 <= UNCHECKED; g2_status2 <= UNCHECKED;
                        g2_status3 <= UNCHECKED; g2_status4 <= UNCHECKED;
                        g3_status0 <= UNCHECKED; g3_status1 <= UNCHECKED; g3_status2 <= UNCHECKED;
                        g3_status3 <= UNCHECKED; g3_status4 <= UNCHECKED;
                        g4_status0 <= UNCHECKED; g4_status1 <= UNCHECKED; g4_status2 <= UNCHECKED;
                        g4_status3 <= UNCHECKED; g4_status4 <= UNCHECKED;
                        g5_status0 <= UNCHECKED; g5_status1 <= UNCHECKED; g5_status2 <= UNCHECKED;
                        g5_status3 <= UNCHECKED; g5_status4 <= UNCHECKED;
                        g6_status0 <= UNCHECKED; g6_status1 <= UNCHECKED; g6_status2 <= UNCHECKED;
                        g6_status3 <= UNCHECKED; g6_status4 <= UNCHECKED;
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
                        guess_1_0 <= 5'd0; guess_1_1 <= 5'd0; guess_1_2 <= 5'd0;
                        guess_1_3 <= 5'd0; guess_1_4 <= 5'd0;
                        guess_2_0 <= 5'd0; guess_2_1 <= 5'd0; guess_2_2 <= 5'd0;
                        guess_2_3 <= 5'd0; guess_2_4 <= 5'd0;
                        guess_3_0 <= 5'd0; guess_3_1 <= 5'd0; guess_3_2 <= 5'd0;
                        guess_3_3 <= 5'd0; guess_3_4 <= 5'd0;
                        guess_4_0 <= 5'd0; guess_4_1 <= 5'd0; guess_4_2 <= 5'd0;
                        guess_4_3 <= 5'd0; guess_4_4 <= 5'd0;
                        guess_5_0 <= 5'd0; guess_5_1 <= 5'd0; guess_5_2 <= 5'd0;
                        guess_5_3 <= 5'd0; guess_5_4 <= 5'd0;
                        guess_6_0 <= 5'd0; guess_6_1 <= 5'd0; guess_6_2 <= 5'd0;
                        guess_6_3 <= 5'd0; guess_6_4 <= 5'd0;
                        
                        // Clear all statuses
                        g1_status0 <= UNCHECKED; g1_status1 <= UNCHECKED; g1_status2 <= UNCHECKED;
                        g1_status3 <= UNCHECKED; g1_status4 <= UNCHECKED;
                        g2_status0 <= UNCHECKED; g2_status1 <= UNCHECKED; g2_status2 <= UNCHECKED;
                        g2_status3 <= UNCHECKED; g2_status4 <= UNCHECKED;
                        g3_status0 <= UNCHECKED; g3_status1 <= UNCHECKED; g3_status2 <= UNCHECKED;
                        g3_status3 <= UNCHECKED; g3_status4 <= UNCHECKED;
                        g4_status0 <= UNCHECKED; g4_status1 <= UNCHECKED; g4_status2 <= UNCHECKED;
                        g4_status3 <= UNCHECKED; g4_status4 <= UNCHECKED;
                        g5_status0 <= UNCHECKED; g5_status1 <= UNCHECKED; g5_status2 <= UNCHECKED;
                        g5_status3 <= UNCHECKED; g5_status4 <= UNCHECKED;
                        g6_status0 <= UNCHECKED; g6_status1 <= UNCHECKED; g6_status2 <= UNCHECKED;
                        g6_status3 <= UNCHECKED; g6_status4 <= UNCHECKED;
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