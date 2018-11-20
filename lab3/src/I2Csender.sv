// send data to WM8731 through I2C protocol
module I2Csender (
	input i_start,
	input [23:0] i_data,
	input i_clk,
	input i_rst,
	output o_finished,
	output o_scl,
	inout o_sda
);

	enum {START, PREPARE, TRANSMIT, FINISH} state_r, state_w;

	logic [ 1:0] clk_count_r, clk_count_w;
	logic [ 3:0] bit_count_r, bit_count_w;
	logic [ 1:0] byte_count_r, byte_count_w;
	logic        scl_r, scl_w;
	logic        sda_r, sda_w;
	logic        ack_r, ack_w;
	logic [23:0] data_r, data_w;
	logic        finished_r, finished_w;

	assign o_finished = finished_r;
	assign o_scl = scl_r;
	assign o_sda = ack_r ? 1'bz : sda_r; // depend receiving acknowledgement bit or not

	always_comb begin
		state_w = state_r;
		clk_count_w = clk_count_r;
		bit_count_w = bit_count_r;
		byte_count_w = byte_count_r;
		scl_w = scl_r;
		sda_w = sda_r;
		ack_w = ack_r;
		data_w = data_r;
		finished_w = finished_r;

		case (state_r)
			START: begin
				if (i_start) begin
					state_w = PREPARE;
					clk_count_w = 0;
					bit_count_w = 0;
					byte_count_w = 0;
					sda_w = 0;
					data_w = i_data;
					finished_w = 0;
				end // if (i_start)
			end // START:

			PREPARE: begin
				scl_w = 0;
				if (!scl_r) begin
					state_w = TRANSMIT;
					sda_w = data_r[23];
					data_w = data_r << 1;
				end // if (!scl_r)
			end // PREPARE:

			TRANSMIT: begin
				// 3 clk cycle per bit
				if (clk_count_r == 0) begin
					clk_count_w = clk_count_r + 1;
					scl_w = 1;
				end // if (clk_count_r == 0)
				else if (clk_count_r == 1) begin
					clk_count_w = clk_count_r + 1;
					scl_w = 0;
				end // else if (clk_count_r == 1)
				else if (clk_count_r == 2) begin
					clk_count_w = 0;
					bit_count_w = bit_count_r + 1;

					// 1 acknowledgement bit per byte = 8 bits
					if (bit_count_r < 7) begin
						sda_w = data_r[23];
						data_w = data_r << 1;
					end // if (bit_count_r < 7)
					else if (bit_count_r == 7) begin
						ack_w = 1;
					end // else if (bit_count_r == 7)
					// finish transmitting after 3 bytes = 24 bits
					else if (bit_count_r == 8 && byte_count_r != 2) begin
						byte_count_w = byte_count_r + 1;
						ack_w = 0;
						bit_count_w = 0;
						sda_w = data_r[23];
						data_w = data_r << 1;
					end // else if (bit_count_r == 8 && byte_count_r != 2)
					else if (bit_count_r == 8 && byte_count_r == 2) begin
						ack_w = 0;
						sda_w = 0;
						state_w = FINISH;
					end // else if (bit_count_r == 8 && byte_count_r == 2)
				end // else if (clk_count_r == 2)
			end // TRANSMIT:

			FINISH: begin
				scl_w = 1;
				if (scl_r) begin
					state_w = START;
					sda_w = 1;
					finished_w = 1;
				end // if (scl_r)
			end // FINISH:
		endcase // state_r
	end // always_comb


	always_ff @(posedge i_clk or posedge i_rst) begin
		if (i_rst) begin
			state_r <= START;
			clk_count_r <= 0;
			bit_count_r <= 0;
			byte_count_r <= 0;
			scl_r <= 1;
			sda_r <= 1;
			ack_r <= 0;
			data_r <= 24'b0011_0100_000_1111_0_0000_0000; // reset
			finished_r <= 0;
		end // if (i_rst)
		else begin
			state_r <= state_w;
			clk_count_r <= clk_count_w;
			bit_count_r <= bit_count_w;
			byte_count_r <= byte_count_w;
			scl_r <= scl_w;
			sda_r <= sda_w;
			ack_r <= ack_w;
			data_r <= data_w;
			finished_r <= finished_w;
		end // else
	end // always_ff @(posedge i_clk or posedge i_rst)

endmodule // I2Csender