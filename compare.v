`timescale 1ns / 1ps
//`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    compare
// Description:    Compares a 5-letter guess against a 5-letter answer for Wordle
//                 Returns color status: GREEN (correct position), YELLOW (wrong
//                 position but in word), GRAY (not in word)
//
// Note: Uses flat arrays for Vivado compatibility (no SystemVerilog unpacked arrays)
//////////////////////////////////////////////////////////////////////////////////
module compare(
    input wire Clk,
    input wire RESET,
    input wire Start,
    // Guess letters (5 letters x 5 bits each = 25 bits)
    input wire [4:0] guess0,
    input wire [4:0] guess1,
    input wire [4:0] guess2,
    input wire [4:0] guess3,
    input wire [4:0] guess4,
    // Answer letters (5 letters x 5 bits each = 25 bits)
    input wire [4:0] answer0,
    input wire [4:0] answer1,
    input wire [4:0] answer2,
    input wire [4:0] answer3,
    input wire [4:0] answer4,
    // State outputs
    output wire q_I,
    output wire q_Green,
    output wire q_YorG,
    // Status outputs (5 letters x 2 bits each)
    output reg [1:0] word_status0,
    output reg [1:0] word_status1,
    output reg [1:0] word_status2,
    output reg [1:0] word_status3,
    output reg [1:0] word_status4,
    // Done flag
    output reg cmp_done
);

    reg [2:0] state;
    assign {q_YorG, q_Green, q_I} = state;

    // States
    localparam
        INI = 3'b001,
        GREEN_CHECK = 3'b010,
        YORG = 3'b100;

    reg [2:0] I, J; // indices for guess and answer arrays (need 3 bits to reach 4)
    reg [2:0] green_counter; // counts number of green matches
   
    // Track which answer positions have been "used" (matched to a guess)
    reg [4:0] answer_used; // bit flags: answer_used[i] = 1 means answer[i] is already matched

    localparam
        Imax = 3'd4,
        Jmax = 3'd4,
        WIN_COUNT = 3'd5; // 5 greens = win

    // Colors
    localparam
        UNCHECKED = 2'b00,
        GREEN     = 2'b01,
        YELLOW    = 2'b10,
        GRAY      = 2'b11;

    // Internal wires to access guess/answer by index
    reg [4:0] guess_I;
    reg [4:0] answer_I;
    reg [4:0] answer_J;
    reg [1:0] word_status_I;
   
    // Mux to select guess[I]
    always @(*) begin
        case (I)
            3'd0: guess_I = guess0;
            3'd1: guess_I = guess1;
            3'd2: guess_I = guess2;
            3'd3: guess_I = guess3;
            3'd4: guess_I = guess4;
            default: guess_I = 5'd0;
        endcase
    end
   
    // Mux to select answer[I]
    always @(*) begin
        case (I)
            3'd0: answer_I = answer0;
            3'd1: answer_I = answer1;
            3'd2: answer_I = answer2;
            3'd3: answer_I = answer3;
            3'd4: answer_I = answer4;
            default: answer_I = 5'd0;
        endcase
    end
   
    // Mux to select answer[J]
    always @(*) begin
        case (J)
            3'd0: answer_J = answer0;
            3'd1: answer_J = answer1;
            3'd2: answer_J = answer2;
            3'd3: answer_J = answer3;
            3'd4: answer_J = answer4;
            default: answer_J = 5'd0;
        endcase
    end
   
    // Mux to select word_status[I]
    always @(*) begin
        case (I)
            3'd0: word_status_I = word_status0;
            3'd1: word_status_I = word_status1;
            3'd2: word_status_I = word_status2;
            3'd3: word_status_I = word_status3;
            3'd4: word_status_I = word_status4;
            default: word_status_I = UNCHECKED;
        endcase
    end

    always @ (posedge Clk, posedge RESET)
    begin
        if(RESET)
        begin
            state <= INI;
            cmp_done <= 0;
            I <= 3'b000;
            J <= 3'b000;
            green_counter <= 3'b000;
            answer_used <= 5'b00000;
            word_status0 <= UNCHECKED;
            word_status1 <= UNCHECKED;
            word_status2 <= UNCHECKED;
            word_status3 <= UNCHECKED;
            word_status4 <= UNCHECKED;
        end
        else
        begin
            case (state)
                // ---------------------------------------------------------
                // INITIAL STATE: Wait for Start signal
                // ---------------------------------------------------------
                INI:
                begin
                    if(Start)
                    begin
                        // Transition to GREEN_CHECK and initialize
                        state <= GREEN_CHECK;
                        cmp_done <= 0;
                        I <= 0;
                        J <= 0;
                        green_counter <= 0;
                        answer_used <= 5'b00000;
                        word_status0 <= UNCHECKED;
                        word_status1 <= UNCHECKED;
                        word_status2 <= UNCHECKED;
                        word_status3 <= UNCHECKED;
                        word_status4 <= UNCHECKED;
                    end
                end

                // ---------------------------------------------------------
                // GREEN CHECK: First pass - mark all exact position matches
                // ---------------------------------------------------------
                GREEN_CHECK:
                begin
                    if(guess_I == answer_I)
                    begin
                        // Set word_status[I] = GREEN
                        case (I)
                            3'd0: word_status0 <= GREEN;
                            3'd1: word_status1 <= GREEN;
                            3'd2: word_status2 <= GREEN;
                            3'd3: word_status3 <= GREEN;
                            3'd4: word_status4 <= GREEN;
                        endcase
                        green_counter <= green_counter + 1;
                        answer_used[I] <= 1'b1;  // Mark this answer position as used
                    end

                    // Move to next position or transition state
                    if(I == Imax)
                    begin  
                        I <= 0; // Reset for YORG state
                        // Check if all 5 are green (win condition)
                        if((green_counter == WIN_COUNT - 1) && (guess_I == answer_I))
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

                // ---------------------------------------------------------
                // YELLOW OR GRAY: Second pass - check non-green positions
                // ---------------------------------------------------------
                YORG:
                begin                  
                    if(word_status_I == UNCHECKED) // Only check positions not already GREEN
                    begin
                        // Check if guess[I] matches answer[J] AND answer[J] is not already used
                        if((guess_I == answer_J) && (answer_used[J] == 1'b0))
                        begin
                            // Found a match - mark as YELLOW
                            case (I)
                                3'd0: word_status0 <= YELLOW;
                                3'd1: word_status1 <= YELLOW;
                                3'd2: word_status2 <= YELLOW;
                                3'd3: word_status3 <= YELLOW;
                                3'd4: word_status4 <= YELLOW;
                            endcase
                            answer_used[J] <= 1'b1;  // Mark this answer position as used
                            J <= 0;  // Reset J for next guess position
                           
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
                            // Checked all answer positions, no match = GRAY
                            case (I)
                                3'd0: word_status0 <= GRAY;
                                3'd1: word_status1 <= GRAY;
                                3'd2: word_status2 <= GRAY;
                                3'd3: word_status3 <= GRAY;
                                3'd4: word_status4 <= GRAY;
                            endcase
                            J <= 0;  // Reset J for next guess position
                           
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
                        J <= 0;  // Reset J when skipping
                       
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
                end
               
                // ---------------------------------------------------------
                // DEFAULT: Safety catch - return to INI
                // ---------------------------------------------------------
                default:
                begin
                    state <= INI;
                end
            endcase
        end
    end

endmodule