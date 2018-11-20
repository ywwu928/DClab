`timescale 1ns/100ps
module LED(
	input i_clk,
	input i_rst,
	input [3:0] i_state,
	input [19:0] i_addr,
    input [15:0] i_record_data,
	output [17:0] LEDR,
	output [7:0] LEDG
);

  parameter S0  = 5'b00000;
  parameter S1  = 5'b00001;
  parameter S2  = 5'b00010;
  parameter S3  = 5'b00011;
  parameter S4  = 5'b00100;
  parameter S5  = 5'b00101;
  parameter S6  = 5'b00110;
  parameter S7  = 5'b00111;
  parameter S8  = 5'b01000;
  parameter S9  = 5'b01001;
  parameter S10 = 5'b01010;
  parameter S11 = 5'b01011;
  parameter S12 = 5'b01100;
  parameter S13 = 5'b01101;
  parameter S14 = 5'b01110;
  parameter S15 = 5'b01111;
  parameter S16 = 5'b10000;
  parameter S17 = 5'b10001;
  parameter S18 = 5'b10010;
  parameter S19 = 5'b10011;
  parameter S20 = 5'b10100;
  parameter S21 = 5'b10101;
  parameter S22 = 5'b10110;
  parameter S23 = 5'b10111;
  parameter S24 = 5'b11000;
  parameter S25 = 5'b11001;
  parameter S26 = 5'b11010;
  parameter S27 = 5'b11011;
  parameter S28 = 5'b11100;
  parameter S29 = 5'b11101;
  parameter S30 = 5'b11110;
  parameter S31 = 5'b11111;

  parameter R0 	= 15'b000000000000000;
  parameter R1 	= 15'b100000000000000;
  parameter R2 	= 15'b110000000000000;
  parameter R3 	= 15'b111000000000000;
  parameter R4 	= 15'b111100000000000;
  parameter R5 	= 15'b111110000000000;
  parameter R6 	= 15'b111111000000000;
  parameter R7 	= 15'b111111100000000;
  parameter R8 	= 15'b111111110000000;
  parameter R9 	= 15'b111111111000000;
  parameter R10 = 15'b111111111100000;
  parameter R11 = 15'b111111111110000;
  parameter R12 = 15'b111111111111000;
  parameter R13 = 15'b111111111111100;
  parameter R14 = 15'b111111111111110;
  parameter R15 = 15'b111111111111111;

  parameter RW = 2'b10;
  parameter RR = 2'b01;






  logic [4:0] addr_top5;
  assign addr_top5 = i_addr[19:15];
  logic flash; 
  assign flash = i_addr[13];
  integer count_r, count_w; 
  logic [255:0]data_array_r,data_array_w;
  logic [2:0] data_volume_r, data_volume_w;
  logic [7:0]temp;
  always@(i_record_data or data_array_r) begin
      data_array_w = data_array_r << 16 + i_record_data;
      
      
  end
	task TimeBarFlash;
		input [3:0]n;
		begin
			if(i_state[0])begin
				if(flash)
					LEDR[n] = 1;
				else
					LEDR[n] = 0;
			end
		end
	endtask

  task Volume;
    begin
       // LEDG = i_record_data[7:0];
        if(i_record_data[15:8] == 0||i_record_data[15:8] == 8'b11111111) LEDG = 0;//no noise
        else 
        if(i_record_data[15:12] == 4'b0000||i_record_data[15:12] == 4'b1111) LEDG = 8'b10000000;
        else if(i_record_data[15:12] == 4'b0001||i_record_data[15:12] == 4'b1110) LEDG = 8'b11000000;
        else if(i_record_data[15:12] == 4'b0010||i_record_data[15:12] == 4'b1101) LEDG = 8'b11100000;
        else if(i_record_data[15:12] == 4'b0011||i_record_data[15:12] == 4'b1100) LEDG = 8'b11110000;
        else if(i_record_data[15:12] == 4'b0100||i_record_data[15:12] == 4'b1011) LEDG = 8'b11111000;
        else if(i_record_data[15:12] == 4'b0101||i_record_data[15:12] == 4'b1010) LEDG = 8'b11111100;
        else if(i_record_data[15:12] == 4'b0110||i_record_data[15:12] == 4'b1001) LEDG = 8'b11111110;
        else if(i_record_data[15:12] == 4'b0111||i_record_data[15:12] == 4'b1000) LEDG = 8'b11111111;
        
        //if(i_record_data[15:13] == 3'b100 || i_record_data[15:13] == 3'b011)LEDG = 8'b11111111;
        //else if(i_record_data[15:12] == 3'b010||i_record_data[15:12] == 3'b101) LEDG = 8'b11110000;
        /*
        if(data_volume_r<=3'b000) LEDG = 0;//no noise
        else if((data_volume_r<=3'b001)&&data_volume_r>3'b000) LEDG = 8'b11000000;
        else if((data_volume_r<=3'b011)&&data_volume_r>=3'b001) LEDG = 8'b11110000;
        else if((data_volume_r<=3'b111)&&data_volume_r>=3'b011) LEDG = 8'b11111100;
*/
    end
  endtask

  task PlayModeFlash;
  	begin
  	if(i_state[0])//play or record
        Volume();
  	else if(i_state[1]) begin//pause
  		if(count_r <= 6000000)begin
  			count_w = count_r +1;
  			LEDG = 8'b11111111;
  		end else if(count_r >= 6000000 && count_r <= 12000000) begin
  			count_w = count_r +1;
  			LEDG = 8'b00000000;
		  end else count_w = 0;
  	end else begin
    LEDG = 0;
    end
    end
  endtask




  	always_comb begin
	  	LEDR[15]=0; 
        LEDG = 0;
        count_w = count_r;
        PlayModeFlash();
	  	if(i_state[2]) begin//writemode
	  		LEDR[17:16] = RW;
	  		

	  	end else begin//read
	  		LEDR[17:16] = RR;

	  	end
		  	

		if(i_addr == 0)begin LEDR[14:0] = R0; end
		else if ( S2 > addr_top5 && addr_top5 >=  S0 ) begin LEDR[14:0] = R1; TimeBarFlash(14); end
		else if ( S4 > addr_top5 && addr_top5 >= S2 ) begin LEDR[14:0] = R2; TimeBarFlash(13); end
		else if ( S6 > addr_top5 && addr_top5 >= S4 ) begin LEDR[14:0] = R3; TimeBarFlash(12); end
		else if ( S8 > addr_top5 && addr_top5 >= S6 ) begin LEDR[14:0] = R4; TimeBarFlash(11); end
		else if (S10 > addr_top5 && addr_top5 >= S8 ) begin LEDR[14:0] = R5; TimeBarFlash(10); end
	    else if (S12 > addr_top5 && addr_top5 >= S10 ) begin LEDR[14:0] = R6; TimeBarFlash(9); end
		else if (S14 > addr_top5 && addr_top5 >= S12 ) begin LEDR[14:0] = R7; TimeBarFlash(8); end
		else if (S16 > addr_top5 && addr_top5 >= S14 ) begin LEDR[14:0] = R8; TimeBarFlash(7); end
		else if (S18 > addr_top5 && addr_top5 >= S16 ) begin LEDR[14:0] = R9; TimeBarFlash(6); end
		else if (S20 > addr_top5 && addr_top5 >= S18 ) begin LEDR[14:0] = R10; TimeBarFlash(5);end
		else if (S22 > addr_top5 && addr_top5 >= S20) begin LEDR[14:0] = R11; TimeBarFlash(4); end
		else if (S24 > addr_top5 && addr_top5 >= S22) begin LEDR[14:0] = R12; TimeBarFlash(3); end
		else if (S26 > addr_top5 && addr_top5 >= S24) begin LEDR[14:0] = R13; TimeBarFlash(2); end
		else if (S28 > addr_top5 && addr_top5 >= S26) begin LEDR[14:0] = R14; TimeBarFlash(1); end
		else if (S30 > addr_top5 && addr_top5 >= S28) begin LEDR[14:0] = R15; TimeBarFlash(0); end
		else if (addr_top5 >= S30) 	begin LEDR[14:0] = R15;LEDR[15] = 1; end
		else            			begin LEDR[14:0] =  R0; end


	 end

	 always_ff@(posedge i_clk or posedge i_rst)begin
	 	if(i_rst) begin
	 		count_r <= 0;
      data_array_r <= 0;
      data_volume_r <= 0;
	 	end else begin
	 		count_r <= count_w;
      data_array_r <= data_array_w;
      data_volume_r <= data_volume_w;
    end
	 end
endmodule
