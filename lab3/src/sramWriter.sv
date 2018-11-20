//code by b05901084
//o_state for idle(1100) stop(0100) record(0101) pause(0110)
//o_state[3] for idle or not,
//o_state[2] for readmode or writemode,
//o_state[0] for recording or not,
//o_state[1] for puase or not
//different from chiachen :i_pause =>i_play
//						   i_clk => i_bclk
//						   no o_LED

module SramWriter(
	input i_bclk,
	input i_rst,
	input i_enable, // From SW
	input i_play,  // From KEY
	input i_stop,	// From KEY
	input i_ready,  // From I2C
	input [15:0] i_record_data,
	output [15:0] o_SRAM_DQ,
	output [3:0]o_state,
	output o_write_n,
	output [19:0] o_addr,
	output [19:0] o_end_addr
);

	enum {IDLE, WAIT, WRITE, PAUSE, STOP} state_w, state_r;

	logic [19:0] addr_w, addr_r;
	logic [19:0] end_addr_w, end_addr_r;
	//logic new_w, new_r;
	logic write_w, write_r;
	logic [31:0] counter_w, counter_r;
	logic [3:0] o_state_w, o_state_r;


	assign o_addr = addr_r;
	assign o_write_n = write_r? 0 : 1'bz;
	assign o_SRAM_DQ = i_enable? (i_record_data) : 16'bz;
	assign o_end_addr = end_addr_r;
	assign o_state = o_state_r;

	always_comb begin
		state_w = state_r;
		addr_w = addr_r;
		write_w = write_r;
		end_addr_w = end_addr_r;
		//new_w = new_r;
		counter_w = counter_r;

		case (state_r)
			IDLE: begin
				o_state_w = 4'b1100;
					//new_w = 0;
					write_w = 0;
				if(i_enable) begin
					state_w = STOP;
					addr_w = 0;
				end

			end
			
			WAIT: begin
				o_state_w = 4'b0101;
				//end_addr_w = addr_r;
				if(!i_enable) begin
					state_w = IDLE;
					end_addr_w = addr_r;
				end else
				if(i_play) begin
					state_w = PAUSE;
				end else
				if(i_ready) begin
					state_w = WRITE;
					write_w = 1;
				end else
				if(i_stop) begin
					state_w = STOP;
				end
			end
			
			WRITE: begin
				o_state_w = 4'b0101;
				//end_addr_w = addr_r;
				if(!i_enable) begin
					state_w = IDLE;
					end_addr_w = addr_r;
				end else
				if(i_play) begin
					state_w = PAUSE;
				end else
				if(i_stop) begin
					state_w = STOP;
				end else 
				if(addr_r == 1048575) begin
					state_w = STOP;
				end else begin
					state_w = WAIT;
					//$display("W out = %d, %d", o_SRAM_DQ, o_addr);
					addr_w = addr_r + 1;
					
				end
				write_w = 0;
			end

			PAUSE: begin
				o_state_w = 4'b0110;
				//end_addr_w = addr_r;
				if(!i_enable) begin
					state_w = IDLE;
					end_addr_w = addr_r;
				end else
				if(i_play) begin
					state_w = WAIT;
				end else
				if(i_stop) begin
					state_w = STOP;
				end
			end

			STOP: begin
				o_state_w = 4'b0100;
				//end_addr_w = addr_r;
				if(!i_enable) begin
					state_w = IDLE;
					end_addr_w = addr_r;
					//addr_w = 0;
				end else
				if(i_play) begin
					state_w = WAIT;
					addr_w = 0;
				end
			end

		endcase
	end

	always_ff @(posedge i_bclk or posedge i_rst) begin
		if(i_rst) begin
			state_r <= IDLE;
			write_r <= 0;
			addr_r <= 0;
			end_addr_r <= 0;
			//new_r <= 1;
			counter_r <= 0;
			o_state_r <= 0;
		end else begin
			state_r <= state_w;
			write_r <= write_w;
			addr_r <= addr_w;
			end_addr_r <= end_addr_w;
			//new_r <= new_w;
			counter_r <= counter_w;
			o_state_r <= o_state_w;
		end
	end



endmodule // sramWriter