`timescale 1ns / 1ps

module top_module_tb;

// Testbench signals
reg clk;
reg reset;
reg btn_up;
reg btn_down;
reg mode_switch;
wire [6:0] seg;
wire [3:0] an;
wire dht11_data;  // Mock DHT11 data line

// DUT instantiation (top-level module)
top_module uut (
    .clk(clk),
    .reset(reset),
    .dht11_data(dht11_data),
    .btn_up(btn_up),
    .btn_down(btn_down),
    .mode_switch(mode_switch),
    .seg(seg),
    .an(an)
);

// Clock generation (10ns period -> 100MHz)
always #5 clk = ~clk;

// Mock DHT11 data behavior
reg [7:0] mock_temp = 8'd30; // Mock temperature value: 30°C
reg [7:0] mock_hum = 8'd50;  // Mock humidity value: 50%
reg dht11_done = 0;

// Generate mock DHT11 responses
assign dht11_data = (dht11_done == 0) ? 1'bZ : 1'b0;  // Simulate DHT11 idle or data transmission

// DHT11 Simulation Logic
always @(posedge clk) begin
    if (reset) begin
        dht11_done <= 0;
    end else if (!dht11_done) begin
        #2000000; // Wait for a simulated DHT11 response (2ms)
        dht11_done <= 1;
    end
end

// Testbench process
initial begin
    // Initialize signals
    clk = 0;
    reset = 1;
    btn_up = 0;
    btn_down = 0;
    mode_switch = 0;

    // Apply reset
    #100;
    reset = 0;

    // Test Read Mode (mode_switch = 0)
    $display("=== Test: Read Temperature Mode ===");
    mode_switch = 0;
    #20000000; // Simulate 20ms to capture DHT11 temperature
    if (uut.display_temp == mock_temp) begin
        $display("PASS: Temperature read correctly as %d°C", uut.display_temp);
    end else begin
        $display("FAIL: Expected %d°C, got %d°C", mock_temp, uut.display_temp);
    end

    // Test Set Mode (mode_switch = 1)
    $display("=== Test: Set Temperature Mode ===");
    mode_switch = 1;

    // Simulate pressing the "up" button
    btn_up = 1;
    #1000000; // Wait 10ms
    btn_up = 0;
    #1000000; // Wait 10ms
    if (uut.display_temp == 26) begin
        $display("PASS: Temperature incremented to %d°C", uut.display_temp);
    end else begin
        $display("FAIL: Expected 26°C, got %d°C", uut.display_temp);
    end

    // Simulate pressing the "down" button
    btn_down = 1;
    #1000000; // Wait 10ms
    btn_down = 0;
    #1000000; // Wait 10ms
    if (uut.display_temp == 25) begin
        $display("PASS: Temperature decremented to %d°C", uut.display_temp);
    end else begin
        $display("FAIL: Expected 25°C, got %d°C", uut.display_temp);
    end

    // Test Mode Switching
    $display("=== Test: Switching Modes ===");
    mode_switch = 0; // Switch to Read Mode
    #100000;
    if (uut.display_temp == mock_temp) begin
        $display("PASS: Mode switch to Read Mode successful");
    end else begin
        $display("FAIL: Mode switch to Read Mode failed");
    end

    // Finish simulation
    $stop;
end

endmodule
