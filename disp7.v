module disp7(
	input clk_i, 
	input [27:0] number_i, //4x 7-seg data cluster
	output reg [6:0] seg_o, 
	output reg [3:0] an_o
    );

reg [15:0] div = 16'b0; //frequency divider 
always @(posedge clk_i)
	div <= div+1'b1; 

always @(div[15:14], number_i) begin 	//Sweeps values to be displayed 
									//for each digit. 
	case(div[15:14]) 
		2'h0: begin 
			an_o 	<= 4'b1110; 
			seg_o 	<= number_i[6:0];
		end 
		2'h1: begin 
			an_o 	<= 4'b1101; 
			seg_o 	<= number_i[13:7];
		end 
		2'h2: begin 
			an_o 	<= 4'b1011; 
			seg_o 	<= number_i[20:14];
		end 
		2'h3: begin 
			an_o 	<= 4'b0111; 
			seg_o 	<= number_i[27:21];
		end  
		default: begin 
			an_o 	<= 4'b1111; 
			seg_o 	<= 7'b1111111;
		end 
	endcase 
end 

endmodule
