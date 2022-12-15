module processElement(
    input [18:0] llr_1,
    input [18:0] llr_2,
    input control,  // 0 execute f, 1 execute g
    input u,
    output [18:0] llr_out
);

wire [18:0] llr_1_abs, llr_2_abs;
wire f_sign;
wire [17:0] f_abs_min;
wire signed [18:0] g_sum;
wire signed [18:0] g_sub;
wire [18:0] g;
wire [18:0] f;

// f node
assign llr_1_abs = (llr_1[18] == 1) ? ~llr_1 + 1 : llr_1;
assign llr_2_abs = (llr_2[18] == 1) ? ~llr_2 + 1 : llr_2;
assign f_sign = llr_1[18] ^ llr_2[18];
assign f_abs_min = (llr_1_abs < llr_2_abs) ? llr_1_abs : llr_2_abs;

// g node
assign g_sum = $signed(llr_1) + $signed(llr_2);
assign g_sub = $signed(llr_2) - $signed(llr_1);
assign g = (u == 0) ? g_sum : g_sub;
assign f = (f_sign == 1) ? ~f_abs_min+1 : f_abs_min;

assign llr_out = (control == 0) ? f : g;

endmodule