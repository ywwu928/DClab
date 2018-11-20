`timescale 1ns/100ps

module tb;
    localparam CLK = 10;
    localparam HCLK = CLK/2;

    logic clk, start, finish, rst, sclk;
    wire sdat;
    initial clk = 0;
    always #HCLK clk = ~clk;

    I2Cinitialize core(
        .i_clk(clk),
        .i_start(start),
        .i_rst(rst),
        .o_scl(sclk),
        .o_finished(finish),
        .o_sda(sdat)
    );

    initial begin
        $fsdbDumpfile("lab3_i2c_2.fsdb");
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
        #(1000*CLK) $finish;
    end

    initial begin
        #(3000*CLK)
        $display("Too slow, abort.");
        $finish;
    end

endmodule
