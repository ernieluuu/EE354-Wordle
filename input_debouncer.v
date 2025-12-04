//////////////////////////////////////////////////////////////////////////////////
// Author: Based on reference design, adapted for EE354 Wordle
// Create Date: 12/03/2025
// File Name: input_debouncer.v
// Description: Simple 4-state button debouncer
//              Generates single-cycle pulse output on button press
//////////////////////////////////////////////////////////////////////////////////

module input_debouncer(CLK, RESET, PB, DPB);

input CLK, RESET;
input PB;
output DPB;

// Parameter: Debounce counter width
// For 100 MHz clock and mechanical buttons:
//   N_dc = 22: debounce time = 2^20 / 100MHz = 10.5 ms (recommended)
//   N_dc = 23: debounce time = 2^21 / 100MHz = 21 ms (very safe)
//
// The debounce time is calculated as: 2^(N_dc-2) / clock_frequency
parameter N_dc = 22;

reg [N_dc-1:0] debounce_count;
reg [1:0] state;

// DPB output is high only when in DPB_st state
assign DPB = (state == 2'b10);

// State encoding
localparam
    INI     = 2'b00,    // Initial state, waiting for button press
    WQ      = 2'b01,    // Wait to Qualify - debouncing the press
    DPB_st  = 2'b10,    // Debounced Press Button state - output pulse
    WFCR    = 2'b11;    // Wait For Complete Release

always @ (posedge CLK, posedge RESET)
begin
    if (RESET)  // Active high reset
    begin
        state <= INI;
        debounce_count <= 0;
    end
    else
    begin
        case (state)
            INI: begin
                // Initial state - reset counter and wait for button press
                debounce_count <= 0;
                if (PB)
                    state <= WQ;
            end

            WQ: begin
                // Wait to Qualify - debounce the press
                debounce_count <= debounce_count + 1;
                if (!PB)
                    // Button released before debounce time - false trigger
                    state <= INI;
                else if (debounce_count[N_dc-2])
                    // Button held long enough - confirmed press
                    state <= DPB_st;
            end

            DPB_st: begin
                // Output DPB pulse for one cycle, then wait for release
                debounce_count <= 0;  // Reset counter for release detection
                state <= WFCR;
            end

            WFCR: begin
                // Wait for complete release before allowing new press
                if (!PB) begin
                    debounce_count <= debounce_count + 1;
                    if (debounce_count[N_dc-2])
                        // Button released and stable - return to initial state
                        state <= INI;
                end
                else begin
                    // Button still pressed or bounced back - reset counter
                    debounce_count <= 0;
                end
            end
        endcase
    end
end

endmodule
