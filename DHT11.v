module DHT11(
	input clk_i,  				//@100 MHz (the same for all modules)
	inout w1_o, 				//wire of communication 
	output reg done_o, 			//Tells when transfer is done 
	output reg [7:0] temp_o,	//8-b temp integer
	output reg [7:0] hum_o, 	//8-b HR integer.
	output 		w1_d 			//Shows when FPGA is asking for data 
); 
//w1, w1_o and enw1 are part of a tri-buffer
//where w1 is the input signal, w1_o the output signal
//and enw1 is the enable signal  
	reg enw1 = 1'b1;	
	reg w1 = 1'b0; 		
	assign w1_d = ~w1; 	//Is high when FPGA is asking for data (driving w1_o to 0).
	assign w1_o = enw1 ? w1 : 1'bZ;  //Tri-buffering 

	//5.12 us clock 
	reg [7:0] div = 8'b0; 
	always @(posedge clk_i) begin 
		div <= div+1'b1; 
	end 
	wire clk_512us; 
	assign clk_512us = div[7]; //This is the 5.12 us clock
	
	//up to 1.342 s counter 
	reg [17:0] cnt_42ms = 18'b0; 
	reg rst_cnt = 1'b1; 

	always @(posedge clk_512us, negedge rst_cnt) begin 
		if(!rst_cnt)
			cnt_42ms <= 18'b0; 
		else
			cnt_42ms <= cnt_42ms+1'b1;  
	end 
	wire f20ms; 

	assign f20ms = (cnt_42ms==18'h0DBC); //Is  high every 18.0019 ms 
	wire timeOut; 
	assign timeOut = &cnt_42ms[17:2]; //Indicates when cnt_42ms has reached its maximum
									//This signal is used as a timer for asking for new data
	reg shift = 1'b0; //Tells when to register incoming bits into a shift register
	
	//FSM 
	reg rst_41 = 1'b0; 
	wire done_41; 
	reg [3:0] state = 4'h0; 
	reg [3:0] nextState = 4'h0;
	always @(state, f20ms, w1_o, done_41, timeOut) begin 
		case(state)
			4'h0: begin //Start State
				rst_cnt <= 1'b1; 	
				enw1 <= 1'b1;		//Enable tri-buffer
				shift <= 1'b0; 
				rst_41 <= 1'b1;  	//Reset data cycles counter 
				done_o <= 1'b0; 
				w1 <= 1'b0;
				if(timeOut) //Has time lapsed more than usually?
					nextState <= 4'h7; //To Restart State
				else if(f20ms) 
					nextState <= 4'h1; //To HiZ State
				else
					nextState <= 4'h0; //To Start State
			end 
			4'h1: begin //HiZ State
				rst_cnt <= 1'b0; 	//Reset cnt_42ms counter
				enw1 <= 1'b0;		//Set w1_o to High Impedance 
				shift <= 1'b0; 	
				rst_41 <= 1'b1;
				done_o <= 1'b0; 
				w1 <= 1'b1; 	
				if(timeOut) 
					nextState <= 4'h7; //To Restart State
				else if(w1_o)	//Now w1_o is being driven by the sensor
								//Look if DTH11 has changed the state of this wire  
					nextState <= 4'h1; //To HiZ State
				else 
					nextState <= 4'h2; //To DL State
			end 
			4'h2: begin //DL State (LOW state of Data cycle State)
				rst_cnt <= 1'b0; 
				enw1 <= 1'b0;
				shift <= 1'b0; 
				rst_41 <= 1'b1;
				done_o <= 1'b0; 
				w1 <= 1'b1; 
				if(timeOut) 
					nextState <= 4'h7; //To Restart State
				else if(w1_o) //Is w1_o wire HIGH?
					nextState <= 4'h3; //To DH State
				else 
					nextState <= 4'h2; //To DL State
			end 
			4'h3: begin //DH State (HIGH state of Data cycle State)
				rst_cnt <= 1'b1; //Stop reseting cnt_42ms
								//(cnt_42ms is used to measure w1_o's HIGH pulse length)
				enw1 <= 1'b0;
				shift <= 1'b0; 
				rst_41 <= 1'b1;
				done_o <= 1'b0; 
				w1 <= 1'b1; 
				if(timeOut) 
					nextState <= 4'h7; //To Restart State
				else if(w1_o) 
					nextState <= 4'h3; //To DH State
				else 
					nextState <= 4'h4; //To Check State
			end 
			4'h4: begin //Check State (Check if all data cycles are done yet State)
				rst_cnt <= 1'b1; 
				enw1 <= 1'b0;
				shift <= 1'b1; //Shift received data register
				rst_41 <= 1'b1;
				done_o <= 1'b0; 
				w1 <= 1'b1; 
				if(timeOut) 
					nextState <= 4'h7; //To Restart State
				else if(done_41) //(Has 42 data cycles happened yet?)
					nextState <= 4'h5; //To Done State
				else 
					nextState <= 4'h2; //To DL State
			end
			4'h5: begin //Done State
				rst_cnt <= 1'b0; 
				enw1 <= 1'b0;
				shift <= 1'b0; 
				rst_41 <= 1'b1;
				done_o <= 1'b1; //Indicates that transfer is done 
				w1 <= 1'b1;  
				nextState <= 4'h7; //To Delay State
			end
			4'h6: begin //Delay State (wait 1.342 seconds before ...
						//asking for new data State)
				rst_cnt <= 1'b1; 
				enw1 <= 1'b0;
				shift <= 1'b0; 
				rst_41 <= 1'b0;	//Reset received bits counter
				done_o <= 1'b0; 
				w1 <= 1'b1; 
				if(timeOut)
					nextState <= 4'h7; //To Restart State
				else 
					nextState <= 4'h6; //To Delay state
			end
			4'h7: begin //Restart State (Reconfig everything)
				rst_cnt <= 1'b0; //Reset cnt_42ms counter
				enw1 <= 1'b0;
				shift <= 1'b0; 
				rst_41 <= 1'b0;
				done_o <= 1'b0; 
				w1 <= 1'b1; 
				nextState <= 4'h0; //To Start State
			end
			default: begin 
				rst_cnt <= 1'b0; 
				enw1 <= 1'b0;
				shift <= 1'b0; 
				rst_41 <= 1'b1;
				done_o <= 1'b0; 
				w1 <= 1'b0;
				nextState <= 4'h8; //To default
			end 
		endcase
	end 
	
	//State updating  
	always @(posedge clk_i)
		state <= nextState; 
	
	//Shift register 
	reg [39:0] dataRec = 40'b0; 
	always @(posedge shift) begin
		if(cnt_42ms < 18'hA) // <51.2us ?
			dataRec <= {dataRec[38:0], 1'b0}; //yes, new data bit is a 0
		else
			dataRec <= {dataRec[38:0], 1'b1}; //No, is a 1
	end 
	
	//41 bits counter
	reg [5:0] cnt_41 = 6'b0; 	//Counts how many cycles have happened since 
								//asking for data is done 
								//Actually, there are 42 cycles (only 40 within data)
	always @(posedge shift, negedge rst_41) begin 
		if(!rst_41) 
			cnt_41 <= 6'b0;
		else 
			cnt_41 <= cnt_41+1'b1; 
	end 
	assign done_41 = (cnt_41==6'h2A); //Indicates all data cyles has been received
	
	always @(posedge clk_i) begin //update outputs 
		if(done_41) begin 
			hum_o <= dataRec[39:32]; 
			temp_o <= dataRec[23:16]; 
		end
	end 
endmodule  
