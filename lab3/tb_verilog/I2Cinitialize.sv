// initialize WM8731 through I2C protocol
module I2Cinitialize (
	input i_clk,
	input i_start,
	input i_rst,
	output o_scl,
	output o_finished,
	inout o_sda
);

	enum {IDLE, SEND, DONE} state_r, state_w;

	logic [23:0] data_r, data_w;
	logic [ 3:0] count_r, count_w;
	logic        send_start_r, send_start_w;
	logic        send_finished;
	logic        finished_r, finished_w;
	logic        scl;
	wire         sda;

	parameter bit [23:0] INITIALIZE_DATA [9:0] = {
		24'b0011010_0_000_0000_0_1001_0111, //Left Line In
        24'b0011010_0_000_0001_0_1001_0111, //Right Line In
        24'b0011010_0_000_0010_0_0111_1001, //Left Headphone out
        24'b0011010_0_000_0011_0_0111_1001, //Right Headphone out
		24'b0011_0100_000_0100_0_0001_0101, // Analogue Audio Path Control
		24'b0011_0100_000_0101_0_0000_0000, // Digital Audio Path Control
		24'b0011_0100_000_0110_0_0000_0000, // Power Down Control
		24'b0011_0100_000_0111_0_0100_0010, // Digital Audio Interface Format
		24'b0011_0100_000_1000_0_0001_1001, // Sampling Control
		24'b0011_0100_000_1001_0_0000_0001  // Active Control
	};

	 assign o_finished = finished_r;
	 assign o_scl = scl;
	 assign o_sda = sda;

	 I2Csender i2csender (
	 	.i_start(send_start_r),
	 	.i_clk(i_clk),
	 	.i_rst(i_rst),
	 	.i_data(data_r),
	 	.o_finished(send_finished),
	 	.o_scl(scl),
	 	.o_sda(sda)
	 );

	 always_comb begin
	 	state_w = state_r;
	 	data_w = data_r;
	 	count_w = count_r;
	 	send_start_w = send_start_r;
	 	finished_w = finished_r;

	 	case (state_r)
	 		IDLE: begin
	 			if (i_start) begin
	 				state_w = SEND;
	 				data_w = INITIALIZE_DATA[count_r];
	 				count_w = count_r + 1;
	 				send_start_w = 1;
	 				finished_w = 0;
	 			end // if (i_start)
	 		end // IDLE:

	 		SEND: begin
	 			if (count_r < 10) begin
	 				if (send_finished) begin
	 					data_w = INITIALIZE_DATA[count_r];
	 					count_w = count_r + 1;
	 					$display("count_r=%0d, data_w=%b", count_r, data_w);
	 				end // if (send_finished)
	 			end // if (count_r < 10)
	 			if (count_r == 10) begin
	 				state_w = DONE;
	 				count_w = 0;
	 			end // if (count_r == 9)
	 		end // SEND:

	 		DONE: begin
	 			state_w = IDLE;
	 			finished_w = 1;
	 			send_start_w = 0;
	 		end // DONE:
	 	endcase // state_r
	 end // always_comb


	 always_ff @(posedge i_clk or posedge i_rst) begin
	 	if (i_rst) begin
	 		state_r <= IDLE;
	 		data_r <= 0;
	 		count_r <= 0;
	 		send_start_r <= 0;
	 		finished_r <= 0;
	 	end // if (i_rst)
	 	else begin
	 		state_r <= state_w;
	 		data_r <= data_w;
	 		count_r <= count_w;
	 		send_start_r <= send_start_w;
	 		finished_r <= finished_w;
	 	end // else
	 end // always_ff @(posedge i_clk or posedge i_rst)

endmodule // I2Cinitialize