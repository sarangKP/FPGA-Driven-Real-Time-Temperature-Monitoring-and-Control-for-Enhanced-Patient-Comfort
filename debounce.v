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
