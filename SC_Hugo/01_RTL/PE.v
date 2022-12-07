module PE(
    input signed [11:0]  LLR_c, 
    input signed [11:0]  LLR_d,
    input                u_sum,    // control signal, for g() adder/subtractor
    input                ctrl_fg,  // control signal, for f()/g()
    output signed [11:0] LLR_ab    // "ctrl_fg" determines output LLR_a/LLR_b
); 

    // ref: https://ieeexplore.ieee.org/document/6632947 (Fig. 6)
    wire signed [11:0] temp_f; 
    wire               sign_LLR_c, sign_LLR_d;  
    wire        [11:0] mag_LLR_c, mag_LLR_d; 
    wire        [10:0] min_LLR; 
    wire signed [11:0] temp_g; 

    // f node -- (ctrl_fg == 0)
    assign sign_LLR_c = (LLR_c[11] == 1'b0) ? 0 : 1; 
    assign sign_LLR_d = (LLR_d[11] == 1'b0) ? 0 : 1;
    assign temp_f[11] = sign_LLR_c ^ sign_LLR_d; 
    
    assign mag_LLR_c = (LLR_c[11] == 1'b0) ? LLR_c : (~LLR_c + 1'b1);
    assign mag_LLR_d = (LLR_c[11] == 1'b0) ? LLR_d : (~LLR_d + 1'b1); 
    assign min_LLR = (mag_LLR_c >= mag_LLR_d) ? mag_LLR_d[10:0] : mag_LLR_c[10:0]; 
    assign temp_f[10:0] = min_LLR; 

    // g node -- (ctrl_fg == 1)
    assign temp_g = (u_sum) ? (LLR_d - LLR_c) : (LLR_d + LLR_c); 

    // output 
    assign LLR_ab = (ctrl_fg) ? temp_g : temp_f; 

endmodule 
