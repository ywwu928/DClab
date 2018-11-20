// convert data from parallel in to serial out
module Para2Seri (
	input	i_clk,
	input	i_rst,
	input	i_start,
	input [15:0] sram_dq,
	output	aud_dacdat,
	output	o_finished
);
	
	enum {IDLE, RUN} state_r, state_w;

	logic [15:0] data_r, data_w;
	logic [ 3:0] count_r, count_w;
	logic        finished_r, finished_w;

	assign o_finished = finished_r;
	assign aud_dacdat = data_r[15];

	always_comb begin
		state_w = state_r;
		data_w = data_r;
		count_w = count_r;
		finished_w = finished_r;

		case(state_r)
			IDLE: begin
				if (i_start) begin
					state_w = RUN;
					data_w = sram_dq;
					count_w = 0;
				end // if (i_start)
			end // IDLE:

			RUN: begin
				if (count_r < 15) begin
					data_w = data_r << 1;
					count_w = count_r + 1;
				end // if (count_r < 15)
				else if (count_r == 15) begin
					state_w = IDLE;
					count_w = 0;
					finished_w = 1;
				end // else if (count_r == 15)
			end // RUN:
		endcase // state_r
	end // always_comb

	always_ff @(posedge i_clk or posedge i_rst) begin
		if (i_rst) begin
			state_r <= IDLE;
			data_r <= 0;
			count_r <= 0;
			finished_r <= 0;
		end // if (i_rst)
		else begin
			state_r <= state_w;
			data_r <= data_w;
			count_r <= count_w;
			finished_r <= finished_w;
		end // else
	end // always_ff @(posedge i_clk or posedge i_rst)

endmodule