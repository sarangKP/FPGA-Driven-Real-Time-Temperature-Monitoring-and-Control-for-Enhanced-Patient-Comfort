module SetMode(
    input clk_i,                 // Main clock signal
    input mode_switch,           // Mode selection (1 = Set Mode)
    input btn_inc,               // Push button to increment temperature
    input btn_dec,               // Push button to decrement temperature
    input [7:0] current_temp,    // Current temperature from sensor
    output reg [3:0] set_temp,   // Set temperature register
    output LED_match             // LED to indicate match
);

// Debounced button signals
wire inc_stable, dec_stable;

// Debounce logic
Debounce DBNC_INC(
    .clk_i(clk_i),
    .btn_i(btn_inc),
    .btn_stable(inc_stable)
);

Debounce DBNC_DEC(
    .clk_i(clk_i),
    .btn_i(btn_dec),
    .btn_stable(dec_stable)
);

// Set temperature logic
always @(posedge clk_i) begin
    if (mode_switch) begin
        if (inc_stable && set_temp < 4'b1111) // Increment temperature
            set_temp <= set_temp + 1;
        else if (dec_stable && set_temp > 4'b0000) // Decrement temperature
            set_temp <= set_temp - 1;
    end
end

// Match LED logic
assign LED_match = (current_temp == {4'b0, set_temp}) ? 1'b1 : 1'b0;

endmodule

module Debounce(
    input clk_i,             // 100 MHz Clock
    input btn_i,             // Raw button input
    output reg btn_stable    // Stable debounced output
);
    reg [19:0] counter = 20'b0; // 20 bits for 1,000,000 cycles at 100 MHz
    reg btn_sync_1, btn_sync_2;

    // Synchronize the button input to the clock
    always @(posedge clk_i) begin
        btn_sync_1 <= btn_i;
        btn_sync_2 <= btn_sync_1;
    end

    // Debounce logic
    always @(posedge clk_i) begin
        if (btn_sync_2 == btn_stable)
            counter <= 20'b0;
        else if (counter == 20'hFFFFF)
            btn_stable <= btn_sync_2;
        else
            counter <= counter + 1;
    end
endmodule

