`timescale 1ns/100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK/2;

    logic clk, start, finish, rst;
    wire data;
    initial clk = 0;
    always #HCLK clk = ~clk;

    Para2Seri core(
        .i_clk(clk),
        .i_start(start),
        .i_rst(rst),
        .sram_dq(16'b0000111101101001),
        .aud_dacdat(data),
        .o_finished(finish)
    );

    initial begin
        $fsdbDumpfile("lab3_p2s.fsdb");
        $fsdbDumpvars;
        rst = 1;
        #(2*CLK) rst = 0;

        #(2*CLK)
        for (int j = 0; j < 3; j++) begin
            @(posedge clk);
        end
        start <= 1;
        @(posedge clk) start <= 0;

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