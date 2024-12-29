module DHT11wdisp(
	input clk_i, 		//@50 MHz (the same for all modules)
	inout w1_o, 		//Data wire of DHT11
	output [6:0] DISP, 	//Segments of 7-seg display
	output [3:0] AN,	//Anodes of 4 7-seg display
	output LED_d		//LED that blinks at each transfer
    );
wire [15:0] dataDisp; 	//{8 bits of temp, 8 bits of HR}
//HR stands for "Humedad Relativa" (Relative Humidity but in spanish)
DHT11 DH_U0( //Module that receives DHT11 data
	.clk_i 	(clk_i),
	.w1_o	(w1_o),
	.temp_o	(dataDisp[15:8]),
	.hum_o	(dataDisp[7:0]), 
	.w1_d 	(LED_d)
); 

wire [13:0] temp_7s; //2 Digits in 7-seg form of read temperature 
BIN2BCD DECOD_Temp(	//Module that decods BIN to BCD and then to 7-seg 
	.clk_i	(clk_i), 
	.bin_i 	(dataDisp[15:8]), 
	.uni_o	(temp_7s[6:0]), 
	.dec_o  (temp_7s[13:7])
);

wire [13:0] hum_7s; //2 Digits in 7-seg form of read HR 
BIN2BCD DECOD_Hum(
	.clk_i	(clk_i), 
	.bin_i 	(dataDisp[7:0]), 
	.uni_o	(hum_7s[6:0]), 
	.dec_o  (hum_7s[13:7])
); 

reg [26:0] div = 27'b0;  //Divider to swith data to display 
						//(HR or temp)
always @(posedge clk_i)
	div <= div+1'b1; 

reg switchDisp = 1'b0; 
always @(posedge div[26])	//Switch everv 2^27/(50*10^6)= 2.68s
	switchDisp <= ~switchDisp; 

reg [27:0] num2disp = 28'b0; //Register of data to be displayed 
always @(switchDisp, temp_7s, hum_7s) begin //Mux for switching data
	if(switchDisp)
		num2disp <= {temp_7s, 7'b0011100, 7'b0110001};	//{<temp>,'°','C'}
	else
		num2disp <= {hum_7s, 7'b1001000, 7'b1111010};	//{<HR>,'H','r'}
end 

disp7 DISP_U0( //Module that controls 4x 7-seg displays. 
	.clk_i		(clk_i), 
	.number_i	(num2disp),
	.seg_o		(DISP), 
	.an_o		(AN)
); 
endmodule
