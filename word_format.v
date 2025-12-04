`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    word_format
// Description:    Allows user to input a 5-letter word using UP/DOWN to change
//                 letters and LEFT/RIGHT to change position. CENTER confirms.
//
// Note: Uses flat ports for Vivado compatibility (no SystemVerilog unpacked arrays)
//////////////////////////////////////////////////////////////////////////////////
module word_format(
    input wire Clk,
    input wire RESET,
    input wire Start,
    input wire UP,
    input wire DOWN,
    input wire LEFT,
    input wire RIGHT,
    input wire CENTER,

    output wire q_I,
    output wire q_Let,
    output wire q_Pos,
    output reg [2:0] pos,
    // Individual word array outputs (5 letters x 5 bits each)
    output reg [4:0] word_array0,
    output reg [4:0] word_array1,
    output reg [4:0] word_array2,
    output reg [4:0] word_array3,
    output reg [4:0] word_array4,

    output reg DONE
);

    reg [2:0] state;
    assign {q_Pos, q_Let, q_I} = state;

    localparam
        I            = 3'b001,
        LetterChange = 3'b010,
        PosChange    = 3'b100;

    // Wire to get current letter value based on pos
    reg [4:0] current_letter;
   
    always @(*) begin
        case (pos)
            3'd0: current_letter = word_array0;
            3'd1: current_letter = word_array1;
            3'd2: current_letter = word_array2;
            3'd3: current_letter = word_array3;
            3'd4: current_letter = word_array4;
            default: current_letter = 5'd0;
        endcase
    end

    always @ (posedge Clk, posedge RESET) begin
        if(RESET) begin
            pos <= 0;
            state <= I;
            word_array0 <= 5'd31;   // Blank
            word_array1 <= 5'd31;   // Blank
            word_array2 <= 5'd31;   // Blank
            word_array3 <= 5'd31;   // Blank
            word_array4 <= 5'd31;   // Blank
            DONE <= 1'b0;
        end
        else begin
            case(state)
                I: begin
                    // state transfers
                    if (Start) begin
                        state <= LetterChange;
                        DONE <= 1'b0; // entering set state again, reset DONE flag
                    end
                    // data transfers
                    pos <= 0;
                end

                LetterChange: begin
                    if(UP) begin
                        // Increment letter at current position
                        case (pos)
                            3'd0: word_array0 <= (word_array0 >= 25) ? 5'd0 : word_array0 + 1;
                            3'd1: word_array1 <= (word_array1 >= 25) ? 5'd0 : word_array1 + 1;
                            3'd2: word_array2 <= (word_array2 >= 25) ? 5'd0 : word_array2 + 1;
                            3'd3: word_array3 <= (word_array3 >= 25) ? 5'd0 : word_array3 + 1;
                            3'd4: word_array4 <= (word_array4 >= 25) ? 5'd0 : word_array4 + 1;
                        endcase
                    end
                    else if(DOWN) begin
                        // Decrement letter at current position
                        case (pos)
                            3'd0: word_array0 <= (word_array0 == 0 || word_array0 > 25) ? 5'd25 : word_array0 - 1;
                            3'd1: word_array1 <= (word_array1 == 0 || word_array1 > 25) ? 5'd25 : word_array1 - 1;
                            3'd2: word_array2 <= (word_array2 == 0 || word_array2 > 25) ? 5'd25 : word_array2 - 1;
                            3'd3: word_array3 <= (word_array3 == 0 || word_array3 > 25) ? 5'd25 : word_array3 - 1;
                            3'd4: word_array4 <= (word_array4 == 0 || word_array4 > 25) ? 5'd25 : word_array4 - 1;
                        endcase
                    end
                    else if (RIGHT) begin
                        // Move position right AND switch to PosChange state
                        if(pos == 4)
                            pos <= 0;
                        else
                            pos <= pos + 1;
                        state <= PosChange;
                    end
                    else if (LEFT) begin
                        // Move position left AND switch to PosChange state
                        if(pos == 0)
                            pos <= 4;
                        else
                            pos <= pos - 1;
                        state <= PosChange;
                    end
                    else if (CENTER) begin
                        DONE <= 1'b1;
                        state <= I;
                    end
                end

                PosChange: begin
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
               
                default: begin
                    state <= I;
                end
            endcase
        end
    end

endmodule