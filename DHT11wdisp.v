module DHT11wdisp(
    input clk_i,                // Main clock
    input mode_switch,          // Switch to toggle modes (Mode 0: Read, Mode 1: Set)
    input btn_inc,              // Push button to increment temperature
    input btn_dec,              // Push button to decrement temperature
    inout w1_o,                 // Data wire of DHT11
    output [6:0] DISP,          // 7-segment display segments
    output [3:0] AN,            // 7-segment display anodes
    output LED_d,               // LED for DHT11 activity
    output LED_match            // LED lights up when set temp matches current temp
);

wire [15:0] dataDisp;           // {8 bits of temp, 8 bits of humidity}
DHT11 DH_U0(
    .clk_i(clk_i),
    .w1_o(w1_o),
    .temp_o(dataDisp[15:8]),
    .hum_o(dataDisp[7:0]),
    .w1_d(LED_d)
);

wire [13:0] temp_7s;            // 7-segment representation of temperature
BIN2BCD DECOD_Temp(
    .clk_i(clk_i),
    .bin_i(dataDisp[15:8]),
    .uni_o(temp_7s[6:0]),
    .dec_o(temp_7s[13:7])
);

wire [13:0] hum_7s;             // 7-segment representation of humidity
BIN2BCD DECOD_Hum(
    .clk_i(clk_i),
    .bin_i(dataDisp[7:0]),
    .uni_o(hum_7s[6:0]),
    .dec_o(hum_7s[13:7])
);

// Divider for display refresh
reg [26:0] div = 27'b0;
always @(posedge clk_i) div <= div + 1'b1;

// Mode Handling
reg switchDisp = 1'b0;
always @(posedge div[26]) switchDisp <= ~switchDisp;

// Register for displaying temperature or humidity
reg [27:0] num2disp = 28'b0;
wire [3:0] set_temp;            // Temperature set in Set Mode

always @(switchDisp, temp_7s, hum_7s, mode_switch, set_temp) begin
    if (mode_switch) // Mode 1: Set Mode
        num2disp <= {14'b0, 7'b0001000, set_temp}; // Display "Set X"
    else if (switchDisp) // Mode 0: Read Mode
        num2disp <= {temp_7s, 7'b0011100, 7'b0110001};  // "°C"
    else
        num2disp <= {hum_7s, 7'b1001000, 7'b1111010};   // "Hr"
end

disp7 DISP_U0(
    .clk_i(clk_i),
    .number_i(num2disp),
    .seg_o(DISP),
    .an_o(AN)
);

// Set Mode Module
SetMode SET_MODE_U0(
    .clk_i(clk_i),
    .mode_switch(mode_switch),
    .btn_inc(btn_inc),
    .btn_dec(btn_dec),
    .current_temp(dataDisp[15:8]),
    .set_temp(set_temp),
    .LED_match(LED_match)
);

endmodule
