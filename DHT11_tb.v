`timescale 1ns / 1ps

module DHT11_tb;

    // Inputs and Outputs
    reg clk_i;
    wire dht11_data;
    wire [7:0] temp_o;
    wire [7:0] hum_o;
    wire done_o;

    // Bidirectional signal simulation
    reg mock_data_dir = 1'b0; // 1 = input, 0 = output
    reg mock_data_out = 1'b1; // Mock data line

    // DHT11 instance
    DHT11 uut (
        .clk_i(clk_i),
        .dht11_data(dht11_data),
        .temp_o(temp_o),
        .hum_o(hum_o),
        .done_o(done_o)
    );

    // Drive the dht11_data line
    assign dht11_data = (mock_data_dir == 1'b0) ? mock_data_out : 1'bz;

    // Clock generation
    initial begin
        clk_i = 0;
        forever #10 clk_i = ~clk_i; // 50MHz clock
    end

    // Testbench sequence
    initial begin
        // Initialize signals
        mock_data_dir = 0;
        mock_data_out = 1;

        // Wait for the start signal
        #100000;

        // Simulate DHT11 response
        mock_data_dir = 0;
        mock_data_out = 0; #80000;  // Low for 80us
        mock_data_out = 1; #80000;  // High for 80us
        mock_data_dir = 1;          // Switch to input (sensor drives the line)

        // Send 40 bits of data (humidity = 25, temperature = 25)
        #50000;
        mock_data_out = 1; #50000; // Start bit
        #50000;
        mock_data_out = 1; #50000; // Example data for temp/humidity

        // Wait for completion
        #1000000;

        $stop;
    end

endmodule
