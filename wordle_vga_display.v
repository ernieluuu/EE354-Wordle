`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Wordle VGA Display Module
// Renders the 6x5 Wordle grid with letters and color-coded backgrounds
//////////////////////////////////////////////////////////////////////////////////
module wordle_vga_display(
    input wire clk,
    input wire bright,
    input wire [9:0] hCount,
    input wire [9:0] vCount,

    // Game state inputs from wordle.v
    input wire [4:0] guess_1_0, guess_1_1, guess_1_2, guess_1_3, guess_1_4,
    input wire [4:0] guess_2_0, guess_2_1, guess_2_2, guess_2_3, guess_2_4,
    input wire [4:0] guess_3_0, guess_3_1, guess_3_2, guess_3_3, guess_3_4,
    input wire [4:0] guess_4_0, guess_4_1, guess_4_2, guess_4_3, guess_4_4,
    input wire [4:0] guess_5_0, guess_5_1, guess_5_2, guess_5_3, guess_5_4,
    input wire [4:0] guess_6_0, guess_6_1, guess_6_2, guess_6_3, guess_6_4,

    input wire [1:0] g1_status0, g1_status1, g1_status2, g1_status3, g1_status4,
    input wire [1:0] g2_status0, g2_status1, g2_status2, g2_status3, g2_status4,
    input wire [1:0] g3_status0, g3_status1, g3_status2, g3_status3, g3_status4,
    input wire [1:0] g4_status0, g4_status1, g4_status2, g4_status3, g4_status4,
    input wire [1:0] g5_status0, g5_status1, g5_status2, g5_status3, g5_status4,
    input wire [1:0] g6_status0, g6_status1, g6_status2, g6_status3, g6_status4,

    input wire [2:0] current_guess,     // Which guess (1-6) we're on
    input wire [3:0] game_state,        // Current state
    input wire [2:0] wf_pos,            // Current letter position cursor
    input wire [4:0] wf_current_word0, wf_current_word1, wf_current_word2,
    input wire [4:0] wf_current_word3, wf_current_word4,

    output reg [11:0] rgb               // 12-bit color output
);

    // =========================================================================
    // Grid Layout Parameters
    // =========================================================================
    localparam TILE_SIZE = 10'd64;      // Each tile is 64x64 pixels
    localparam TILE_BORDER = 10'd4;     // 4-pixel border around each tile
    localparam GRID_START_X = 10'd160;  // Center horizontally: (640 - 5*64)/2
    localparam GRID_START_Y = 10'd64;   // Start 64 pixels from top

    // Letter sprite parameters (48x48 centered in 64x64 tile)
    localparam LETTER_SIZE = 6'd48;
    localparam LETTER_OFFSET = 6'd8;    // 8-pixel padding on each side

    // =========================================================================
    // Color Definitions (12-bit: 4R 4G 4B)
    // =========================================================================
    localparam COLOR_BG        = 12'h121;  // Dark background
    localparam COLOR_BORDER    = 12'h888;  // Gray border
    localparam COLOR_EMPTY     = 12'h333;  // Dark gray (empty/unchecked tile)
    localparam COLOR_GRAY      = 12'h666;  // Gray (wrong letter)
    localparam COLOR_YELLOW    = 12'hDA0;  // Yellow (wrong position)
    localparam COLOR_GREEN     = 12'h6B4;  // Green (correct)
    localparam COLOR_LETTER    = 12'hFFF;  // White letter
    localparam COLOR_CURSOR    = 12'h08F;  // Blue cursor highlight

    // Status codes from wordle.v
    localparam UNCHECKED = 2'b00;
    localparam GREEN     = 2'b01;
    localparam YELLOW    = 2'b10;
    localparam GRAY      = 2'b11;

    // Game states from wordle.v
    localparam INI        = 4'b0000;
    localparam P1_SET     = 4'b0001;
    localparam P2_GUESS   = 4'b0011;
    localparam WIN        = 4'b0111;
    localparam LOSE       = 4'b1000;

    // =========================================================================
    // Grid Position Calculation
    // =========================================================================
    wire in_grid_x = (hCount >= GRID_START_X) && (hCount < GRID_START_X + 5*TILE_SIZE);
    wire in_grid_y = (vCount >= GRID_START_Y) && (vCount < GRID_START_Y + 6*TILE_SIZE);
    wire in_grid = in_grid_x && in_grid_y;

    wire [9:0] x_in_grid = hCount - GRID_START_X;
    wire [9:0] y_in_grid = vCount - GRID_START_Y;

    wire [2:0] grid_col = x_in_grid[8:6];  // Divide by 64 (2^6)
    wire [2:0] grid_row = y_in_grid[8:6];  // Divide by 64 (2^6)

    // Position within current tile
    wire [5:0] tile_x = x_in_grid[5:0];    // Modulo 64
    wire [5:0] tile_y = y_in_grid[5:0];    // Modulo 64

    // Border detection
    wire in_border = (tile_x < TILE_BORDER) || (tile_x >= TILE_SIZE - TILE_BORDER) ||
                     (tile_y < TILE_BORDER) || (tile_y >= TILE_SIZE - TILE_BORDER);

    // Letter sprite area (centered 48x48)
    wire in_letter = (tile_x >= LETTER_OFFSET) && (tile_x < LETTER_OFFSET + LETTER_SIZE) &&
                     (tile_y >= LETTER_OFFSET) && (tile_y < LETTER_OFFSET + LETTER_SIZE);
    wire [5:0] letter_x = tile_x - LETTER_OFFSET;
    wire [5:0] letter_y = tile_y - LETTER_OFFSET;

    // =========================================================================
    // Current Tile Data Selection (Combinational)
    // =========================================================================
    reg [4:0] current_letter;
    reg [1:0] current_status;
    reg is_current_tile;  // Flag for cursor highlighting

    always @(*) begin
        // Default values
        current_letter = 5'd26;  // 26 = empty/blank
        current_status = UNCHECKED;
        is_current_tile = 1'b0;

        // Check if this is the current tile being edited
        if ((game_state == P1_SET || game_state == P2_GUESS) &&
            (grid_row == current_guess - 1) && (grid_col == wf_pos)) begin
            is_current_tile = 1'b1;
        end

        // Select letter and status based on grid position
        case (grid_row)
            3'd0: begin  // Row 1
                case (grid_col)
                    3'd0: begin current_letter = guess_1_0; current_status = g1_status0; end
                    3'd1: begin current_letter = guess_1_1; current_status = g1_status1; end
                    3'd2: begin current_letter = guess_1_2; current_status = g1_status2; end
                    3'd3: begin current_letter = guess_1_3; current_status = g1_status3; end
                    3'd4: begin current_letter = guess_1_4; current_status = g1_status4; end
                endcase
            end
            3'd1: begin  // Row 2
                case (grid_col)
                    3'd0: begin current_letter = guess_2_0; current_status = g2_status0; end
                    3'd1: begin current_letter = guess_2_1; current_status = g2_status1; end
                    3'd2: begin current_letter = guess_2_2; current_status = g2_status2; end
                    3'd3: begin current_letter = guess_2_3; current_status = g2_status3; end
                    3'd4: begin current_letter = guess_2_4; current_status = g2_status4; end
                endcase
            end
            3'd2: begin  // Row 3
                case (grid_col)
                    3'd0: begin current_letter = guess_3_0; current_status = g3_status0; end
                    3'd1: begin current_letter = guess_3_1; current_status = g3_status1; end
                    3'd2: begin current_letter = guess_3_2; current_status = g3_status2; end
                    3'd3: begin current_letter = guess_3_3; current_status = g3_status3; end
                    3'd4: begin current_letter = guess_3_4; current_status = g3_status4; end
                endcase
            end
            3'd3: begin  // Row 4
                case (grid_col)
                    3'd0: begin current_letter = guess_4_0; current_status = g4_status0; end
                    3'd1: begin current_letter = guess_4_1; current_status = g4_status1; end
                    3'd2: begin current_letter = guess_4_2; current_status = g4_status2; end
                    3'd3: begin current_letter = guess_4_3; current_status = g4_status3; end
                    3'd4: begin current_letter = guess_4_4; current_status = g4_status4; end
                endcase
            end
            3'd4: begin  // Row 5
                case (grid_col)
                    3'd0: begin current_letter = guess_5_0; current_status = g5_status0; end
                    3'd1: begin current_letter = guess_5_1; current_status = g5_status1; end
                    3'd2: begin current_letter = guess_5_2; current_status = g5_status2; end
                    3'd3: begin current_letter = guess_5_3; current_status = g5_status3; end
                    3'd4: begin current_letter = guess_5_4; current_status = g5_status4; end
                endcase
            end
            3'd5: begin  // Row 6
                case (grid_col)
                    3'd0: begin current_letter = guess_6_0; current_status = g6_status0; end
                    3'd1: begin current_letter = guess_6_1; current_status = g6_status1; end
                    3'd2: begin current_letter = guess_6_2; current_status = g6_status2; end
                    3'd3: begin current_letter = guess_6_3; current_status = g6_status3; end
                    3'd4: begin current_letter = guess_6_4; current_status = g6_status4; end
                endcase
            end
        endcase

        // Override with current word being typed for active row
        if ((game_state == P1_SET || game_state == P2_GUESS) &&
            (grid_row == current_guess - 1)) begin
            case (grid_col)
                3'd0: current_letter = wf_current_word0;
                3'd1: current_letter = wf_current_word1;
                3'd2: current_letter = wf_current_word2;
                3'd3: current_letter = wf_current_word3;
                3'd4: current_letter = wf_current_word4;
            endcase
            current_status = UNCHECKED;  // Current word not yet checked
        end
    end

    // =========================================================================
    // Tile Background Color Selection
    // =========================================================================
    reg [11:0] tile_bg_color;

    always @(*) begin
        if (is_current_tile) begin
            tile_bg_color = COLOR_CURSOR;  // Highlight current tile
        end else begin
            case (current_status)
                UNCHECKED: tile_bg_color = COLOR_EMPTY;
                GREEN:     tile_bg_color = COLOR_GREEN;
                YELLOW:    tile_bg_color = COLOR_YELLOW;
                GRAY:      tile_bg_color = COLOR_GRAY;
            endcase
        end
    end

    // =========================================================================
    // Letter ROM Interface
    // =========================================================================
    wire [15:0] letter_addr;
    wire letter_pixel;

    // Address calculation: letter_index * 2304 + letter_y * 48 + letter_x
    // 2304 = 2048 + 256 = 2^11 + 2^8
    // 48 = 32 + 16 = 2^5 + 2^4
    assign letter_addr = {current_letter, 11'd0} +  // letter * 2048
                         {current_letter, 8'd0} +   // letter * 256 (total: 2304)
                         {letter_y, 5'd0} +         // letter_y * 32
                         {letter_y, 4'd0} +         // letter_y * 16 (total: y*48)
                         {1'b0, letter_x};          // + letter_x

    // Instantiate letter ROM
    letter_rom rom (
        .clk(clk),
        .addr(letter_addr),
        .data(letter_pixel)
    );

    // =========================================================================
    // Pipeline Registers (for ROM read latency)
    // =========================================================================
    reg in_grid_d, in_border_d, in_letter_d;
    reg [11:0] tile_bg_color_d;
    reg [4:0] current_letter_d;

    always @(posedge clk) begin
        in_grid_d <= in_grid;
        in_border_d <= in_border;
        in_letter_d <= in_letter;
        tile_bg_color_d <= tile_bg_color;
        current_letter_d <= current_letter;
    end

    // =========================================================================
    // RGB Output Generation
    // =========================================================================
    always @(posedge clk) begin
        if (~bright) begin
            // Blanking period
            rgb <= 12'h000;
        end else if (in_grid_d) begin
            if (in_border_d) begin
                // Draw tile border
                rgb <= COLOR_BORDER;
            end else if (in_letter_d && letter_pixel && current_letter_d < 26) begin
                // Draw letter (white on colored background)
                rgb <= COLOR_LETTER;
            end else begin
                // Draw tile background
                rgb <= tile_bg_color_d;
            end
        end else begin
            // Outside grid - dark background
            rgb <= COLOR_BG;
        end
    end

endmodule
