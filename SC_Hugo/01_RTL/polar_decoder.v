module polar_decoder (
    clk,
    rst_n,
    module_en,
    proc_done,
    raddr,
    rdata,
    waddr,
    wdata
);
    // IO description
    input  wire         clk;
    input  wire         rst_n;
    input  wire         module_en;
    input  wire [191:0] rdata;
    output wire [ 10:0] raddr;
    output wire [  5:0] waddr;
    output wire [139:0] wdata;
    output wire         proc_done;
    
    // ---------------------------------------------------------------------------
	// Wires and Registers
	// ---------------------------------------------------------------------------
	// ---- Add your own wires and registers here if needed ---- // 
    // output reg 
    reg proc_done_r, proc_done_w; 
    // state 
    reg [2:0] state_r, state_w; 
    // counter 
    reg [6:0] total_pack_num_r, total_pack_num_w; // u6.0 
    reg [7:0] K_num_r, K_num_w; // u7.0
    reg [9:0] N_num_r, N_num_w; // u9.0 
    reg [6:0] cur_pack_r, cur_pack_w;
    reg [4:0] cur_line_r;             // start from each packet's line 2 (LLR begin)
                                      // current LLR addr = 1 + ((cur_pack_r-1) * 33) + (cur_line_r)
                                      // e.g. packet no.2, line 3 = 1 + (1*33) + 1 = LLR_mem[36]
    reg [3:0] stage_now_r, stage_now_w; // stage 0 --> stage 8 (left --> right), I am in which stage now 
    reg [7:0] stage_cnt_r, stage_cnt_w; // encode the execution order 
    reg       stage_count_down_done_r, stage_count_down_done_w; // finish each stage encoding 
    // partial sum (u_s) : 1 (bit) * 512 for each stage 
    reg [255:0] u_s8_r, u_s8_w;
    reg [127:0] u_s7_r, u_s7_w;
    reg [63:0] u_s6_r, u_s6_w;
    reg [31:0] u_s5_r, u_s5_w;
    reg [15:0] u_s4_r, u_s4_w;
    reg [7:0] u_s3_r, u_s3_w;
    reg [3:0] u_s2_r, u_s2_w;
    reg [1:0] u_s1_r, u_s1_w;
    // store calculated value of each stage's node  
    reg signed [16:0] stage_value_8_r [0:255]; 
    reg signed [16:0] stage_value_7_r [0:127];
    reg signed [16:0] stage_value_6_r [0:63];
    reg signed [16:0] stage_value_5_r [0:31];
    reg signed [16:0] stage_value_4_r [0:15];
    reg signed [16:0] stage_value_3_r [0:7];
    reg signed [16:0] stage_value_2_r [0:3];
    reg signed [16:0] stage_value_1_r [0:1];

    reg signed [16:0] stage_value_8_w [0:255]; 
    reg signed [16:0] stage_value_7_w [0:127];
    reg signed [16:0] stage_value_6_w [0:63];
    reg signed [16:0] stage_value_5_w [0:31];
    reg signed [16:0] stage_value_4_w [0:15];
    reg signed [16:0] stage_value_3_w [0:7];
    reg signed [16:0] stage_value_2_w [0:3];
    reg signed [16:0] stage_value_1_w [0:1];

    parameter IDLE       = 0; 
    parameter READ_PACK  = 1; 
    parameter READ_N_K   = 2;
    parameter READ_LLR   = 3; 
    parameter DECODE     = 4; // dec_128, dec_256, dec_512 
    parameter PROC_DONE  = 5; 

    
    // ---------------------------------------------------------------------------
	// Wires and Registers for Memory 
	// ---------------------------------------------------------------------------
	// ---- Add your own wires and registers here if needed ---- //
    // LLR memory   
    reg [10:0] raddr_r;
    reg signed [11:0] llr_data_r [0:511]; 
    reg signed [11:0] llr_data_w [0:511];
    integer i; 

    // DEC memory  
    reg [139:0] wdata_r, wdata_w; 
    reg [5:0]   waddr_r, waddr_w;    
    reg [7:0]   out_idx_r, out_idx_w; 
    reg [7:0]   dec_k_idx_r, dec_k_idx_w; // K at most 140 bits


    // ---------------------------------------------------------------------------
	// Module Instance (PE, p_node, reliability_LUT) 
	// ---------------------------------------------------------------------------
	// reliability_LUT
    //  - if "stage_cnt_r == 000", then "f_index = 000 0", "g_index = 000 1" 
    wire [8:0] reliability_f, reliability_g; 
    wire [8:0] ch_idx_1, ch_idx_2; 
    wire [1:0] N; 
    wire       isfrozen_f, isfrozen_g;

    assign N = (N_num_r[9:8] == 2'b00) ? 2'b00 : (N_num_r[9:8] == 2'b01) ? 2'b01 : 2'b10; 
    assign ch_idx_1 = dec_k_idx_r; 
    assign ch_idx_2 = dec_k_idx_r + 1; 
    assign isfrozen_f = (reliability_f < (N_num_r - K_num_r));
    assign isfrozen_g = (reliability_g < (N_num_r - K_num_r));

    reliability_LUT lut_f(.N_channel(N), .channel_index(ch_idx_1), .reliability_index(reliability_f));
    reliability_LUT lut_g(.N_channel(N), .channel_index(ch_idx_2), .reliability_index(reliability_g));

    // PE : f(), g() 
    //  - use "generate" to wrap "assign / module" into for loop  
    reg  [16:0]  PE_in [0:511]; 
    reg          PE_flag_r, PE_flag_w; 
    wire [255:0] PE_u; 
    wire [16:0]  PE_out [0:255]; // extra 5 sign-bits to avoid overflow

    assign PE_u = (stage_now_r == 8) ? u_s8_r : 
                  (stage_now_r == 7) ? {128'b0, u_s7_r} :
                  (stage_now_r == 6) ? {192'b0, u_s6_r} :
                  (stage_now_r == 5) ? {224'b0, u_s5_r} :
                  (stage_now_r == 4) ? {240'b0, u_s4_r} :
                  (stage_now_r == 3) ? {248'b0, u_s3_r} :
                  (stage_now_r == 2) ? {252'b0, u_s2_r} :
                  (stage_now_r == 1) ? {254'b0, u_s1_r} : 0; 

    generate 
        genvar j; 
        for (j = 0 ; j < 256 ; j = j + 1) begin: PE
            PE pe(.LLR_c(PE_in[2*j]), .LLR_d(PE_in[(2*j)+1]), .u_sum(PE_u[j]), .ctrl_fg(PE_flag_r), .LLR_out(PE_out[j]));  
        end 
    endgenerate

    // p_node
    wire u_hat_1, u_hat_2; 

    p_node p(.LLR_1(stage_value_1_r[0]), .LLR_2(stage_value_1_r[1]), .frozen_1(isfrozen_f), .frozen_2(isfrozen_g), .u_hat_1(u_hat_1), .u_hat_2(u_hat_2)); 

	// ---------------------------------------------------------------------------
	// Continuous Assignment
	// ---------------------------------------------------------------------------
	// ---- Add your own wire data assignments here if needed ---- //
    // output reg
	assign proc_done = proc_done_r; 
    // LLR memory  
    assign raddr = raddr_r; 
    // DEC memory 
    assign wdata = wdata_r; 
    assign waddr = waddr_r;  


	// ---------------------------------------------------------------------------
	// Combinational Blocks
	// ---------------------------------------------------------------------------
	// ---- Write your conbinational block design here ---- //
    always @(*) begin  
        // info 
        proc_done_w = 0; 
        total_pack_num_w = (state_r == READ_PACK) ? rdata[6:0] : total_pack_num_r; 
        N_num_w = (state_r == READ_N_K) ? rdata[9:0] : N_num_r; 
        K_num_w = (state_r == READ_N_K) ? rdata[17:10] : K_num_r; 
        for (i = 0 ; i < 512 ; i = i + 1) begin 
            llr_data_w[i] = llr_data_r[i]; 
        end 
        // state 
        state_w = state_r; 
        // DEC_memory 
        dec_k_idx_w = dec_k_idx_r; 
        waddr_w = waddr_r; 
        wdata_w = wdata_r; 
        out_idx_w = out_idx_r; 
        // counter  
        cur_pack_w = cur_pack_r; 
        stage_now_w = stage_now_r; 
        stage_cnt_w = stage_cnt_r; 
        stage_count_down_done_w = stage_count_down_done_r; 
        for (i = 0; i < 256 ; i = i + 1) begin 
            stage_value_8_w[i] = stage_value_8_r[i];  
            stage_value_7_w[i[6:0]] = stage_value_7_r[i[6:0]]; 
            stage_value_6_w[i[5:0]] = stage_value_6_r[i[5:0]]; 
            stage_value_5_w[i[4:0]] = stage_value_5_r[i[4:0]]; 
            stage_value_4_w[i[3:0]] = stage_value_4_r[i[3:0]]; 
            stage_value_3_w[i[2:0]] = stage_value_3_r[i[2:0]]; 
            stage_value_2_w[i[1:0]] = stage_value_2_r[i[1:0]]; 
            stage_value_1_w[i[0]] = stage_value_1_r[i[0]]; 
        end
        // PE 
        PE_flag_w = 0; 
        u_s8_w = 0; 
        u_s7_w = 0;
        u_s6_w = 0;
        u_s5_w = 0;
        u_s4_w = 0;
        u_s3_w = 0;
        u_s2_w = 0;
        u_s1_w = 0;
        for (i = 0 ; i < 512 ; i = i + 1) begin 
            PE_in[i] = 0; 
        end 
        // case by op 
        case (state_r) 
            IDLE: begin 
                if (module_en) begin  
                    // state
                    state_w = READ_PACK; 
                end 
                else state_w = state_r; 
            end 
            READ_PACK: begin 
                // state 
                state_w = READ_N_K; 
            end
            READ_N_K: begin  
                cur_pack_w = cur_pack_r + 1;
                // state 
                state_w = READ_LLR; 
            end
            READ_LLR: begin 
                // N = 128, 256, 512
                //   - counter (%16, line+1) 
                //   - LLR_mem address 
                //   - next state (state_w)
                PE_flag_w = 0; 
                for (i = 0 ; i < 512 ; i = i + 1) begin 
                    // each reg in memory has 12 bits 
                    // one cycle == read one raddr 
                    //  - cur_line = 0 : i[3:0] = 0000 ~ 1111 --> one raddr 16 LLR 
                    //  - cur_line = 1 : i[3:0] = 0000 ~ 1111 --> one raddr 16 LLR 
                    if (cur_line_r == (i >> 4)) begin 
                        llr_data_w[i] = $signed(rdata[(12*i[3:0])+:12]); 
                    end 
                    else llr_data_w[i] = llr_data_r[i];  
                end
                // state
                if (N_num_r == 128) begin 
                    stage_now_w = 6; // start from rightmost stage
                    state_w = (cur_line_r == 7) ? DECODE : READ_LLR; // state
                end 
                else if (N_num_r == 256) begin 
                    stage_now_w = 7; // start from rightmost stage
                    state_w = (cur_line_r == 15) ? DECODE : READ_LLR; // state
                end 
                else begin  
                    stage_now_w = 8; // start from rightmost stage
                    state_w = (cur_line_r == 31) ? DECODE : READ_LLR; // state
                end 
            end 
            DECODE: begin 
                stage_now_w = (stage_now_r == 0) ? stage_now_r : (stage_now_r - 1); 
                PE_flag_w = (stage_now_r == 0) ? 1 : 0;
                // stage encoding --> start from which stage to stage 0 
                if (stage_now_r == 0) begin 
                    stage_cnt_w = stage_cnt_r + 1; 
                    dec_k_idx_w = dec_k_idx_r + 2;
                    // done 
                    if ((N_num_r == 128) && (stage_cnt_r == 6'b111111)) state_w = PROC_DONE; 
                    else if ((N_num_r == 256) && (stage_cnt_r == 7'b1111111)) state_w = PROC_DONE;
                    else if ((N_num_r == 512) && (stage_cnt_r == 8'b11111111)) state_w = PROC_DONE;
                    else state_w = state_r; 
                    // write data 
                    $display("(6) u_hat_1 : %b", u_hat_1); 
                    $display("(6) u_hat_2 : %b", u_hat_2); 
                    $display("(6) stage_cnt : %b", stage_cnt_r); 
                    $display("----------------------------------");
                    if ((isfrozen_f == 1) && (isfrozen_g == 1)) begin 
                        out_idx_w = out_idx_r; // skip frozen bit
                    end 
                    else if ((isfrozen_f == 1) && (isfrozen_g == 0)) begin 
                        wdata_w[out_idx_r] = u_hat_2; // only K-channel information needs to consider, skip frozen bit
                        out_idx_w = out_idx_r + 1; 
                    end 
                    else if ((isfrozen_f == 0) && (isfrozen_g == 1)) begin 
                        wdata_w[out_idx_r] = u_hat_1; // only K-channel information needs to consider, skip frozen bit
                        out_idx_w = out_idx_r + 1;
                    end 
                    else begin 
                        wdata_w[out_idx_r] = u_hat_1; 
                        wdata_w[out_idx_r+1] = u_hat_2;
                        out_idx_w = out_idx_r + 2;
                    end 
                    // stage flow 
                    if (stage_cnt_w[7] == ~stage_cnt_r[7]) begin 
                        stage_now_w = 8; 
                        u_s1_w[0] = u_hat_1 ^ u_hat_2; 
                        u_s1_w[1] = u_hat_1;
                        // 
                        u_s2_w[0] = u_s1_r[0] ^ u_s1_w[0];  
                        u_s2_w[1] = u_s1_r[1] ^ u_s1_w[1];
                        u_s2_w[2] = u_s1_w[0]; 
                        u_s2_w[3] = u_s1_w[1];
                        // 
                        for (i = 0 ; i < 4 ; i = i + 1) begin 
                            u_s3_w[i] = u_s2_r[i] ^ u_s2_w[i]; 
                            u_s3_w[i+4] = u_s2_w[i]; 
                        end 
                        // 
                        for (i = 0 ; i < 8 ; i = i + 1) begin 
                            u_s4_w[i] = u_s3_r[i] ^ u_s3_w[i]; 
                            u_s4_w[i+8] = u_s3_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 16 ; i = i + 1) begin 
                            u_s5_w[i] = u_s4_r[i] ^ u_s4_w[i]; 
                            u_s5_w[i+16] = u_s4_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 32 ; i = i + 1) begin 
                            u_s6_w[i] = u_s5_r[i] ^ u_s5_w[i]; 
                            u_s6_w[i+32] = u_s5_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 64 ; i = i + 1) begin 
                            u_s7_w[i] = u_s6_r[i] ^ u_s6_w[i]; 
                            u_s7_w[i+64] = u_s6_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 128 ; i = i + 1) begin 
                            u_s8_w[i] = u_s7_r[i] ^ u_s7_w[i]; 
                            u_s8_w[i+128] = u_s7_w[i]; 
                        end
                    end 
                    else if (stage_cnt_w[6] == ~stage_cnt_r[6]) begin 
                        stage_now_w = 7; 
                        u_s1_w[0] = u_hat_1 ^ u_hat_2; 
                        u_s1_w[1] = u_hat_1;
                        // 
                        u_s2_w[0] = u_s1_r[0] ^ u_s1_w[0];  
                        u_s2_w[1] = u_s1_r[1] ^ u_s1_w[1];
                        u_s2_w[2] = u_s1_w[0]; 
                        u_s2_w[3] = u_s1_w[1];
                        // 
                        for (i = 0 ; i < 4 ; i = i + 1) begin 
                            u_s3_w[i] = u_s2_r[i] ^ u_s2_w[i]; 
                            u_s3_w[i+4] = u_s2_w[i]; 
                        end 
                        // 
                        for (i = 0 ; i < 8 ; i = i + 1) begin 
                            u_s4_w[i] = u_s3_r[i] ^ u_s3_w[i]; 
                            u_s4_w[i+8] = u_s3_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 16 ; i = i + 1) begin 
                            u_s5_w[i] = u_s4_r[i] ^ u_s4_w[i]; 
                            u_s5_w[i+16] = u_s4_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 32 ; i = i + 1) begin 
                            u_s6_w[i] = u_s5_r[i] ^ u_s5_w[i]; 
                            u_s6_w[i+32] = u_s5_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 64 ; i = i + 1) begin 
                            u_s7_w[i] = u_s6_r[i] ^ u_s6_w[i]; 
                            u_s7_w[i+64] = u_s6_w[i]; 
                        end
                    end 
                    else if (stage_cnt_w[5] == ~stage_cnt_r[5]) begin 
                        stage_now_w = 6;
                        u_s1_w[0] = u_hat_1 ^ u_hat_2; 
                        u_s1_w[1] = u_hat_1;
                        // 
                        u_s2_w[0] = u_s1_r[0] ^ u_s1_w[0];  
                        u_s2_w[1] = u_s1_r[1] ^ u_s1_w[1];
                        u_s2_w[2] = u_s1_w[0]; 
                        u_s2_w[3] = u_s1_w[1];
                        // 
                        for (i = 0 ; i < 4 ; i = i + 1) begin 
                            u_s3_w[i] = u_s2_r[i] ^ u_s2_w[i]; 
                            u_s3_w[i+4] = u_s2_w[i]; 
                        end 
                        // 
                        for (i = 0 ; i < 8 ; i = i + 1) begin 
                            u_s4_w[i] = u_s3_r[i] ^ u_s3_w[i]; 
                            u_s4_w[i+8] = u_s3_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 16 ; i = i + 1) begin 
                            u_s5_w[i] = u_s4_r[i] ^ u_s4_w[i]; 
                            u_s5_w[i+16] = u_s4_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 32 ; i = i + 1) begin 
                            u_s6_w[i] = u_s5_r[i] ^ u_s5_w[i]; 
                            u_s6_w[i+32] = u_s5_w[i]; 
                        end
                    end 
                    else if (stage_cnt_w[4] == ~stage_cnt_r[4]) begin 
                        stage_now_w = 5;
                        u_s1_w[0] = u_hat_1 ^ u_hat_2; 
                        u_s1_w[1] = u_hat_1;
                        // 
                        u_s2_w[0] = u_s1_r[0] ^ u_s1_w[0];  
                        u_s2_w[1] = u_s1_r[1] ^ u_s1_w[1];
                        u_s2_w[2] = u_s1_w[0]; 
                        u_s2_w[3] = u_s1_w[1];
                        // 
                        for (i = 0 ; i < 4 ; i = i + 1) begin 
                            u_s3_w[i] = u_s2_r[i] ^ u_s2_w[i]; 
                            u_s3_w[i+4] = u_s2_w[i]; 
                        end 
                        // 
                        for (i = 0 ; i < 8 ; i = i + 1) begin 
                            u_s4_w[i] = u_s3_r[i] ^ u_s3_w[i]; 
                            u_s4_w[i+8] = u_s3_w[i]; 
                        end
                        // 
                        for (i = 0 ; i < 16 ; i = i + 1) begin 
                            u_s5_w[i] = u_s4_r[i] ^ u_s4_w[i]; 
                            u_s5_w[i+16] = u_s4_w[i]; 
                        end
                    end 
                    else if (stage_cnt_w[3] == ~stage_cnt_r[3]) begin 
                        stage_now_w = 4;
                        u_s1_w[0] = u_hat_1 ^ u_hat_2; 
                        u_s1_w[1] = u_hat_1;
                        // 
                        u_s2_w[0] = u_s1_r[0] ^ u_s1_w[0];  
                        u_s2_w[1] = u_s1_r[1] ^ u_s1_w[1];
                        u_s2_w[2] = u_s1_w[0]; 
                        u_s2_w[3] = u_s1_w[1];
                        // 
                        for (i = 0 ; i < 4 ; i = i + 1) begin 
                            u_s3_w[i] = u_s2_r[i] ^ u_s2_w[i]; 
                            u_s3_w[i+4] = u_s2_w[i]; 
                        end 
                        // 
                        for (i = 0 ; i < 8 ; i = i + 1) begin 
                            u_s4_w[i] = u_s3_r[i] ^ u_s3_w[i]; 
                            u_s4_w[i+8] = u_s3_w[i]; 
                        end
                    end 
                    else if (stage_cnt_w[2] == ~stage_cnt_r[2]) begin 
                        stage_now_w = 3;
                        u_s1_w[0] = u_hat_1 ^ u_hat_2; 
                        u_s1_w[1] = u_hat_1;
                        // 
                        u_s2_w[0] = u_s1_r[0] ^ u_s1_w[0];  
                        u_s2_w[1] = u_s1_r[1] ^ u_s1_w[1];
                        u_s2_w[2] = u_s1_w[0]; 
                        u_s2_w[3] = u_s1_w[1];
                        // 
                        for (i = 0 ; i < 4 ; i = i + 1) begin 
                            u_s3_w[i] = u_s2_r[i] ^ u_s2_w[i]; 
                            u_s3_w[i+4] = u_s2_w[i]; 
                        end 
                    end 
                    else if (stage_cnt_w[1] == ~stage_cnt_r[1]) begin 
                        stage_now_w = 2;
                        u_s1_w[0] = u_hat_1 ^ u_hat_2; 
                        u_s1_w[1] = u_hat_1;
                        // 
                        u_s2_w[0] = u_s1_r[0] ^ u_s1_w[0];  
                        u_s2_w[1] = u_s1_r[1] ^ u_s1_w[1];
                        u_s2_w[2] = u_s1_w[0]; 
                        u_s2_w[3] = u_s1_w[1];
                    end 
                    else if (stage_cnt_w[0] == ~stage_cnt_r[0]) begin 
                        stage_now_w = 1; 
                        u_s1_w[0] = u_hat_1 ^ u_hat_2; 
                        u_s1_w[1] = u_hat_1; 
                    end 
                    else stage_now_w = stage_now_r; 
                end 
                else if (stage_now_r == 8) begin  
                    // $display("(5) stage_now_r : %d", stage_now_r); 
                    // $display("----------------------------------");
                    for (i = 0 ; i < 256 ; i = i + 1) begin // f, g input are the same (see N = 8 figure)
                        PE_in[2*i] = { {5{llr_data_r[i][11]}}, llr_data_r[i] }; 
                        PE_in[(2*i)+1] = { {5{llr_data_r[i+256][11]}}, llr_data_r[i+256] }; 
                    end 
                    for (i = 0 ; i < 256 ; i = i + 1) begin 
                        stage_value_8_w[i] = PE_out[i]; 
                    end 
                end 
                else if (stage_now_r == 7) begin // N = 256 channel, total input = 256
                    // $display("(5) stage_now_r : %d", stage_now_r); 
                    // $display("----------------------------------");
                    for (i = 0 ; i < 128 ; i = i + 1) begin // f, g's input come from stage_8's output
                        PE_in[2*i] = (N_num_r == 256) ? { {5{llr_data_r[i][11]}}, llr_data_r[i] } : stage_value_8_r[i]; 
                        PE_in[(2*i)+1] = (N_num_r == 256) ? { {5{llr_data_r[i+128][11]}}, llr_data_r[i+128] } : stage_value_8_r[i+128]; 
                    end 
                    for (i = 0 ; i < 128 ; i = i + 1) begin 
                        stage_value_7_w[i] = PE_out[i]; 
                    end
                end 
                else if (stage_now_r == 6) begin // N = 128 channel, total input = 128 
                    $display("(4) Example for N = 128, in \"stage_now_r\" == 6"); 
                    // $display("(5) stage_now_r : %d", stage_now_r); 
                    // $display("----------------------------------");
                    for (i = 0 ; i < 64 ; i = i + 1) begin 
                        PE_in[2*i] = (N_num_r == 128) ? { {5{llr_data_r[i][11]}}, llr_data_r[i] } : stage_value_7_r[i]; 
                        PE_in[(2*i)+1] = (N_num_r == 128) ? { {5{llr_data_r[i+64][11]}}, llr_data_r[i+64] } : stage_value_7_r[i+64];
                    end
                    for (i = 0 ; i < 64 ; i = i + 1) begin 
                        stage_value_6_w[i] = PE_out[i]; 
                    end
                end
                else if (stage_now_r == 5) begin // N = 64 channel, total input = 64
                    // $display("(5) stage_now_r : %d", stage_now_r); 
                    // $display("----------------------------------");
                    for (i = 0 ; i < 32 ; i = i + 1) begin 
                        PE_in[2*i] = stage_value_6_r[i]; 
                        PE_in[(2*i)+1] = stage_value_6_r[i+32];
                    end
                    for (i = 0 ; i < 32 ; i = i + 1) begin 
                        stage_value_5_w[i] = PE_out[i]; 
                    end
                end
                else if (stage_now_r == 4) begin // N = 32 channel, total input = 32
                    // $display("(5) stage_now_r : %d", stage_now_r); 
                    // $display("----------------------------------");
                    for (i = 0 ; i < 16 ; i = i + 1) begin 
                        PE_in[2*i] = stage_value_5_r[i]; 
                        PE_in[(2*i)+1] = stage_value_5_r[i+16];
                    end
                    for (i = 0 ; i < 16 ; i = i + 1) begin 
                        stage_value_4_w[i] = PE_out[i]; 
                    end
                end
                else if (stage_now_r == 3) begin // N = 16 channel, total input = 16
                    // $display("(5) stage_now_r : %d", stage_now_r); 
                    // $display("----------------------------------");
                    for (i = 0 ; i < 8 ; i = i + 1) begin 
                        PE_in[2*i] = stage_value_4_r[i]; 
                        PE_in[(2*i)+1] = stage_value_4_r[i+8];
                    end
                    for (i = 0 ; i < 8 ; i = i + 1) begin 
                        stage_value_3_w[i] = PE_out[i]; 
                    end
                end
                else if (stage_now_r == 2) begin // N = 8 channel, total input = 8
                    // $display("(5) stage_now_r : %d", stage_now_r); 
                    // $display("----------------------------------");
                    for (i = 0 ; i < 4 ; i = i + 1) begin 
                        PE_in[2*i] = stage_value_3_r[i]; 
                        PE_in[(2*i)+1] = stage_value_3_r[i+4];
                    end
                    for (i = 0 ; i < 4 ; i = i + 1) begin 
                        stage_value_2_w[i] = PE_out[i]; 
                    end
                end
                else if (stage_now_r == 1) begin // N = 4 channel, total input = 4
                    // $display("(5) stage_now_r : %d", stage_now_r); 
                    // $display("----------------------------------");
                    for (i = 0 ; i < 2 ; i = i + 1) begin 
                        PE_in[2*i] = stage_value_2_r[i]; 
                        PE_in[(2*i)+1] = stage_value_2_r[i+2];
                    end
                    for (i = 0 ; i < 2 ; i = i + 1) begin 
                        stage_value_1_w[i] = PE_out[i]; 
                    end
                end
                else stage_now_w = stage_now_r; 
            end 
            PROC_DONE: begin 
                wdata_w = waddr_r + 1;
                // reset 
                stage_now_w = 0; 
                stage_cnt_w = 0; 
                stage_count_down_done_w = 1'b0;  
                out_idx_w = 0; 
                dec_k_idx_w = 0; 
                // finish all packets, go to next "pattern"
                if (cur_pack_r == total_pack_num_r) begin 
                    proc_done_w = 1'b1; 
                    // state 
                    state_w = IDLE; 
                end 
                // just finish decoding, go to next "packet"
                else begin 
                    // state 
                    state_w = READ_N_K; 
                end 
            end 
            default: state_w = IDLE; 
        endcase
    end 


	// ---------------------------------------------------------------------------
	// Sequential Block
	// ---------------------------------------------------------------------------
	// ---- Write your sequential block design here ---- //
    // active low asynchronous reset 
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin 
            // info  
            for (i = 0 ; i < 512 ; i = i + 1) begin 
                llr_data_r[i] <= 0; 
            end
            // output reg 
            proc_done_r <= 1'b0; 
            // state 
            state_r <= IDLE; 
            // LLR_memory 
            raddr_r <= 0; 
            // DEC_memory 
            wdata_r <= 0; 
            waddr_r <= 0; 
            out_idx_r <= 0; 
            dec_k_idx_r <= 0; 
            // counter 
            total_pack_num_r <= 0;  
            K_num_r <= 0; 
            N_num_r <= 0; 
            cur_pack_r <= 0;
            cur_line_r <= 0;
            stage_now_r <= 0; 
            stage_cnt_r <= 0; 
            stage_count_down_done_r <= 1'b0; 
            // PE 
            PE_flag_r <= 0; 
            u_s8_r <= 0;
            u_s7_r <= 0;
            u_s6_r <= 0;
            u_s5_r <= 0;
            u_s4_r <= 0;
            u_s3_r <= 0;
            u_s2_r <= 0;
            u_s1_r <= 0; 
            // store for each stage's node 
            for (i = 0; i < 256 ; i = i + 1) begin 
                stage_value_8_r[i] <= 0;  
                stage_value_7_r[i[6:0]] <= 0; 
                stage_value_6_r[i[5:0]] <= 0; 
                stage_value_5_r[i[4:0]] <= 0; 
                stage_value_4_r[i[3:0]] <= 0; 
                stage_value_3_r[i[2:0]] <= 0; 
                stage_value_2_r[i[1:0]] <= 0; 
                stage_value_1_r[i[0]] <= 0; 
            end
        end 
        else begin  
            // info 
            proc_done_r <= proc_done_w; 
            total_pack_num_r <= total_pack_num_w; 
            K_num_r <= K_num_w; 
            N_num_r <= N_num_w; 
            for (i = 0 ; i < 512 ; i = i + 1) begin 
                llr_data_r[i] <= llr_data_w[i]; 
            end
            // state 
            state_r <= state_w; 
            // DEC_memory 
            waddr_r <= waddr_w; 
            wdata_r <= wdata_w; 
            out_idx_r <= out_idx_w; 
            dec_k_idx_r <= dec_k_idx_w; 
            // counter  
            cur_pack_r <= cur_pack_w; 
            stage_now_r <= stage_now_w; 
            stage_cnt_r <= stage_cnt_w; 
            stage_count_down_done_r <= stage_count_down_done_w;
            // PE 
            PE_flag_r <= PE_flag_w; 
            u_s8_r <= u_s8_w;
            u_s7_r <= u_s7_w;
            u_s6_r <= u_s6_w;
            u_s5_r <= u_s5_w;
            u_s4_r <= u_s4_w;
            u_s3_r <= u_s3_w;
            u_s2_r <= u_s2_w;
            u_s1_r <= u_s1_w; 
            // load #packet & N, K 
            case (state_r) 
                IDLE: begin 
                    raddr_r <= (module_en == 1'b1) ? (raddr_r + 1) : raddr_r; 
                    cur_line_r <= 0;
                end 
                READ_PACK: begin 
                    raddr_r <= raddr_r + 1; 
                    $display("(1) total pack num = %d", total_pack_num_w);
                end 
                READ_N_K: begin 
                    raddr_r <= raddr_r + 1;
                    cur_line_r <= 0; 
                    $display("=================================="); 
                    $display("    packet no.  %d", cur_pack_w); 
                    $display("==================================");
                    $display("(2) N_num = %d", N_num_w); 
                    $display("(2) K_num = %d", K_num_w); 
                    $display("(2) raddr_r = %d", raddr_r); 
                    $display("----------------------------------");
                end 
                READ_LLR: begin 
                    if (N_num_r == 128) begin 
                        raddr_r <= (cur_line_r == 7) ? (raddr_r + (32-8)) : (raddr_r + 1); 
                        cur_line_r <= (cur_line_r == 7) ? 0 : (cur_line_r + 1); // 16 (LLR) * 8 = 128
                    end 
                    else if (N_num_r == 256) begin 
                        raddr_r <= (cur_line_r == 15) ? (raddr_r + (32-16)) : (raddr_r + 1);
                        cur_line_r <= (cur_line_r == 15) ? 0 : (cur_line_r + 1); // 16 (LLR) * 16 = 256
                    end 
                    else begin 
                        raddr_r <= (cur_line_r == 31) ? (raddr_r + (32-32)) : (raddr_r + 1);
                        cur_line_r <= (cur_line_r == 31) ? 0 : (cur_line_r + 1); // 16 (LLR) * 31 = 512
                    end 
                end 
                DECODE: begin 
                    raddr_r <= raddr_r;
                    if (stage_now_r == 0) cur_line_r <= 1; // after N, K 
                    else cur_line_r <= 0; 
                end 
                PROC_DONE: begin 
                    raddr_r <= raddr_r + 1;
                    cur_line_r <= 0; 
                end 
                default: raddr_r <= raddr_r; 
            endcase 
            for (i = 0; i < 256 ; i = i + 1) begin 
                stage_value_8_r[i] <= stage_value_8_w[i];  
                stage_value_7_r[i[6:0]] <= stage_value_7_w[i[6:0]]; 
                stage_value_6_r[i[5:0]] <= stage_value_6_w[i[5:0]]; 
                stage_value_5_r[i[4:0]] <= stage_value_5_w[i[4:0]]; 
                stage_value_4_r[i[3:0]] <= stage_value_4_w[i[3:0]]; 
                stage_value_3_r[i[2:0]] <= stage_value_3_w[i[2:0]]; 
                stage_value_2_r[i[1:0]] <= stage_value_2_w[i[1:0]]; 
                stage_value_1_r[i[0]] <= stage_value_1_w[i[0]]; 
            end  
        end 
    end 


endmodule