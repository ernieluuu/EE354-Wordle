`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for Letter ROM
// Tests if letters.mem is properly loaded into ROM
//////////////////////////////////////////////////////////////////////////////////
module letter_rom_tb;

    // Clock generation
    reg clk;
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock (10ns period)
    end

    // ROM interface
    reg [15:0] addr;
    wire data;

    // Instantiate the ROM
    letter_rom uut (
        .clk(clk),
        .addr(addr),
        .data(data)
    );

    // Test variables
    integer i;
    integer ones_count;
    integer zeros_count;

    initial begin
        $display("========================================");
        $display("Letter ROM Load Test");
        $display("========================================");

        // Wait for ROM to initialize
        addr = 0;
        #20;

        // Test 1: Check if ROM has any '1' bits at all
        $display("\nTest 1: Scanning first 100 addresses...");
        ones_count = 0;
        zeros_count = 0;

        for (i = 0; i < 100; i = i + 1) begin
            addr = i;
            #10;  // Wait for ROM read
            if (data == 1'b1) ones_count = ones_count + 1;
            else zeros_count = zeros_count + 1;
        end

        $display("  Found %d ones, %d zeros", ones_count, zeros_count);
        if (ones_count == 0) begin
            $display("  FAIL: ROM appears to be all zeros - letters.mem not loaded!");
        end else begin
            $display("  PASS: ROM contains data");
        end

        // Test 2: Sample middle row of Letter A (should have some 1s)
        $display("\nTest 2: Sampling middle row of Letter A (row 24)...");
        ones_count = 0;

        for (i = 0; i < 48; i = i + 1) begin
            addr = 1152 + i;  // Row 24 of letter A (24 * 48 = 1152)
            #10;
            if (data == 1'b1) ones_count = ones_count + 1;
        end

        $display("  Found %d ones in row 24 of letter A", ones_count);

        // Test 3: Quick scan of entire ROM
        $display("\nTest 3: Quick scan of ROM (every 100th address)...");
        ones_count = 0;

        for (i = 0; i < 60000; i = i + 100) begin
            addr = i;
            #10;
            if (data == 1'b1) ones_count = ones_count + 1;
        end

        $display("  Found %d ones in sampled addresses", ones_count);

        if (ones_count == 0) begin
            $display("\nCRITICAL ERROR: ROM is completely empty!");
            $display("letters.mem file was NOT loaded.");
            $display("Fix: Add letters.mem to simulation sources in Vivado");
        end else begin
            $display("\nSUCCESS: ROM contains letter data!");
        end

        $display("\n========================================");
        $finish;
    end

endmodule
