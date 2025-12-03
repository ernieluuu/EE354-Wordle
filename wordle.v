`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 11/20/2025
// File Name: wordle.v 
// Description: Core Wordle game state machine (Verilog-2001 compatible)
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
    // The secret word P1 set (5 letters, 5 bits each)
    output reg [4:0] stored_word_0,
    output reg [4:0] stored_word_1,
    output reg [4:0] stored_word_2,
    output reg [4:0] stored_word_3,
    output reg [4:0] stored_word_4,
    
    // P2's guesses (6 guesses, 5 letters each, 5 bits per letter)
    output reg [4:0] guess_1_0, guess_1_1, guess_1_2, guess_1_3, guess_1_4,
    output reg [4:0] guess_2_0, guess_2_1, guess_2_2, guess_2_3, guess_2_4,
    output reg [4:0] guess_3_0, guess_3_1, guess_3_2, guess_3_3, guess_3_4,
    output reg [4:0] guess_4_0, guess_4_1, guess_4_2, guess_4_3, guess_4_4,
    output reg [4:0] guess_5_0, guess_5_1, guess_5_2, guess_5_3, guess_5_4,
    output reg [4:0] guess_6_0, guess_6_1, guess_6_2, guess_6_3, guess_6_4,
    
    // Color status for each guess (2 bits per letter)
    output reg [1:0] g1_status_0, g1_status_1, g1_status_2, g1_status_3, g1_status_4,
    output reg [1:0] g2_status_0, g2_status_1, g2_status_2, g2_status_3, g2_status_4,
    output reg [1:0] g3_status_0, g3_status_1, g3_status_2, g3_status_3, g3_status_4,
    output reg [1:0] g4_status_0, g4_status_1, g4_status_2, g4_status_3, g4_status_4,
    output reg [1:0] g5_status_0, g5_status_1, g5_status_2, g5_status_3, g5_status_4,
    output reg [1:0] g6_status_0, g6_status_1, g6_status_2, g6_status_3, g6_status_4,
    
    output reg [2:0] current_guess,          // Which guess (1-6) we're on
    output wire [3:0] game_state,            // Current state for debug/VGA
    output wire [2:0] wf_pos,                // Current letter position (for UI cursor)
    
    // Current word being edited (for UI display)
    output wire [4:0] wf_current_word_0,
    output wire [4:0] wf_current_word_1,
    output wire [4:0] wf_current_word_2,
    output wire [4:0] wf_current_word_3,
    output wire [4:0] wf_current_word_4
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
    wire [4:0] wf_word_out_0, wf_word_out_1, wf_word_out_2, wf_word_out_3, wf_word_out_4;
    wire q_I_wf, q_Let_wf, q_Pos_wf;
    
    // Compare module control  
    reg cmp_start;
    reg cmp_reset;
    reg cmp_started;             // Flag to track if start pulse was sent
    wire cmp_done;
    wire [1:0] cmp_word_status_0, cmp_word_status_1, cmp_word_status_2, cmp_word_status_3, cmp_word_status_4;
    wire q_I_cmp, q_Green_cmp, q_YorG_cmp;
    
    // Internal guess storage for compare module
    reg [4:0] current_guess_word_0;
    reg [4:0] current_guess_word_1;
    reg [4:0] current_guess_word_2;
    reg [4:0] current_guess_word_3;
    reg [4:0] current_guess_word_4;
    
    // Flag to detect all green (win condition)
    wire all_green;
    assign all_green = (cmp_word_status_0 == GREEN) && 
                       (cmp_word_status_1 == GREEN) && 
                       (cmp_word_status_2 == GREEN) && 
                       (cmp_word_status_3 == GREEN) && 
                       (cmp_word_status_4 == GREEN);

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
        .word_0(wf_word_out_0),
        .word_1(wf_word_out_1),
        .word_2(wf_word_out_2),
        .word_3(wf_word_out_3),
        .word_4(wf_word_out_4),
        .DONE(wf_done)
    );
    
    compare cmp_inst (
        .Clk(clk),
        .SCEN(SCEN),
        .RESET(cmp_reset),
        .CENTER(CENTER),
        .Start(cmp_start),
        .guess_0(current_guess_word_0),
        .guess_1(current_guess_word_1),
        .guess_2(current_guess_word_2),
        .guess_3(current_guess_word_3),
        .guess_4(current_guess_word_4),
        .answer_0(stored_word_0),
        .answer_1(stored_word_1),
        .answer_2(stored_word_2),
        .answer_3(stored_word_3),
        .answer_4(stored_word_4),
        .q_I(q_I_cmp),
        .q_Green(q_Green_cmp),
        .q_YorG(q_YorG_cmp),
        .word_status_0(cmp_word_status_0),
        .word_status_1(cmp_word_status_1),
        .word_status_2(cmp_word_status_2),
        .word_status_3(cmp_word_status_3),
        .word_status_4(cmp_word_status_4),
        .cmp_done(cmp_done)
    );

    // =========================================================================
    // Pass-through outputs for VGA
    // =========================================================================
    assign wf_pos = wf_pos_out;
    assign wf_current_word_0 = wf_word_out_0;
    assign wf_current_word_1 = wf_word_out_1;
    assign wf_current_word_2 = wf_word_out_2;
    assign wf_current_word_3 = wf_word_out_3;
    assign wf_current_word_4 = wf_word_out_4;
    assign game_state = state;

    // =========================================================================
    // Main State Machine
    // =========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= INI;
            current_guess <= 3'd1;
            
            // Reset all stored data
            stored_word_0 <= 5'd0;
            stored_word_1 <= 5'd0;
            stored_word_2 <= 5'd0;
            stored_word_3 <= 5'd0;
            stored_word_4 <= 5'd0;
            
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
            
            g1_status_0 <= UNCHECKED; g1_status_1 <= UNCHECKED; g1_status_2 <= UNCHECKED;
            g1_status_3 <= UNCHECKED; g1_status_4 <= UNCHECKED;
            g2_status_0 <= UNCHECKED; g2_status_1 <= UNCHECKED; g2_status_2 <= UNCHECKED;
            g2_status_3 <= UNCHECKED; g2_status_4 <= UNCHECKED;
            g3_status_0 <= UNCHECKED; g3_status_1 <= UNCHECKED; g3_status_2 <= UNCHECKED;
            g3_status_3 <= UNCHECKED; g3_status_4 <= UNCHECKED;
            g4_status_0 <= UNCHECKED; g4_status_1 <= UNCHECKED; g4_status_2 <= UNCHECKED;
            g4_status_3 <= UNCHECKED; g4_status_4 <= UNCHECKED;
            g5_status_0 <= UNCHECKED; g5_status_1 <= UNCHECKED; g5_status_2 <= UNCHECKED;
            g5_status_3 <= UNCHECKED; g5_status_4 <= UNCHECKED;
            g6_status_0 <= UNCHECKED; g6_status_1 <= UNCHECKED; g6_status_2 <= UNCHECKED;
            g6_status_3 <= UNCHECKED; g6_status_4 <= UNCHECKED;
            
            // Reset module controls
            wf_reset <= 1'b1;
            cmp_reset <= 1'b1;
            wf_start <= 1'b0;
            cmp_start <= 1'b0;
            wf_started <= 1'b0;
            cmp_started <= 1'b0;
            
            // Reset internal guess word
            current_guess_word_0 <= 5'd0;
            current_guess_word_1 <= 5'd0;
            current_guess_word_2 <= 5'd0;
            current_guess_word_3 <= 5'd0;
            current_guess_word_4 <= 5'd0;
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
                        stored_word_0 <= wf_word_out_0;
                        stored_word_1 <= wf_word_out_1;
                        stored_word_2 <= wf_word_out_2;
                        stored_word_3 <= wf_word_out_3;
                        stored_word_4 <= wf_word_out_4;
                        
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
                        current_guess_word_0 <= wf_word_out_0;
                        current_guess_word_1 <= wf_word_out_1;
                        current_guess_word_2 <= wf_word_out_2;
                        current_guess_word_3 <= wf_word_out_3;
                        current_guess_word_4 <= wf_word_out_4;
                        
                        // Store in the appropriate guess register for VGA display
                        case (current_guess)
                            3'd1: begin
                                guess_1_0 <= wf_word_out_0; guess_1_1 <= wf_word_out_1;
                                guess_1_2 <= wf_word_out_2; guess_1_3 <= wf_word_out_3;
                                guess_1_4 <= wf_word_out_4;
                            end
                            3'd2: begin
                                guess_2_0 <= wf_word_out_0; guess_2_1 <= wf_word_out_1;
                                guess_2_2 <= wf_word_out_2; guess_2_3 <= wf_word_out_3;
                                guess_2_4 <= wf_word_out_4;
                            end
                            3'd3: begin
                                guess_3_0 <= wf_word_out_0; guess_3_1 <= wf_word_out_1;
                                guess_3_2 <= wf_word_out_2; guess_3_3 <= wf_word_out_3;
                                guess_3_4 <= wf_word_out_4;
                            end
                            3'd4: begin
                                guess_4_0 <= wf_word_out_0; guess_4_1 <= wf_word_out_1;
                                guess_4_2 <= wf_word_out_2; guess_4_3 <= wf_word_out_3;
                                guess_4_4 <= wf_word_out_4;
                            end
                            3'd5: begin
                                guess_5_0 <= wf_word_out_0; guess_5_1 <= wf_word_out_1;
                                guess_5_2 <= wf_word_out_2; guess_5_3 <= wf_word_out_3;
                                guess_5_4 <= wf_word_out_4;
                            end
                            3'd6: begin
                                guess_6_0 <= wf_word_out_0; guess_6_1 <= wf_word_out_1;
                                guess_6_2 <= wf_word_out_2; guess_6_3 <= wf_word_out_3;
                                guess_6_4 <= wf_word_out_4;
                            end
                            default: ; // Do nothing
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
                                g1_status_0 <= cmp_word_status_0;
                                g1_status_1 <= cmp_word_status_1;
                                g1_status_2 <= cmp_word_status_2;
                                g1_status_3 <= cmp_word_status_3;
                                g1_status_4 <= cmp_word_status_4;
                            end
                            3'd2: begin
                                g2_status_0 <= cmp_word_status_0;
                                g2_status_1 <= cmp_word_status_1;
                                g2_status_2 <= cmp_word_status_2;
                                g2_status_3 <= cmp_word_status_3;
                                g2_status_4 <= cmp_word_status_4;
                            end
                            3'd3: begin
                                g3_status_0 <= cmp_word_status_0;
                                g3_status_1 <= cmp_word_status_1;
                                g3_status_2 <= cmp_word_status_2;
                                g3_status_3 <= cmp_word_status_3;
                                g3_status_4 <= cmp_word_status_4;
                            end
                            3'd4: begin
                                g4_status_0 <= cmp_word_status_0;
                                g4_status_1 <= cmp_word_status_1;
                                g4_status_2 <= cmp_word_status_2;
                                g4_status_3 <= cmp_word_status_3;
                                g4_status_4 <= cmp_word_status_4;
                            end
                            3'd5: begin
                                g5_status_0 <= cmp_word_status_0;
                                g5_status_1 <= cmp_word_status_1;
                                g5_status_2 <= cmp_word_status_2;
                                g5_status_3 <= cmp_word_status_3;
                                g5_status_4 <= cmp_word_status_4;
                            end
                            3'd6: begin
                                g6_status_0 <= cmp_word_status_0;
                                g6_status_1 <= cmp_word_status_1;
                                g6_status_2 <= cmp_word_status_2;
                                g6_status_3 <= cmp_word_status_3;
                                g6_status_4 <= cmp_word_status_4;
                            end
                            default: ; // Do nothing
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
                        g1_status_0 <= UNCHECKED; g1_status_1 <= UNCHECKED; g1_status_2 <= UNCHECKED;
                        g1_status_3 <= UNCHECKED; g1_status_4 <= UNCHECKED;
                        g2_status_0 <= UNCHECKED; g2_status_1 <= UNCHECKED; g2_status_2 <= UNCHECKED;
                        g2_status_3 <= UNCHECKED; g2_status_4 <= UNCHECKED;
                        g3_status_0 <= UNCHECKED; g3_status_1 <= UNCHECKED; g3_status_2 <= UNCHECKED;
                        g3_status_3 <= UNCHECKED; g3_status_4 <= UNCHECKED;
                        g4_status_0 <= UNCHECKED; g4_status_1 <= UNCHECKED; g4_status_2 <= UNCHECKED;
                        g4_status_3 <= UNCHECKED; g4_status_4 <= UNCHECKED;
                        g5_status_0 <= UNCHECKED; g5_status_1 <= UNCHECKED; g5_status_2 <= UNCHECKED;
                        g5_status_3 <= UNCHECKED; g5_status_4 <= UNCHECKED;
                        g6_status_0 <= UNCHECKED; g6_status_1 <= UNCHECKED; g6_status_2 <= UNCHECKED;
                        g6_status_3 <= UNCHECKED; g6_status_4 <= UNCHECKED;
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
                        g1_status_0 <= UNCHECKED; g1_status_1 <= UNCHECKED; g1_status_2 <= UNCHECKED;
                        g1_status_3 <= UNCHECKED; g1_status_4 <= UNCHECKED;
                        g2_status_0 <= UNCHECKED; g2_status_1 <= UNCHECKED; g2_status_2 <= UNCHECKED;
                        g2_status_3 <= UNCHECKED; g2_status_4 <= UNCHECKED;
                        g3_status_0 <= UNCHECKED; g3_status_1 <= UNCHECKED; g3_status_2 <= UNCHECKED;
                        g3_status_3 <= UNCHECKED; g3_status_4 <= UNCHECKED;
                        g4_status_0 <= UNCHECKED; g4_status_1 <= UNCHECKED; g4_status_2 <= UNCHECKED;
                        g4_status_3 <= UNCHECKED; g4_status_4 <= UNCHECKED;
                        g5_status_0 <= UNCHECKED; g5_status_1 <= UNCHECKED; g5_status_2 <= UNCHECKED;
                        g5_status_3 <= UNCHECKED; g5_status_4 <= UNCHECKED;
                        g6_status_0 <= UNCHECKED; g6_status_1 <= UNCHECKED; g6_status_2 <= UNCHECKED;
                        g6_status_3 <= UNCHECKED; g6_status_4 <= UNCHECKED;
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