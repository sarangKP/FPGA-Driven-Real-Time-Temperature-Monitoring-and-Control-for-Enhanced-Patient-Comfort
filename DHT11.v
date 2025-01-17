module DHT11(
    input clk_i,           // Input clock
    inout dht11_data,      // Single-wire communication pin
    output reg [7:0] temp_o, // Temperature output
    output reg [7:0] hum_o,  // Humidity output
    output reg done_o       // Done signal
);

    // Internal signals
    reg [3:0] state = 0;    // FSM state
    reg [5:0] bit_count = 0; // Bit counter
    reg [39:0] data_reg = 0; // 40-bit data register (DHT11 response)
    reg drive_low = 1'b0;   // Control signal to drive line low
    reg dht11_data_dir = 1'b1; // Direction control (1 = input, 0 = output)

    // Tri-state buffer for bidirectional data line
    assign dht11_data = (dht11_data_dir == 1'b0) ? 1'b0 : 1'bz;

    // Clock divider for timing control (1ms clock)
    reg [15:0] clk_div = 0;
    reg clk_1ms = 0;

    always @(posedge clk_i) begin
        clk_div <= clk_div + 1;
        if (clk_div == 16'd50000) begin
            clk_1ms <= ~clk_1ms;
            clk_div <= 0;
        end
    end

    // FSM for DHT11 communication
    always @(posedge clk_1ms) begin
        case (state)
            0: begin
                // Start state: send start signal
                drive_low <= 1'b1;
                dht11_data_dir <= 1'b0;
                state <= 1;
            end
            1: begin
                // Wait 18ms (DHT11 start signal)
                if (clk_div == 16'd18000) begin
                    drive_low <= 1'b0;
                    dht11_data_dir <= 1'b1; // Switch to input mode
                    state <= 2;
                end
            end
            2: begin
                // Wait for DHT11 response (low pulse followed by high pulse)
                if (dht11_data == 1'b0)
                    state <= 3;
            end
            3: begin
                if (dht11_data == 1'b1)
                    state <= 4;
            end
            4: begin
                // Start receiving 40 bits of data
                if (bit_count < 40) begin
                    if (dht11_data == 1'b1)
                        data_reg[39 - bit_count] <= 1'b1;
                    else
                        data_reg[39 - bit_count] <= 1'b0;

                    bit_count <= bit_count + 1;
                end else begin
                    // All bits received
                    state <= 5;
                end
            end
            5: begin
                // Parse data and finish
                hum_o <= data_reg[39:32];
                temp_o <= data_reg[23:16];
                done_o <= 1'b1;
                state <= 0; // Reset state for next operation
            end
        endcase
    end

endmodule
