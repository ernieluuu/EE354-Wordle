`timescale 1ns / 1ps
`default_nettype none
//////////////////////////////////////////////////////////////////////////////////
// Author: Ernest Lu
// Create Date: 12/03/2025
// File Name: wordle_tb.v
// Description: Testbench for Wordle game controller
//              Tests P1 setting word and P2 making guesses
//////////////////////////////////////////////////////////////////////////////////

module wordle_tb;

    // =========================================================================
    // Inputs (declared as reg)
    // =========================================================================
    reg Clk;
    reg SCEN;
    reg Reset;
    reg Start;
    reg UP;
    reg DOWN;
    reg LEFT;
    reg RIGHT;
    reg CENTER;

    // =========================================================================
    // Outputs (declared as wire)
    // =========================================================================
    wire [4:0] stored_word [0:4];

    wire [4:0] guess_1 [0:4];
    wire [4:0] guess_2 [0:4];
    wire [4:0] guess_3 [0:4];
    wire [4:0] guess_4 [0:4];
    wire [4:0] guess_5 [0:4];
    wire [4:0] guess_6 [0:4];

    wire [1:0] g1_status [0:4];
    wire [1:0] g2_status [0:4];
    wire [1:0] g3_status [0:4];
    wire [1:0] g4_status [0:4];
    wire [1:0] g5_status [0:4];
    wire [1:0] g6_status [0:4];

    wire [2:0] current_guess;
    wire [3:0] game_state;
    wire [2:0] wf_pos;
    wire [4:0] wf_current_word [0:4];

    // =========================================================================
    // State encoding for display
    // =========================================================================
    localparam
        INI        = 4'b0000,
        P1_SET     = 4'b0001,
        RESET_WF_1 = 4'b0010,
        P2_GUESS   = 4'b0011,
        RESET_WF_2 = 4'b0100,
        CMP        = 4'b0101,
        RESET_CMP  = 4'b0110,
        WIN        = 4'b0111,
        LOSE       = 4'b1000;

    // String variable for state display in waveform
    reg [10*8:0] state_string;

    always @(*) begin
        case (game_state)
            INI:        state_string = "INI       ";
            P1_SET:     state_string = "P1_SET    ";
            RESET_WF_1: state_string = "RESET_WF_1";
            P2_GUESS:   state_string = "P2_GUESS  ";
            RESET_WF_2: state_string = "RESET_WF_2";
            CMP:        state_string = "CMP       ";
            RESET_CMP:  state_string = "RESET_CMP ";
            WIN:        state_string = "WIN       ";
            LOSE:       state_string = "LOSE      ";
            default:    state_string = "UNKNOWN   ";
        endcase
    end

    // =========================================================================
    // Instantiate the Unit Under Test (UUT)
    // =========================================================================
    wordle uut (
        .clk(Clk),
        .reset(Reset),
        .SCEN(SCEN),
        .Start(Start),
        .UP(UP),
        .DOWN(DOWN),
        .LEFT(LEFT),
        .RIGHT(RIGHT),
        .CENTER(CENTER),
        .stored_word(stored_word),
        .guess_1(guess_1),
        .guess_2(guess_2),
        .guess_3(guess_3),
        .guess_4(guess_4),
        .guess_5(guess_5),
        .guess_6(guess_6),
        .g1_status(g1_status),
        .g2_status(g2_status),
        .g3_status(g3_status),
        .g4_status(g4_status),
        .g5_status(g5_status),
        .g6_status(g6_status),
        .current_guess(current_guess),
        .game_state(game_state),
        .wf_pos(wf_pos),
        .wf_current_word(wf_current_word)
    );

    // =========================================================================
    // Clock Generation
    // =========================================================================
    initial begin
        Clk = 0;
    end

    always begin
        #10; Clk = ~Clk;  // 20ns period = 50MHz clock
    end

    // =========================================================================
    // Main Test Stimulus
    // =========================================================================
    initial begin
        // Initialize all inputs
        Clk = 0;
        SCEN = 1;  // Enable clock permanently for testing
        Reset = 0;
        Start = 0;
        UP = 0;
        DOWN = 0;
        LEFT = 0;
        RIGHT = 0;
        CENTER = 0;

        $display("========================================");
        $display("Wordle Testbench Starting");
        $display("========================================");

        // Wait 100ns for initialization
        #100;

        // =====================================================================
        // TEST 1: P1 sets word "CRANE", P2 guesses and wins
        // =====================================================================
        $display("\nTEST 1: P1 sets CRANE, P2 wins on guess 3");
        $display("------------------------------------------");

        // Generate a reset pulse
        Reset = 1;
        #20;
        Reset = 0;
        #20;

        // Wait for INI state
        wait (game_state == INI);
        @(posedge Clk);
        #1;

        // Press Start button
        $display("Pressing Start...");
        Start = 1;
        @(posedge Clk);
        #1;
        Start = 0;

        // Wait for P1_SET state
        wait (game_state == P1_SET);
        @(posedge Clk);
        #1;
        $display("Entered P1_SET state");

        // =====================================================================
        // Player 1 enters word "CRANE" (C=2, R=17, A=0, N=13, E=4)
        // =====================================================================
        $display("\nP1 entering word: CRANE");

        // Position 0: Set to 'C' (2)
        // Press DOWN 2 times to go from A(0) to C(2)
        DOWN = 1;
        @(posedge Clk);
        #1;
        DOWN = 0;
        @(posedge Clk);
        #1;

        DOWN = 1;
        @(posedge Clk);
        #1;
        DOWN = 0;
        @(posedge Clk);
        #1;

        // Move to position 1
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 1: Set to 'R' (17)
        // Press DOWN 17 times
        repeat(17) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end

        // Move to position 2
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 2: 'A' (0) - already at A, no need to change

        // Move to position 3
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 3: Set to 'N' (13)
        repeat(13) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end

        // Move to position 4
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 4: Set to 'E' (4)
        repeat(4) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end

        // Press CENTER to confirm word
        CENTER = 1;
        @(posedge Clk);
        #1;
        CENTER = 0;
        @(posedge Clk);
        #1;

        // Wait for word_format to finish and transition to P2_GUESS
        wait (game_state == RESET_WF_1 || game_state == P2_GUESS);
        wait (game_state == P2_GUESS);
        @(posedge Clk);
        #1;

        $display("P1 word set: %c%c%c%c%c",
                 stored_word[0]+65, stored_word[1]+65,
                 stored_word[2]+65, stored_word[3]+65, stored_word[4]+65);

        // =====================================================================
        // Player 2 Guess 1: "STALE" (S=18, T=19, A=0, L=11, E=4)
        // =====================================================================
        $display("\nP2 Guess 1: STALE");

        // Position 0: Set to 'S' (18)
        repeat(18) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 1: Set to 'T' (19)
        repeat(19) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 2: 'A' (0) - already there
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 3: Set to 'L' (11)
        repeat(11) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 4: Set to 'E' (4)
        repeat(4) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end

        // Press CENTER to confirm
        CENTER = 1;
        @(posedge Clk);
        #1;
        CENTER = 0;
        @(posedge Clk);
        #1;

        // Wait for comparison and return to P2_GUESS (or WIN)
        wait (game_state == CMP);
        wait (game_state == RESET_WF_2 || game_state == WIN || game_state == LOSE);
        wait (game_state == P2_GUESS || game_state == WIN || game_state == LOSE);
        @(posedge Clk);
        #1;

        $display("Guess 1: %c%c%c%c%c  Status: %s%s%s%s%s",
                 guess_1[0]+65, guess_1[1]+65, guess_1[2]+65,
                 guess_1[3]+65, guess_1[4]+65,
                 (g1_status[0]==2'b01)?"G":(g1_status[0]==2'b10)?"Y":"-",
                 (g1_status[1]==2'b01)?"G":(g1_status[1]==2'b10)?"Y":"-",
                 (g1_status[2]==2'b01)?"G":(g1_status[2]==2'b10)?"Y":"-",
                 (g1_status[3]==2'b01)?"G":(g1_status[3]==2'b10)?"Y":"-",
                 (g1_status[4]==2'b01)?"G":(g1_status[4]==2'b10)?"Y":"-");

        // =====================================================================
        // Player 2 Guess 2: "BRAKE" (B=1, R=17, A=0, K=10, E=4)
        // =====================================================================
        $display("\nP2 Guess 2: BRAKE");

        // Position 0: Set to 'B' (1)
        DOWN = 1;
        @(posedge Clk);
        #1;
        DOWN = 0;
        @(posedge Clk);
        #1;
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 1: Set to 'R' (17)
        repeat(17) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 2: 'A' (0)
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 3: Set to 'K' (10)
        repeat(10) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 4: Set to 'E' (4)
        repeat(4) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end

        CENTER = 1;
        @(posedge Clk);
        #1;
        CENTER = 0;
        @(posedge Clk);
        #1;

        wait (game_state == CMP);
        wait (game_state == RESET_WF_2 || game_state == WIN || game_state == LOSE);
        wait (game_state == P2_GUESS || game_state == WIN || game_state == LOSE);
        @(posedge Clk);
        #1;

        $display("Guess 2: %c%c%c%c%c  Status: %s%s%s%s%s",
                 guess_2[0]+65, guess_2[1]+65, guess_2[2]+65,
                 guess_2[3]+65, guess_2[4]+65,
                 (g2_status[0]==2'b01)?"G":(g2_status[0]==2'b10)?"Y":"-",
                 (g2_status[1]==2'b01)?"G":(g2_status[1]==2'b10)?"Y":"-",
                 (g2_status[2]==2'b01)?"G":(g2_status[2]==2'b10)?"Y":"-",
                 (g2_status[3]==2'b01)?"G":(g2_status[3]==2'b10)?"Y":"-",
                 (g2_status[4]==2'b01)?"G":(g2_status[4]==2'b10)?"Y":"-");

        // =====================================================================
        // Player 2 Guess 3: "CRANE" (C=2, R=17, A=0, N=13, E=4) - CORRECT!
        // =====================================================================
        $display("\nP2 Guess 3: CRANE (correct answer)");

        // Position 0: Set to 'C' (2)
        repeat(2) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 1: Set to 'R' (17)
        repeat(17) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 2: 'A' (0)
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 3: Set to 'N' (13)
        repeat(13) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end
        RIGHT = 1;
        @(posedge Clk);
        #1;
        RIGHT = 0;
        @(posedge Clk);
        #1;

        // Position 4: Set to 'E' (4)
        repeat(4) begin
            DOWN = 1;
            @(posedge Clk);
            #1;
            DOWN = 0;
            @(posedge Clk);
            #1;
        end

        CENTER = 1;
        @(posedge Clk);
        #1;
        CENTER = 0;
        @(posedge Clk);
        #1;

        // Wait for WIN state
        wait (game_state == CMP);
        wait (game_state == WIN || game_state == RESET_WF_2);
        @(posedge Clk);
        #1;

        if (game_state == WIN) begin
            $display("\n*** PLAYER 2 WINS! ***");
            $display("Guess 3: %c%c%c%c%c  Status: GGGGG",
                     guess_3[0]+65, guess_3[1]+65, guess_3[2]+65,
                     guess_3[3]+65, guess_3[4]+65);
        end else begin
            $display("ERROR: Expected WIN state, got %s", state_string);
        end

        // Wait a bit to observe WIN state
        #200;

        $display("\n========================================");
        $display("Test Complete!");
        $display("========================================");

        #100;
        $finish;
    end

endmodule
