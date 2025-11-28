`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu

// slows 100MHz clock to desired frequency
// max_count = 100_000_000 / (2 * desired_frequency)

//////////////////////////////////////////////////////////////////////////////////

module create_slowed_clk #( parameter integer max_count = 714_285 ) // currently defaults to 70hz clock
(
    input wire clk_in,
    input wire rst_l,
    output reg clk_out
);

    reg[31:0] count = 0;

    always @ (posedge clk_in or negedge rst_l)   
    begin 
        if(rst_l == 0) begin
            count <= 0;
            clk_out <=0;
        end
        else if (count == max_count - 1) begin
            clk_out <= ~clk_out;
            count <= 0;
        end
        else begin
            count <= count + 1;
        end
    end

endmodule