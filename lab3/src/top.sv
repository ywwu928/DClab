module top (
	input  		i_clk,
	input		i_clk2,
	input  		i_rst,
	input		i_play,
	input		i_stop,
	input		i_speed_up,
	input		i_speed_down,
	input		i_mode,		// SW[0] 0:Record 1:Play
	input		i_interpol,	// SW[1]
	output [7:0] LEDG,
	output [17:0] LEDR,

	output 	[19:0] o_SRAM_ADDR,
	output 	o_SRAM_CE_N,
	inout 	[15:0] SRAM_DQ,
	output 	o_SRAM_LB_N,
	output 	o_SRAM_OE_N,
	output 	o_SRAM_UB_N,
	output 	o_SRAM_WE_N, 

	output o_I2C_SCLK,
	inout I2C_SDAT,
	input i_AUD_ADCDAT,
	inout ADCLRCK,
	output o_AUD_DACDAT,
	inout DACLRCK,

	output LCD_BLON,
	inout [7:0] LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW,
	
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,
	output [6:0] HEX6,
	output [6:0] HEX7	
);

	enum {INIT, PLAY, RECORD} state_w, state_r;

	logic [19:0] end_addr;
	logic pre_ADCLRCK_w, pre_ADCLRCK_r;
	logic pre_DACLRCK_w, pre_DACLRCK_r;
	logic play_mode_pause_w, play_mode_pause_r;
	logic play_mode_stop_w, play_mode_stop_r;
	logic play_mode_spdup_w, play_mode_spdup_r;	
	logic play_mode_spddw_w, play_mode_spddw_r;	


	logic [19:0] addr_write, addr_read;
	logic [15:0] record_data, play_data;
	logic [19:0] sram_addr;
	logic [3:0] hex_speed;
	logic [2:0] LCD_state;
	logic [3:0] play_state;
	logic [3:0] record_state;
	logic [2:0] hex_state;
	logic start_init, done_init;
	logic start_record, done_record;
	logic start_play, done_play;
	logic lcd_ready;
	logic record_LED;

	assign start_init = (state_r == INIT);
	assign hex_state = (i_mode?play_state:record_state);
	assign start_record = (pre_ADCLRCK_r == 1 && ADCLRCK == 0 && !i_mode);
	assign start_play =(pre_DACLRCK_r != DACLRCK && i_mode);
	//always@(ADCLRCK) start_record =(!ADCLRCK)&&(!i_mode);
	//always@(DACLRCK) start_play =(!DACLRCK)&&(i_mode);

	assign o_SRAM_CE_N = 0;
	assign o_SRAM_UB_N = 0;
	assign o_SRAM_LB_N = 0;
	assign o_SRAM_ADDR = sram_addr;
	assign sram_addr = i_mode? addr_read : addr_write;
	/*
	assign LEDG[8:5] = 4'b0000;
	assign LEDG[4] = lcd_ready;
	assign LEDG[3] = done_init;
	assign LEDG[2] = (state_r == PLAY);
	assign LEDG[1] = (state_r == RECORD);
	assign LEDG[0] = (state_r == INIT);
	*/
	
	I2Cinitialize init(
	   .i_clk(i_clk2),
	   .i_start(start_init),
	   .i_rst(i_rst),
	   .o_scl(o_I2C_SCLK),
	   .o_finished(done_init),
	   .o_sda(I2C_SDAT)
	);

	Seri2Para s2p(
   	.i_clk(i_clk),
   	.i_rst(i_rst),
   	.i_start(start_record),
   	.aud_adcdat(i_AUD_ADCDAT),
   	.o_finished(done_record),
   	.sram_dq(record_data)
	);
	SramWriter recorder(
		.i_bclk(i_clk),
		.i_rst(i_rst),
		.i_enable(!i_mode), // From SW
		.i_play(i_play),  // From KEY
		.i_stop(i_stop),	// From KEY
		.i_ready(done_record),  // From I2C
		.i_record_data(record_data),
		.o_SRAM_DQ(SRAM_DQ),
		.o_state(record_state),
		.o_write_n(o_SRAM_WE_N),
		.o_addr(addr_write),
		.o_end_addr(end_addr)
	);

	Para2Seri p2s(
	   .i_clk(i_clk),
	   .i_rst(i_rst),
	   .i_start(start_play),
	   .sram_dq(play_data),
	   .aud_dacdat(o_AUD_DACDAT),
		.o_finished(done_play)
	);
	SramReader player(
		.i_bclk(i_clk),
		.i_rst(i_rst),
		.i_enable(i_mode),
		//.i_play(i_play),		// From KEY
		//.i_stop(i_stop),		// From KEY
		//.i_speed_up(i_speed_up),	// From KEY
		//.i_speed_down(i_speed_down),	// From KEY
		.i_play(play_mode_pause_r),		// From KEY
		.i_stop(play_mode_stop_r),		// From KEY
		.i_speed_up(play_mode_spdup_r),	// From KEY
		.i_speed_down(play_mode_spddw_r),	// From KEY
		.i_interpol(i_interpol),
		.i_DACLRCK(DACLRCK),
		.i_end_addr(end_addr),
		.i_SRAM_DQ(SRAM_DQ),

		.o_addr(addr_read),
		.o_DACDAT(play_data),
		.o_play_n(o_SRAM_OE_N),
		.o_state(play_state),
		.o_speed(hex_speed)
	);
/*
	LCD lcd(
		.i_clk(i_clk),
		.i_rst(i_rst),
		.LCD_DATA(LCD_DATA),
		.LCD_EN(LCD_EN),
		.LCD_RW(LCD_RW),
		.LCD_RS(LCD_RS),
		//.LCD_ON(LCD_ON),
		//.LCD_BLON(LCD_BLON),
		.INPUT_STATE(hex_state),
		//.READY(lcd_ready)
	);
*/	
	SevenHexDecoder_State HexState(
	  .i_state(hex_state),
	  .i_speed(hex_speed),
	  .o_seven_5(HEX5),
	  .o_seven_4(HEX4), 
	  .o_seven_3(HEX3),
	  .o_seven_2(HEX2),
	  .o_seven_1(HEX1),
	  .o_seven_0(HEX0)
	);  

	SevenHexDecoder Hex(
	   .i_addr(sram_addr), // SRAM address
		.o_seven_ten(HEX7),
		.o_seven_one(HEX6)
	);

	LED LEDdisplay(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_state(hex_state),
        .i_addr(sram_addr),
        .i_record_data(record_data),
        .LEDR(LEDR),
        .LEDG(LEDG)
	);
	
	always_comb begin
		// _w = _r
		state_w = state_r;
		pre_DACLRCK_w = DACLRCK;
		pre_ADCLRCK_w = ADCLRCK;		
				play_mode_pause_w = play_mode_pause_r;
		play_mode_stop_w = play_mode_stop_r;
		play_mode_spdup_w = play_mode_spdup_r;	
		play_mode_spddw_w = play_mode_spddw_r;	
		case (state_r) 
			INIT: begin
					LCD_state = 3'b000;
					if (done_init) begin
						state_w = RECORD;
					end
			end

			RECORD: begin 
					LCD_state = 3'b010;
					if (i_mode) begin
						state_w = PLAY;
					end
			end

			PLAY: begin
					LCD_state = 3'b100;


					if (pre_DACLRCK_r == 0 && DACLRCK == 1) begin
						play_mode_pause_w = 0;
						play_mode_stop_w = 0;
						play_mode_spdup_w = 0;
						play_mode_spddw_w = 0;
					end else begin
						if (i_play) begin
							play_mode_pause_w = 1;
						end
						if (i_stop) begin
							play_mode_stop_w = 1;
						end
						if (i_speed_up) begin
							play_mode_spdup_w = 1;
						end
						if (i_speed_down) begin
							play_mode_spddw_w = 1;
						end
					end



					if (!i_mode) begin
						state_w = RECORD;
					end
			end
		endcase // state_r
	end


	always_ff @(posedge i_clk or posedge i_rst) begin
		if(i_rst) begin
			state_r <= INIT;
			pre_ADCLRCK_r <= 0;
			pre_DACLRCK_r <= 0;
						play_mode_pause_r <= 0;
			play_mode_stop_r <= 0;
			play_mode_spdup_r <= 0;	
			play_mode_spddw_r <= 0;					
		end else begin
			state_r <= state_w;	
			pre_DACLRCK_r <= pre_DACLRCK_w;
			pre_ADCLRCK_r <= pre_ADCLRCK_w;
						play_mode_pause_r <= play_mode_pause_w;
			play_mode_stop_r <= play_mode_stop_w;
			play_mode_spdup_r <= play_mode_spdup_w;	
			play_mode_spddw_r <= play_mode_spddw_w;			
		end
	end




endmodule