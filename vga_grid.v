module vga_grid (
    input wire clk,              // 25.175 MHz pixel clock
    input wire reset,
    output reg [3:0] vga_r,      // 4-bit red
    output reg [3:0] vga_g,      // 4-bit green
    output reg [3:0] vga_b,      // 4-bit blue
    output reg hsync,
    output reg vsync
);

    // VGA 640x480 @ 60Hz timing parameters
    localparam H_VISIBLE = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;
    localparam H_TOTAL   = 800;
    
    localparam V_VISIBLE = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;
    localparam V_TOTAL   = 525;
    
    // Wordle grid parameters
    localparam TILE_SIZE = 64;     // Each tile is 64x64 pixels
    localparam TILE_BORDER = 4;    // Border around each tile
    localparam GRID_START_X = 160; // Center the 5-wide grid: (640 - 5*64)/2
    localparam GRID_START_Y = 64;  // Start grid 64 pixels from top
    
    // Letter sprite parameters (stored in tile, centered with padding)
    localparam LETTER_SIZE = 48;   // Letter is 48x48 within 64x64 tile
    localparam LETTER_OFFSET = 8;  // 8-pixel padding on each side
    
    // Color definitions (4-bit per channel)
    localparam COLOR_EMPTY     = 12'hFFF; // White background
    localparam COLOR_GRAY      = 12'h787; // Gray (wrong letter)
    localparam COLOR_YELLOW    = 12'hCC5; // Yellow (wrong position)
    localparam COLOR_GREEN     = 12'h6C5; // Green (correct)
    localparam COLOR_BORDER    = 12'hCCC; // Light gray border
    localparam COLOR_BG        = 12'h111; // Dark background
    localparam COLOR_LETTER    = 12'h000; // Black letter
    
    // Horizontal and vertical counters
    reg [9:0] h_count;
    reg [9:0] v_count;
    
    // Visible area flags
    wire h_visible = (h_count < H_VISIBLE);
    wire v_visible = (v_count < V_VISIBLE);
    wire visible = h_visible && v_visible;
    
    // Grid state storage: [letter(5 bits) | color_state(2 bits)]
    // letter: 0-25 = A-Z, 26 = empty
    // color_state: 0=empty/white, 1=gray, 2=yellow, 3=green
    reg [6:0] grid [0:5][0:4];
    
    // Initialize grid with example Wordle game
    integer i, j;
    initial begin
        // Clear grid
        for (i = 0; i < 6; i = i + 1) begin
            for (j = 0; j < 5; j = j + 1) begin
                grid[i][j] = 7'b11010_00; // 26 = empty, state 0
            end
        end
        
        // Example: CRANE (row 0) - some correct
        grid[0][0] = {5'd2,  2'd1};  // C - gray
        grid[0][1] = {5'd17, 2'd2};  // R - yellow
        grid[0][2] = {5'd0,  2'd3};  // A - green
        grid[0][3] = {5'd13, 2'd1};  // N - gray
        grid[0][4] = {5'd4,  2'd2};  // E - yellow
        
        // Example: STALE (row 1)
        grid[1][0] = {5'd18, 2'd1};  // S - gray
        grid[1][1] = {5'd19, 2'd1};  // T - gray
        grid[1][2] = {5'd0,  2'd3};  // A - green
        grid[1][3] = {5'd11, 2'd2};  // L - yellow
        grid[1][4] = {5'd4,  2'd3};  // E - green
    end
    
    // Calculate which grid cell we're in
    wire [9:0] x_in_grid = h_count - GRID_START_X;
    wire [9:0] y_in_grid = v_count - GRID_START_Y;
    
    wire in_grid_x = (h_count >= GRID_START_X) && (h_count < GRID_START_X + 5*TILE_SIZE);
    wire in_grid_y = (v_count >= GRID_START_Y) && (v_count < GRID_START_Y + 6*TILE_SIZE);
    wire in_grid = in_grid_x && in_grid_y;
    
    wire [2:0] grid_col = x_in_grid / TILE_SIZE; // 0-4
    wire [2:0] grid_row = y_in_grid / TILE_SIZE; // 0-5
    
    // Position within current tile
    wire [5:0] tile_x = x_in_grid % TILE_SIZE;
    wire [5:0] tile_y = y_in_grid % TILE_SIZE;
    
    // Check if we're in the border region of a tile
    wire in_border = (tile_x < TILE_BORDER) || (tile_x >= TILE_SIZE - TILE_BORDER) ||
                     (tile_y < TILE_BORDER) || (tile_y >= TILE_SIZE - TILE_BORDER);
    
    // Get current cell data
    wire [6:0] cell_data = grid[grid_row][grid_col];
    wire [4:0] letter_index = cell_data[6:2];
    wire [1:0] color_state = cell_data[1:0];
    
    // Determine background color based on state
    reg [11:0] tile_bg_color;
    always @(*) begin
        case(color_state)
            2'd0: tile_bg_color = COLOR_EMPTY;
            2'd1: tile_bg_color = COLOR_GRAY;
            2'd2: tile_bg_color = COLOR_YELLOW;
            2'd3: tile_bg_color = COLOR_GREEN;
        endcase
    end
    
    // Letter sprite lookup
    // Position within the letter sprite area (48x48 centered in tile)
    wire [5:0] letter_x = tile_x - LETTER_OFFSET;
    wire [5:0] letter_y = tile_y - LETTER_OFFSET;
    wire in_letter_area = (tile_x >= LETTER_OFFSET) && (tile_x < LETTER_OFFSET + LETTER_SIZE) &&
                          (tile_y >= LETTER_OFFSET) && (tile_y < LETTER_OFFSET + LETTER_SIZE);
    
    // Letter ROM address calculation
    wire [10:0] letter_addr = letter_index * LETTER_SIZE * LETTER_SIZE + 
                              letter_y * LETTER_SIZE + letter_x;
    wire letter_pixel;
    
    // Letter ROM instance (would be initialized from a .mem file)
    letter_rom letter_memory (
        .clk(clk),
        .addr(letter_addr),
        .data(letter_pixel)
    );
    
    // VGA timing generation
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            h_count <= 0;
            v_count <= 0;
        end else begin
            // Horizontal counter
            if (h_count == H_TOTAL - 1) begin
                h_count <= 0;
                // Vertical counter
                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;
            end else begin
                h_count <= h_count + 1;
            end
        end
    end
    
    // Sync signal generation
    always @(posedge clk) begin
        hsync <= (h_count >= H_VISIBLE + H_FRONT) && 
                 (h_count < H_VISIBLE + H_FRONT + H_SYNC);
        vsync <= (v_count >= V_VISIBLE + V_FRONT) && 
                 (v_count < V_VISIBLE + V_FRONT + V_SYNC);
    end
    
    // Color output with 1-cycle pipeline for letter ROM read
    reg in_grid_d, in_border_d, in_letter_area_d;
    reg [11:0] tile_bg_color_d;
    
    always @(posedge clk) begin
        // Pipeline delay for ROM read
        in_grid_d <= in_grid;
        in_border_d <= in_border;
        in_letter_area_d <= in_letter_area;
        tile_bg_color_d <= tile_bg_color;
    end
    
    // RGB output multiplexer
    always @(posedge clk) begin
        if (visible) begin
            if (in_grid_d) begin
                if (in_border_d) begin
                    // Draw tile border
                    {vga_r, vga_g, vga_b} <= COLOR_BORDER;
                end else if (in_letter_area_d && letter_pixel && letter_index < 26) begin
                    // Draw letter (black on colored background)
                    {vga_r, vga_g, vga_b} <= COLOR_LETTER;
                end else begin
                    // Draw tile background
                    {vga_r, vga_g, vga_b} <= tile_bg_color_d;
                end
            end else begin
                // Outside grid - dark background
                {vga_r, vga_g, vga_b} <= COLOR_BG;
            end
        end else begin
            // Blanking period
            {vga_r, vga_g, vga_b} <= 12'h000;
        end
    end

endmodule

// Letter ROM module (simplified - would need actual letter bitmap data)
module letter_rom (
    input wire clk,
    input wire [10:0] addr,  // 26 letters * 48 * 48 = ~60K pixels
    output reg data
);
    // This would be initialized with actual letter bitmaps
    // For now, just a placeholder that draws a simple pattern
    always @(posedge clk) begin
        // Simple pattern for demonstration
        // In reality, you'd use: initial $readmemb("letters.mem", rom);
        data <= addr[3] ^ addr[4]; // Creates a simple pattern
    end
endmodule