`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    word_format 
//////////////////////////////////////////////////////////////////////////////////
module word_format(
    input Clk,
    input SCEN,
    input RESET,
    input Start,
    input UP,
    input DOWN,
    input LEFT,
    input RIGHT,
    input CENTER,

    output q_I,
    output q_Let,
    output q_Pos,
    output reg [2:0] pos,
    output reg [4:0] word_array [0:4],    // A-Z = 26 letters = 5 bits

	output reg DONE
);

    reg [2:0] state;
    assign {q_Pos, q_Let, q_I} = state;

    localparam
        I            = 3'b001,
        LetterChange = 3'b010,
        PosChange    = 3'b100,
        UNK          = 3'bXXX;

    // wires and registers - NOTE: commented out bc its alr declared in the output declaration
    //reg [2:0] pos;              // 5 positions for letters
    //reg [4:0] word_array [0:4]; // 5 index array of 5 bit letters

    always @ (posedge Clk, posedge RESET) begin
        if(RESET) begin
            pos <= 0;
            state <= I;
            word_array[0] <= 5'd0;    // 'A'
            word_array[1] <= 5'd0;    // 'A'
            word_array[2] <= 5'd0;    // 'A'
            word_array[3] <= 5'd0;    // 'A'
            word_array[4] <= 5'd0;    // 'A'
			
			DONE <= 1'b0;
        end
        else
            case(state)
                I: begin
                    // state transfers
                    if (Start)
                        state <= LetterChange;
						DONE <= 1'b0; // entering set state again, reset DONE flag
                    // data transfers
                    pos <= 0;
                end

                LetterChange:
                    if(SCEN) begin
                        if(UP) begin
                            if (word_array[pos] >= 25)
                                word_array[pos] <= 0;
                            else
                                word_array[pos] <= word_array[pos] + 1;
                            /*
                            word_array[pos] <= word_array[pos] + 1;
                            if(word_array[pos] == 25 || word_array[pos] == 26)
                                word_array[pos] <= 0;    // wrap around back to 0
                            */
                        end
                        else if(DOWN) begin
                            if (word_array[pos] == 0)
                                word_array[pos] <= 25;
                            else
                                word_array[pos] <= word_array[pos] - 1;
                            /*
                            word_array[pos] <= word_array[pos] - 1;
                            if(word_array[pos] == 0)
                                word_array[pos] <= 25;    // wrap around back to 25
                            */
                        end
                        else if (LEFT || RIGHT)
                            state <= PosChange;
                        else if (CENTER) begin
							DONE <= 1'b1;
                            state <= I;
						end
                    end

                PosChange:
                    if(SCEN) begin
                        /*
                        if(RIGHT) begin
                            pos <= pos + 1;
                            if(pos == 5)
                                pos <= 0;
                        end
                        else if(LEFT) begin
                            pos <= pos - 1;
                            if(pos == 0)
                                pos <= 5;
                        end
                        */
                        if(RIGHT) begin
                            if(pos == 4)
                                pos <= 0;
                            else
                                pos <= pos + 1;
                        end
                        else if(LEFT) begin
                            if(pos == 0)
                                pos <= 4;
                            else
                                pos <= pos - 1;
                        end
                        else if(UP || DOWN)
                            state <= LetterChange;
                        else if(CENTER) begin
                            DONE <= 1'b1;
							state <= I;
						end
                    end
            endcase
    end

endmodule