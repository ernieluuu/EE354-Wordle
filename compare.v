`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    compare 
//////////////////////////////////////////////////////////////////////////////////
module compare(
	input Clk, input SCEN, input RESET, input CENTER, 
	input Start,input [4:0] guess [0:4], input [4:0] answer [0:4],
	
	output q_I, output q_Green, output q_YorG,
	output [1:0] letter_status, 	// 00 = unchecked, 01 = green, 10 = yellow, 11 = gray
	output reg [1:0] word_status [0:4], // returns gray, yellow, or green

	output reg cmp_done	// flag that is set to 1 when cmp is done; important so as to not inf loop
	);

	reg [2:0] state;
	assign {q_YorG, q_Green, q_I} = state;
	
	// States
	localparam 
		INI = 3'b001, GREEN_CHECK = 3'b010, YORG = 3'b100, UNK = 3'bXXX;
	
	reg [1:0] I, J; // two indices for guess and answer arrays
	reg [2:0] green_counter; // local flag
	
	localparam 
		Imax = 3'b100, Jmax = 3'b100, win = 3'b101; // max array index = 4, win = 5 greens

	// Colors
	localparam
		UNCHECKED = 2'b00,
		GREEN     = 2'b01,
		YELLOW    = 2'b10,
		GRAY      = 2'b11;
	
	always @ (posedge Clk, posedge RESET)
	begin
		if(RESET)
		begin
			state <= INI;
			cmp_done <= 0;
			I <= 2'bXX;
			J <= 2'bXX;
			green_counter <= 3'bXXX;
		    word_status[0] <= UNCHECKED;
			word_status[1] <= UNCHECKED;
			word_status[2] <= UNCHECKED;
			word_status[3] <= UNCHECKED;
			word_status[4] <= UNCHECKED;
		end
		else
		begin
			case (state)
				INI:
				begin
					if (cmp_done == 0)
					begin
						// state transitions
						if(Start)
							state <= GREEN_CHECK;
						// RTL
						if(Start)
						begin
							I <= 0;
							J <= 0;
							green_counter <= 0;
							word_status[0] <= UNCHECKED; 
							word_status[1] <= UNCHECKED; 
							word_status[2] <= UNCHECKED; 
							word_status[3] <= UNCHECKED;
							word_status[4] <= UNCHECKED;
						end
					end
					else
						begin
							if(Start) // New game requested
								cmp_done <= 0;
						end
				end
				
				GREEN_CHECK:
				begin
					/*
					// state transitions
					if((green_counter < win) && (I == Imax))
						state <= YORG; // Not green
					if((green_counter == win)) 
						state <= INI; // All green
					*/		
					// RTL
					if(guess[I] == answer[I])
					begin
						word_status[I] <= GREEN; // Green
						green_counter <= green_counter + 1;
					end

					// Move to next position or transition state
					if(I == Imax)
					begin	
						I <= 0; // Reset for YORG state
						if(green_counter == win - 1 && guess[I] == answer[I])
						begin
							cmp_done <= 1;
							state <= INI;
						end
						else
						begin
							state <= YORG;
						end
					end
					else
						begin
							I <= I + 1;
						end
					
				end
				
				YORG: // Yellow or Gray
				begin					
					/* // state transitions
					if(I == Imax && word_status[I] != UNCHECKED)
						state <= INI;	*/

					// RTL
					if(word_status[I] == UNCHECKED) // only check unchecked
					begin
						if((guess[I] == answer[J]) && (word_status[J] != GREEN)) // if the letters match and letter not green
						begin
							word_status[I] <= YELLOW; // yellow logic
							J <= 0;
							if(I == Imax) 
							begin
								cmp_done <= 1;
								state <= INI;
							end
							else 
							begin
								I <= I + 1;
							end
						end
						else if(J == Jmax)
						begin
							// Checked all positions, no match = GRAY
							word_status[I] <= GRAY;
							J <= 0;
							if(I == Imax)
							begin
								cmp_done <= 1;
								state <= INI;
							end
							else 
							begin
								I <= I + 1;
							end
						end
						else
						begin
							J <= J + 1; // Check next answer position
						end
					end
					else // word_status[I] is already GREEN, skip it
						begin 
							if(I == Imax) 
							begin
								cmp_done <= 1;
								state <= INI;
							end
							else
							begin
								I <= I+1;
							end
						end
					end
			endcase
		end
	end
				
endmodule

