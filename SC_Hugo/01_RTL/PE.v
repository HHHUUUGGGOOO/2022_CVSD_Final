module PE(
    input signed [16:0]  LLR_c,    // to avoid overflow, add extra bit
    input signed [16:0]  LLR_d,
    input                u_sum,    // control signal, for g() adder/subtractor
    input                ctrl_fg,
    output signed [16:0] LLR_out
); 

    // ref: https://ieeexplore.ieee.org/document/6632947 (Fig. 6)
    wire signed [16:0] temp_f; 
    wire               out_sign; 
    wire               sign_LLR_c, sign_LLR_d;  
    wire        [16:0] mag_LLR_c, mag_LLR_d; 
    wire        [16:0] min_LLR; 
    wire signed [16:0] temp_g; 

    // f node -- (ctrl_fg == 0)
    assign sign_LLR_c = (LLR_c[16] == 1'b0) ? 0 : 1; 
    assign sign_LLR_d = (LLR_d[16] == 1'b0) ? 0 : 1;
    assign out_sign = sign_LLR_c ^ sign_LLR_d; 
    
    assign mag_LLR_c = (LLR_c[16] == 1'b0) ? LLR_c : (~LLR_c + 1'b1);
    assign mag_LLR_d = (LLR_c[16] == 1'b0) ? LLR_d : (~LLR_d + 1'b1); 
    assign min_LLR = (mag_LLR_c >= mag_LLR_d) ? mag_LLR_d : mag_LLR_c; 
    assign temp_f = (out_sign) ? (~min_LLR + 1'b1) : min_LLR;  

    // g node -- (ctrl_fg == 1)
    assign temp_g = (u_sum) ? (LLR_d - LLR_c) : (LLR_d + LLR_c); 

    // output 
    assign LLR_out = (ctrl_fg) ? temp_g : temp_f; 

endmodule 
