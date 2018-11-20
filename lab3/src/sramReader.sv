//code by b05901084
//the LCDdisplay design should see 
//o_play_n for if playing or not,
//o_speed[4] for fast(0) or slow(1),
//o_speed[3:0] for speed
//o_state for idle(1000) stop(0000) play(0001) pause(0010)
//o_state[3] for idle or not,
//o_state[2] for readmode or writemode,
//o_state[0] for playing or not,
//o_state[1] for puase or not
//different from chiachen :i_pause =>i_play
//						   [2:0]o_state => [3:0]o_state
//						   [4:0]o_speed => [3:0]o_speed

module SramReader(
	input i_bclk,
	input i_rst,
	input i_enable,
	input i_play,		// From KEY//change pause to play
	input i_stop,		// From KEY
	input i_speed_up,	// From KEY
	input i_speed_down,	// From KEY
	input i_interpol,
	input i_DACLRCK,
	input [19:0] i_end_addr,
	input [15:0] i_SRAM_DQ,

	output [19:0] o_addr,
	output [15:0] o_DACDAT,
	output o_play_n,
	output [3:0]  o_state,
	output [3:0]  o_speed
);

	enum {IDLE, STOP, PLAY, PAUSE} state_w, state_r;
	enum {NORMAL, FAST, SLOW} play_mode_w, play_mode_r;
	logic [15:0] data_w, data_r;
	logic signed [15:0] data_prev_w, data_prev_r;
	logic signed [15:0] output_data_w, output_data_r;
	logic [19:0] addr_w, addr_r;
	logic [2:0]  speed_w, speed_r;
	logic [2:0]  spd_counter_w, spd_counter_r;
	reg [2:0] o_state_r,o_state_w;

	assign o_addr = addr_r;
	assign o_DACDAT = output_data_r;
	assign o_play_n = !(state_r == PLAY);
	assign o_speed[3] = (play_mode_r == SLOW);
	assign o_speed[2:0] = speed_r;
	assign o_state = o_state_r;

//	speed controled by key up and key down
	task SpeedControl;
		input [1:0] play_mode;
		begin
			case(play_mode)
				FAST: begin
					if(i_speed_up) begin
						speed_w = ((speed_r == 7) ? speed_r : speed_r + 1);
					end
					if(i_speed_down) begin
						speed_w = speed_r - 1;
						play_mode_w = ((speed_r == 1) ? NORMAL: play_mode_r);
					end
				end
				NORMAL: begin
					if(i_speed_up) begin
					
						speed_w = 1;
						play_mode_w = FAST;
					end
					if(i_speed_down) begin
						speed_w = 1;
						play_mode_w = SLOW;
					end
				end
				SLOW: begin
					if(i_speed_up) begin
						speed_w = speed_r - 1;
						play_mode_w = ((speed_r == 1) ? NORMAL: play_mode_r);
						spd_counter_w = spd_counter_r;
					end else
						spd_counter_w = spd_counter_r + 1;
					if(i_speed_down) begin
						speed_w = ((speed_r == 7) ? speed_r : speed_r + 1);
					end
				end
			endcase
		end
	endtask

	always_comb begin
		state_w = state_r;
		play_mode_w = play_mode_r;
		data_w = data_r;
		data_prev_w = data_prev_r;
		output_data_w = output_data_r;
		addr_w = addr_r;
		speed_w = speed_r;
		spd_counter_w = spd_counter_r;

		case (state_r)
			IDLE: begin
				addr_w = 0;
				o_state_w = 4'b1000;
				if(i_enable) begin
					state_w = STOP;
					speed_w = 0;
					play_mode_w = NORMAL;
				end
			end
			
			STOP: begin
			//$display("STOP");
				o_state_w = 4'b0000;
				
				speed_w = 0;
				data_prev_w = 0;
				play_mode_w = NORMAL;
				spd_counter_w = 0;
				if(!i_enable) begin
					state_w = IDLE;
				end else if(i_play) begin
					addr_w = 0;
					state_w = PLAY;
				end
				SpeedControl(play_mode_r);
			end
			
			PLAY: begin
			//$display("PLAY");
				o_state_w = 4'b0001;
				if(!i_enable) begin
					state_w = IDLE;
				end else if(i_play) begin
					state_w = PAUSE;
				end else if(i_stop) begin
					state_w = STOP;
				end else if(addr_r >  (i_end_addr - (play_mode_r == FAST? speed_r + 2 : 2))) begin
					state_w = STOP;
				end

				SpeedControl(play_mode_r);
				//$display("prev = %d,current = %d, out = %d, %d",data_prev_r, i_SRAM_DQ, o_DACDAT, o_addr);
				//support slowing while playing
				case(play_mode_r)
					NORMAL: begin
					//$display("N");
						data_prev_w = i_SRAM_DQ;
						output_data_w = i_SRAM_DQ;
						addr_w = addr_r + 1;
					end
					FAST: begin
					//$display("F");
						data_prev_w = i_SRAM_DQ;
						output_data_w = i_SRAM_DQ;
						addr_w = addr_r + speed_r + 1;
					end
					SLOW: begin
					//$display("S");
						
						if(spd_counter_r == speed_r) begin
							spd_counter_w = 0;
							data_prev_w = i_SRAM_DQ;
							addr_w = addr_r + 1;
						end
							
						
						output_data_w = i_interpol? 
										$signed(data_prev_r) + $signed($signed($signed(i_SRAM_DQ) - $signed(data_prev_r))/$signed(speed_r + 1))*$signed(spd_counter_r) :
										data_prev_r;
					end
				endcase
			end
			PAUSE: begin
			$display("PAUSE");
			o_state_w = 4'b0010;
				if(!i_enable) begin
					state_w = IDLE;
				end else if(i_play) begin
					state_w = PLAY;
				end else if(i_stop) begin
					state_w = STOP;
				end

				SpeedControl(play_mode_r);
			end
		endcase
	end

	always_ff @(posedge i_DACLRCK or posedge i_rst) begin
		if(i_rst) begin
			state_r <= IDLE;
			play_mode_r <= NORMAL;
			data_r <= 0;
			data_prev_r <= 0;
			output_data_r <= 0;
			addr_r <= 0;
			speed_r <= 0;
			spd_counter_r <= 0;
			o_state_r <= 0;
		end else begin
			state_r <= state_w;
			play_mode_r <= play_mode_w;
			data_r <= data_w;
			data_prev_r <= data_prev_w;
			output_data_r <= output_data_w;
			addr_r <= addr_w;
			speed_r <= speed_w;
			spd_counter_r <= spd_counter_w;
			o_state_r <= o_state_w;
		end
	end




endmodule // sramReader