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
    // input wire start_btn,       // Start game button
    input wire BtnU,          // UP navigation
    input wire BtnD,        // DOWN navigation
    input wire BtnL,        // LEFT navigation
    input wire BtnR,       // RIGHT navigation
    input wire BtnC,      // CENTER/Confirm button
	
	//output wire Ld7,
	//output wire Ld6,

	// LED outputs for game status display
	output wire Ld13,
	output wire Ld12,
	output wire Ld11,
	output wire Ld10,
	output wire Ld9,
	output wire Ld8,
	output wire Ld5,
	output wire Ld4,
	output wire Ld3,
	output wire Ld2,
	output wire Ld1,
	output wire Ld0,

	input wire Sw0, // for reset
	input wire Sw1, // for start
	
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
	output wire Cg,
	output wire Dp,

    // VGA Outputs
    output wire [3:0] vgaR,
    output wire [3:0] vgaG,
    output wire [3:0] vgaB,
    output wire hSync,
    output wire vSync,

	// Quad SPI Flash disable
	output wire QuadSpiFlashCS

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

	// VGA signals
	wire bright;
	wire [9:0] hc, vc;
	wire [11:0] rgb;

    // Game state outputs from wordle module (flat wires to match wordle.v outputs)
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

    wire [2:0] current_guess;           // Current guess number (1-6)
    wire [3:0] game_state;              // Current state of game FSM
    wire [2:0] wf_pos;                  // Current letter position being edited
    wire [4:0] wf_current_word0, wf_current_word1, wf_current_word2, wf_current_word3, wf_current_word4;
	
	// SSD signals
	reg [31:0] DIV_CLK;
	wire [2:0] ssdscan_clk;
	wire [4:0] SSD7, SSD6, SSD5, SSD4, SSD3;
	wire [4:0] SSD0;
	reg [4:0] SSD;
	reg [6:0] SSD_CATHODES;

	// RESET BTN
	wire reset_btn = Sw0;

	// Start Btn
	// FIXME: may cause issues w/ SCEN, since it is a switch, not a button
	wire start_btn = Sw1;

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
    // Button Debouncing
    // =========================================================================
    wire BtnU_debounced, BtnD_debounced, BtnL_debounced, BtnR_debounced, BtnC_debounced;

    input_debouncer debounce_up (
        .CLK(clk_100mhz),
        .RESET(reset_btn),
        .PB(BtnU),
        .DPB(BtnU_debounced)
    );

    input_debouncer debounce_down (
        .CLK(clk_100mhz),
        .RESET(reset_btn),
        .PB(BtnD),
        .DPB(BtnD_debounced)
    );

    input_debouncer debounce_left (
        .CLK(clk_100mhz),
        .RESET(reset_btn),
        .PB(BtnL),
        .DPB(BtnL_debounced)
    );

    input_debouncer debounce_right (
        .CLK(clk_100mhz),
        .RESET(reset_btn),
        .PB(BtnR),
        .DPB(BtnR_debounced)
    );

    input_debouncer debounce_center (
        .CLK(clk_100mhz),
        .RESET(reset_btn),
        .PB(BtnC),
        .DPB(BtnC_debounced)
    );

    // =========================================================================
    // Clock Divider for SSD Scanning
    // =========================================================================
    // Generate divided clock for SSD scanning (bits 20:18 used for 8-display scan)
    always @(posedge clk_100mhz or posedge reset_btn) begin
        if (reset_btn)
            DIV_CLK <= 0;
        else
            DIV_CLK <= DIV_CLK + 1;
    end

    // =========================================================================
    // Wordle Game Controller Instantiation
    // =========================================================================

    wordle game_controller (
        .clk(clk_100mhz),
        .reset(reset_btn),

        // Button inputs (debounced)
        .Start(start_btn),
        .UP(BtnU_debounced),
        .DOWN(BtnD_debounced),
        .LEFT(BtnL_debounced),
        .RIGHT(BtnR_debounced),
        .CENTER(BtnC_debounced),

        // Game state outputs (connect to VGA module in future)
        .stored_word0(stored_word0), .stored_word1(stored_word1), .stored_word2(stored_word2),
        .stored_word3(stored_word3), .stored_word4(stored_word4),

        .guess_1_0(guess_1_0), .guess_1_1(guess_1_1), .guess_1_2(guess_1_2), .guess_1_3(guess_1_3), .guess_1_4(guess_1_4),
        .guess_2_0(guess_2_0), .guess_2_1(guess_2_1), .guess_2_2(guess_2_2), .guess_2_3(guess_2_3), .guess_2_4(guess_2_4),
        .guess_3_0(guess_3_0), .guess_3_1(guess_3_1), .guess_3_2(guess_3_2), .guess_3_3(guess_3_3), .guess_3_4(guess_3_4),
        .guess_4_0(guess_4_0), .guess_4_1(guess_4_1), .guess_4_2(guess_4_2), .guess_4_3(guess_4_3), .guess_4_4(guess_4_4),
        .guess_5_0(guess_5_0), .guess_5_1(guess_5_1), .guess_5_2(guess_5_2), .guess_5_3(guess_5_3), .guess_5_4(guess_5_4),
        .guess_6_0(guess_6_0), .guess_6_1(guess_6_1), .guess_6_2(guess_6_2), .guess_6_3(guess_6_3), .guess_6_4(guess_6_4),

        .g1_status0(g1_status0), .g1_status1(g1_status1), .g1_status2(g1_status2), .g1_status3(g1_status3), .g1_status4(g1_status4),
        .g2_status0(g2_status0), .g2_status1(g2_status1), .g2_status2(g2_status2), .g2_status3(g2_status3), .g2_status4(g2_status4),
        .g3_status0(g3_status0), .g3_status1(g3_status1), .g3_status2(g3_status2), .g3_status3(g3_status3), .g3_status4(g3_status4),
        .g4_status0(g4_status0), .g4_status1(g4_status1), .g4_status2(g4_status2), .g4_status3(g4_status3), .g4_status4(g4_status4),
        .g5_status0(g5_status0), .g5_status1(g5_status1), .g5_status2(g5_status2), .g5_status3(g5_status3), .g5_status4(g5_status4),
        .g6_status0(g6_status0), .g6_status1(g6_status1), .g6_status2(g6_status2), .g6_status3(g6_status3), .g6_status4(g6_status4),

        .current_guess(current_guess),
        .game_state(game_state),
        .wf_pos(wf_pos),
        .wf_current_word0(wf_current_word0), .wf_current_word1(wf_current_word1), .wf_current_word2(wf_current_word2),
        .wf_current_word3(wf_current_word3), .wf_current_word4(wf_current_word4)
    );

    // =========================================================================
    // VGA Display Modules
    // =========================================================================

    // VGA display controller - generates timing signals
    display_controller dc (
        .clk(clk_100mhz),
        .hSync(hSync),
        .vSync(vSync),
        .bright(bright),
        .hCount(hc),
        .vCount(vc)
    );

    // Wordle VGA display - renders the game grid
    wordle_vga_display vga_display (
        .clk(clk_100mhz),
        .bright(bright),
        .hCount(hc),
        .vCount(vc),

        // Connect all game state signals
        .guess_1_0(guess_1_0), .guess_1_1(guess_1_1), .guess_1_2(guess_1_2), .guess_1_3(guess_1_3), .guess_1_4(guess_1_4),
        .guess_2_0(guess_2_0), .guess_2_1(guess_2_1), .guess_2_2(guess_2_2), .guess_2_3(guess_2_3), .guess_2_4(guess_2_4),
        .guess_3_0(guess_3_0), .guess_3_1(guess_3_1), .guess_3_2(guess_3_2), .guess_3_3(guess_3_3), .guess_3_4(guess_3_4),
        .guess_4_0(guess_4_0), .guess_4_1(guess_4_1), .guess_4_2(guess_4_2), .guess_4_3(guess_4_3), .guess_4_4(guess_4_4),
        .guess_5_0(guess_5_0), .guess_5_1(guess_5_1), .guess_5_2(guess_5_2), .guess_5_3(guess_5_3), .guess_5_4(guess_5_4),
        .guess_6_0(guess_6_0), .guess_6_1(guess_6_1), .guess_6_2(guess_6_2), .guess_6_3(guess_6_3), .guess_6_4(guess_6_4),

        .g1_status0(g1_status0), .g1_status1(g1_status1), .g1_status2(g1_status2), .g1_status3(g1_status3), .g1_status4(g1_status4),
        .g2_status0(g2_status0), .g2_status1(g2_status1), .g2_status2(g2_status2), .g2_status3(g2_status3), .g2_status4(g2_status4),
        .g3_status0(g3_status0), .g3_status1(g3_status1), .g3_status2(g3_status2), .g3_status3(g3_status3), .g3_status4(g3_status4),
        .g4_status0(g4_status0), .g4_status1(g4_status1), .g4_status2(g4_status2), .g4_status3(g4_status3), .g4_status4(g4_status4),
        .g5_status0(g5_status0), .g5_status1(g5_status1), .g5_status2(g5_status2), .g5_status3(g5_status3), .g5_status4(g5_status4),
        .g6_status0(g6_status0), .g6_status1(g6_status1), .g6_status2(g6_status2), .g6_status3(g6_status3), .g6_status4(g6_status4),

        .current_guess(current_guess),
        .game_state(game_state),
        .wf_pos(wf_pos),
        .wf_current_word0(wf_current_word0), .wf_current_word1(wf_current_word1), .wf_current_word2(wf_current_word2),
        .wf_current_word3(wf_current_word3), .wf_current_word4(wf_current_word4),

        .rgb(rgb)
    );

    // Connect RGB outputs
    assign vgaR = rgb[11:8];
    assign vgaG = rgb[7:4];
    assign vgaB = rgb[3:0];

    // Disable Quad SPI Flash
    assign QuadSpiFlashCS = 1'b1;

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
	
	// Check if each letter position has GREEN status in the IMMEDIATELY PREVIOUS guess
	reg [4:0] green_leds;  // One bit for each of the 5 LEDs (LED13-LED9) for 5 letter positions

	always @ (g1_status0, g1_status1, g1_status2, g1_status3, g1_status4,
			  g2_status0, g2_status1, g2_status2, g2_status3, g2_status4,
			  g3_status0, g3_status1, g3_status2, g3_status3, g3_status4,
			  g4_status0, g4_status1, g4_status2, g4_status3, g4_status4,
			  g5_status0, g5_status1, g5_status2, g5_status3, g5_status4,
			  g6_status0, g6_status1, g6_status2, g6_status3, g6_status4,
			  current_guess)
    begin

		// LED9 (position 0): Check if previous guess has green in position 0
		case (current_guess)
			3'd1: green_leds[0] = 1'b0;  // No previous guess
			3'd2: green_leds[0] = (g1_status0 == 2'b01);  // Check guess 1
			3'd3: green_leds[0] = (g2_status0 == 2'b01);  // Check guess 2
			3'd4: green_leds[0] = (g3_status0 == 2'b01);  // Check guess 3
			3'd5: green_leds[0] = (g4_status0 == 2'b01);  // Check guess 4
			3'd6: green_leds[0] = (g5_status0 == 2'b01);  // Check guess 5
			default: green_leds[0] = 1'b0;
		endcase

		// LED10 (position 1)
		case (current_guess)
			3'd1: green_leds[1] = 1'b0;  // No previous guess
			3'd2: green_leds[1] = (g1_status1 == 2'b01);  // Check guess 1
			3'd3: green_leds[1] = (g2_status1 == 2'b01);  // Check guess 2
			3'd4: green_leds[1] = (g3_status1 == 2'b01);  // Check guess 3
			3'd5: green_leds[1] = (g4_status1 == 2'b01);  // Check guess 4
			3'd6: green_leds[1] = (g5_status1 == 2'b01);  // Check guess 5
			default: green_leds[1] = 1'b0;
		endcase

		// LED11 (position 2)
		case (current_guess)
			3'd1: green_leds[2] = 1'b0;  // No previous guess
			3'd2: green_leds[2] = (g1_status2 == 2'b01);  // Check guess 1
			3'd3: green_leds[2] = (g2_status2 == 2'b01);  // Check guess 2
			3'd4: green_leds[2] = (g3_status2 == 2'b01);  // Check guess 3
			3'd5: green_leds[2] = (g4_status2 == 2'b01);  // Check guess 4
			3'd6: green_leds[2] = (g5_status2 == 2'b01);  // Check guess 5
			default: green_leds[2] = 1'b0;
		endcase

		// LED12 (position 3)
		case (current_guess)
			3'd1: green_leds[3] = 1'b0;  // No previous guess
			3'd2: green_leds[3] = (g1_status3 == 2'b01);  // Check guess 1
			3'd3: green_leds[3] = (g2_status3 == 2'b01);  // Check guess 2
			3'd4: green_leds[3] = (g3_status3 == 2'b01);  // Check guess 3
			3'd5: green_leds[3] = (g4_status3 == 2'b01);  // Check guess 4
			3'd6: green_leds[3] = (g5_status3 == 2'b01);  // Check guess 5
			default: green_leds[3] = 1'b0;
		endcase

		// LED13 (position 4)
		case (current_guess)
			3'd1: green_leds[4] = 1'b0;  // No previous guess
			3'd2: green_leds[4] = (g1_status4 == 2'b01);  // Check guess 1
			3'd3: green_leds[4] = (g2_status4 == 2'b01);  // Check guess 2
			3'd4: green_leds[4] = (g3_status4 == 2'b01);  // Check guess 3
			3'd5: green_leds[4] = (g4_status4 == 2'b01);  // Check guess 4
			3'd6: green_leds[4] = (g5_status4 == 2'b01);  // Check guess 5
			default: green_leds[4] = 1'b0;
		endcase

	end

	// Assign to actual LED outputs
	assign {Ld13, Ld12, Ld11, Ld10, Ld9} = green_leds;
	assign Ld8 = 1'b0;  // Tie off unused LED
	
	// =========================================================================
    // SSD controls
    // =========================================================================
	assign SSD7 = wf_current_word0;  // First letter (leftmost)
	assign SSD6 = wf_current_word1;  // Second letter
	assign SSD5 = wf_current_word2;  // Third letter
	assign SSD4 = wf_current_word3;  // Fourth letter
	assign SSD3 = wf_current_word4;  // Fifth letter

	reg [4:0] SSD0_display;

	always @ (game_state)
	begin : SSD0_SELECT
		case (game_state)
			4'b0000: SSD0_display = 5'b10010;  // Display 'S' (INI state)
			4'b0111: SSD0_display = 5'b10110;  // Display 'W' (Win)
			4'b1000: SSD0_display = 5'b01011;  // Display 'L' (Loss)
			4'b0001: SSD0_display = 5'b01000;  // Display 'I' (looks like 1 for player 1)
			4'b0011: SSD0_display = 5'b11001;  // Display 'Z' (looks like 2 for player 2)
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
			  g1_status0, g1_status1, g1_status2, g1_status3, g1_status4,
			  g2_status0, g2_status1, g2_status2, g2_status3, g2_status4,
			  g3_status0, g3_status1, g3_status2, g3_status3, g3_status4,
			  g4_status0, g4_status1, g4_status2, g4_status3, g4_status4,
			  g5_status0, g5_status1, g5_status2, g5_status3, g5_status4,
			  g6_status0, g6_status1, g6_status2, g6_status3, g6_status4,
			  current_guess)
	begin : DP_YELLOW_CHECK
		case (ssdscan_clk)
			3'b111: begin // SSD7 showing letter position 0
				case (current_guess)
					3'd1: dp_yellow = 1'b0;  // No previous guess
					3'd2: dp_yellow = (g1_status0 == 2'b10);  // Check guess 1
					3'd3: dp_yellow = (g2_status0 == 2'b10);  // Check guess 2
					3'd4: dp_yellow = (g3_status0 == 2'b10);  // Check guess 3
					3'd5: dp_yellow = (g4_status0 == 2'b10);  // Check guess 4
					3'd6: dp_yellow = (g5_status0 == 2'b10);  // Check guess 5
					default: dp_yellow = 1'b0;
				endcase
			end

			3'b110: begin // SSD6 showing letter position 1
				case (current_guess)
					3'd1: dp_yellow = 1'b0;  // No previous guess
					3'd2: dp_yellow = (g1_status1 == 2'b10);  // Check guess 1
					3'd3: dp_yellow = (g2_status1 == 2'b10);  // Check guess 2
					3'd4: dp_yellow = (g3_status1 == 2'b10);  // Check guess 3
					3'd5: dp_yellow = (g4_status1 == 2'b10);  // Check guess 4
					3'd6: dp_yellow = (g5_status1 == 2'b10);  // Check guess 5
					default: dp_yellow = 1'b0;
				endcase
			end

			3'b101: begin // SSD5 showing letter position 2
				case (current_guess)
					3'd1: dp_yellow = 1'b0;  // No previous guess
					3'd2: dp_yellow = (g1_status2 == 2'b10);  // Check guess 1
					3'd3: dp_yellow = (g2_status2 == 2'b10);  // Check guess 2
					3'd4: dp_yellow = (g3_status2 == 2'b10);  // Check guess 3
					3'd5: dp_yellow = (g4_status2 == 2'b10);  // Check guess 4
					3'd6: dp_yellow = (g5_status2 == 2'b10);  // Check guess 5
					default: dp_yellow = 1'b0;
				endcase
			end

			3'b100: begin // SSD4 showing letter position 3
				case (current_guess)
					3'd1: dp_yellow = 1'b0;  // No previous guess
					3'd2: dp_yellow = (g1_status3 == 2'b10);  // Check guess 1
					3'd3: dp_yellow = (g2_status3 == 2'b10);  // Check guess 2
					3'd4: dp_yellow = (g3_status3 == 2'b10);  // Check guess 3
					3'd5: dp_yellow = (g4_status3 == 2'b10);  // Check guess 4
					3'd6: dp_yellow = (g5_status3 == 2'b10);  // Check guess 5
					default: dp_yellow = 1'b0;
				endcase
			end

			3'b011: begin // SSD3 showing letter position 4
				case (current_guess)
					3'd1: dp_yellow = 1'b0;  // No previous guess
					3'd2: dp_yellow = (g1_status4 == 2'b10);  // Check guess 1
					3'd3: dp_yellow = (g2_status4 == 2'b10);  // Check guess 2
					3'd4: dp_yellow = (g3_status4 == 2'b10);  // Check guess 3
					3'd5: dp_yellow = (g4_status4 == 2'b10);  // Check guess 4
					3'd6: dp_yellow = (g5_status4 == 2'b10);  // Check guess 5
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
			5'b01010: SSD_CATHODES = 7'b1010000 ; // K 
			5'b01011: SSD_CATHODES = 7'b1110001 ; // L (left bar + bottom)
			5'b01100: SSD_CATHODES = 7'b0001001 ; // M (approximation)
			5'b01101: SSD_CATHODES = 7'b1101010 ; // N (left + middle + right lower)
			5'b01110: SSD_CATHODES = 7'b0000001 ; // O (same as 0)
			5'b01111: SSD_CATHODES = 7'b0011000 ; // P (upper left + top + middle)
			5'b10000: SSD_CATHODES = 7'b0001100 ; // Q (like O with tail)
			5'b10001: SSD_CATHODES = 7'b1111010 ; // R (approximation)
			5'b10010: SSD_CATHODES = 7'b0100100 ; // S (same as 5)
			5'b10011: SSD_CATHODES = 7'b1110000 ; // T (left + top + middle)
			5'b10100: SSD_CATHODES = 7'b1100011 ; // U 
			5'b10101: SSD_CATHODES = 7'b1000001 ; // V (same as U - approximation)
			5'b10110: SSD_CATHODES = 7'b1010100 ; // W 
			5'b10111: SSD_CATHODES = 7'b0101010 ; // X (same as H - approximation)
			5'b11000: SSD_CATHODES = 7'b1000100 ; // Y (like 4)
			5'b11001: SSD_CATHODES = 7'b0010010 ; // Z (same as 2)
			5'b11111: SSD_CATHODES = 7'b1111111 ; // Blank (all segments off)
			default: SSD_CATHODES = 7'b1111111 ; // default blank
		endcase
	end
endmodule
