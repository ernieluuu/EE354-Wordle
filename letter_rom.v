`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Letter ROM Module
// Stores 26 letter sprites (A-Z) as 48x48 pixel bitmaps
// Total storage: 26 letters × 48 × 48 = 59,904 bits
//////////////////////////////////////////////////////////////////////////////////
module letter_rom (
    input wire clk,
    input wire [15:0] addr,      // Address: 0 to 59,903
    output reg data              // 1-bit pixel data (1=draw letter, 0=transparent)
);

    // ROM storage - 59,904 bits for all letter sprites
    reg [0:0] rom [0:59903];

    // Load letter sprites from memory file
    initial begin
        $readmemb("sprites/letters.mem", rom);
    end

    // Synchronous read
    always @(posedge clk) begin
        data <= rom[addr];
    end

endmodule
