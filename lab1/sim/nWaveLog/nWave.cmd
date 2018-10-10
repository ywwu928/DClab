wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 {/home/team06/b05901084/lab1/sim/Lab1_test.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/Top_test"
wvGetSignalSetScope -win $_nWave1 "/Top_test/dut/top0"
wvSetPosition -win $_nWave1 {("G1" 14)}
wvSetPosition -win $_nWave1 {("G1" 14)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/Top_test/dut/top0/count_r\[5:0\]} \
{/Top_test/dut/top0/count_w\[5:0\]} \
{/Top_test/dut/top0/counter_r\[7:0\]} \
{/Top_test/dut/top0/counter_w\[7:0\]} \
{/Top_test/dut/top0/countnum\[7:0\]} \
{/Top_test/dut/top0/i_clk} \
{/Top_test/dut/top0/i_rst} \
{/Top_test/dut/top0/i_rst_d} \
{/Top_test/dut/top0/i_start} \
{/Top_test/dut/top0/my_state\[1:0\]} \
{/Top_test/dut/top0/o_random_out\[3:0\]} \
{/Top_test/dut/top0/setnum} \
{/Top_test/dut/top0/temp_r\[3:0\]} \
{/Top_test/dut/top0/temp_w\[3:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 12 13 14 )} 
wvSetPosition -win $_nWave1 {("G1" 14)}
wvGetSignalClose -win $_nWave1
wvExit
