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
    // input wire reset_btn,       // Reset button (active high), defined as Sw0 in XDC

    // Game Control Buttons (raw inputs from FPGA buttons)
    input wire start_btn,       // Start game button
    input wire up_btn,          // UP navigation
    input wire down_btn,        // DOWN navigation
    input wire left_btn,        // LEFT navigation
    input wire right_btn,       // RIGHT navigation
    input wire center_btn,      // CENTER/Confirm button
	
	input wire Ld7,
	input wire Ld6,
	input wire Ld5,
	input wire Ld4,
	input wire Ld3,
	input wire Ld2,
	input wire Ld1,
	input wire Ld0,
	
	input wire Sw0, // for reset
	
	// SSD Anodes
	output wire An7,
	output wire An6,
	output wire An5,
	output wire An4,
	output wire An3,
	output wire An2,
	output wire An1,
	output wire An0,
	
	// SSD Cathodes
	output wire Ca,
	output wire Cb,
	output wire Cc,
	output wire Cd,
	output wire Ce,
	output wire Cf,
	output wire Cg

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
	
	// SSD signals
	wire [2:0] ssdscan_clk;
	wire [4:0] SSD7, SSD6, SSD5, SSD4, SSD3;
	wire [3:0] SSD0
	
	// RESET BTN
	wire reset_btn = Sw0;

    // =========================================================================
    // Clock Generation for Button Debouncing
    // =========================================================================
    // Generate a ~70Hz clock enable signal (SCEN) for button debouncing
    // max_count = 100_000_000 / (2 * 70) H 714,285

    create_slowed_clk #(
        .max_count(714_285)             // 70 Hz clock enable
    ) scen_generator (
        .clk_in(clk_100mhz),
        .rst_l(reset_btn),             // Active low reset (invert reset_btn)
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
	
	// =========================================================================
    // LED controls
    // =========================================================================
	reg [5:0] guess_display; // display on LEDs 0-5 the current guess
	always @ (current_guess) begin
		case (current_guess)
			3'd1: guess_display = 6'b000001;
			3'd2: guess_display = 6'b000011;
			3'd3: guess_display = 6'b000111;
			3'd4: guess_display = 6'b001111;
			3'd5: guess_display = 6'b011111;
			3'd6: guess_display = 6'b111111;
			default: guess_display = 6'b000000;
		endcase
	end
	
	assign {Ld5, Ld4, Ld3, Ld2, Ld1, Ld0} = guess_display;
	
	// Check if each letter position has GREEN status across all guesses
	reg [4:0] green_leds;  // One bit for each of the 6 LEDs (LED8-LED13)

	always @ (g1_status[0], g1_status[1], g1_status[2], g1_status[3], g1_status[4],
			  g2_status[0], g2_status[1], g2_status[2], g2_status[3], g2_status[4],
			  g3_status[0], g3_status[1], g3_status[2], g3_status[3], g3_status[4],
			  g4_status[0], g4_status[1], g4_status[2], g4_status[3], g4_status[4],
			  g5_status[0], g5_status[1], g5_status[2], g5_status[3], g5_status[4],
			  g6_status[0], g6_status[1], g6_status[2], g6_status[3], g6_status[4]) 
    begin
		
		// LED8 (position 0): Check if ANY guess has green in position 0
		green_leds[0] = (g1_status[0] == 2'b01) || (g2_status[0] == 2'b01) || 
						(g3_status[0] == 2'b01) || (g4_status[0] == 2'b01) || 
						(g5_status[0] == 2'b01) || (g6_status[0] == 2'b01);
		
		// LED9 (position 1)
		green_leds[1] = (g1_status[1] == 2'b01) || (g2_status[1] == 2'b01) || 
						(g3_status[1] == 2'b01) || (g4_status[1] == 2'b01) || 
						(g5_status[1] == 2'b01) || (g6_status[1] == 2'b01);
		
		// LED10 (position 2)
		green_leds[2] = (g1_status[2] == 2'b01) || (g2_status[2] == 2'b01) || 
						(g3_status[2] == 2'b01) || (g4_status[2] == 2'b01) || 
						(g5_status[2] == 2'b01) || (g6_status[2] == 2'b01);
		
		// LED11 (position 3)
		green_leds[3] = (g1_status[3] == 2'b01) || (g2_status[3] == 2'b01) || 
						(g3_status[3] == 2'b01) || (g4_status[3] == 2'b01) || 
						(g5_status[3] == 2'b01) || (g6_status[3] == 2'b01);
		
		// LED12 (position 4)
		green_leds[4] = (g1_status[4] == 2'b01) || (g2_status[4] == 2'b01) || 
						(g3_status[4] == 2'b01) || (g4_status[4] == 2'b01) || 
						(g5_status[4] == 2'b01) || (g6_status[4] == 2'b01);
		
	end

	// Assign to actual LED outputs
	assign {Ld13, Ld12, Ld11, Ld10, Ld9} = green_leds;
	
	// =========================================================================
    // SSD controls
    // =========================================================================
	assign SSD7 = wf_current_word[0];  // First letter (leftmost)
	assign SSD6 = wf_current_word[1];  // Second letter
	assign SSD5 = wf_current_word[2];  // Third letter
	assign SSD4 = wf_current_word[3];  // Fourth letter
	assign SSD3 = wf_current_word[4];  // Fifth letter

	reg [4:0] SSD0_display;

	always @ (game_state)
	begin : SSD0_SELECT
		case (game_state)
			4'b0111: SSD0_display = 5'b10110;  // Display 'W' (Win)
			4'b1000: SSD0_display = 5'b01011;  // Display 'L' (Loss)
			default: SSD0_display = 5'b11111;  // keep blank
		endcase
	end

	assign SSD0 = SSD0_display;

	// Use single 3-bit scan clock for all 8 displays
	assign ssdscan_clk = DIV_CLK[20:18];  // 3 bits to select 0-7

	// Decode ssdscan_clk to activate appropriate anode (active low)
	assign An0 = !(ssdscan_clk == 3'b000);
	assign An1 = 1'b1;  // unused
	assign An2 = 1'b1;  // unused
	assign An3 = !(ssdscan_clk == 3'b011);
	assign An4 = !(ssdscan_clk == 3'b100);
	assign An5 = !(ssdscan_clk == 3'b101);
	assign An6 = !(ssdscan_clk == 3'b110);
	assign An7 = !(ssdscan_clk == 3'b111);

	// Single multiplexer for all SSDs
	always @ (ssdscan_clk, SSD0, SSD3, SSD4, SSD5, SSD6, SSD7)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk)
			3'b000: SSD = SSD0;
			3'b001: SSD = 5'b11111;  // unused, blank display
			3'b010: SSD = 5'b11111;  // unused, blank display
			3'b011: SSD = SSD3;
			3'b100: SSD = SSD4;
			3'b101: SSD = SSD5;
			3'b110: SSD = SSD6;
			3'b111: SSD = SSD7;
			default: SSD = 5'b11111;
		endcase
	end

	// Determine if current letter being displayed has YELLOW status
	reg dp_yellow;

	always @ (ssdscan_clk,
			  g1_status[0], g1_status[1], g1_status[2], g1_status[3], g1_status[4],
			  g2_status[0], g2_status[1], g2_status[2], g2_status[3], g2_status[4],
			  g3_status[0], g3_status[1], g3_status[2], g3_status[3], g3_status[4],
			  g4_status[0], g4_status[1], g4_status[2], g4_status[3], g4_status[4],
			  g5_status[0], g5_status[1], g5_status[2], g5_status[3], g5_status[4],
			  g6_status[0], g6_status[1], g6_status[2], g6_status[3], g6_status[4],
			  current_guess)
	begin : DP_YELLOW_CHECK
		case (ssdscan_clk)
			3'b111: begin // SSD7 showing letter position 0
				case (current_guess)
					3'd1: dp_yellow = (g1_status[0] == 2'b10);
					3'd2: dp_yellow = (g2_status[0] == 2'b10);
					3'd3: dp_yellow = (g3_status[0] == 2'b10);
					3'd4: dp_yellow = (g4_status[0] == 2'b10);
					3'd5: dp_yellow = (g5_status[0] == 2'b10);
					3'd6: dp_yellow = (g6_status[0] == 2'b10);
					default: dp_yellow = 1'b0;
				endcase
			end
			
			3'b110: begin // SSD6 showing letter position 1
				case (current_guess)
					3'd1: dp_yellow = (g1_status[1] == 2'b10);
					3'd2: dp_yellow = (g2_status[1] == 2'b10);
					3'd3: dp_yellow = (g3_status[1] == 2'b10);
					3'd4: dp_yellow = (g4_status[1] == 2'b10);
					3'd5: dp_yellow = (g5_status[1] == 2'b10);
					3'd6: dp_yellow = (g6_status[1] == 2'b10);
					default: dp_yellow = 1'b0;
				endcase
			end
			
			3'b101: begin // SSD5 showing letter position 2
				case (current_guess)
					3'd1: dp_yellow = (g1_status[2] == 2'b10);
					3'd2: dp_yellow = (g2_status[2] == 2'b10);
					3'd3: dp_yellow = (g3_status[2] == 2'b10);
					3'd4: dp_yellow = (g4_status[2] == 2'b10);
					3'd5: dp_yellow = (g5_status[2] == 2'b10);
					3'd6: dp_yellow = (g6_status[2] == 2'b10);
					default: dp_yellow = 1'b0;
				endcase
			end
			
			3'b100: begin // SSD4 showing letter position 3
				case (current_guess)
					3'd1: dp_yellow = (g1_status[3] == 2'b10);
					3'd2: dp_yellow = (g2_status[3] == 2'b10);
					3'd3: dp_yellow = (g3_status[3] == 2'b10);
					3'd4: dp_yellow = (g4_status[3] == 2'b10);
					3'd5: dp_yellow = (g5_status[3] == 2'b10);
					3'd6: dp_yellow = (g6_status[3] == 2'b10);
					default: dp_yellow = 1'b0;
				endcase
			end
			
			3'b011: begin // SSD3 showing letter position 4
				case (current_guess)
					3'd1: dp_yellow = (g1_status[4] == 2'b10);
					3'd2: dp_yellow = (g2_status[4] == 2'b10);
					3'd3: dp_yellow = (g3_status[4] == 2'b10);
					3'd4: dp_yellow = (g4_status[4] == 2'b10);
					3'd5: dp_yellow = (g5_status[4] == 2'b10);
					3'd6: dp_yellow = (g6_status[4] == 2'b10);
					default: dp_yellow = 1'b0;
				endcase
			end
			
			default: dp_yellow = 1'b0;  // No yellow dot for SSD0-2
		endcase
	end

	// Modify the final cathode assignment
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, ~dp_yellow};

	always @ (SSD) // display letters A-Z
	begin : HEX_TO_SSD
		case (SSD)
			5'b00000: SSD_CATHODES = 7'b0001000 ; // A
			5'b00001: SSD_CATHODES = 7'b1100000 ; // B
			5'b00010: SSD_CATHODES = 7'b0110001 ; // C
			5'b00011: SSD_CATHODES = 7'b1000010 ; // D
			5'b00100: SSD_CATHODES = 7'b0110000 ; // E
			5'b00101: SSD_CATHODES = 7'b0111000 ; // F
			5'b00110: SSD_CATHODES = 7'b0100001 ; // G (like 9 but lower segment)
			5'b00111: SSD_CATHODES = 7'b1101000 ; // H (left/right bars + middle)
			5'b01000: SSD_CATHODES = 7'b1001111 ; // I (same as 1)
			5'b01001: SSD_CATHODES = 7'b1000011 ; // J (right side + bottom)
			5'b01010: SSD_CATHODES = 7'b1100100 ; // K 
			5'b01011: SSD_CATHODES = 7'b1110001 ; // L (left bar + bottom)
			5'b01100: SSD_CATHODES = 7'b0101001 ; // M (approximation)
			5'b01101: SSD_CATHODES = 7'b1101010 ; // N (left + middle + right lower)
			5'b01110: SSD_CATHODES = 7'b0000001 ; // O (same as 0)
			5'b01111: SSD_CATHODES = 7'b0011000 ; // P (upper left + top + middle)
			5'b10000: SSD_CATHODES = 7'b0001100 ; // Q (like O with tail)
			5'b10001: SSD_CATHODES = 7'b1111010 ; // R (approximation)
			5'b10010: SSD_CATHODES = 7'b0100100 ; // S (same as 5)
			5'b10011: SSD_CATHODES = 7'b1110000 ; // T (left + top + middle)
			5'b10100: SSD_CATHODES = 7'b1100011 ; // U 
			5'b10101: SSD_CATHODES = 7'b1000001 ; // V (same as U - approximation)
			5'b10110: SSD_CATHODES = 7'b1010111 ; // W 
			5'b10111: SSD_CATHODES = 7'b0101010 ; // X (same as H - approximation)
			5'b11000: SSD_CATHODES = 7'b1000100 ; // Y (like 4)
			5'b11001: SSD_CATHODES = 7'b0010010 ; // Z (same as 2)
			default: SSD_CATHODES = 7'bXXXXXXX ; // default
		endcase
	end
endmodule
