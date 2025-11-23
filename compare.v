`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:08:25 12/01/2017 
// Design Name: 
// Module Name:    compare 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module compare(
	input Clk, input SCEN, input RESET, input CENTER, input Start,
	input [4:0] guess [0:4],
	input [4:0] answer [0:4],
	
	output q_I, output q_Green, output q_YorG,
	output [1:0] letter_status // 00 = unchecked, 01 = green, 10 = yellow, 11 = gray
	output [1:0] word_status [0:4], // returns gray, yellow, or green
	);

	reg [2:0] state;
	assign {q_YorG, q_Green, q_I} = state;
	
	localparam
	INI = 3'b001, GREEN = 3'b010, YORG = 3'b100, UNK = 3'bXXXX;
	
	reg [1:0] I, J; // two indices for guess and answer arrays
	
	wire [2:0] green_counter; // local flag
	
	localparam Imax = 3'b100, Jmax = 3'b100, win = 3'b101; // max array index = 4
	
	always @ (posedge Clk, posedge RESET)
	begin
		if(Reset)
		begin
			state <= I;
			I <= 2'bXX;
			J <= 2'bXX;
			green_counter <= 3'bXXX;
		end
		else
		begin
			case (state)
				INI:
				begin
				// state transitions
					if(Start)
						state <= GREEN;
				// RTL
					if(Start)
					begin
					I <= 2'b00;
					J <= 2'b00;
					green_counter = 0;
					word_status[0] <= 2'b00; word_status[1] <= 2'b00; 
					word_status[2] <= 2'b00; word_status[3] <= 2'b00;
					word_status[4] <= 2'b00; // format word_status to all gray at first
					end
				end
				
				GREEN:
				begin
				// state transitions
					if((green_counter < win) && (I == Imax))
						state <= YORG; // Not green
					if((green_counter == win)) 
						state <= INI; // All green
				
				// RTL
					if(guess[I] == answer[I])
					begin
						word_status[I] <= 2'b01; // Green
						green_counter <= green_counter + 1;
					end
					I <= I + 1;
					if(I == Imax)
						I <= 0;
					
				end
				
				YORG: // Yellow or Gray
				begin
				// state transitions
				if(I == Imax && word_status[I] != 2'b00)
					state <= INI;
					
					
				// RTL
				if(word_status[I] == 2'b00) // only check unchecked
				begin
					if((guess[I] == answer[J]) && (word_status[J] == 2'b00)) // if the letters match and the 
																			// letter is prev. unchecked
					begin
						word_status[I] <= 2'b10; // yellow logic
						I <= I + 1;
						J <= 0;
					end
					
					J <= J + 1; // gets here if it doesn't match
					if(J == Jmax) // gray logic, I is not found in the answer array
					begin
						word_status[I] = 2'b11;
						J <= 0;
						I <= I + 1; // move to next letter
					end
				end
				else
					I <= I + 1;
				
				if(I == Imax)
					I <= 0;
				
endmodule

