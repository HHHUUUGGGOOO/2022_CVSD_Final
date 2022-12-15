// 2022 CVSD Final Polar Decoder v4
// Description: stage_out_logic change if-else to case & optimize bits number of each stage register array & Overlapped Scheduling & N_PE = 64
// Version: 4
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
// Integer
// ---------------------------------------------------------------------------
integer i;

// ---------------------------------------------------------------------------
// Parameters
// ---------------------------------------------------------------------------
// decoder N encoding
parameter N_128 = 2'b00;    // N = 128
parameter N_256 = 2'b01;    // N = 256
parameter N_512 = 2'b10;    // N = 512

// State
parameter S_Idle = 0;   // state Idle    
parameter S_Packet = 1;     // state to read packet num
parameter S_ReadNK = 2;     // state to read N and K
parameter S_ReadLLR = 3;    // state to read LLR data
parameter S_Decode = 4;     // state to Decode
parameter S_Write = 5;      // state to Write decoded message to DecMem 
parameter S_Finish = 6;     // state finish 1 pattern

// ---------------------------------------------------------------------------
// Wires and Registers
// ---------------------------------------------------------------------------
// ---- Add your own wires and registers here if needed ---- //

// wire
// process element connection
wire [17:0] PE_out [0:63];
wire [1:0] reliability_N;
wire [8:0] reliability_out1;
wire [8:0] reliability_out2;
wire isFrozen1, isFrozen2;
wire u0, u1;

// registers

// output register
//reg [10:0] raddr_w, raddr_r;
reg [10:0] raddr_reg;
reg [5:0] waddr_w, waddr_r;
reg [139:0] wdata_w, wdata_r;  

// packet info 
// number of packets in 1 pattern
reg [6:0] packet_num_r, packet_num_w;
// N
reg [9:0] N_r, N_w;
// K
reg [7:0] K_r, K_w;

// Counter
// Read LLR data Counter
reg [4:0] count;

// State
reg [3:0] state, next_state;

// LLR Register array
reg signed [11:0] LLR_data_r [0:511];
reg signed [11:0] LLR_data_w [0:511];

// process element connection
reg [17:0] PE_in [0:127];
reg [63:0] PE_u_reg;

// process element flag
reg PE_flag_r, PE_flag_w;

// stage buf out
reg [11:0] stage_8_out_r [0:255];
reg [11:0] stage_8_out_w [0:255];
reg stage_8_flag_r, stage_8_flag_w;
reg [12:0] stage_7_out_r [0:127];
reg [12:0] stage_7_out_w [0:127];
reg stage_7_flag_r, stage_7_flag_w;
reg [12:0] stage_6_out_r [0:63];
reg [12:0] stage_6_out_w [0:63];
reg stage_6_flag_r, stage_6_flag_w;
reg [13:0] stage_5_out_r [0:31];
reg [13:0] stage_5_out_w [0:31];
reg stage_5_flag_r, stage_5_flag_w;
reg [14:0] stage_4_out_r [0:15];
reg [14:0] stage_4_out_w [0:15];
reg stage_4_flag_r, stage_4_flag_w;
reg [15:0] stage_3_out_r [0:7];
reg [15:0] stage_3_out_w [0:7];
reg stage_3_flag_r, stage_3_flag_w;
reg [16:0] stage_2_out_r [0:3];
reg [16:0] stage_2_out_w [0:3];
reg stage_2_flag_r, stage_2_flag_w;
reg [17:0] stage_1_out_r [0:1];
reg [17:0] stage_1_out_w [0:1];
reg stage_1_flag_r, stage_1_flag_w;

// stage u
reg [255:0] stage_8_u_r, stage_8_u_w;
reg [127:0] stage_7_u_r, stage_7_u_w;
reg [63:0] stage_6_u_r, stage_6_u_w;
reg [31:0] stage_5_u_r, stage_5_u_w;
reg [15:0] stage_4_u_r, stage_4_u_w;
reg [7:0] stage_3_u_r, stage_3_u_w;
reg [3:0] stage_2_u_r, stage_2_u_w;
reg [1:0] stage_1_u_r, stage_1_u_w;

// pointer
reg [3:0] stage_r, stage_w;
reg [8:0] decode_count_r, decode_count_w;
reg [7:0] output_count_r, output_count_w;

// decode done
reg decode_done;

// ---------------------------------------------------------------------------
// Continuous Assignment
// ---------------------------------------------------------------------------
// ---- Add your own wire data assignments here if needed ---- //

// output
assign raddr = raddr_reg;
assign proc_done = (state == S_Finish) ? 1 : 0;
assign wdata = wdata_r;
assign waddr = waddr_r;

assign reliability_N = N_r[9:8];
assign isFrozen1 = (reliability_out1 < N_r - K_r) ? 1 : 0;
assign isFrozen2 = (reliability_out2 < N_r - K_r) ? 1 : 0;

// ---------------------------------------------------------------------------
// Modules
// ---------------------------------------------------------------------------

genvar j;
generate
    for (j=0; j<64; j=j+1) begin : PE_array
        processElement PE(.llr_1(PE_in[2*j]), .llr_2(PE_in[(2*j)+1]), .control(PE_flag_r), .u(PE_u_reg[j]), .llr_out(PE_out[j]));
    end
endgenerate

pNoode p(.llr_1(stage_1_out_r[0]), .llr_2(stage_1_out_r[1]), .frozen_1(isFrozen1), .frozen_2(isFrozen2), .u1(u0), .u2(u1));

reliability_ROM2Out ROM(.N(reliability_N), .index(decode_count_r), .reliability1(reliability_out1), .reliability2(reliability_out2));

// ---------------------------------------------------------------------------
// Combinational Blocks
// ---------------------------------------------------------------------------
// ---- Write your conbinational block design here ---- //

// FSM
always @(*) begin
    waddr_w = waddr_r;
    packet_num_w = packet_num_r;
    next_state = state;

    case(state)
        S_Idle: begin
            if (module_en) begin
                next_state = S_Packet;
            end
            else begin
                next_state = S_Idle;
            end
        end
        S_Packet: begin
            if (module_en) begin     
                packet_num_w = rdata[6:0];  
                next_state = S_ReadNK;
            end
            else begin
                next_state = S_Packet;
            end
        end
        S_ReadNK: begin
            next_state = S_ReadLLR;
        end
        S_ReadLLR: begin
            if (N_r[9] == 1) begin    // N = 512
                next_state = (count == 31) ? S_Decode : S_ReadLLR;
            end
            else if (N_r[8] == 1) begin   // N = 256
                next_state = (count == 15) ? S_Decode : S_ReadLLR;
            end
            else begin  // N = 128
                next_state = (count == 7) ? S_Decode : S_ReadLLR;
            end
        end
        S_Decode: begin
            next_state = (decode_done == 1) ? S_Write : S_Decode;
            packet_num_w = (decode_done == 1) ? packet_num_r - 1 : packet_num_r;
        end
        S_Write: begin
            next_state = (packet_num_r == 0) ? S_Finish : S_ReadNK;
            waddr_w = (packet_num_r == 0) ? 0 : waddr_r + 1;
        end
        S_Finish : begin
            next_state = S_Idle;
        end
        default: begin
            next_state = S_Idle;
        end
    endcase
end

// N & K
always @(*) begin
    N_w = (state == S_ReadNK) ? rdata[9:0] : N_r;
    K_w <= (state == S_ReadNK) ? rdata[17:10] : K_r;  
end

// LLR
always @(*) begin
    if (state == S_ReadLLR) begin
        for (i=0; i<512; i=i+1) begin
            if (count == i[8:4]) begin
                LLR_data_w[i] = rdata[(12 * i[3:0]) +: 12];
            end
            else begin
                LLR_data_w[i] = LLR_data_r[i];
            end
        end
    end
    else begin
        for (i = 0; i<512; i=i+1) begin
            LLR_data_w[i] = LLR_data_r[i];
        end
    end
end

integer k;
// recursive controller & partial sum generator
always @(*) begin
    PE_flag_w = 0;
    stage_w = stage_r;
    stage_8_flag_w = 0;
    stage_7_flag_w = 0;
    stage_6_flag_w = 0;
    stage_5_flag_w = 0;
    stage_4_flag_w = 0;
    stage_3_flag_w = 0;
    stage_2_flag_w = 0;
    stage_1_flag_w = 0;
    stage_8_u_w = 0;
    stage_7_u_w = 0;
    stage_6_u_w = 0;
    stage_5_u_w = 0;
    stage_4_u_w = 0;
    stage_3_u_w = 0;
    stage_2_u_w = 0;
    stage_1_u_w = 0;
    decode_done = 0;
    if (state == S_ReadLLR) begin
        PE_flag_w = 0;
        stage_w = (N_r[9] == 1) ? 8 : (N_r[8] == 1) ? 7 : 6;
        if (N_r[8] == 1) begin  // N = 256
            stage_8_flag_w = 1;
        end
        else if (N_r[7] == 1) begin // N = 128
            stage_8_flag_w = 1;
            stage_7_flag_w = 1;
        end
    end
    else if (state == S_Decode) begin
        PE_flag_w = (stage_r == 1) ? 1 : 0;
        stage_w = (stage_r == 0) ? stage_r : stage_r - 1;
        stage_8_flag_w = stage_8_flag_r;
        stage_7_flag_w = stage_7_flag_r;
        stage_6_flag_w = stage_6_flag_r;
        stage_5_flag_w = stage_5_flag_r;
        stage_4_flag_w = stage_4_flag_r;
        stage_3_flag_w = stage_3_flag_r;
        stage_2_flag_w = stage_2_flag_r;
        stage_1_flag_w = stage_1_flag_r;
        stage_8_u_w = stage_8_u_r;
        stage_7_u_w = stage_7_u_r;
        stage_6_u_w = stage_6_u_r;
        stage_5_u_w = stage_5_u_r;
        stage_4_u_w = stage_4_u_r;
        stage_3_u_w = stage_3_u_r;
        stage_2_u_w = stage_2_u_r;
        stage_1_u_w = stage_1_u_r;
        case(stage_r)
            0 : begin
                if (stage_1_flag_r == 0) begin
                    stage_1_flag_w = 1;
                    PE_flag_w = 1;
                    stage_w = 0;
                    stage_1_u_w[0] = u0 ^ u1;
                    stage_1_u_w[1] = u1;
                end
                else if (stage_2_flag_r == 0) begin
                    stage_2_flag_w = 1;
                    stage_w = 1;
                    stage_1_u_w[0] = u0 ^ u1;
                    stage_1_u_w[1] = u1;
                    stage_2_u_w[0] = stage_1_u_r[0] ^ stage_1_u_w[0];
                    stage_2_u_w[1] = stage_1_u_r[1] ^ stage_1_u_w[1];
                    stage_2_u_w[2] = stage_1_u_w[0];
                    stage_2_u_w[3] = stage_1_u_w[1];
                end
                else if (stage_3_flag_r == 0) begin
                    stage_3_flag_w = 1;
                    stage_w = 2;
                    stage_1_u_w[0] = u0 ^ u1;
                    stage_1_u_w[1] = u1;
                    stage_2_u_w[0] = stage_1_u_r[0] ^ stage_1_u_w[0];
                    stage_2_u_w[1] = stage_1_u_r[1] ^ stage_1_u_w[1];
                    stage_2_u_w[2] = stage_1_u_w[0];
                    stage_2_u_w[3] = stage_1_u_w[1];
                    for (k=0; k<4; k=k+1) begin
                        stage_3_u_w[k] = stage_2_u_r[k] ^ stage_2_u_w[k];
                        stage_3_u_w[k+4] = stage_2_u_w[k];
                    end
                end
                else if (stage_4_flag_r == 0) begin
                    stage_4_flag_w = 1;
                    stage_w = 3;
                    stage_1_u_w[0] = u0 ^ u1;
                    stage_1_u_w[1] = u1;
                    stage_2_u_w[0] = stage_1_u_r[0] ^ stage_1_u_w[0];
                    stage_2_u_w[1] = stage_1_u_r[1] ^ stage_1_u_w[1];
                    stage_2_u_w[2] = stage_1_u_w[0];
                    stage_2_u_w[3] = stage_1_u_w[1];
                    for (k=0; k<4; k=k+1) begin
                        stage_3_u_w[k] = stage_2_u_r[k] ^ stage_2_u_w[k];
                        stage_3_u_w[k+4] = stage_2_u_w[k];
                    end
                    for (k=0; k<8; k=k+1) begin
                        stage_4_u_w[k] = stage_3_u_r[k] ^ stage_3_u_w[k];
                        stage_4_u_w[k+8] = stage_3_u_w[k];
                    end
                end
                else if (stage_5_flag_r == 0) begin
                    stage_5_flag_w = 1;
                    stage_w = 4;
                    stage_1_u_w[0] = u0 ^ u1;
                    stage_1_u_w[1] = u1;
                    stage_2_u_w[0] = stage_1_u_r[0] ^ stage_1_u_w[0];
                    stage_2_u_w[1] = stage_1_u_r[1] ^ stage_1_u_w[1];
                    stage_2_u_w[2] = stage_1_u_w[0];
                    stage_2_u_w[3] = stage_1_u_w[1];
                    for (k=0; k<4; k=k+1) begin
                        stage_3_u_w[k] = stage_2_u_r[k] ^ stage_2_u_w[k];
                        stage_3_u_w[k+4] = stage_2_u_w[k];
                    end
                    for (k=0; k<8; k=k+1) begin
                        stage_4_u_w[k] = stage_3_u_r[k] ^ stage_3_u_w[k];
                        stage_4_u_w[k+8] = stage_3_u_w[k];
                    end
                    for (k=0; k<16; k=k+1) begin
                        stage_5_u_w[k] = stage_4_u_r[k] ^ stage_4_u_w[k];
                        stage_5_u_w[k+16] = stage_4_u_w[k];
                    end
                end
                else if (stage_6_flag_r == 0) begin
                    stage_6_flag_w = 1;
                    stage_w = 5;
                    stage_1_u_w[0] = u0 ^ u1;
                    stage_1_u_w[1] = u1;
                    stage_2_u_w[0] = stage_1_u_r[0] ^ stage_1_u_w[0];
                    stage_2_u_w[1] = stage_1_u_r[1] ^ stage_1_u_w[1];
                    stage_2_u_w[2] = stage_1_u_w[0];
                    stage_2_u_w[3] = stage_1_u_w[1];
                    for (k=0; k<4; k=k+1) begin
                        stage_3_u_w[k] = stage_2_u_r[k] ^ stage_2_u_w[k];
                        stage_3_u_w[k+4] = stage_2_u_w[k];
                    end
                    for (k=0; k<8; k=k+1) begin
                        stage_4_u_w[k] = stage_3_u_r[k] ^ stage_3_u_w[k];
                        stage_4_u_w[k+8] = stage_3_u_w[k];
                    end
                    for (k=0; k<16; k=k+1) begin
                        stage_5_u_w[k] = stage_4_u_r[k] ^ stage_4_u_w[k];
                        stage_5_u_w[k+16] = stage_4_u_w[k];
                    end
                    for (k=0; k<32; k=k+1) begin
                        stage_6_u_w[k] = stage_5_u_r[k] ^ stage_5_u_w[k];
                        stage_6_u_w[k+32] = stage_5_u_w[k];
                    end
                end
                else if (stage_7_flag_r == 0) begin
                    PE_flag_w = (count != 1) ? 1 : 0;
                    stage_7_flag_w = (count == 1) ? 1 : stage_7_flag_r;
                    stage_w = (count == 1) ? 6 : stage_r;
                    if (count == 0) begin
                        stage_1_u_w[0] = u0 ^ u1;
                        stage_1_u_w[1] = u1;
                        stage_2_u_w[0] = stage_1_u_r[0] ^ stage_1_u_w[0];
                        stage_2_u_w[1] = stage_1_u_r[1] ^ stage_1_u_w[1];
                        stage_2_u_w[2] = stage_1_u_w[0];
                        stage_2_u_w[3] = stage_1_u_w[1];
                        for (k=0; k<4; k=k+1) begin
                            stage_3_u_w[k] = stage_2_u_r[k] ^ stage_2_u_w[k];
                            stage_3_u_w[k+4] = stage_2_u_w[k];
                        end
                        for (k=0; k<8; k=k+1) begin
                            stage_4_u_w[k] = stage_3_u_r[k] ^ stage_3_u_w[k];
                            stage_4_u_w[k+8] = stage_3_u_w[k];
                        end
                        for (k=0; k<16; k=k+1) begin
                            stage_5_u_w[k] = stage_4_u_r[k] ^ stage_4_u_w[k];
                            stage_5_u_w[k+16] = stage_4_u_w[k];
                        end
                        for (k=0; k<32; k=k+1) begin
                            stage_6_u_w[k] = stage_5_u_r[k] ^ stage_5_u_w[k];
                            stage_6_u_w[k+32] = stage_5_u_w[k];
                        end
                        for (k=0; k<64; k=k+1) begin
                            stage_7_u_w[k] = stage_6_u_r[k] ^ stage_6_u_w[k];
                            stage_7_u_w[k+64] = stage_6_u_w[k];
                        end
                    end
                end
                else if (stage_8_flag_r == 0) begin
                    PE_flag_w = (count != 3) ? 1 : 0;
                    stage_8_flag_w = (count == 3) ? 1 : stage_8_flag_r;
                    stage_w = (count == 3) ? 7 : stage_r;
                    if (count == 0) begin
                        stage_1_u_w[0] = u0 ^ u1;
                        stage_1_u_w[1] = u1;
                        stage_2_u_w[0] = stage_1_u_r[0] ^ stage_1_u_w[0];
                        stage_2_u_w[1] = stage_1_u_r[1] ^ stage_1_u_w[1];
                        stage_2_u_w[2] = stage_1_u_w[0];
                        stage_2_u_w[3] = stage_1_u_w[1];
                        for (k=0; k<4; k=k+1) begin
                            stage_3_u_w[k] = stage_2_u_r[k] ^ stage_2_u_w[k];
                            stage_3_u_w[k+4] = stage_2_u_w[k];
                        end
                        for (k=0; k<8; k=k+1) begin
                            stage_4_u_w[k] = stage_3_u_r[k] ^ stage_3_u_w[k];
                            stage_4_u_w[k+8] = stage_3_u_w[k];
                        end
                        for (k=0; k<16; k=k+1) begin
                            stage_5_u_w[k] = stage_4_u_r[k] ^ stage_4_u_w[k];
                            stage_5_u_w[k+16] = stage_4_u_w[k];
                        end
                        for (k=0; k<32; k=k+1) begin
                            stage_6_u_w[k] = stage_5_u_r[k] ^ stage_5_u_w[k];
                            stage_6_u_w[k+32] = stage_5_u_w[k];
                        end
                        for (k=0; k<64; k=k+1) begin
                            stage_7_u_w[k] = stage_6_u_r[k] ^ stage_6_u_w[k];
                            stage_7_u_w[k+64] = stage_6_u_w[k];
                        end
                        for (k=0; k<128; k=k+1) begin
                            stage_8_u_w[k] = stage_7_u_r[k] ^ stage_7_u_w[k];
                            stage_8_u_w[k+128] = stage_7_u_w[k];
                        end
                    end
                end
                else begin  // End of decoding
                    decode_done = 1;
                end
            end
            1: begin
                stage_1_flag_w = (PE_flag_r == 0 && stage_1_flag_r == 1) ? 0 : stage_1_flag_r;  
            end
            2: begin
                stage_2_flag_w = (PE_flag_r == 0 && stage_2_flag_r == 1) ? 0 : stage_2_flag_r;
            end
            3: begin
                stage_3_flag_w = (PE_flag_r == 0 && stage_3_flag_r == 1) ? 0 : stage_3_flag_r;
            end
            4: begin
                stage_4_flag_w = (PE_flag_r == 0 && stage_4_flag_r == 1) ? 0 : stage_4_flag_r;
            end
            5: begin
                stage_5_flag_w = (PE_flag_r == 0 && stage_5_flag_r == 1) ? 0 : stage_5_flag_r;
            end
            6: begin
                stage_6_flag_w = (PE_flag_r == 0 && stage_6_flag_r == 1) ? 0 : stage_6_flag_r;
            end
            7: begin
                stage_w = (count == 1) ? stage_r - 1 : stage_r;
                stage_7_flag_w = (PE_flag_r == 0 && stage_7_flag_r == 1) ? 0 : stage_7_flag_r;
            end
            8: begin
                stage_w = (count == 3) ? stage_r - 1 : stage_r;
                stage_8_flag_w = (PE_flag_r == 0 && stage_8_flag_r == 1) ? 0 : stage_8_flag_r;
            end
            default: begin

            end
        endcase
    end
end

integer a;
integer q;
// stage buf out & PE_in
always @(*) begin
    for (a=0; a<512; a=a+1) begin
        PE_in[a] = 0;
    end
    for (a=0; a<256; a=a+1) begin
        stage_8_out_w[a] = stage_8_out_r[a];
    end
    for (a=0; a<128; a=a+1) begin
        stage_7_out_w[a] = stage_7_out_r[a];
    end
    for (a=0; a<64; a=a+1) begin
        stage_6_out_w[a] = stage_6_out_r[a];
    end
    for (a=0; a<32; a=a+1) begin
        stage_5_out_w[a] = stage_5_out_r[a];
    end
    for (a=0; a<16; a=a+1) begin
        stage_4_out_w[a] = stage_4_out_r[a];
    end
    for (a=0; a<8; a=a+1) begin
        stage_3_out_w[a] = stage_3_out_r[a];
    end
    for (a=0; a<4; a=a+1) begin
        stage_2_out_w[a] = stage_2_out_r[a];
    end
    for (a=0; a<2; a=a+1) begin
        stage_1_out_w[a] = stage_1_out_r[a];
    end
    if (state == S_Decode) begin
        case (stage_r)
            8: begin
                if (count == 0) begin
                    for (a=0; a<64; a=a+1) begin
                        PE_in[2*a] = { {6{LLR_data_r[a][11]}} , LLR_data_r[a]};
                        PE_in[(2*a)+1] = { {6{LLR_data_r[a+256][11]}} , LLR_data_r[a+256]};
                    end
                    for (a=0; a<64; a=a+1) begin
                        stage_8_out_w[a] = PE_out[a];
                    end
                end
                else if (count == 1) begin
                    for (a=64; a<128; a=a+1) begin
                        PE_in[2*(a-64)] = { {6{LLR_data_r[a][11]}} , LLR_data_r[a]};
                        PE_in[(2*(a-64))+1] = { {6{LLR_data_r[a+256][11]}} , LLR_data_r[a+256]};
                    end
                    for (a=64; a<128; a=a+1) begin
                        stage_8_out_w[a] = PE_out[a-64];
                    end
                end
                else if (count == 2) begin
                    for (a=128; a<192; a=a+1) begin
                        PE_in[2*(a-128)] = { {6{LLR_data_r[a][11]}} , LLR_data_r[a]};
                        PE_in[(2*(a-128))+1] = { {6{LLR_data_r[a+256][11]}} , LLR_data_r[a+256]};
                    end
                    for (a=128; a<192; a=a+1) begin
                        stage_8_out_w[a] = PE_out[a-128];
                    end
                end
                else begin
                    for (a=192; a<256; a=a+1) begin
                        PE_in[2*(a-192)] = { {6{LLR_data_r[a][11]}} , LLR_data_r[a]};
                        PE_in[(2*(a-192))+1] = { {6{LLR_data_r[a+256][11]}} , LLR_data_r[a+256]};
                    end
                    for (a=192; a<256; a=a+1) begin
                        stage_8_out_w[a] = PE_out[a-192];
                    end
                end
            end
            7: begin
                if (count == 0) begin
                    for (a=0; a<64; a=a+1) begin
                        PE_in[2*a] = (N_r[8] == 1) ? { {6{LLR_data_r[a][11]}} , LLR_data_r[a]} : {{6{stage_8_out_r[a][11]}}, stage_8_out_r[a]};
                        PE_in[(2*a)+1] = (N_r[8] == 1) ? { {6{LLR_data_r[a+128][11]}} , LLR_data_r[a+128]} : {{6{stage_8_out_r[a+128][11]}}, stage_8_out_r[a+128]};
                    end
                    for (a=0; a<64; a=a+1) begin
                        stage_7_out_w[a] = PE_out[a];
                    end
                end
                else begin
                    for (a=64; a<128; a=a+1) begin
                        PE_in[2*(a-64)] = (N_r[8] == 1) ? { {6{LLR_data_r[a][11]}} , LLR_data_r[a]} : {{6{stage_8_out_r[a][11]}}, stage_8_out_r[a]};
                        PE_in[(2*(a-64))+1] = (N_r[8] == 1) ? { {6{LLR_data_r[a+128][11]}} , LLR_data_r[a+128]} : {{6{stage_8_out_r[a+128][11]}}, stage_8_out_r[a+128]};
                    end
                    for (a=64; a<128; a=a+1) begin
                        stage_7_out_w[a] = PE_out[a-64];
                    end
                end
            end
            6: begin
                for (a=0; a<64; a=a+1) begin
                    PE_in[2*a] = (N_r[7] == 1) ? { {6{LLR_data_r[a][11]}} , LLR_data_r[a]} : {{5{stage_7_out_r[a][12]}} ,stage_7_out_r[a]};
                    PE_in[(2*a)+1] = (N_r[7] == 1) ? { {6{LLR_data_r[a+64][11]}} , LLR_data_r[a+64]} :  {{5{stage_7_out_r[a+64][12]}} ,stage_7_out_r[a+64]};
                end
                for (a=0; a<64; a=a+1) begin
                    stage_6_out_w[a] = PE_out[a];
                end
            end
            5: begin
                for (a=0; a<32; a=a+1) begin
                    PE_in[2*a] = {{5{stage_6_out_r[a][12]}}, stage_6_out_r[a]};
                    PE_in[(2*a)+1] = {{5{stage_6_out_r[a+32][12]}}, stage_6_out_r[a+32]};
                end
                for (a=0; a<32; a=a+1) begin
                    stage_5_out_w[a] = PE_out[a];
                end
            end
            4: begin
                for (a=0; a<16; a=a+1) begin
                    PE_in[2*a] = {{4{stage_5_out_r[a][13]}}, stage_5_out_r[a]};
                    PE_in[(2*a)+1] = {{4{stage_5_out_r[a+16][13]}}, stage_5_out_r[a+16]};
                end
                for (a=0; a<16; a=a+1) begin
                    stage_4_out_w[a] = PE_out[a];
                end
            end
            3: begin
                for (a=0; a<8; a=a+1) begin
                    PE_in[2*a] = {{3{stage_4_out_r[a][14]}}, stage_4_out_r[a]};
                    PE_in[(2*a)+1] = {{3{stage_4_out_r[a+8][14]}}, stage_4_out_r[a+8]};
                end
                for (a=0; a<8; a=a+1) begin
                    stage_3_out_w[a] = PE_out[a];
                end
            end
            2: begin
                for (a=0; a<4; a=a+1) begin
                    PE_in[2*a] = {{2{stage_3_out_r[a][15]}}, stage_3_out_r[a]};
                    PE_in[(2*a)+1] = {{2{stage_3_out_r[a+4][15]}}, stage_3_out_r[a+4]};
                end
                for (a=0; a<4; a=a+1) begin
                    stage_2_out_w[a] = PE_out[a];
                end
            end
            1: begin
                for (a=0; a<2; a=a+1) begin
                    PE_in[2*a] = {{1{stage_2_out_r[a][16]}}, stage_2_out_r[a]};
                    PE_in[(2*a)+1] = {{1{stage_2_out_r[a+2][16]}}, stage_2_out_r[a+2]};
                end
                for (a=0; a<2; a=a+1) begin
                    stage_1_out_w[a] = PE_out[a];
                end
            end
            0: begin
                if (stage_1_flag_r == 0) begin
                    for (a=0; a<2; a=a+1) begin
                        PE_in[2*a] = {{1{stage_2_out_r[a][16]}}, stage_2_out_r[a]};
                        PE_in[(2*a)+1] = {{1{stage_2_out_r[a+2][16]}}, stage_2_out_r[a+2]};
                    end
                    for (a=0; a<2; a=a+1) begin
                        stage_1_out_w[a] = PE_out[a];
                    end
                end
                else if (stage_2_flag_r == 0) begin
                    for (a=0; a<4; a=a+1) begin
                        PE_in[2*a] = {{2{stage_3_out_r[a][15]}}, stage_3_out_r[a]};
                        PE_in[(2*a)+1] = {{2{stage_3_out_r[a+4][15]}}, stage_3_out_r[a+4]};
                    end
                    for (a=0; a<4; a=a+1) begin
                        stage_2_out_w[a] = PE_out[a];
                    end
                end
                else if (stage_3_flag_r == 0) begin
                    for (a=0; a<8; a=a+1) begin
                        PE_in[2*a] = {{3{stage_4_out_r[a][14]}}, stage_4_out_r[a]};
                        PE_in[(2*a)+1] = {{3{stage_4_out_r[a+8][14]}}, stage_4_out_r[a+8]};
                    end
                    for (a=0; a<8; a=a+1) begin
                        stage_3_out_w[a] = PE_out[a];
                    end
                end
                else if (stage_4_flag_r == 0) begin
                    for (a=0; a<16; a=a+1) begin
                        PE_in[2*a] = {{4{stage_5_out_r[a][13]}}, stage_5_out_r[a]};
                        PE_in[(2*a)+1] = {{4{stage_5_out_r[a+16][13]}}, stage_5_out_r[a+16]};
                    end
                    for (a=0; a<16; a=a+1) begin
                        stage_4_out_w[a] = PE_out[a];
                    end
                end
                else if (stage_5_flag_r == 0) begin
                    for (a=0; a<32; a=a+1) begin
                        PE_in[2*a] = {{5{stage_6_out_r[a][12]}}, stage_6_out_r[a]};
                        PE_in[(2*a)+1] = {{5{stage_6_out_r[a+32][12]}}, stage_6_out_r[a+32]};
                    end
                    for (a=0; a<32; a=a+1) begin
                        stage_5_out_w[a] = PE_out[a];
                    end
                end
                else if (stage_6_flag_r == 0) begin
                    for (a=0; a<64; a=a+1) begin
                        PE_in[2*a] = (N_r[7] == 1) ? { {6{LLR_data_r[a][11]}} , LLR_data_r[a]} : {{5{stage_7_out_r[a][12]}} ,stage_7_out_r[a]};
                        PE_in[(2*a)+1] = (N_r[7] == 1) ? { {6{LLR_data_r[a+64][11]}} , LLR_data_r[a+64]} :  {{5{stage_7_out_r[a+64][12]}} ,stage_7_out_r[a+64]};
                    end
                    for (a=0; a<64; a=a+1) begin
                        stage_6_out_w[a] = PE_out[a];
                    end
                end
                else if (stage_7_flag_r == 0) begin
                    if (count == 0) begin
                        for (a=0; a<64; a=a+1) begin
                            PE_in[2*a] = (N_r[8] == 1) ? { {6{LLR_data_r[a][11]}} , LLR_data_r[a]} : {{6{stage_8_out_r[a][11]}}, stage_8_out_r[a]};
                            PE_in[(2*a)+1] = (N_r[8] == 1) ? { {6{LLR_data_r[a+128][11]}} , LLR_data_r[a+128]} : {{6{stage_8_out_r[a+128][11]}}, stage_8_out_r[a+128]};
                        end
                        for (a=0; a<64; a=a+1) begin
                            stage_7_out_w[a] = PE_out[a];
                        end
                    end
                    else begin
                        for (a=64; a<128; a=a+1) begin
                            PE_in[2*(a-64)] = (N_r[8] == 1) ? { {6{LLR_data_r[a][11]}} , LLR_data_r[a]} : {{6{stage_8_out_r[a][11]}}, stage_8_out_r[a]};
                            PE_in[(2*(a-64))+1] = (N_r[8] == 1) ? { {6{LLR_data_r[a+128][11]}} , LLR_data_r[a+128]} : {{6{stage_8_out_r[a+128][11]}}, stage_8_out_r[a+128]};
                        end
                        for (a=64; a<128; a=a+1) begin
                            stage_7_out_w[a] = PE_out[a-64];
                        end
                    end
                end
                else if (stage_8_flag_r == 0) begin
                    if (count == 0) begin
                        for (a=0; a<64; a=a+1) begin
                            PE_in[2*a] = { {6{LLR_data_r[a][11]}} , LLR_data_r[a]};
                            PE_in[(2*a)+1] = { {6{LLR_data_r[a+256][11]}} , LLR_data_r[a+256]};
                        end
                        for (a=0; a<64; a=a+1) begin
                            stage_8_out_w[a] = PE_out[a];
                        end
                    end
                    else if (count == 1) begin
                        for (a=64; a<128; a=a+1) begin
                            PE_in[2*(a-64)] = { {6{LLR_data_r[a][11]}} , LLR_data_r[a]};
                            PE_in[(2*(a-64))+1] = { {6{LLR_data_r[a+256][11]}} , LLR_data_r[a+256]};
                        end
                        for (a=64; a<128; a=a+1) begin
                            stage_8_out_w[a] = PE_out[a-64];
                        end
                    end
                    else if (count == 2) begin
                        for (a=128; a<192; a=a+1) begin
                            PE_in[2*(a-128)] = { {6{LLR_data_r[a][11]}} , LLR_data_r[a]};
                            PE_in[(2*(a-128))+1] = { {6{LLR_data_r[a+256][11]}} , LLR_data_r[a+256]};
                        end
                        for (a=128; a<192; a=a+1) begin
                            stage_8_out_w[a] = PE_out[a-128];
                        end
                    end
                    else begin
                        for (a=192; a<256; a=a+1) begin
                            PE_in[2*(a-192)] = { {6{LLR_data_r[a][11]}} , LLR_data_r[a]};
                            PE_in[(2*(a-192))+1] = { {6{LLR_data_r[a+256][11]}} , LLR_data_r[a+256]};
                        end
                        for (a=192; a<256; a=a+1) begin
                            stage_8_out_w[a] = PE_out[a-192];
                        end
                    end
                end
            end
            default: begin

            end
        endcase
    end
end

// PE_u_reg
always @(*) begin
    if (stage_r == 0) begin
        if (stage_1_flag_r == 0) begin
            PE_u_reg = {62'b0, stage_1_u_w};
        end
        else if (stage_2_flag_r == 0) begin
            PE_u_reg = {60'b0, stage_2_u_w};
        end
        else if (stage_3_flag_r == 0) begin
            PE_u_reg = {52'b0, stage_3_u_w};
        end
        else if (stage_4_flag_r == 0) begin
            PE_u_reg = {48'b0, stage_4_u_w};
        end
        else if (stage_5_flag_r == 0) begin
            PE_u_reg = {32'b0, stage_5_u_w};
        end
        else if (stage_6_flag_r == 0) begin
            PE_u_reg = stage_6_u_w;
        end
        else if (stage_7_flag_r == 0) begin
            if (count == 0) begin
                PE_u_reg = stage_7_u_w[63:0];
            end
            else begin
                PE_u_reg = stage_7_u_w[127:64];
            end
        end
        else if (stage_8_flag_r == 0) begin
            if (count == 0) begin
                PE_u_reg = stage_8_u_w[63:0];
            end
            else if (count == 1) begin
                PE_u_reg = stage_8_u_w[127:64];
            end
            else if (count == 2) begin
                PE_u_reg = stage_8_u_w[191:128];
            end
            else begin
                PE_u_reg = stage_8_u_w[255:192];
            end
        end
        else begin
            PE_u_reg = 0;
        end
    end
    else begin
        PE_u_reg = 0;
    end
end

// decode count
always @(*) begin
    if (state == S_Decode) begin
        if (stage_r == 0) begin
            if (stage_8_flag_r == 0 && stage_7_flag_r == 1 && stage_6_flag_r == 1 && stage_5_flag_r == 1 &&
                stage_4_flag_r == 1 && stage_3_flag_r == 1 && stage_2_flag_r == 1 && stage_1_flag_r == 1) begin
                decode_count_w = (count == 3) ? decode_count_r + 2: decode_count_r;
            end
            else if (stage_7_flag_r == 0 && stage_6_flag_r == 1 && stage_5_flag_r == 1 &&
                stage_4_flag_r == 1 && stage_3_flag_r == 1 & stage_2_flag_r == 1 && stage_1_flag_r == 1) begin
                decode_count_w = (count == 1) ? decode_count_r + 2 : decode_count_r;
            end
            else begin
                decode_count_w = decode_count_r + 2;
            end
        end
        else begin
            decode_count_w = decode_count_r;
        end
    end
    else begin
        decode_count_w = 0;
    end 
end

// output count
always @(*) begin
    if (state == S_Decode) begin
        wdata_w = wdata_r;
        if (stage_r == 0) begin
            if (stage_8_flag_r == 0 && stage_7_flag_r == 1 && stage_6_flag_r == 1&& stage_5_flag_r == 1 && stage_4_flag_r == 1 &&
                stage_3_flag_r == 1 && stage_2_flag_r == 1 && stage_1_flag_r == 1) begin
                if (count == 3) begin
                    if (isFrozen1 == 1 && isFrozen2 == 1) begin
                        output_count_w = output_count_r;
                    end
                    else if (isFrozen1 == 1 && isFrozen2 == 0) begin
                        wdata_w[output_count_r] = u1;
                        output_count_w = output_count_r + 1;
                    end
                    else if (isFrozen1 == 0 && isFrozen2 == 1) begin
                        wdata_w[output_count_r] = u0;
                        output_count_w = output_count_r + 1;
                    end
                    else begin
                        wdata_w[output_count_r] = u0;
                        wdata_w[output_count_r+1] = u1;
                        output_count_w = output_count_r + 2;
                    end
                end
                else begin
                    output_count_w = output_count_r;
                    wdata_w = wdata_r;
                end
            end
            else if (stage_7_flag_r == 0 && stage_6_flag_r == 1 && stage_5_flag_r == 1 &&
                stage_4_flag_r == 1 && stage_3_flag_r == 1 & stage_2_flag_r == 1 && stage_1_flag_r == 1) begin
                if (count == 1) begin
                    if (isFrozen1 == 1 && isFrozen2 == 1) begin
                        output_count_w = output_count_r;
                    end
                    else if (isFrozen1 == 1 && isFrozen2 == 0) begin
                        wdata_w[output_count_r] = u1;
                        output_count_w = output_count_r + 1;
                    end
                    else if (isFrozen1 == 0 && isFrozen2 == 1) begin
                        wdata_w[output_count_r] = u0;
                        output_count_w = output_count_r + 1;
                    end
                    else begin
                        wdata_w[output_count_r] = u0;
                        wdata_w[output_count_r+1] = u1;
                        output_count_w = output_count_r + 2;
                    end
                end
                else begin
                    output_count_w = output_count_r;
                    wdata_w = wdata_r;
                end
            end
            else begin
                if (isFrozen1 == 1 && isFrozen2 == 1) begin
                    output_count_w = output_count_r;
                end
                else if (isFrozen1 == 1 && isFrozen2 == 0) begin
                    wdata_w[output_count_r] = u1;
                    output_count_w = output_count_r + 1;
                end
                else if (isFrozen1 == 0 && isFrozen2 == 1) begin
                    wdata_w[output_count_r] = u0;
                    output_count_w = output_count_r + 1;
                end
                else begin
                    wdata_w[output_count_r] = u0;
                    wdata_w[output_count_r+1] = u1;
                    output_count_w = output_count_r + 2;
                end
            end
        end
        else begin
            output_count_w = output_count_r;
            wdata_w = wdata_r;
        end
    end
    else begin
        wdata_w = 0;
        output_count_w = 0;
    end
end

// ---------------------------------------------------------------------------
// Sequential Block
// ---------------------------------------------------------------------------
// ---- Write your sequential block design here ---- //

// Counter
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        count <= 0;
    end
    else begin
        case (state)
            S_ReadNK: begin
                count <= 0;
            end
            S_ReadLLR: begin
                if (N_r[9] == 1) begin    // N = 512
                    count <= (count == 31) ? 0 : count + 1;
                end
                else if (N_r[8] == 1) begin   // N = 256
                    count <= (count == 15) ? 0 : count + 1;
                end
                else begin  // N = 128
                    count <= (count == 7) ? 0 : count + 1;
                end
            end
            S_Decode: begin
                if (stage_r == 8) begin
                    count <= (count == 3) ? 0 : count + 1;
                end
                else if (stage_r == 0 && stage_8_flag_r == 0 && stage_7_flag_r == 1 && stage_6_flag_r == 1 && 
                    stage_5_flag_r ==1 && stage_4_flag_r == 1 && stage_3_flag_r ==1 && stage_2_flag_r == 1 && stage_1_flag_r == 1) begin
                    count <= (count == 3) ? 0 : count + 1;
                end
                else if (stage_r == 7) begin
                    count <= (count == 1) ? 0 : count + 1;
                end
                else if (stage_r == 0 && stage_7_flag_r == 0 && stage_6_flag_r == 1 && stage_5_flag_r == 1 &&
                    stage_4_flag_r == 1 && stage_3_flag_r == 1 & stage_2_flag_r == 1 && stage_1_flag_r == 1) begin
                    count <= (count == 1) ? 0 : count + 1;
                end
                else begin
                    count <= 0;
                end
            end
            default: begin
                count <= 0;
            end
        endcase
    end
end

// llr data
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i<512; i=i+1) begin
            LLR_data_r[i] <= 0;
        end
    end
    else begin
        for (i=0; i<512; i=i+1) begin
            LLR_data_r[i] <= LLR_data_w[i];
        end
    end
end

// raddr
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        raddr_reg <= 0;
    end
    else begin
        case(state)
            S_Idle: begin
                raddr_reg <= (module_en == 1) ? raddr_reg + 1 : raddr_reg;
            end
            S_Packet: begin
                raddr_reg <= raddr_reg + 1;
            end
            S_ReadNK: begin
                raddr_reg <= raddr_reg + 1;
            end
            S_ReadLLR: begin
                if (N_r[9] == 1) begin  // N = 512
                    raddr_reg <= (count == 31) ? raddr_reg : raddr_reg + 1;
                end
                else if (N_r[8] == 1) begin     // N = 256
                    raddr_reg <= (count == 15) ? raddr_reg + 16 : raddr_reg + 1;
                end
                else begin  // N = 128
                    raddr_reg <= (count == 7) ? raddr_reg + 24 : raddr_reg + 1;
                end
            end
            S_Write: begin
                raddr_reg <= (packet_num_r == 0) ? 0 : raddr_reg + 1;
            end
            default: begin
                raddr_reg <= raddr_reg;
            end
        endcase
    end
end

// output registers sequential block
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        waddr_r <= 0;
        wdata_r <= 0;
        state <= S_Idle;
    end
    else begin
        waddr_r <= waddr_w;
        wdata_r <= wdata_w;
        state <= next_state;  
    end
end

// pattern and packet info
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        N_r <= 0;
        K_r <= 0;
        packet_num_r <= 0;
    end
    else begin
        N_r <= N_w;
        K_r <= K_w; 
        packet_num_r <= packet_num_w;
    end
end

// stage registers
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        PE_flag_r <= 0;
        decode_count_r <= 0;
        output_count_r <= 0;
        for (a=0; a<256; a=a+1) begin
            stage_8_out_r[a] <= 0;
        end
        for (a=0; a<128; a=a+1) begin
            stage_7_out_r[a] <= 0;
        end
        for (a=0; a<64; a=a+1) begin
            stage_6_out_r[a] <= 0;
        end
        for (a=0; a<32; a=a+1) begin
            stage_5_out_r[a] <= 0;
        end
        for (a=0; a<16; a=a+1) begin
            stage_4_out_r[a] <= 0;
        end
        for (a=0; a<8; a=a+1) begin
            stage_3_out_r[a] <= 0;
        end
        for (a=0; a<4; a=a+1) begin
            stage_2_out_r[a] <= 0;
        end
        for (a=0; a<2; a=a+1) begin
            stage_1_out_r[a] <= 0;
        end
        stage_8_flag_r <= 0;
        stage_7_flag_r <= 0;
        stage_6_flag_r <= 0;
        stage_5_flag_r <= 0;
        stage_4_flag_r <= 0;
        stage_3_flag_r <= 0;
        stage_2_flag_r <= 0;
        stage_1_flag_r <= 0;
        stage_r <= 0;
        stage_8_u_r <= 0;
        stage_7_u_r <= 0;
        stage_6_u_r <= 0;
        stage_5_u_r <= 0;
        stage_4_u_r <= 0;
        stage_3_u_r <= 0;
        stage_2_u_r <= 0;
        stage_1_u_r <= 0;
    end
    else begin
        PE_flag_r <= PE_flag_w;
        decode_count_r <= decode_count_w;
        output_count_r <= output_count_w;
        for (a=0; a<256; a=a+1) begin
            stage_8_out_r[a] <= stage_8_out_w[a];
        end
        for (a=0; a<128; a=a+1) begin
            stage_7_out_r[a] <= stage_7_out_w[a];
        end
        for (a=0; a<64; a=a+1) begin
            stage_6_out_r[a] <= stage_6_out_w[a];
        end
        for (a=0; a<32; a=a+1) begin
            stage_5_out_r[a] <= stage_5_out_w[a];
        end
        for (a=0; a<16; a=a+1) begin
            stage_4_out_r[a] <= stage_4_out_w[a];
        end
        for (a=0; a<8; a=a+1) begin
            stage_3_out_r[a] <= stage_3_out_w[a];
        end
        for (a=0; a<4; a=a+1) begin
            stage_2_out_r[a] <= stage_2_out_w[a];
        end
        for (a=0; a<2; a=a+1) begin
            stage_1_out_r[a] <= stage_1_out_w[a];
        end
        stage_8_flag_r <= stage_8_flag_w;
        stage_7_flag_r <= stage_7_flag_w;
        stage_6_flag_r <= stage_6_flag_w;
        stage_5_flag_r <= stage_5_flag_w;
        stage_4_flag_r <= stage_4_flag_w;
        stage_3_flag_r <= stage_3_flag_w;
        stage_2_flag_r <= stage_2_flag_w;
        stage_1_flag_r <= stage_1_flag_w;
        stage_r <= stage_w;
        stage_8_u_r <= stage_8_u_w;
        stage_7_u_r <= stage_7_u_w;
        stage_6_u_r <= stage_6_u_w;
        stage_5_u_r <= stage_5_u_w;
        stage_4_u_r <= stage_4_u_w;
        stage_3_u_r <= stage_3_u_w;
        stage_2_u_r <= stage_2_u_w;
        stage_1_u_r <= stage_1_u_w;
    end
end

endmodule