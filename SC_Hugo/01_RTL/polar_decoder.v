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
    reg [6:0] total_pack_num; // u6.0 
    reg [7:0] K_num; // u7.0
    reg [9:0] N_num; // u9.0
    reg [6:0] cur_pack_r, cur_pack_w;
    reg [4:0] cur_line_r, cur_line_w; // start from each packet's line 2 (LLR begin)
                                      // current LLR addr = 1 + ((cur_pack_r-1) * 33) + (cur_line_r)
                                      // e.g. packet no.2, line 3 = 1 + (1*33) + 1 = LLR_mem[36]

    parameter IDLE       = 0; 
    parameter READ_PACK  = 1; 
    parameter READ_N_K   = 2;
    parameter READ_LLR   = 3; 
    parameter DECODE_128 = 4;
    parameter DECODE_256 = 5; 
    parameter DECODE_512 = 6; 
    parameter PROC_DONE  = 7; 

    
    // ---------------------------------------------------------------------------
	// Wires and Registers for Memory 
	// ---------------------------------------------------------------------------
	// ---- Add your own wires and registers here if needed ---- //
    // LLR memory   
    reg [10:0] raddr_r, raddr_w;
    reg [11:0] llr_data [0:511]; 
    integer i; 

    // DEC memory  
    reg [139:0] wdata_r, wdata_w; 
    reg [5:0]   waddr_r, waddr_w;    


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
        // output reg 
        proc_done_w = proc_done_r; 
        // state 
        state_w = state_r; 
        // LLR_memory 
        raddr_w = raddr_r; 
        // DEC_memory 
        wdata_w = wdata_r; 
        waddr_w = waddr_r; 
        // counter  
        cur_pack_w = cur_pack_r; 
        cur_line_w = cur_line_r;
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
                // read # of packets, and store to total_pack 
                total_pack_num = rdata[6:0];
                // ready to read first N, K 
                raddr_w = 1; 
                // state 
                state_w = READ_N_K; 
            end
            READ_N_K: begin 
                // for each packet, the "cur_line_w" reset
                cur_pack_w = cur_pack_r + 1;
                cur_line_w = 0;  
                raddr_w = raddr_r + 1;
                // if reach packet number, finish 
                if (cur_pack_r == (total_pack_num - 1)) begin 
                    // state
                    state_w = PROC_DONE; 
                end 
                // else, read the first line of packet to get N, K
                else begin  
                    N_num = rdata[9:0];   // u9.0
                    K_num = rdata[17:10]; // u7.0
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
                    state_w = (cur_line == 7) ? DECODE_128 : READ_LLR; // state
                end 
                else if (N_num == 256) begin 
                    cur_line_w = (cur_line_r == 15) ? 0 : (cur_line_r + 1); // 16 (LLR) * 16 = 256
                    raddr_w = (cur_line_r == 15) ? (raddr_r + (32-16)) : (raddr_r + 1); // fulfill 33 lines in a packet
                    state_w = (cur_line == 15) ? DECODE_256 : READ_LLR; // state
                end 
                else begin 
                    cur_line_w = (cur_line_r == 31) ? 0 : (cur_line_r + 1); // 16 (LLR) * 32 = 512
                    raddr_w = (cur_line_r == 31) ? (raddr_r + (32-32)) : (raddr_r + 1); // fulfill 33 lines in a packet
                    state_w = (cur_line == 31) ? DECODE_512 : READ_LLR; // state
                end 
            end 
            DECODE_128: begin 
                
            end 
            DECODE_256: begin 

            end
            DECODE_512: begin 

            end 
            PROC_DONE: begin 
                // finish all packets, go to next "pattern"
                if (cur_pack_r == total_pack_num) begin 
                    // check correctness 
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
            // counter 
            total_pack_num <= 0;  
            K_num <= 0; 
            N_num <= 0; 
            cur_pack_r <= 0;
            cur_line_r <= 0;
        end 
        else begin 
            // output reg 
            proc_done_r <= proc_done_w; 
            // state 
            state_r <= state_w; 
            // LLR_memory  
            raddr_r <= raddr_w; 
            if (state_r == READ_LLR) begin 
                for (i = 0 ; i < 512 ; i = i + 1) begin 
                    // each reg in memory has 12 bits (index "i" % 16)
                    llr_data[i] <= rdata[(12*i[3:0])+:12];
                end
            end 
            // DEC_memory 
            wdata_r <= wdata_w; 
            waddr_r <= waddr_w; 
            // counter  
            cur_pack_r <= cur_pack_w; 
            cur_line_r <= cur_line_w;
        end 
    end 


endmodule