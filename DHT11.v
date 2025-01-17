module DHT11 (
    input clk_i,            // Input clock
    inout w1_o,             // Bidirectional data line to/from DHT11
    output reg done_o,      // Signal indicating data transmission complete
    output reg [7:0] temp_o,// 8-bit temperature data
    output reg [7:0] hum_o, // 8-bit humidity data
    output w1_d             // Drive enable signal
);

// Tri-state driver for the DHT11 data line
reg data_dir;
reg data_out;
assign w1_o = (data_dir) ? data_out : 1'bz;

// State machine states
localparam INIT       = 3'b000;
localparam START      = 3'b001;
localparam WAIT_RESP  = 3'b010;
localparam READ_DATA  = 3'b011;
localparam DONE       = 3'b100;

// Internal signals
reg [2:0] state = INIT;
reg [39:0] data;
reg [5:0] bit_count;
reg [15:0] counter;

always @(posedge clk_i) begin
    case (state)
        INIT: begin
            data_dir <= 1;    // Drive the line low
            data_out <= 0;
            counter <= 0;
            state <= START;
        end

        START: begin
            if (counter < 16000) begin // Wait 1ms
                counter <= counter + 1;
            end else begin
                data_dir <= 0; // Release the line
                state <= WAIT_RESP;
            end
        end

        WAIT_RESP: begin
            if (w1_o == 0) begin // Wait for DHT11 response
                state <= READ_DATA;
                counter <= 0;
                bit_count <= 0;
                data <= 40'b0;
            end
        end

        READ_DATA: begin
            if (bit_count < 40) begin
                if (counter < 200) begin
                    counter <= counter + 1;
                end else begin
                    data <= {data[38:0], w1_o}; // Shift in the data bit
                    bit_count <= bit_count + 1;
                    counter <= 0;
                end
            end else begin
                state <= DONE;
            end
        end

        DONE: begin
            hum_o <= data[39:32];   // Extract humidity
            temp_o <= data[23:16];  // Extract temperature
            done_o <= 1;            // Signal that reading is done
            state <= INIT;          // Reset state
        end
    endcase
end

endmodule
