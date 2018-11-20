module SevenHexDecoder_State(
  input [3:0] i_state,
  input [3:0] i_speed, // MSB: faster or slower
  output logic [6:0] o_seven_5,
  output logic [6:0] o_seven_4, 
  output logic [6:0] o_seven_3,
  output logic [6:0] o_seven_2,
  output logic [6:0] o_seven_1,
  output logic [6:0] o_seven_0
);


  parameter [3:0] INPUT_IDLE   = 4'b1000;
  parameter [3:0] INPUT_RECORD = 4'b0101;
  parameter [3:0] INPUT_STOP_W   = 4'b0100;
  parameter [3:0] INPUT_STOP_R   = 4'b0000;
  parameter [3:0] INPUT_PLAY   = 4'b0001;
  parameter [3:0] INPUT_PAUSE_W  = 4'b0110;
  parameter [3:0] INPUT_PAUSE_R  = 4'b0010;

    /* The layout of seven segment display, 1: dark
   *    00
   *   5  1
   *    66
   *   4  2
   *    33
   */
  parameter DNONE = 7'b1111111;
  parameter DFULL = 7'b0000000;

  parameter D0 = 7'b1000000;
  parameter D1 = 7'b1111001;
  parameter D2 = 7'b0100100;
  parameter D3 = 7'b0110000;
  parameter D4 = 7'b0011001;
  parameter D5 = 7'b0010010;
  parameter D6 = 7'b0000010;
  parameter D7 = 7'b1011000;
  parameter D8 = 7'b0000000;
  parameter D9 = 7'b0010000;

  parameter DA = 7'b0001000;
  parameter DC = 7'b1000110;
  parameter DD = 7'b1000000;
  parameter DE = 7'b0000110;
  parameter DI = 7'b1111001;
  parameter DL = 7'b1000111;
  parameter DN = 7'b1001000;
  parameter DO = 7'b1000000;
  parameter DP = 7'b0001100;
  parameter DR = 7'b0001000;
  parameter DS = 7'b0010010;
  parameter DT = 7'b1001110;
  parameter DU = 7'b1000001;
  parameter DY = 7'b0010001;
  parameter D_ = 7'b0111111;
  parameter DDOT = 7'b0111111;


  parameter S2 = 3'b001;
  parameter S3 = 3'b010;
  parameter S4 = 3'b011;
  parameter S5 = 3'b100;
  parameter S6 = 3'b101;
  parameter S7 = 3'b110;
  parameter S8 = 3'b111;

  always_comb begin
        o_seven_5 = D_;
        o_seven_4 = D_;
        o_seven_3 = D_;
        o_seven_2 = D_;
        o_seven_1 = D_;
        o_seven_0 = D_;  
    case(i_state)
      INPUT_IDLE: begin
        o_seven_5 = DNONE;
        o_seven_4 = DNONE;
        o_seven_3 = DI;
        o_seven_2 = DD;
        o_seven_1 = DL;
        o_seven_0 = DE;
      end
      INPUT_RECORD: begin
        o_seven_5 = DR;
        o_seven_4 = DE;
        o_seven_3 = DC;
        o_seven_2 = DO;
        o_seven_1 = DR;
        o_seven_0 = DD;
      end
      INPUT_STOP_W: begin
        o_seven_5 = DNONE;
        o_seven_4 = DNONE;
        o_seven_3 = DS;
        o_seven_2 = DT;
        o_seven_1 = DO;
        o_seven_0 = DP;
      end
      INPUT_STOP_R: begin
        o_seven_5 = DNONE;
        o_seven_4 = DDOT;
        o_seven_3 = DS;
        o_seven_2 = DT;
        o_seven_1 = DO;
        o_seven_0 = DP;
      end
      INPUT_PLAY: begin
        if (i_speed[3] == 1) begin
          o_seven_5 = D_;
        end else begin
          o_seven_5 = DNONE;
        end

        case(i_speed[2:0])
          S2: o_seven_4 = D2;
          S3: o_seven_4 = D3;
          S4: o_seven_4 = D4;
          S5: o_seven_4 = D5;
          S6: o_seven_4 = D6;
          S7: o_seven_4 = D7;
          S8: o_seven_4 = D8;
          default: o_seven_4 = DNONE;
        endcase
        
        o_seven_3 = DP;
        o_seven_2 = DL;
        o_seven_1 = DA;
        o_seven_0 = DY;
      end
      INPUT_PAUSE_R: begin
        o_seven_5 = DDOT;
        o_seven_4 = DP;
        o_seven_3 = DA;
        o_seven_2 = DU;
        o_seven_1 = DS;
        o_seven_0 = DE;
      end
      INPUT_PAUSE_W: begin

        o_seven_5 = DNONE;
        o_seven_4 = DP;
        o_seven_3 = DA;
        o_seven_2 = DU;
        o_seven_1 = DS;
        o_seven_0 = DE;
      end
      default: begin
        o_seven_5 = DFULL;
        o_seven_4 = DFULL;
        o_seven_3 = DFULL;
        o_seven_2 = DFULL;
        o_seven_1 = DFULL;
        o_seven_0 = DFULL;
      end
    endcase
  end
endmodule