`timescale 1ns / 1ps

module DHT11_tb;

// Testbench signals
reg clk;
wire dht11_data;   // Mock DHT11 data line
wire [7:0] temp_o; // Temperature output from the DHT11 module
wire [7:0] hum_o;  // Humidity output from the DHT11 module
wire done_o;       // Done signal from the DHT11 module
wire w1_d;         // Indicates whether FPGA is driving the data line

// Tri-state control for the mock DHT11 sensor
reg mock_data_dir;  // Direction control: 0 = FPGA drives the line, 1 = sensor drives the line
reg mock_data_out;  // Output value for the mock sensor

assign dht11_data = (mock_data_dir) ? mock_data_out : 1'bz;

// Instantiate the DUT (DHT11 module)
DHT11 uut (
    .clk_i(clk),
    .w1_o(dht11_data),
    .done_o(done_o),
    .temp_o(temp_o),
    .hum_o(hum_o),
    .w1_d(w1_d)
);

// Clock generation (10ns period -> 100MHz)
always #5 clk = ~clk;

// Mock DHT11 Behavior
initial begin
    mock_data_dir = 1'b0; // Initially, FPGA drives the line
    mock_data_out = 1'b1; // Idle state is high
end

// Task to send a single bit
task send_bit(input bit_value);
    begin
        mock_data_out = 0; #50;  // Start bit (LOW for 50µs)
        mock_data_out = bit_value; #200;  // Send the bit (HIGH for 200µs or LOW for 50µs)
        mock_data_out = 1; #50;  // Stop bit (HIGH for 50µs)
    end
endtask

// Task to send a byte (8 bits)
task send_byte(input [7:0] byte_value);
    integer i;
    begin
        for (i = 7; i >= 0; i = i - 1) begin
            send_bit(byte_value[i]);  // Send each bit of the byte
        end
    end
endtask

// Task to simulate the entire DHT11 communication
task mock_dht11_communication(input [7:0] humidity, input [7:0] temperature);
    begin
        #18000;  // Wait for 18ms start signal from FPGA
        mock_data_dir = 1'b1;  // Sensor drives the line
        mock_data_out = 0; #80;  // Pull line LOW for 80µs
        mock_data_out = 1; #80;  // Pull line HIGH for 80µs

        // Send humidity (8 bits integer + 8 bits decimal, but decimal is 0 for DHT11)
        send_byte(humidity);    // Send integer part of humidity
        send_byte(8'b00000000); // Send decimal part of humidity (always 0 for DHT11)

        // Send temperature (8 bits integer + 8 bits decimal, but decimal is 0 for DHT11)
        send_byte(temperature); // Send integer part of temperature
        send_byte(8'b00000000); // Send decimal part of temperature (always 0 for DHT11)

        // Send checksum
        send_byte(humidity + temperature);

        mock_data_dir = 1'b0;  // Release the line
        mock_data_out = 1'b1;  // Return to idle state
    end
endtask

// Testbench process
initial begin
    // Initialize signals
    clk = 0;

    // Display simulation start
    $display("Starting DHT11 Testbench");

    // Simulate a temperature of 25°C and humidity of 50%
    fork
        mock_dht11_communication(8'd50, 8'd25);  // Humidity = 50%, Temperature = 25°C
    join

    // Wait for the communication to complete
    #200000;

    // Check the results
    if (hum_o == 8'd50 && temp_o == 8'd25 && done_o) begin
        $display("PASS: Received correct humidity (%d%%) and temperature (%d°C)", hum_o, temp_o);
    end else begin
        $display("FAIL: Incorrect data received. Humidity = %d%%, Temperature = %d°C", hum_o, temp_o);
    end

    // End simulation
    $stop;
end

endmodule
