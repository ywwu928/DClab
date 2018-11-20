//BY FAN



module LCD (
    input i_rst,
    input i_clk,        //100kHz 50MHz
    input [3:0]INPUT_STATE, //IDLE=0, INIT=1, PLAY=2, PLAYPAUSE=3, RECORD=4, RECPAUSE=5
    input [3:0]INPUT_SPEED, 
    
    inout [7:0] LCD_DATA,
    output      LCD_EN,
    output      LCD_RS,
    output      LCD_RW,
    output      LCD_ON,
    output      LCD_BLON

);
    //LCD_state
    parameter LCDINIT            = 3'd0;
    parameter WAIT               = 3'd1;
    parameter DISPLAY_IDLE       = 3'd2;
    parameter DISPLAY_INIT       = 3'd3;
    parameter DISPLAY_PLAY       = 3'd4;
    parameter DISPLAY_PLAYPAUSE  = 3'd5;
    parameter DISPLAY_RECORD     = 3'd6;
    parameter DISPLAY_RECPAUSE   = 3'd7;

    //input state
    parameter IDLE      = 4'd1000;
    parameter INIT      = 4'd1;
    parameter PLAY      = 4'd0001;
    parameter PLAYPAUSE = 4'd0010;
    parameter RECORD    = 4'd0101;
    parameter RECPAUSE  = 4'd0110;

    //RS=0 RW=0
    parameter FUNCTION_SET    = 8'h38;
    parameter DISPLAY_ON      = 8'h0C; //CUSOR OFF
    parameter CLEAR_DISPLAY   = 8'h01; //ALSO CLEAR DDRAM CONTENT
    parameter ENTRY_MODE_SET  = 8'h06;
    parameter DDERAM_ADDR_SET = 8'h80;
    parameter RETURN          = 8'hC0; //8'b11000000
    
    //write to ram: 43us RS=1 RW=0
    parameter CGRAM_BLANK  = 8'h20;
    parameter CGRAM_SLASH  = 8'h2F;
    parameter CGRAM_0      = 8'h30;
    parameter CGRAM_1      = 8'h31;
    parameter CGRAM_2      = 8'h32;
    parameter CGRAM_3      = 8'h33;
    parameter CGRAM_4      = 8'h34;
    parameter CGRAM_5      = 8'h35;
    parameter CGRAM_6      = 8'h36;
    parameter CGRAM_7      = 8'h37;
    parameter CGRAM_8      = 8'h38;
    parameter CGRAM_9      = 8'h39;
    
    parameter CGRAM_CC      = 8'h43;
    parameter CGRAM_DD      = 8'h44;
    parameter CGRAM_II      = 8'h49;
    parameter CGRAM_LL      = 8'h4C;
    parameter CGRAM_PP      = 8'h50;
    parameter CGRAM_RR      = 8'h52;
    parameter CGRAM_SS      = 8'h53;
    parameter CGRAM_XX      = 8'h58;
    parameter CGRAM_a      = 8'h61;
    parameter CGRAM_c      = 8'h63;
    parameter CGRAM_d      = 8'h64;
    parameter CGRAM_e      = 8'h65;
    parameter CGRAM_g      = 8'h67;
    parameter CGRAM_i      = 8'h69;
    parameter CGRAM_l      = 8'h6C;
    parameter CGRAM_n      = 8'h6E;
    parameter CGRAM_o      = 8'h6F;
    parameter CGRAM_p      = 8'h70;
    parameter CGRAM_r      = 8'h72;
    parameter CGRAM_s      = 8'h73;
    parameter CGRAM_t      = 8'h74;
    parameter CGRAM_u      = 8'h75;
    parameter CGRAM_y      = 8'h79;
    parameter CGRAM_z      = 8'h7A;


    logic        EN;
    logic        RSUpdate;
    logic        DataUpdate;
    logic [2:0]  LCDstate_r, LCDstate_w;
    logic [2:0]  INPUT_STATE_r,  INPUT_STATE_w;
	logic [3:0]  INPUT_SPEED_r,  INPUT_SPEED_w;
    logic [5:0]  cursor_r,   cursor_w;
    logic        RS_r,       RS_w;
    logic [7:0]  data_r,     data_w;
    logic [10:0] counter_r, counter_w;


    assign LCD_DATA = data_r[7:0];
    assign LCD_RS   = RS_r;
    assign LCD_EN   = EN;
    assign LCD_RW   = 0;
    assign LCD_ON   = 1;
    assign LCD_BLON = 0;

    ENclk ENsub(
        .clk(i_clk),
        .rst(i_rst),
        .EN(EN),
        .RS_update(RSUpdate),
        .data_update(DataUpdate)
    );

    always_comb begin
        LCDstate_w = LCDstate_r;
        INPUT_STATE_w  = INPUT_STATE_r;
	       INPUT_SPEED_w  = INPUT_SPEED_r;
        cursor_w   = cursor_r;
        RS_w       = RS_r;
        data_w     = data_r;
        counter_w  = counter_r;
        case(LCDstate_r)
//---------------------INIT----------------------------           
            LCDINIT: begin
                if (counter_r != 0) 
                    counter_w = counter_r + 1;
                else if (RSUpdate) begin
                    cursor_w = cursor_r + 1;
                    case(cursor_r+1)
                        1, 2, 3, 4, 5, 22: RS_w = 0;
                        39: begin
                            LCDstate_w = WAIT;
                            cursor_w   = 4;
                            RS_w       = 0;
                            data_w     = DDERAM_ADDR_SET;
                        end
                        default: RS_w  = 1;
                    endcase
                end
                else if (DataUpdate) begin
                    case(cursor_r)
                        1: data_w = FUNCTION_SET;
                        2: data_w = DISPLAY_ON;
                        3: data_w = CLEAR_DISPLAY;
                        4: data_w = ENTRY_MODE_SET;
                        5: data_w = DDERAM_ADDR_SET;
                        6: data_w = CGRAM_LL;
                        7: data_w = CGRAM_CC;
                        8: data_w = CGRAM_DD;
                        10: data_w = CGRAM_RR;
                        11: data_w = CGRAM_e;
                        12: data_w = CGRAM_a;
                        13: data_w = CGRAM_d;
                        14: data_w = CGRAM_y;
                        22: data_w = RETURN;
                        default: data_w = CGRAM_BLANK;
                    endcase
                end
            end
//---------------------WAIT----------------------------            
            WAIT: begin
                if ((INPUT_STATE_r != INPUT_STATE) || (INPUT_SPEED_r != INPUT_SPEED)) begin
                    INPUT_STATE_w = INPUT_STATE;
						  INPUT_SPEED_w = INPUT_SPEED;
                    case(INPUT_STATE)
                        IDLE: LCDstate_w        = DISPLAY_IDLE;
                        INIT: LCDstate_w        = DISPLAY_INIT;
                        PLAY: LCDstate_w        = DISPLAY_PLAY;
                        PLAYPAUSE: LCDstate_w   = DISPLAY_PLAYPAUSE;
                        RECORD: LCDstate_w      = DISPLAY_RECORD;
                        RECPAUSE: LCDstate_w    = DISPLAY_RECPAUSE;
							default: LCDstate_w = DISPLAY_IDLE;
                    endcase
                end
                else LCDstate_w = WAIT;
            end
//---------------------IDLE----------------------------            
            DISPLAY_IDLE: begin
                if (cursor_r == 4) begin
                    if (RSUpdate)
                        cursor_w = cursor_r + 1;
                end
                else begin
                    if (RSUpdate) begin
                        cursor_w = cursor_r + 1;
                        case(cursor_r+1)
                            22: RS_w = 0;
                            39: begin
                                LCDstate_w = WAIT;
                                cursor_w   = 4;
                                RS_w       = 0;
                                data_w     = DDERAM_ADDR_SET;
                            end
                            default: RS_w  = 1;
                        endcase
                    end
                    else if (DataUpdate) begin
                        case(cursor_r)
                            5:  data_w = DDERAM_ADDR_SET;
                            6:  data_w = CGRAM_RR;
                            7:  data_w = CGRAM_e;
                            8:  data_w = CGRAM_c;
                            9:  data_w = CGRAM_o;
                            10: data_w = CGRAM_r;
                            11: data_w = CGRAM_d;
                            12: data_w = CGRAM_e;
                            13: data_w = CGRAM_r;
                            15: data_w = CGRAM_RR;
                            16: data_w = CGRAM_e;
                            17: data_w = CGRAM_a;
                            18: data_w = CGRAM_d;
                            19: data_w = CGRAM_y;
                            22: data_w = RETURN;
                            default: data_w = CGRAM_BLANK;
                        endcase
                    end
                end
            end
//---------------------DISPLAY_INIT----------------------------            
            DISPLAY_INIT: begin
                if (cursor_r == 4) begin
                    if (RSUpdate)
                        cursor_w = cursor_r + 1;
                end
                else begin
                    if (RSUpdate) begin
                        cursor_w = cursor_r + 1;
                        case(cursor_r+1)
                            22: RS_w = 0;
                            39: begin
                                LCDstate_w = WAIT;
                                cursor_w   = 4;
                                RS_w       = 0;
                                data_w     = DDERAM_ADDR_SET;
                            end
                            default: RS_w  = 1;
                        endcase
                    end
                    else if (DataUpdate) begin
                        case(cursor_r)
                            5:  data_w = DDERAM_ADDR_SET;
                            6:  data_w = CGRAM_II;
                            7:  data_w = CGRAM_n;
                            8:  data_w = CGRAM_i;
                            9:  data_w = CGRAM_t;
                            10: data_w = CGRAM_i;
                            11: data_w = CGRAM_a;
                            12: data_w = CGRAM_l;
                            13: data_w = CGRAM_i;
                            14: data_w = CGRAM_z;
                            15: data_w = CGRAM_i;
                            16: data_w = CGRAM_n;
                            17: data_w = CGRAM_g;
                            22: data_w = RETURN;
                            default: data_w = CGRAM_BLANK;
                        endcase
                    end
                end
            end
//---------------------PLAY----------------------------            
            DISPLAY_PLAY: begin
                if (cursor_r == 4) begin
                    if (RSUpdate)
                        cursor_w = cursor_r + 1;
                end
                else begin
                    if (RSUpdate) begin
                        cursor_w = cursor_r + 1;
                        case(cursor_r+1)
                            22: RS_w = 0;
                            39: begin
                                LCDstate_w = WAIT;
                                cursor_w   = 4;
                                RS_w       = 0;
                                data_w     = DDERAM_ADDR_SET;
                            end
                            default: RS_w  = 1;
                        endcase
                    end
                    else if (DataUpdate) begin
                        case(cursor_r)
                            5:  data_w = DDERAM_ADDR_SET;
                            6:  data_w = CGRAM_PP;
                            7:  data_w = CGRAM_l;
                            8:  data_w = CGRAM_a;
                            9:  data_w = CGRAM_y;
                            22: data_w = RETURN;
                            23: data_w = CGRAM_SS;
                            24: data_w = CGRAM_p;
                            25: data_w = CGRAM_e;
                            26: data_w = CGRAM_e;
                            27: data_w = CGRAM_d;
                            29: begin
                                case(INPUT_SPEED)
                                    0,1,2,3,4,5,6: data_w = CGRAM_1;
                                    default:       data_w = CGRAM_BLANK;
                                endcase
                            end
                            30: begin
                                case(INPUT_SPEED)
                                    0,1,2,3,4,5,6: data_w = CGRAM_SLASH;
                                    default:       data_w = CGRAM_BLANK;
                                endcase
                            end
                            31: begin
                                case(INPUT_SPEED)
                                    0, 14:  data_w = CGRAM_8;
                                    1, 13:  data_w = CGRAM_7;
                                    2, 12:  data_w = CGRAM_6;
                                    3, 11:  data_w = CGRAM_5;
                                    4, 10:  data_w = CGRAM_4;
                                    5, 9:   data_w = CGRAM_3;
                                    6, 8:   data_w = CGRAM_2;
                                    7:      data_w = CGRAM_1;
                                endcase
                            end
                            32: data_w = CGRAM_XX;
                            default: data_w = CGRAM_BLANK;
                        endcase
                    end
                end
            end
//---------------------PLAY->PAUSE----------------------------            
            DISPLAY_PLAYPAUSE: begin
                if (cursor_r == 4) begin
                    if (RSUpdate)
                        cursor_w = cursor_r + 1;
                end
                else begin
                    if (RSUpdate) begin
                        cursor_w = cursor_r + 1;
                        case(cursor_r+1)
                            22: RS_w = 0;
                            39: begin
                                LCDstate_w = WAIT;
                                cursor_w   = 4;
                                RS_w       = 0;
                                data_w     = DDERAM_ADDR_SET;
                            end
                            default: RS_w  = 1;
                        endcase
                    end
                    else if (DataUpdate) begin
                        case(cursor_r)
                            5:  data_w = DDERAM_ADDR_SET;
                            6:  data_w = CGRAM_PP;
                            7:  data_w = CGRAM_l;
                            8:  data_w = CGRAM_a;
                            9:  data_w = CGRAM_y;
                            22: data_w = RETURN;
                            23: data_w = CGRAM_PP;
                            24: data_w = CGRAM_a;
                            25: data_w = CGRAM_u;
                            26: data_w = CGRAM_s;
                            27: data_w = CGRAM_e;
                            default: data_w = CGRAM_BLANK;
                        endcase
                    end
                end
            end
//---------------------RECORD----------------------------            
            DISPLAY_RECORD: begin
                if (cursor_r == 4) begin
                    if (RSUpdate)
                        cursor_w = cursor_r + 1;
                end
                else begin
                    if (RSUpdate) begin
                        cursor_w = cursor_r + 1;
                        case(cursor_r+1)
                            22: RS_w = 0;
                            39: begin
                                LCDstate_w = WAIT;
                                cursor_w   = 4;
                                RS_w       = 0;
                                data_w     = DDERAM_ADDR_SET;
                            end
                            default: RS_w  = 1;
                        endcase
                    end
                    else if (DataUpdate) begin
                        case(cursor_r)
                            5:  data_w = DDERAM_ADDR_SET;
                            6:  data_w = CGRAM_RR;
                            7:  data_w = CGRAM_e;
                            8:  data_w = CGRAM_c;
                            9:  data_w = CGRAM_o;
                            10: data_w = CGRAM_r;
                            11: data_w = CGRAM_d;
                            22: data_w = RETURN;
                            default: data_w = CGRAM_BLANK;
                        endcase
                    end
                end
            end
//---------------------RECORD->PAUSE----------------------------            
            DISPLAY_RECPAUSE: begin
                if (cursor_r == 4) begin
                    if (RSUpdate)
                        cursor_w = cursor_r + 1;
                end
                else begin
                    if (RSUpdate) begin
                        cursor_w = cursor_r + 1;
                        case(cursor_r+1)
                            22: RS_w = 0;
                            39: begin
                                LCDstate_w = WAIT;
                                cursor_w   = 4;
                                RS_w       = 0;
                                data_w     = DDERAM_ADDR_SET;
                            end
                            default: RS_w  = 1;
                        endcase
                    end
                    else if (DataUpdate) begin
                        case(cursor_r)
                            5:  data_w = DDERAM_ADDR_SET;
                            6:  data_w = CGRAM_RR;
                            7:  data_w = CGRAM_e;
                            8:  data_w = CGRAM_c;
                            9:  data_w = CGRAM_o;
                            10: data_w = CGRAM_r;
                            11: data_w = CGRAM_d;
                            22: data_w = RETURN;
                            23: data_w = CGRAM_PP;
                            24: data_w = CGRAM_a;
                            25: data_w = CGRAM_u;
                            26: data_w = CGRAM_s;
                            27: data_w = CGRAM_e;
                            default: data_w = CGRAM_BLANK;
                        endcase
                    end
                end
            end
        endcase
    end




    always_ff@(posedge i_clk or posedge i_rst)  begin
        if(i_rst == 1) begin
            LCDstate_r <= LCDINIT;
            INPUT_STATE_r  <= 6;
				INPUT_SPEED_r  <= 15;
            data_r     <= FUNCTION_SET;
            cursor_r   <= 0;
            RS_r       <= 0;
            counter_r  <= 1;
        end
        else begin
            LCDstate_r  <= LCDstate_w;
            INPUT_STATE_r   <= INPUT_STATE_w;
				INPUT_SPEED_r   <= INPUT_SPEED_w;
            data_r      <= data_w;
            cursor_r    <= cursor_w;
            RS_r        <= RS_w;
            counter_r   <= counter_w;
        end 
    end
endmodule

module  ENclk(
    input  clk,
    input  rst,
    output EN,
    output RS_update,
    output data_update
);
    parameter IDLE = 2'd0;
    parameter HIGH = 2'd1;
    parameter LOW  = 2'd2;
    
    logic [1:0] state_r,         state_w;
    logic [3:0] cnt_r,           cnt_w;
    logic       EN_r,            EN_w;
    logic       RS_update_r,     RS_update_w;
    logic       data_update_r,   data_update_w;

    assign EN          = EN_r;
    assign RS_update   = RS_update_r;
    assign data_update = data_update_r;
    
    always_comb begin
        state_w       = state_r;
        cnt_w         = cnt_r;
        EN_w          = EN_r;
        RS_update_w   = RS_update_r;
        data_update_w = data_update_r;
        case(state_r)
            IDLE: begin
                cnt_w = cnt_r + 1;
                if (cnt_w == 2)
                    RS_update_w = 1;
                else if (cnt_r == 5) begin
                    state_w = HIGH;
                    EN_w    = 1;
                    cnt_w   = 0;
                end
                else
                    RS_update_w = 0;
            end
            HIGH: begin
                cnt_w = cnt_r + 1;
                if (cnt_r == 6)
                    data_update_w = 1;
                else if (cnt_r == 15) begin
                    state_w = LOW;
                    EN_w    = 0;
                    cnt_w   = 0;
                end
                else
                    data_update_w = 0;
            end
            LOW: begin
                cnt_w = cnt_r + 1;
                if (cnt_r == 10)
                    RS_update_w = 1;
                else if (cnt_r == 15) begin
                    state_w = HIGH;
                    EN_w    = 1;
                    cnt_w   = 0;
                end
                else
                    RS_update_w = 0;
            end
        endcase
    end    
    always_ff @(posedge clk or posedge rst)begin
        if(rst == 1) begin
            state_r       = IDLE;
            cnt_r         = 0;
            EN_r          = 0;
            RS_update_r   = 0;
            data_update_r = 0;
        end
        else begin
            state_r       = state_w;
            cnt_r         = cnt_w;
            EN_r          = EN_w;
            RS_update_r   = RS_update_w;
            data_update_r = data_update_w;
        end
    end
endmodule


