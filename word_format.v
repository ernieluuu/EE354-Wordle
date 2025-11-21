`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:08:25 12/01/2017 
// Design Name: 
// Module Name:    counterVerilog 
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
module word_format(
	
	input Clk, input SCEN, input RESET,
	input UP, input DOWN, input LEFT, input RIGHT,
	output pos;
	output q_I, output q_Let, output q_Pos,
	output [4:0] word_array [0:4], // A-Z = 26 letters = 5 bits
	);
	
	localparam
	I = 3'b001, LetterChange = 3'b010, PosChange = 3'b100, UNK = 3'bXXX;

	// wires and registers
	wire [2:0] pos; // 5 positions for letters
	

	always @ (posedge Clk, posedge RESET)
	begin
		if(RESET)
		begin
			pos <= 3'bXXX;
			state <= I;
		end
		else
			case(state)
				I:
				begin
					// state transfers
					if (Start) state <= LetterChange;
					// data transfers
					pos <= 0;
				end
				LetterChange:
				if(SCEN)
					begin
						if(UP)
						begin
							word_array[pos] <= word_array[pos] + 1;
							if(word_array[pos] == 25 || 26)
								word_array[pos] <= 0; // wrap around back to 0
						end
						else if(DOWN)
						begin
							word_array[pos] <= word_array[pos] - 1;
							if(word_array[pos] == 0)
								word_array[pos] <= 25; // wrap around back to 25
						end
						else if (LEFT || RIGHT)
							state <= PosChange;
					end
				
				PosChange:
				if(SCEN)
					begin
						if(RIGHT)
						begin
							pos <= pos + 1;
							if(pos == 5)
								pos <= 0;
						end
						else if(LEFT)
						begin
							pos <= pos - 1;
							if(pos == 0)
								pos <= 5;
						end
						else if(UP || DOWN)
							state <= LetterChange;
					end
				
	end
	
endmodule