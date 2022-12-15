module pNoode(
    input [17:0] llr_1,
    input [17:0] llr_2,
    input frozen_1, // 0 not frozen, 1 for frozen
    input frozen_2,
    output u1,
    output u2
);

wire [17:0] llr_1_abs, llr_2_abs;
wire comp;

assign llr_1_abs = (llr_1[17] == 1) ? ~llr_1 + 1 : llr_1;
assign llr_2_abs = (llr_2[17] == 1) ? ~llr_2 + 1 : llr_2;
assign comp = (llr_1_abs < llr_2_abs) ? 0 : 1;

assign u1 = (llr_1[17] ^ llr_2[17]) & (~frozen_1);
assign u2 = (~comp & ~frozen_2 & llr_2[17]) | (comp & ~frozen_1 & ~frozen_2 & llr_2[17])
                | (comp & frozen_1 & ~frozen_2 & llr_1[17]);


endmodule