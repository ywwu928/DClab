//by084
module Rsa256Wrapper(
    input avm_rst,
    input avm_clk,
    output [4:0] avm_address,
    output avm_read,
    input [31:0] avm_readdata,
    output avm_write,
    output [31:0] avm_writedata,
    input avm_waitrequest
);
    localparam RX_BASE     = 0*4;
    localparam TX_BASE     = 1*4;
    localparam STATUS_BASE = 2*4;
    localparam TX_OK_BIT = 6;
    localparam RX_OK_BIT = 7;

    // Feel free to design your own FSM!
    localparam S_GET_KEY = 0;
    localparam S_GET_DATA = 1;
    localparam S_WAIT_CALCULATE = 2;
    localparam S_SEND_DATA = 3;
	
	parameter RST=3'b0;
	parameter QUERY_RX=3'd1;
	parameter READ=3'd2;
	parameter CALCULATE=3'd3;
	parameter QUERY_TX=3'd4;
	parameter WRITE=3'd5;
	
	parameter N=2'd0;
	parameter E=2'd1;
	parameter A=2'd2;
	parameter NULL=2'd3;
	
    logic [255:0] n_r, n_w, e_r, e_w, enc_r, enc_w, dec_r, dec_w;
    logic [2:0] state_r, state_w;
	logic [1:0] data_state_r,data_state_w;
    logic [6:0] bytes_counter_r, bytes_counter_w;
    logic [4:0] avm_address_r, avm_address_w;
    logic avm_read_r, avm_read_w, avm_write_r, avm_write_w;

    logic rsa_start_r, rsa_start_w;
    logic rsa_finished;
    logic [255:0] rsa_dec;
	
	
	logic [7:0] read_addr_r,read_addr_w,write_addr_r,write_addr_w;

    assign avm_address = avm_address_r;
    assign avm_read = avm_read_r;
    assign avm_write = avm_write_r;
    assign avm_writedata = dec_r[247-:8];

	
    Rsa256Core rsa256_core(
        .i_clk(avm_clk),
        .i_rst(avm_rst),
        .i_start(rsa_start_r),
        .i_a(enc_r),
        .i_e(e_r),
        .i_n(n_r),
        .o_a_pow_e(rsa_dec),
        .o_finished(rsa_finished)
    );

    task StartRead;
        input [4:0] addr;
		input [2:0] stat;
        begin
            avm_read_w = 1;
            avm_write_w = 0;
            avm_address_w = addr;
			state_w = stat;
        end
    endtask
    task StartWrite;
        input [4:0] addr;
		input [2:0] stat;
        begin
            avm_read_w = 0;
            avm_write_w = 1;
            avm_address_w = addr;
			state_w = stat;
        end
    endtask
	
	task ReadData;
		output [255:0]data_w;
        input [255:0]data_r;
		begin
			//$display("%d #%d #%h",data_state_r,read_addr_w,avm_readdata[7:0]);
			data_w = (data_r<<8) + avm_readdata[7:0];
			
			if(read_addr_r == 0)begin
				data_state_w = data_state_r + 1;
					
			end 
			read_addr_w = read_addr_r - 8;
			
			//avm_address_w = STATUS_BASE;
			//state_w = QUERY_RX;
		end	
	endtask
	
	task WriteData;
		begin
			//avm_writedata[7:0] = dec_w[read_addr_w +:8];

			//$display("@#$",dec_w[247 -:8]);			
			write_addr_w = write_addr_r +8;
			if(write_addr_r == 240)begin
			write_addr_w = 0;
			end
			dec_w = dec_r<<8;
			
							

		end	
	endtask
///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////
    always @(*) begin
        // TODO
        //$display("ddd");
            n_w = n_r;
            e_w = e_r;
            enc_w = enc_r;
            dec_w = dec_r;
			read_addr_w = read_addr_r;
			write_addr_w = write_addr_r;
			data_state_w = data_state_r;
			rsa_start_w = rsa_start_r;
		    avm_address_w = avm_address_r;
            avm_read_w = avm_read_r;
            avm_write_w = avm_write_r;
            state_w = state_r;
            bytes_counter_w = bytes_counter_r;
		case(state_r)
			
			QUERY_RX: begin//go to read_state
				//$display("QUERY_RX");
				if(!avm_waitrequest && avm_readdata[RX_OK_BIT])begin
					//avm_address_w = RX_BASE;
					StartRead(RX_BASE,READ);
				end else begin
					StartRead(avm_address_r,state_r);
				end
			end
			
			READ: begin
				//$display("READ");
			if(!avm_waitrequest & avm_read_r)begin
				//StartRead(avm_address_r);					
					case(data_state_r)
						N:begin
							ReadData(n_w,n_r);
							//StartRead(STATUS_BASE,QUERY_RX);
						end
						E:begin
							ReadData(e_w,e_r);
							//StartRead(STATUS_BASE,QUERY_RX);
						end
						A:begin
							ReadData(enc_w,enc_r);
							
						end
						endcase
						if(data_state_r == A & read_addr_r == 0) begin
							rsa_start_w = 1;
							data_state_w = A;
							avm_address_w = STATUS_BASE;
							state_w = CALCULATE;
						end else
							StartRead(STATUS_BASE,QUERY_RX);
					//default:
					//	state_w = state_r;	
				end else begin
					StartRead(RX_BASE,READ);
				end	
			end			
			
			CALCULATE:	begin
			
				//temp
				//$display("CALCULATE");
				//dec_w = enc_r;
				//if(rsa_start_w == 1)begin
				rsa_start_w = 0;
				//end
				if(rsa_finished)begin
				//rsa_start_w = 0;
				dec_w = rsa_dec;
				read_addr_w = 248;
				write_addr_w = 0;
				state_w = QUERY_TX;
				end
			end
			
			QUERY_TX: begin
				
				if(!avm_waitrequest && avm_readdata[TX_OK_BIT])begin
					//$display("QUERY_TX");
					StartWrite(TX_BASE,WRITE);
					//state_w = WRITE;

				end else begin
					StartRead(STATUS_BASE,QUERY_TX);
				end			
			end
			WRITE: begin
				//$display("WRITE");
				
				if(!avm_waitrequest& avm_write_r)begin
					WriteData();
					if(write_addr_r !=240)begin
					StartRead(STATUS_BASE,QUERY_TX);
					end else
					StartRead(STATUS_BASE,QUERY_RX);	
				end else begin
					StartWrite(TX_BASE,WRITE);
				end
			end	
		endcase
    end


    always_ff @(posedge avm_clk or posedge avm_rst) begin
        //$display("clk");
		if (avm_rst) begin
        	//$display("rst");
            n_r <= 0;
            e_r <= 0;
            enc_r <= 0;
            dec_r <= 0;
            avm_address_r <= STATUS_BASE;
            avm_read_r <= 1;
            avm_write_r <= 0;
            //state_r <= S_GET_KEY;
            state_r <= QUERY_RX;
			bytes_counter_r <= 63;
            rsa_start_r <= 0;
			data_state_r <= N;
			read_addr_r<= 248;
			write_addr_r<= 0;
        end else begin
        	//$display("!rst");
            n_r <= n_w;
            e_r <= e_w;
            enc_r <= enc_w;
            dec_r <= dec_w;
            avm_address_r <= avm_address_w;
            avm_read_r <= avm_read_w;
            avm_write_r <= avm_write_w;
            state_r <= state_w;
            bytes_counter_r <= bytes_counter_w;
            rsa_start_r <= rsa_start_w;
			data_state_r <= data_state_w;
			read_addr_r<=read_addr_w;
			write_addr_r<=write_addr_w;
        end
    end

endmodule
