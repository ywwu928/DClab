//BY FAN

module LCDcontroller(	
	input i_clk,
	input [2:0] i_state,
	inout [7:0] io_LCD_DATA,
	output LCD_EN,
	output LCD_ON,
	output LCD_RS,
	output LCD_RW
);
localparam EN_IDLE=0, EN_HIGH=1, EN_END=2;
localparam IDLE=0, WAIT=1, EN=2,END=3, INIT=4;
logic [1:0] EN_state_r, EN_state_w;
logic [2:0] state_r, state_w;
logic [3:0] EN_count_r, EN_count_w, stall_count_r, stall_count_w;
logic l_en, EN_start, EN_fin;
logic [4:0] cursor_r, cursor_w;
logic [8:0] LCD_data; // {RS,DATA[7:0]}

assign LCD_ON = 1;
assign LCD_RW = 0;
assign io_LCD_DATA = LCD_data[7:0];
assign LCD_EN = l_en;
assign LCD_RS = LCD_data[8];

//l_en generate
always_comb begin
EN_count_w = EN_count_r;
EN_state_w = EN_state_r;
l_en = 0;
EN_fin = 0;
	case(EN_state_r)
		EN_IDLE : begin
			if(EN_start) begin
				EN_state_w = EN_HIGH;
				EN_count_w = 0;
			end
		end
		EN_HIGH : begin
			if(EN_count_r < 15) begin
				EN_count_w = EN_count_r + 1;
				l_en = 1;
			end else begin
				EN_state_w = EN_END;
			end
		end
		EN_END : begin
			EN_fin = 1;
			EN_state_w = EN_IDLE;
		end
		default: begin
			EN_state_w = EN_IDLE;
		end
	endcase
end
// data
always_comb begin
	case(cursor_r)
		0 : //function set
			LCD_data = 9'h038;
		1 : //display on
			LCD_data = 9'h00c;
		2 : //display clear
			LCD_data = 9'h001;
		3 : //entry mode set
			LCD_data = 9'h006;
		// display
		4 : 
			LCD_data = 9'h080;
		5:
			LCD_data = 9'h152;
		default : 
			LCD_data = 9'h001;
	endcase
end
always_comb begin
state_w = state_r;
cursor_w = cursor_r;
stall_count_w = stall_count_r;
EN_start = 0;
	case(state_r)
		INIT: begin
			if(i_state==2) begin
				EN_start = 1;
				state_w = EN;
				cursor_w = 0;
			end
		end
		IDLE: begin
			
		end
		EN: begin
			if(EN_fin) begin
				state_w = WAIT;
				stall_count_w = 0;
			end
		end
		WAIT: begin
			if(stall_count_r < 15) begin
				stall_count_w = stall_count_r + 1;
			end else begin
				state_w = END;
			end
		end
		END: begin
			if(cursor_r < 5) begin
				state_w = EN;
				EN_start = 1;
				cursor_w = cursor_r + 1;
			end else begin
				state_w = IDLE;
			end
		end
		default: begin
			state_w = INIT;
		end
	endcase
end

always_ff @(posedge i_clk) begin
//EN
EN_count_r <= EN_count_w;
EN_state_r <= EN_state_w;
//controller
state_r <= state_w;	
cursor_r <= cursor_w;
stall_count_r <= stall_count_w;
end	
endmodule