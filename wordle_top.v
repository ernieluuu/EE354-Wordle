`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 12/03/2025
// File Name: wordle_top.v
// Description: Top-level module for FPGA Wordle implementation
//              Handles clock generation, button debouncing, and instantiates
//              the core game controller
//////////////////////////////////////////////////////////////////////////////////

module wordle_top(
    // FPGA Board Inputs
    input wire clk_100mhz,      // 100 MHz system clock from FPGA
    input wire reset_btn,       // Reset button (active high)

    // Game Control Buttons (raw inputs from FPGA buttons)
    input wire start_btn,       // Start game button
    input wire up_btn,          // UP navigation
    input wire down_btn,        // DOWN navigation
    input wire left_btn,        // LEFT navigation
    input wire right_btn,       // RIGHT navigation
    input wire center_btn       // CENTER/Confirm button

    // VGA Outputs (for future use - commented out for now)
    // output wire [3:0] vga_r,
    // output wire [3:0] vga_g,
    // output wire [3:0] vga_b,
    // output wire hsync,
    // output wire vsync

    // Debug outputs (optional - for testing)
    // output wire [3:0] debug_state,
    // output wire [2:0] debug_guess
);

    // =========================================================================
    // Internal Signals
    // =========================================================================

    // Clock Enable Signal (for button debouncing)
    // Generated at ~70Hz for smooth button response
    wire SCEN;

    // Game state outputs from wordle module
    wire [4:0] stored_word [0:4];       // Secret word set by P1

    wire [4:0] guess_1 [0:4];           // All 6 guesses from P2
    wire [4:0] guess_2 [0:4];
    wire [4:0] guess_3 [0:4];
    wire [4:0] guess_4 [0:4];
    wire [4:0] guess_5 [0:4];
    wire [4:0] guess_6 [0:4];

    wire [1:0] g1_status [0:4];         // Color status for each guess
    wire [1:0] g2_status [0:4];         // (00=unchecked, 01=green, 10=yellow, 11=gray)
    wire [1:0] g3_status [0:4];
    wire [1:0] g4_status [0:4];
    wire [1:0] g5_status [0:4];
    wire [1:0] g6_status [0:4];

    wire [2:0] current_guess;           // Current guess number (1-6)
    wire [3:0] game_state;              // Current state of game FSM
    wire [2:0] wf_pos;                  // Current letter position being edited
    wire [4:0] wf_current_word [0:4];   // Current word being edited in UI

    // =========================================================================
    // Clock Generation for Button Debouncing
    // =========================================================================
    // Generate a ~70Hz clock enable signal (SCEN) for button debouncing
    // max_count = 100_000_000 / (2 * 70) H 714,285

    create_slowed_clk #(
        .max_count(714_285)             // 70 Hz clock enable
    ) scen_generator (
        .clk_in(clk_100mhz),
        .rst_l(~reset_btn),             // Active low reset (invert reset_btn)
        .clk_out(SCEN)
    );

    // =========================================================================
    // Wordle Game Controller Instantiation
    // =========================================================================

    wordle game_controller (
        .clk(clk_100mhz),
        .reset(reset_btn),

        // Button inputs (with clock enable for debouncing)
        .SCEN(SCEN),
        .Start(start_btn),
        .UP(up_btn),
        .DOWN(down_btn),
        .LEFT(left_btn),
        .RIGHT(right_btn),
        .CENTER(center_btn),

        // Game state outputs (connect to VGA module in future)
        .stored_word(stored_word),

        .guess_1(guess_1),
        .guess_2(guess_2),
        .guess_3(guess_3),
        .guess_4(guess_4),
        .guess_5(guess_5),
        .guess_6(guess_6),

        .g1_status(g1_status),
        .g2_status(g2_status),
        .g3_status(g3_status),
        .g4_status(g4_status),
        .g5_status(g5_status),
        .g6_status(g6_status),

        .current_guess(current_guess),
        .game_state(game_state),
        .wf_pos(wf_pos),
        .wf_current_word(wf_current_word)
    );

    // =========================================================================
    // VGA Display Module (Future Implementation)
    // =========================================================================
    /*
    // VGA pixel clock generation (25.175 MHz for 640x480 @ 60Hz)
    wire vga_clk;

    create_slowed_clk #(
        .max_count(2)                   // 100MHz / (2*2) = 25 MHz (close to 25.175)
    ) vga_clk_gen (
        .clk_in(clk_100mhz),
        .rst_l(~reset_btn),
        .clk_out(vga_clk)
    );

    // VGA display module
    wordle_display vga_display (
        .clk(vga_clk),
        .reset(reset_btn),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .hsync(hsync),
        .vsync(vsync)
        // TODO: Connect game state signals to display
    );
    */

    // =========================================================================
    // Debug Outputs (Optional)
    // =========================================================================
    // Uncomment to route internal signals to LEDs/debug pins
    // assign debug_state = game_state;
    // assign debug_guess = current_guess;

endmodule
