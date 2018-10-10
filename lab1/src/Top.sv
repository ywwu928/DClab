module Top(
	input i_clk,
	input i_rst,
	input i_start,
	output [3:0] o_random_out
);
//reg [3:0] o_random_out;

parameter FREQ = 1;

logic clk;
logic [31:0]count_r,count_w;
logic [15:0] seed_r,seed_w;
logic [15:0] Q_w,Q_r;
logic [3:0] temp_w, temp_r;
typedef enum logic [1:0] {
   STATE_RST,STATE_IDLE,STATE_RUN
} state;
state my_state,next_state;


assign o_random_out = temp_w;


always @(posedge i_clk or negedge i_rst) begin
  if (!i_rst)
clk <= 0;
else
clk <= ~clk;

end


always @(posedge clk or negedge i_rst or posedge i_start) begin
	
	//seed_r <= seed_r + 1;
	if(!i_rst) begin
		//if(^my_state === 'x) begin

			seed_r <= 0;
			count_r <= 0;
			Q_r <= 0;
			temp_r <= 4'b0;
			my_state <= STATE_IDLE;
			
		//end
	end 
	else begin
			my_state <= next_state;
			seed_r <= seed_w;
			count_r <= count_w;
			Q_r <= Q_w;
			temp_r <= temp_w;
	end
	if(i_start)begin 
		my_state <= STATE_RST;
		//Q_r <= seed_w;
		$display("START");
		
	end

	end
always @(posedge clk) begin
		
	case(my_state)
	STATE_IDLE: begin //when i_rst pressed,STATE_RUN finished 
	//do nothing but display the last number
		//$display("IDLE");
		//temp_w = 1;
				
		//my_state <= STATE_RST;
		next_state = my_state;
		//seed_w = seed_r+1;
		count_w = count_r;
		Q_w = Q_r + 1;
		temp_w = temp_r;
	if(i_start)begin 
		next_state = STATE_RST;
		Q_w = seed_r;
		$display("START");
		
	end




	end 
	STATE_RST: begin //when i_start pressed for any given time after i_rst pressed
	//reset for running random out
		$display(seed_r);
		//Q_r<=seed;
		count_w = 0;
		//temp_r <= 0;
		//my_state <= STATE_RUN;
		next_state = STATE_RUN;
		
	end
	STATE_RUN: begin //after STATE_RST
	//run 
		count_w = count_r + FREQ;
		case(count_w) 
				 5000000,
				10000000,
				15000000,
				20000000,
				25000000,
				30000000,
				37000000,
				46000000,
				57000000,
				70000000,
				85000000,
				102000000,
				121000000,
				142000000: 	begin
									Q_w = {Q_r[0],Q_r[15:13],Q_r[12]^Q_r[0],Q_r[11:1]};
									temp_w = Q_r[3:0];
									if(temp_r == temp_w) begin
									$display("plus");
									temp_w = temp_w+1;
									end
									next_state = my_state;
								end

				142000001:	begin
									
									next_state = STATE_IDLE;
									Q_w = Q_r;
									temp_w = temp_r;
								end
						default: begin
									next_state = my_state;
									Q_w = Q_r;
									temp_w = temp_r;
									end		
		endcase

			if(i_start)begin 
			next_state = STATE_RST;
			Q_w = seed_r;
			//$display("START");
		
	end
	end
	
	endcase
end




endmodule