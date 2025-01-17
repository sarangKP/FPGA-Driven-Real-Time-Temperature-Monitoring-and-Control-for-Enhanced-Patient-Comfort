module top_module (
    input clk,               // System clock
    input reset,             // Reset signal
    inout dht11_data,        // DHT11 data line
    input btn_up,            // Button to increase set temperature
    input btn_down,          // Button to decrease set temperature
    input mode_switch,       // Switch to toggle between read and set mode
    output reg [6:0] seg,    // 7-segment display segments
    output reg [3:0] an      // 7-segment display enable signals
);

// State Definitions
localparam READ_TEMP = 1'b0;
localparam SET_TEMP  = 1'b1;

// Internal Signals
wire [7:0] temp_read;
wire [7:0] hum_read;
wire dht11_done;
wire btn_up_debounced, btn_down_debounced;
reg [7:0] set_temp = 8'd25; // Default set temperature
reg [7:0] display_temp;
reg mode;

// Instantiate the DHT11 module
DHT11 dht11_inst (
    .clk_i(clk),
    .w1_o(dht11_data),
    .done_o(dht11_done),
    .temp_o(temp_read),
    .hum_o(hum_read),
    .w1_d()
);

// Debounce for buttons
debounce btn_up_debounce (
    .clk(clk),
    .reset(reset),
    .btn_in(btn_up),
    .btn_out(btn_up_debounced)
);

debounce btn_down_debounce (
    .clk(clk),
    .reset(reset),
    .btn_in(btn_down),
    .btn_out(btn_down_debounced)
);

// Mode control logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        mode <= READ_TEMP;
    end else begin
        mode <= mode_switch;
    end
end

// Set temperature adjustment logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        set_temp <= 8'd25; // Reset set temperature to 25°C
    end else if (mode == SET_TEMP) begin
        if (btn_up_debounced) begin
            set_temp <= set_temp + 1;
        end else if (btn_down_debounced) begin
            set_temp <= set_temp - 1;
        end
    end
end

// Display temperature based on mode
always @(posedge clk or posedge reset) begin
    if (reset) begin
        display_temp <= 8'd0;
    end else begin
        if (mode == READ_TEMP) begin
            display_temp <= temp_read; // Show DHT11 temperature
        end else begin
            display_temp <= set_temp;  // Show set temperature
        end
    end
end

// 7-segment display logic
reg [3:0] digit;
reg [1:0] digit_select = 2'b00;

always @(posedge clk) begin
    digit_select <= digit_select + 1'b1;
end

always @(*) begin
    case (digit_select)
        2'b00: begin
            an = 4'b1110;
            digit = display_temp % 10; // Units digit
        end
        2'b01: begin
            an = 4'b1101;
            digit = (display_temp / 10) % 10; // Tens digit
        end
        2'b10: begin
            an = 4'b1011;
            digit = 4'b1111; // Blank digit
        end
        2'b11: begin
            an = 4'b0111;
            digit = 4'b1111; // Blank digit
        end
    endcase
end

always @(*) begin
    case (digit)
        4'h0: seg = 7'b1000000;
        4'h1: seg = 7'b1111001;
        4'h2: seg = 7'b0100100;
        4'h3: seg = 7'b0110000;
        4'h4: seg = 7'b0011001;
        4'h5: seg = 7'b0010010;
        4'h6: seg = 7'b0000010;
        4'h7: seg = 7'b1111000;
        4'h8: seg = 7'b0000000;
        4'h9: seg = 7'b0010000;
        default: seg = 7'b1111111; // Blank
    endcase
end

endmodule

// DHT11 Module
module DHT11 (
    input clk_i,
    inout w1_o,
    output reg done_o,
    output reg [7:0] temp_o,
    output reg [7:0] hum_o,
    output w1_d
);
// Implementation of the DHT11 protocol
// Add the implementation here, as referenced in the initial code provided.
endmodule

// Debounce Module
module debounce (
    input clk,
    input reset,
    input btn_in,
    output reg btn_out
);
reg [15:0] cnt;
reg btn_sync, btn_stable;

always @(posedge clk or posedge reset) begin
    if (reset) begin
        cnt <= 16'd0;
        btn_sync <= 1'b0;
        btn_stable <= 1'b0;
    end else begin
        btn_sync <= btn_in;
        if (btn_sync == btn_stable) begin
            cnt <= 16'd0;
        end else begin
            cnt <= cnt + 1'b1;
            if (cnt == 16'd65535) begin
                btn_stable <= btn_sync;
                cnt <= 16'd0;
            end
        end
    end
    btn_out <= btn_stable;
end

endmodule
