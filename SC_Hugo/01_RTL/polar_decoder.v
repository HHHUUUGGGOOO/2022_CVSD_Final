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
    reg proc_done_r; 
    // state 
    reg [2:0] state_r, state_w; 
    // counter 
    reg [6:0] total_pack_num; // u6.0 
    reg [7:0] K_num; // u7.0
    reg [9:0] N_num; // u9.0
    reg [6:0] cur_pack_r, cur_pack_w;
    reg [4:0] cur_line_r, cur_line_w; // start from each packet's line 2 (LLR begin)
                                      // current LLR addr = 1 + ((cur_pack_r-1) * 33) + (cur_line_r)
                                      // e.g. packet no.2, line 3 = 1 + (1*33) + 1 = LLR_mem[36]
    reg [3:0] stage_now_r, stage_now_w; // stage 0 --> stage 8 (left --> right), I am in which stage now 
    reg [7:0] stage_cnt_r, stage_cnt_w; // encode the execution order 
    reg       stage_count_down_done_r, stage_count_down_done_w; // finish each stage encoding 
    // partial sum (u_s) : 1 (bit) * 512 for each stage 
    reg u_init [511:0]; // successively decoded from u_1 --> u_N
    reg u_s0 [511:0];
    reg u_s1 [511:0];
    reg u_s2 [511:0];
    reg u_s3 [511:0];
    reg u_s4 [511:0];
    reg u_s5 [511:0];
    reg u_s6 [511:0];
    reg u_s7 [511:0];
    reg u_s8 [511:0];
    // f node (N = 512 --> there're 256 f())
    //   - (1) (input) f_a, f_b : 12+1 (bits, avoid overflow), total 256 f() 
    //   - (2) (output) f_out : same as input, use wire, and assign to reg later 
    reg  signed [12:0] f_a [0:255]; 
    reg  signed [12:0] f_b [0:255]; 
    wire signed [12:0] f_out [0:255];  
    // g node (N = 512 --> there're 256 g())
    //   - (1) (input) g_a, g_b : 12+1 (bits, avoid overflow), total 256 g()
    //   - (2) (output) g_out : same as input, use wire, and assign to reg later
    //   - (3) g_usum : single bit, to store the needed "u_s"
    reg  signed [12:0] g_a [0:255]; 
    reg  signed [12:0] g_b [0:255];
    wire signed [12:0] g_out [0:255];
    reg                g_usum [0:255]; 
    // store calculated value of each stage's node  
    reg signed [12:0] stage_value_8 [0:255]; 
    reg signed [12:0] stage_value_7 [0:127];
    reg signed [12:0] stage_value_6 [0:63];
    reg signed [12:0] stage_value_5 [0:31];
    reg signed [12:0] stage_value_4 [0:15];
    reg signed [12:0] stage_value_3 [0:7];
    reg signed [12:0] stage_value_2 [0:3];
    reg signed [12:0] stage_value_1 [0:1];

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
    reg [10:0] raddr_r, raddr_w;
    reg signed [11:0] llr_data [0:511]; 
    integer i; 

    // DEC memory  
    reg [139:0] wdata_r; 
    reg [5:0]   waddr_r;    
    reg [7:0]   dec_k_idx; // K at most 140 bits


    // ---------------------------------------------------------------------------
	// Module Instance (PE, p_node, reliability_LUT) 
	// ---------------------------------------------------------------------------
	// reliability_LUT
    //  - if "stage_cnt_r == 000", then "f_index = 000 0", "g_index = 000 1" 
    wire [8:0] reliability_f, reliability_g; 
    wire       isfrozen_f, isfrozen_g;

    reliability_LUT lut_f(.N_channel(N_num[9:8]), .channel_index({stage_cnt_r, 1'b0}), reliability_index(reliability_f));
    reliability_LUT lut_g(.N_channel(N_num[9:8]), .channel_index({stage_cnt_r, 1'b1}), reliability_index(reliability_g));

    assign isfrozen_f = (reliability_f < (N_num - K_num));
    assign isfrozen_g = (reliability_g < (N_num - K_num));

    // PE (256*f(), 256*g())
    //  - use "generate" to wrap "assign / module" into for loop  
    generate 
        genvar j; 
        for (j = 0 ; j < 256 ; j = j + 1) begin: PE_generate
            PE pe_f(.LLR_c(f_a[j]), .LLR_d(f_b[j]), .u_sum(g_usum[j]), .LLR_a(f_out[j]), .LLR_b(g_out[j]));
            PE pe_g(.LLR_c(g_a[j]), .LLR_d(g_b[j]), .u_sum(g_usum[j]), .LLR_a(f_out[j]), .LLR_b(g_out[j]));
        end 
    endgenerate

    // p_node
    wire u_hat_1, u_hat_2; 

    p_node p(.LLR_1(stage_value_1[{stage_cnt_r, 1'b0}]), .LLR_2(stage_value_1[{stage_cnt_r, 1'b1}]), .frozen_1(isfrozen_f), .frozen_2(isfrozen_g), .u_hat_1(u_hat_1), .u_hat_2(u_hat_2)); 

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
        // state 
        state_w = state_r; 
        // LLR_memory 
        raddr_w = raddr_r; 
        // counter  
        cur_pack_w = cur_pack_r; 
        cur_line_w = cur_line_r;
        stage_now_w = stage_now_r; 
        stage_cnt_w = stage_cnt_r; 
        stage_count_down_done_w = stage_count_down_done_r; 
        // partial sum generator 
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: init --> 0
            u_s0[i] = u_init[i]; 
        end 
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: 0 --> 1
            if (i[0] == 1'b0) u_s1[i] = u_s0[i] ^ u_s0[i+1]; 
            else u_s1[i] = u_s0[i]; 
        end
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: 1 --> 2
            if (i[1] == 1'b0) u_s2[i] = u_s1[i] ^ u_s1[i+2]; 
            else u_s2[i] = u_s1[i];
        end
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: 2 --> 3
            if (i[2] == 1'b0) u_s3[i] = u_s2[i] ^ u_s2[i+4]; 
            else u_s3[i] = u_s2[i];
        end
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: 3 --> 4
            if (i[3] == 1'b0) u_s4[i] = u_s3[i] ^ u_s3[i+8]; 
            else u_s4[i] = u_s3[i];
        end
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: 4 --> 5
            if (i[4] == 1'b0) u_s5[i] = u_s4[i] ^ u_s4[i+16]; 
            else u_s5[i] = u_s4[i];
        end
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: 5 --> 6
            if (i[5] == 1'b0) u_s6[i] = u_s5[i] ^ u_s5[i+32]; 
            else u_s6[i] = u_s5[i];
        end
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: 6 --> 7
            if (i[6] == 1'b0) u_s7[i] = u_s6[i] ^ u_s6[i+64]; 
            else u_s7[i] = u_s6[i];
        end
        for (i = 0 ; i < 512 ; i = i + 1) begin // stage: 7 --> 8
            if (i[7] == 1'b0) u_s8[i] = u_s7[i] ^ u_s7[i+128]; 
            else u_s8[i] = u_s7[i];
        end 
        // case by op 
        case (state_r) 
            IDLE: begin 
                if (module_en) begin 
                    // reset 
                    proc_done_w = 1'b0; 
                    N_num = 0; 
                    K_num = 0; 
                    total_pack_num = 0; 
                    cur_pack_w = 0;  
                    cur_line_w = 0;
                    // ready to read # of packets
                    raddr_w = 0; 
                    // state
                    state_w = READ_PACK; 
                end 
                else state_w = state_r; 
            end 
            READ_PACK: begin 
                // read # of packets @ sequential always
                // ready to read first N, K 
                raddr_w = 1; 
                // state 
                state_w = READ_N_K; 
            end
            READ_N_K: begin 
                // for each packet, the "cur_line_w" reset
                cur_pack_w = cur_pack_r + 1;  
                raddr_w = raddr_r + 1;
                // if reach packet number, finish 
                if (cur_pack_r == (total_pack_num - 1)) begin 
                    // state
                    state_w = PROC_DONE; 
                end 
                // else, read the first line of packet to get N, K
                else begin  
                    // N, K are read @ sequential always 
                    // state 
                    state_w = READ_LLR; 
                end 
            end
            READ_LLR: begin 
                // N = 128, 256, 512
                //   - counter (%16, line+1) (cur_line_w)
                //   - LLR_mem address (raddr_w)
                //   - next state (state_w)
                if (N_num == 128) begin 
                    cur_line_w = (cur_line_r == 7) ? 0 : (cur_line_r + 1); // 16 (LLR) * 8 = 128
                    raddr_w = (cur_line_r == 7) ? (raddr_r + (32-8)) : (raddr_r + 1); // fulfill 33 lines in a packet 
                    stage_now_w = 6; // start from rightmost stage
                    state_w = (cur_line_r == 7) ? DECODE : READ_LLR; // state
                end 
                else if (N_num == 256) begin 
                    cur_line_w = (cur_line_r == 15) ? 0 : (cur_line_r + 1); // 16 (LLR) * 16 = 256
                    raddr_w = (cur_line_r == 15) ? (raddr_r + (32-16)) : (raddr_r + 1); // fulfill 33 lines in a packet
                    stage_now_w = 7; // start from rightmost stage
                    state_w = (cur_line_r == 15) ? DECODE : READ_LLR; // state
                end 
                else begin 
                    cur_line_w = (cur_line_r == 31) ? 0 : (cur_line_r + 1); // 16 (LLR) * 32 = 512
                    raddr_w = (cur_line_r == 31) ? (raddr_r + (32-32)) : (raddr_r + 1); // fulfill 33 lines in a packet
                    stage_now_w = 8; // start from rightmost stage
                    state_w = (cur_line_r == 31) ? DECODE : READ_LLR; // state
                end 
            end 
            DECODE: begin 
                // stage encoding --> start from which stage to stage 0 
                if (stage_count_down_done_r == 1'b1) begin 
                    stage_count_down_done_w = 1'b0;  
                    stage_cnt_w = stage_cnt_r + 1; 
                    if ((N_num == 128) && (stage_cnt_r == 6'b111111)) state_w = PROC_DONE; 
                    else if ((N_num == 256) && (stage_cnt_r == 7'b1111111)) state_w = PROC_DONE;
                    else if ((N_num == 512) && (stage_cnt_r == 8'b11111111)) state_w = PROC_DONE;
                    else if (stage_cnt_w[7] == ~stage_cnt_r[7]) stage_now_w = 7; 
                    else if (stage_cnt_w[6] == ~stage_cnt_r[6]) stage_now_w = 6; 
                    else if (stage_cnt_w[5] == ~stage_cnt_r[5]) stage_now_w = 5;
                    else if (stage_cnt_w[4] == ~stage_cnt_r[4]) stage_now_w = 4;
                    else if (stage_cnt_w[3] == ~stage_cnt_r[3]) stage_now_w = 3;
                    else if (stage_cnt_w[2] == ~stage_cnt_r[2]) stage_now_w = 2;
                    else if (stage_cnt_w[1] == ~stage_cnt_r[1]) stage_now_w = 1;
                    else if (stage_cnt_w[0] == ~stage_cnt_r[0]) stage_now_w = 0; 
                    else stage_now_w = stage_now_r; 
                end 
                else begin 
                    // current stage 
                    if (stage_now_r != 0) stage_now_w = stage_now_r - 1; 
                    // stage case (stage 8 to stage 0, right to left) --> update f, g value in each stage's register 
                    else if (stage_now_r == 8) begin 
                        for (i = 0 ; i < 256 ; i = i + 1) begin // f, g input are the same (see N = 8 figure)
                            f_a[i] = llr_data[i]; 
                            f_b[i] = llr_data[i+256]; 
                            g_a[i] = llr_data[i]; 
                            g_b[i] = llr_data[i+256]; 
                            g_usum[i] = u_s8[{1'b0, i[7:0]}]; // xor with (0 0000000 ~ 0 1111111), g node is at (1 0000000 ~ 1 1111111)
                        end 
                    end 
                    else if (stage_now_r == 7) begin // N = 256 channel, total input = 256
                        for (i = 0 ; i < 128 ; i = i + 1) begin // f, g's input come from stage_8's output
                            f_a[i] = stage_value_8[i]; 
                            f_b[i] = stage_value_8[i+128]; 
                            g_a[i] = stage_value_8[i]; 
                            g_b[i] = stage_value_8[i+128]; 
                            g_usum[i] = u_s7[{stage_cnt_r[8], 1'b0, i[6:0]}];
                        end 
                    end 
                    else if (stage_now_r == 6) begin // N = 128 channel, total input = 128
                        for (i = 0 ; i < 64 ; i = i + 1) begin 
                            f_a[i] = stage_value_7[i]; 
                            f_b[i] = stage_value_7[i+64]; 
                            g_a[i] = stage_value_7[i]; 
                            g_b[i] = stage_value_7[i+64];
                            g_usum[i] = u_s6[{stage_cnt_r[8:7], 1'b0, i[5:0]}];
                        end
                    end
                    else if (stage_now_r == 5) begin // N = 64 channel, total input = 64
                        for (i = 0 ; i < 32 ; i = i + 1) begin 
                            f_a[i] = stage_value_6[i]; 
                            f_b[i] = stage_value_6[i+32]; 
                            g_a[i] = stage_value_6[i]; 
                            g_b[i] = stage_value_6[i+32];
                            g_usum[i] = u_s5[{stage_cnt_r[8:6], 1'b0, i[4:0]}];
                        end
                    end
                    else if (stage_now_r == 4) begin // N = 32 channel, total input = 32
                        for (i = 0 ; i < 16 ; i = i + 1) begin 
                            f_a[i] = stage_value_5[i]; 
                            f_b[i] = stage_value_5[i+16]; 
                            g_a[i] = stage_value_5[i]; 
                            g_b[i] = stage_value_5[i+16];
                            g_usum[i] = u_s4[{stage_cnt_r[8:5], 1'b0, i[3:0]}];
                        end
                    end
                    else if (stage_now_r == 3) begin // N = 16 channel, total input = 16
                        for (i = 0 ; i < 8 ; i = i + 1) begin 
                            f_a[i] = stage_value_4[i]; 
                            f_b[i] = stage_value_4[i+8];
                            g_a[i] = stage_value_4[i]; 
                            g_b[i] = stage_value_4[i+8]; 
                            g_usum[i] = u_s3[{stage_cnt_r[8:4], 1'b0, i[2:0]}];
                        end
                    end
                    else if (stage_now_r == 2) begin // N = 8 channel, total input = 8
                        for (i = 0 ; i < 4 ; i = i + 1) begin 
                            f_a[i] = stage_value_3[i]; 
                            f_b[i] = stage_value_3[i+4]; 
                            g_a[i] = stage_value_3[i]; 
                            g_b[i] = stage_value_3[i+4];
                            g_usum[i] = u_s2[{stage_cnt_r[8:3], 1'b0, i[1:0]}];
                        end
                    end
                    else if (stage_now_r == 1) begin // N = 4 channel, total input = 4
                        for (i = 0 ; i < 2 ; i = i + 1) begin 
                            f_a[i] = stage_value_2[i]; 
                            f_b[i] = stage_value_2[i+2]; 
                            g_a[i] = stage_value_2[i]; 
                            g_b[i] = stage_value_2[i+2];
                            g_usum[i] = u_s1[{stage_cnt_r[8:2], 1'b0, i[0]}];
                        end
                    end
                    else begin // stage_now_r == 0, p_node 
                        // done one iteration 
                        stage_count_down_done_w = 1'b1;
                        for (i = 0 ; i < 1 ; i = i + 1) begin 
                            f_a[i] = stage_value_1[i]; 
                            f_b[i] = stage_value_1[i+1]; 
                            g_a[i] = stage_value_1[i]; 
                            g_b[i] = stage_value_1[i+1];
                            g_usum[i] = u_s0[{stage_cnt_r[8:1], 1'b0}];
                        end
                    end
                end  
            end 
            PROC_DONE: begin 
                // reset 
                cur_line_w = 0; 
                stage_now_w = 0; 
                stage_cnt_w = 0; 
                stage_count_down_done_w = 1'b0; 
                // finish all packets, go to next "pattern"
                if (cur_pack_r == total_pack_num) begin 
                    // check correctness, pull up proc_done @ sequential always  
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
            // output reg 
            proc_done_r <= 1'b0; 
            // state 
            state_r <= IDLE; 
            // LLR_memory 
            raddr_r <= 0; 
            for (i = 0 ; i < 512 ; i = i + 1) begin 
                llr_data[i] <= 0; 
            end 
            // DEC_memory 
            wdata_r <= 0; 
            waddr_r <= 0; 
            dec_k_idx <= 0; 
            // counter 
            total_pack_num <= 0;  
            K_num <= 0; 
            N_num <= 0; 
            cur_pack_r <= 0;
            cur_line_r <= 0;
            stage_now_r <= 0; 
            stage_cnt_r <= 0; 
            stage_count_down_done_r <= 1'b0; 
            // partial sum 
            for (i = 0 ; i < 512 ; i = i + 1) begin 
                u_init[i] <= 0; 
            end 
            // f, g node 
            for (i = 0 ; i < 256 ; i = i + 1) begin 
                f_a[i] <= 0; 
                f_b[i] <= 0; 
                g_a[i] <= 0; 
                g_b[i] <= 0; 
                g_usum[i] <= 0; 
            end
            // store for each stage's node 
            for (i = 0; i < 256 ; i = i + 1) begin 
                stage_value_8[i] <= 0; 
            end 
            for (i = 0; i < 128 ; i = i + 1) begin 
                stage_value_7[i] <= 0; 
            end
            for (i = 0; i < 64 ; i = i + 1) begin 
                stage_value_6[i] <= 0; 
            end
            for (i = 0; i < 32 ; i = i + 1) begin 
                stage_value_5[i] <= 0; 
            end
            for (i = 0; i < 16 ; i = i + 1) begin 
                stage_value_4[i] <= 0; 
            end
            for (i = 0; i < 8 ; i = i + 1) begin 
                stage_value_3[i] <= 0; 
            end
            for (i = 0; i < 4 ; i = i + 1) begin 
                stage_value_2[i] <= 0; 
            end
            for (i = 0; i < 2 ; i = i + 1) begin 
                stage_value_1[i] <= 0; 
            end
        end 
        else begin  
            // state 
            state_r <= state_w; 
            // LLR_memory  
            raddr_r <= raddr_w; 
            // DEC_memory 
            waddr_r <= (cur_pack_r - 1);
            // load #packet & N, K 
            if (state_r == READ_PACK) total_pack_num <= rdata[6:0];
            else if (state_r == READ_N_K) begin 
                if (cur_line_r == 0) begin 
                    N_num <= rdata[9:0]; 
                    K_num <= rdata[17:10]; 
                end 
            end 
            // LLR_memory 
            else if (state_r == READ_LLR) begin // rdata from LLR_mem will input at each cycle
                for (i = 0 ; i < 512 ; i = i + 1) begin 
                    // each reg in memory has 12 bits 
                    // one cycle == read one raddr 
                    //  - cur_line = 0 : i[3:0] = 0000 ~ 1111 --> one raddr 16 LLR 
                    //  - cur_line = 1 : i[3:0] = 0000 ~ 1111 --> one raddr 16 LLR 
                    if (cur_line_r == (i >> 4)) begin 
                        llr_data[i] <= $signed(rdata[(12*i[3:0])+:12]);
                    end 
                    else llr_data[i] <= llr_data[i]; 
                end
                // stage value start from 
                if (N_num == 128) begin 
                    for (i = 0 ; i < 128 ; i = i + 1) begin 
                        // only has 8 lines 
                        if (cur_line_r == (i >> 4)) begin 
                            stage_value_7[i] <= $signed(rdata[(12*i[3:0])+:12]);
                        end 
                        else stage_value_7[i] <= stage_value_7[i]; 
                    end 
                end 
                else if (N_num == 256) begin 
                    for (i = 0 ; i < 256 ; i = i + 1) begin 
                        // only has 16 lines 
                        if (cur_line_r == (i >> 4)) begin 
                            stage_value_8[i] <= $signed(rdata[(12*i[3:0])+:12]);
                        end 
                        else stage_value_8[i] <= stage_value_8[i]; 
                    end
                end 
            end 
            // DEC_memory 
            else if (state_r == PROC_DONE) begin 
                wdata_r <= 0; 
                dec_k_idx <= 0; 
                if (cur_pack_r == total_pack_num) proc_done_r <= 1'b1;
            end 
            else if (state_r == DECODE) begin 
                if (stage_now_r == 8) begin 
                    for (i = 0 ; i < 256 ; i = i + 1) begin // f() part or g() part
                        stage_value_8[i] <= (stage_cnt_r[7]) ? g_out[i] : f_out[i]; 
                    end 
                end 
                else if (stage_now_r == 7) begin 
                    for (i = 0 ; i < 128 ; i = i + 1) begin 
                        stage_value_7[i] <= (stage_cnt_r[6]) ? g_out[i] : f_out[i]; 
                    end
                end
                else if (stage_now_r == 6) begin 
                    for (i = 0 ; i < 64 ; i = i + 1) begin 
                        stage_value_6[i] <= (stage_cnt_r[5]) ? g_out[i] : f_out[i]; 
                    end
                end
                else if (stage_now_r == 5) begin 
                    for (i = 0 ; i < 32 ; i = i + 1) begin 
                        stage_value_5[i] <= (stage_cnt_r[4]) ? g_out[i] : f_out[i]; 
                    end
                end
                else if (stage_now_r == 4) begin 
                    for (i = 0 ; i < 16 ; i = i + 1) begin 
                        stage_value_4[i] <= (stage_cnt_r[3]) ? g_out[i] : f_out[i]; 
                    end
                end
                else if (stage_now_r == 3) begin 
                    for (i = 0 ; i < 8 ; i = i + 1) begin 
                        stage_value_3[i] <= (stage_cnt_r[2]) ? g_out[i] : f_out[i]; 
                    end
                end
                else if (stage_now_r == 2) begin 
                    for (i = 0 ; i < 4 ; i = i + 1) begin 
                        stage_value_2[i] <= (stage_cnt_r[1]) ? g_out[i] : f_out[i]; 
                    end
                end
                else if (stage_now_r == 1) begin 
                    for (i = 0 ; i < 2 ; i = i + 1) begin 
                        stage_value_1[i] <= (stage_cnt_r[0]) ? g_out[i] : f_out[i]; 
                    end
                end
                // when finish decoding 1 p_node
                else if (stage_now_r == 0) begin  
                    // partial sum 
                    u_init[{stage_cnt_r, 1'b0}] <= u_hat_1; 
                    u_init[{stage_cnt_r, 1'b1}] <= u_hat_2;
                    // DEC_memory      
                    if (isfrozen_f == 1'b0) wdata_r[dec_k_idx] <= u_hat_1; 
                    else if (isfrozen_g == 1'b0) wdata_r[dec_k_idx+1] <= u_hat_2;
                    dec_k_idx <= dec_k_idx + 2; 
                end 
            end 
            // counter  
            cur_pack_r <= cur_pack_w; 
            cur_line_r <= cur_line_w;
            stage_now_r <= stage_now_w; 
            stage_cnt_r <= stage_cnt_w; 
            stage_count_down_done_r <= stage_count_down_done_w;  
        end 
    end 


endmodule