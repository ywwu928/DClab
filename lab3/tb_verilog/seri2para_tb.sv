`timescale 1ns/100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK/2;

    logic clk, start, finish, rst, data_in;
    logic [15:0] data_out;
    initial clk = 0;
    always #HCLK clk = ~clk;

    Seri2Para core(
        .i_clk(clk),
        .i_start(start),
        .i_rst(rst),
        .aud_adcdat(data_in),
        .sram_dq(data_out),
        .o_finished(finish)
    );

    initial begin
        $fsdbDumpfile("lab3_s2p.fsdb");
        $fsdbDumpvars;
        rst = 1;
        #(2*CLK) rst = 0;

        #(2*CLK)
        for (int j = 0; j < 3; j++) begin
            @(posedge clk);
        end
        start <= 1;
        @(posedge clk) 
        data_in <= 1;
        start <= 0;

        @(posedge clk) data_in <= 1;
        @(posedge clk) data_in <= 1;
        @(posedge clk) data_in <= 1;
        @(posedge clk) data_in <= 0;
        @(posedge clk) data_in <= 0;
        @(posedge clk) data_in <= 0;
        @(posedge clk) data_in <= 0;
        @(posedge clk) data_in <= 1;
        @(posedge clk) data_in <= 0;
        @(posedge clk) data_in <= 0;
        @(posedge clk) data_in <= 1;
        @(posedge clk) data_in <= 0;
        @(posedge clk) data_in <= 1;
        @(posedge clk) data_in <= 1;
        @(posedge clk) data_in <= 0;

/*        for (int k = 0; k < 9; k++) begin
            @(posedge finish)
            @(posedge clk) start <= 1;
            @(posedge clk) start <= 0;
        end // for (int k = 0; k < 9; k++)
*/
        @(posedge finish)
        #(100*CLK) $finish;
    end

    initial begin
        #(3000*CLK)
        $display("Too slow, abort.");
        $finish;
    end

endmodule