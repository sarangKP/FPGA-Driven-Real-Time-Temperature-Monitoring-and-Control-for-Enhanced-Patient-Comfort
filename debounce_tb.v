`timescale 1ns / 1ps

module debounce_tb;

reg clk;
reg reset;
reg btn_in;
wire btn_out;

// DUT instantiation
debounce uut (
    .clk(clk),
    .reset(reset),
    .btn_in(btn_in),
    .btn_out(btn_out)
);

// Clock generation (10ns period -> 100MHz)
always #5 clk = ~clk;

// Testbench process
initial begin
    // Initialize signals
    clk = 0;
    reset = 1;
    btn_in = 0;

    // Apply reset
    #100;
    reset = 0;

    // Simulate noisy button press
    $display("=== Test: Noisy Button Input ===");
    btn_in = 1;
    #10;
    btn_in = 0;
    #10;
    btn_in = 1;
    #10;
    btn_in = 0;
    #10;
    btn_in = 1;
    #200000; // Wait for debounce to settle
    if (btn_out == 1) begin
        $display("PASS: Button stabilized to HIGH");
    end else begin
        $display("FAIL: Button did not stabilize correctly");
    end

    // Simulate button release
    btn_in = 0;
    #200000; // Wait for debounce to settle
    if (btn_out == 0) begin
        $display("PASS: Button stabilized to LOW");
    end else begin
        $display("FAIL: Button did not stabilize correctly");
    end

    // Finish simulation
    $stop;
end

endmodule
