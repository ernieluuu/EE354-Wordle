`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 11/20/2025
// File Name: wordle.v 
// Description: Core game code that handles ...
//////////////////////////////////////////////////////////////////////////////////
module wordle(
    input clk;          // clock signal
    input reset;        // reset signal

    // FIXME: needs to say the size of the registers

    // Stored word P1 sets
    output reg stored_word;
    
    // P2's guesses
    output reg guess_1;
    output reg guess_2;
    output reg guess_3;
    output reg guess_4;
    output reg guess_5;
    output reg guess_6;

    /*

    - board
    - num guesses counter?
    - checks at the end of each one...

    */

);



// Game Over Logic
always @(posedge clk) begin

end

endmodule