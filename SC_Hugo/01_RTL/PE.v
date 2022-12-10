module PE(
    input signed [12:0]  LLR_c,    // to avoid overflow, add extra bit
    input signed [12:0]  LLR_d,
    input                u_sum,    // control signal, for g() adder/subtractor
    output signed [12:0] LLR_a, 
    output signed [12:0] LLR_b
); 

    // ref: https://ieeexplore.ieee.org/document/6632947 (Fig. 6)
    wire signed [12:0] temp_f; 
    wire               sign_LLR_c, sign_LLR_d;  
    wire        [12:0] mag_LLR_c, mag_LLR_d; 
    wire        [12:0] min_LLR; 
    wire signed [12:0] temp_g; 

    // f node -- (ctrl_fg == 0)
    assign sign_LLR_c = (LLR_c[12] == 1'b0) ? 0 : 1; 
    assign sign_LLR_d = (LLR_d[12] == 1'b0) ? 0 : 1;
    assign temp_f[12] = sign_LLR_c ^ sign_LLR_d; 
    
    assign mag_LLR_c = (LLR_c[12] == 1'b0) ? LLR_c : (~LLR_c + 1'b1);
    assign mag_LLR_d = (LLR_c[12] == 1'b0) ? LLR_d : (~LLR_d + 1'b1); 
    assign min_LLR = (mag_LLR_c >= mag_LLR_d) ? mag_LLR_d : mag_LLR_c; 
    assign temp_f[11:0] = min_LLR[11:0]; 

    // g node -- (ctrl_fg == 1)
    assign temp_g = (u_sum) ? (LLR_d - LLR_c) : (LLR_d + LLR_c); 

    // output 
    assign LLR_a = temp_f;
    assign LLR_b = temp_g; 

endmodule 
