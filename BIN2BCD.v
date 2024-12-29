module BIN2BCD(	
	input clk_i, 
	input [7:0] bin_i, 
	output [6:0] uni_o, 
	output [6:0] dec_o, 
	output [6:0] cen_o
    );

reg [7:0] binR = 8'b0; 	//This way, inputs are registered
always @(posedge clk_i)
	binR <= bin_i; 
//How to convert 8 bits to 3 BCD?
reg [3:0] DEC; 
reg [3:0] CEN; 
reg [3:0] UNI; 
integer i; 
always @(binR) begin
	DEC = 4'b0; 
	CEN = 4'b0; 
	UNI = 4'b0; 

	for(i=7; i>=0; i=i-1) begin 
		if(CEN >= 5)
			CEN = CEN+3; 
		if(DEC >= 5)
			DEC = DEC+3; 
		if(UNI >= 5)
			UNI = UNI+3;
		CEN = CEN<<1; 
		CEN[0] = DEC[3]; 
		DEC = DEC<<1; 
		DEC[0] = UNI[3];
		UNI = UNI<<1; 
		UNI[0] = binR[i];  
	end
end 

BCD27S DECODE_UNI(UNI, uni_o);	//Decode BCD to 7-seg
BCD27S DECODE_DEC(DEC, dec_o);
BCD27S DECODE_CEN(CEN, cen_o);

endmodule

module BCD27S(
	input  [3:0] bcd_in, 
	output reg 	[6:0]	seg_o
); 
	always @(bcd_in) begin //Decoder
	case(bcd_in)
		4'h0 : seg_o <= 7'b0000001; 
		4'h1 : seg_o <= 7'b1001111; 
		4'h2 : seg_o <= 7'b0010010; 
		4'h3 : seg_o <= 7'b0000110; 
		4'h4 : seg_o <= 7'b1001100; 
		4'h5 : seg_o <= 7'b0100100; 
		4'h6 : seg_o <= 7'b0100000; 
		4'h7 : seg_o <= 7'b0001111; 
		4'h8 : seg_o <= 7'b0000000; 
		4'h9 : seg_o <= 7'b0000100;
		4'hA : seg_o <= 7'b0001000;
		4'hB : seg_o <= 7'b1100000;
		4'hC : seg_o <= 7'b0110001;
		4'hD : seg_o <= 7'b1000010;
		4'hE : seg_o <= 7'b0110000;
		4'hF : seg_o <= 7'b0111000;
		default : seg_o <= 7'b1111111;	//Nothing
	endcase
end 
endmodule