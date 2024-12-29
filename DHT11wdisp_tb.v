`timescale 1ns/1ps

module DHT11wdisp_tb;

    // Inputs
    reg clk_i;
    reg mode_switch;
    reg btn_inc;
    reg btn_dec;
    wire [6:0] DISP;
    wire [3:0] AN;
    wire LED_d;
    wire LED_match;
    reg [7:0] simulated_temp;  // Simulated temperature input
    reg [7:0] simulated_humidity; // Simulated humidity input
    wire w1_o;

    // Clock generation
    initial clk_i = 0;
    always #5 clk_i = ~clk_i; // 100 MHz clock (10ns period)

    // Instantiate the DUT (Device Under Test)
    DHT11wdisp DUT(
        .clk_i(clk_i),
        .mode_switch(mode_switch),
        .btn_inc(btn_inc),
        .btn_dec(btn_dec),
        .w1_o(w1_o),
        .DISP(DISP),
        .AN(AN),
        .LED_d(LED_d),
        .LED_match(LED_match)
    );

    // Simulation tasks
    task simulate_temp_humidity(input [7:0] temp, input [7:0] humidity);
        begin
            simulated_temp = temp;
            simulated_humidity = humidity;
            // Simulate sensor behavior
            DUT.DH_U0.dataRec[39:32] = humidity;
            DUT.DH_U0.dataRec[23:16] = temp;
        end
    endtask

    // Test sequence
    initial begin
        // Initial values
        mode_switch = 0; // Start in Read Mode
        btn_inc = 0;
        btn_dec = 0;

        // Simulate sensor data
        simulate_temp_humidity(8'd25, 8'd60); // Temp = 25, Humidity = 60

        #200; // Wait 200 ns

        // Switch to Set Mode
        mode_switch = 1;
        #200;

        // Increment temperature set point
        btn_inc = 1; #10 btn_inc = 0; #90; // Increment to 1
        btn_inc = 1; #10 btn_inc = 0; #90; // Increment to 2
        btn_inc = 1; #10 btn_inc = 0; #90; // Increment to 3
        btn_inc = 1; #10 btn_inc = 0; #90; // Increment to 4
        btn_inc = 1; #10 btn_inc = 0; #90; // Increment to 5

        // Decrement temperature set point
        btn_dec = 1; #10 btn_dec = 0; #90; // Decrement to 4
        btn_dec = 1; #10 btn_dec = 0; #90; // Decrement to 3

        // Switch back to Read Mode
        mode_switch = 0;
        #200;

        // Simulate sensor reading to match set point
        simulate_temp_humidity(8'd3, 8'd55); // Temp = 3, Humidity = 55

        #200;

        // Observe LED_match
        $display("LED_match should light up if current temp matches set temp");
        $stop; // End simulation
    end

endmodule
