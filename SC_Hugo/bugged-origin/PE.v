module processElement(
    input [18:0] llr_1,
    input [18:0] llr_2,
    input control,  // 0 execute f, 1 execute g
    input u,
    output [18:0] llr_out
);

// input
wire signed [18:0] llr1;
wire signed [18:0] llr2;


wire [18:0] llr_1_abs, llr_2_abs;
wire f_sign;
wire [17:0] f_abs_min;
wire signed [18:0] g_sum;
wire signed [18:0] g_sub;
wire [18:0] g;
wire [18:0] f;

assign llr1 = llr_1;
assign llr2 = llr_2;

// f node
assign llr_1_abs = (llr1[18] == 1) ? ~llr1 + 1 : llr1;
assign llr_2_abs = (llr2[18] == 1) ? ~llr2 + 1 : llr2;
assign f_sign = llr1[18] ^ llr2[18];
assign f_abs_min = (llr_1_abs < llr_2_abs) ? llr_1_abs : llr_2_abs;

// g node
assign g_sum = llr1 + llr2;
assign g_sub = llr2 - llr1;
assign g = (u == 0) ? g_sum : g_sub;
assign f = (f_sign == 1) ? ~f_abs_min+1 : f_abs_min;

assign llr_out = (control == 0) ? f : g;

endmodule