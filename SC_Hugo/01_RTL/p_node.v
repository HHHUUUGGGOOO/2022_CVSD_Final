module p_node(
    input [11:0] LLR_1, 
    input [11:0] LLR_2, 
    input [9:0]  N,         // to check if frozen (#channel, N = 128, 256, 512)
    input [7:0]  K,         
    input [8:0]  ch_idx_1,  // to check if frozen (channel index) 
    input [8:0]  ch_idx_2,  
    output       u_hat_1,   // estimated u(2i-1) 
    output       u_hat_2    // estimated u(2i)
); 

    // ref: https://ieeexplore.ieee.org/document/6632947 (formula 34, 35)
    // =================================================================
    //     u(2i-1) = (~frozen_1) * (sign(LLR_1) ^ sign(LLR_2))
    //     sign(x) = (x >= 0) ? 0 : 1
    //    -----------------------------------------------------------
    //     u(2i)   = (~comp) * (~frozen_2) * (sign(LLR_2)) + 
    //               comp * (~frozen_1) * (~frozen_2) sign(LLR_2) + 
    //               comp * (~frozen_1) * (~frozen_2) sign(LLR_1) 
    //     comp    = (|LLR_1| >= |LLR_2|) ? 1 : 0
    // =================================================================

    // temp wire 
    wire [10:0] tmp; 
    wire [8:0]  rindex_1, rindex_2; // reliability index  
    // special wire from input (boolean)
    wire sign_LLR_1; 
    wire sign_LLR_2; 
    wire frozen_1; // frozen = (reliability_index < (N-K))
    wire frozen_2; 
    wire comp; 

    // assign special input 
    assign sign_LLR_1 = (LLR_1[11] == 1'b0) ? 0 : 1; 
    assign sign_LLR_2 = (LLR_2[11] == 1'b0) ? 0 : 1; 
    assign frozen_1   = rindex_1 < (N - K); 
    assign frozen_2   = rindex_2 < (N - K); 

    // call module 
    reliability_LUT lut_1(.N_channel(N[9:8]), .channel_index(ch_idx_1), .reliability_index(rindex_1)); 
    reliability_LUT lut_2(.N_channel(N[9:8]), .channel_index(ch_idx_2), .reliability_index(rindex_2));

    // logic circuit 


endmodule 