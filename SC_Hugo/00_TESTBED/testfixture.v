`timescale 1ns/10ps
`define CYCLE       10.0
`define HCYCLE      (`CYCLE/2)
// `define MAX_CYCLE   100000000
`define MAX_CYCLE   1000000000  // for full pattern 

`ifdef GSIM
    `define SDFFILE     "../02_SYN/Netlist/polar_decoder_syn.sdf"   //Modify your sdf file name
`elsif POST
    `define SDFFILE     "../04_APR/polar_decoder_pr.sdf" //Modify your sdf file name
`endif

`ifdef BASE
    `define TOTAL_PACK 1
`elsif FULL
    `define TOTAL_PACK 17
`else
    `define TOTAL_PACK 1
`endif

module test;

wire                clk;
wire                rst_n;
reg                 module_en;
wire                proc_done;

reg [1000*8:1] Input, Golden;

reg over1, over2, over;
reg valid;
integer i, x, y, err, pass;
reg [5:0] pack_num;

initial begin
    over1       = 0;
    over2       = 0;
    over        = 0;
    valid       = 0;
    i           = 0;
    x           = 0;
    err         = 0;
    pass        = 0;
    module_en   = 0;
    pack_num    = 0;
end


`ifdef SDF
   initial       $sdf_annotate(`SDFFILE, u_polar_decoder );
`endif

initial begin
`ifdef BASE
$fsdbDumpfile("polar_decoder_BASE.fsdb");
`elsif FULL
$fsdbDumpfile("polar_decoder_FULL.fsdb");
`else
$fsdbDumpfile("polar_decoder_BASE.fsdb");
`endif
$fsdbDumpvars;
$fsdbDumpMDA;
end

parameter LLR_MEM_WIDTH = 192;
parameter LLR_MEM_WORD  = 1453;
parameter LLR_MEM_DEPTH = 2 << ($clog2(LLR_MEM_WORD)-1);
parameter LLR_MEM_ADDRW = $clog2(LLR_MEM_DEPTH);

parameter DEC_MEM_WIDTH = 140;
parameter DEC_MEM_WORD  = 44;
parameter DEC_MEM_DEPTH = 2 << ($clog2(DEC_MEM_WORD)-1);
parameter DEC_MEM_ADDRW = $clog2(DEC_MEM_DEPTH);

reg [ DEC_MEM_WIDTH - 1 : 0 ] golden_mem [ 0 : DEC_MEM_DEPTH-1 ];



wire [ LLR_MEM_ADDRW-1 : 0 ] LLR_addr;
wire [ LLR_MEM_WIDTH-1 : 0 ] LLR_rdata;

wire                         DEC_wen;
wire [ DEC_MEM_ADDRW-1 : 0 ] DEC_addr;
wire [ DEC_MEM_WIDTH-1 : 0 ] DEC_wdata;
wire [ DEC_MEM_WIDTH-1 : 0 ] DEC_rdata;

initial begin
    // data ready before reset
    `ifdef BASE
        $sformat(Input,  "../00_TESTBED/PATTERN/baseline/baseline.mem"); 
        $sformat(Golden, "../00_TESTBED/PATTERN/baseline/baseline_golden.mem"); 
    `elsif FULL
        $sformat(Input,  "../00_TESTBED/PATTERN/full/full_%0d.mem", x); 
        $sformat(Golden, "../00_TESTBED/PATTERN/full/full_%0d_golden.mem", x); 
    `else
        $sformat(Input,  "../00_TESTBED/PATTERN/baseline/baseline.mem"); 
        $sformat(Golden, "../00_TESTBED/PATTERN/baseline/baseline_golden.mem"); 
    `endif
    $readmemb (Input, u_LLR_mem.mem_r);
    $readmemb (Golden, golden_mem);
    // wait async reset    
    # ( 4 * `CYCLE + 1.0);
    module_en = 1; 
    while (i < `TOTAL_PACK) begin
        // data are ready before module_en = 1
        // indexing with x
        `ifdef BASE
            $sformat(Input,  "../00_TESTBED/PATTERN/baseline/baseline.mem"); 
            $sformat(Golden, "../00_TESTBED/PATTERN/baseline/baseline_golden.mem"); 
        `elsif FULL
            $sformat(Input,  "../00_TESTBED/PATTERN/full/full_%0d.mem", x); 
            $sformat(Golden, "../00_TESTBED/PATTERN/full/full_%0d_golden.mem", x); 
        `else
            $sformat(Input,  "../00_TESTBED/PATTERN/baseline/baseline.mem"); 
            $sformat(Golden, "../00_TESTBED/PATTERN/baseline/baseline_golden.mem"); 
        `endif
        
        $readmemb (Input, u_LLR_mem.mem_r);
        $readmemb (Golden, golden_mem);
        over1     = 0;
        valid     = 0;
        @(posedge clk);
        #(1.0);
        module_en = 1;

        pack_num = u_LLR_mem.mem_r[0][5:0];

	    $display("-------------------------------------------------------------------");
        $display("   Pattern: %0s", Input);
	    $display("-------------------------------------------------------------------");


        $display("-----------------------------------------------------");  
        $display("Start to Send LLR Info & Data ...");       
        $display("-----------------------------------------------------");
        while (~proc_done) begin  
            @(negedge clk);
        end
        over1 = 1;
        valid = 1;
        i = i + 1;
        @(posedge clk);
        #(1.0);
        module_en = 0;
        @(negedge clk);
    end
end

initial begin
    while (x < `TOTAL_PACK) begin
        @(negedge clk);
        while (~valid) begin
            @(negedge clk);
        end
        for (y = 0; y < pack_num; y = y + 1) begin
            if (u_DEC_mem.mem_r[y] !== golden_mem[y]) begin
                $display("Packet %02d#, decoded bit %02d = %035h != expect %35h", x, y, u_DEC_mem.mem_r[y], golden_mem[y]);
                err = err + 1;
            end
            else begin
                $display("Packet %02d#, decoded bit %02d   ** Correct!! ** ", x, y);
                pass = pass + 1;
            end
        end
        x = x + 1;
    end
    over2 = 1;                                                                  
end

always @(*)begin
   over = over1 && over2;
end

initial begin
    while (~over) begin
        @(negedge clk);
    end   
    $display("\n-----------------------------------------------------\n");
    if (err == 0)  begin
    $display("Congratulations! All data have been generated successfully!\n");
    $display("-------------------------PASS------------------------\n");
    end
    else begin
    $display("Final Simulation Result as below (`・ω・´): \n");         
    $display("-----------------------------------------------------\n");
    $display("Pass:   %3d \n", pass);
    $display("Error:  %3d \n", err);
    $display("-----------------------------------------------------\n");
    end
    #(`CYCLE/2); $finish;
end

// DUT IO description
polar_decoder u_polar_decoder (
    .clk        (clk        ),
    .rst_n      (rst_n      ),
    .module_en  (module_en  ),
    .proc_done  (proc_done  ),
    .raddr      (LLR_addr   ),
    .rdata      (LLR_rdata  ),
    .waddr      (DEC_addr   ),
    .wdata      (DEC_wdata  )
);



// LLR MEM description

// only read data
LLR_mem # (
    .MEM_WIDTH (LLR_MEM_WIDTH),
    .MEM_DEPTH (LLR_MEM_DEPTH)
) u_LLR_mem (
	.i_clk      (clk        ),
	.i_rst_n    (rst_n      ),
	.i_addr     (LLR_addr   ),
	.o_rdata    (LLR_rdata  )
);

// Decoded MEM description
assign DEC_wen   = 1;

// only write data
DEC_mem # (
    .MEM_WIDTH (DEC_MEM_WIDTH),
    .MEM_DEPTH (DEC_MEM_DEPTH)
) u_DEC_mem (
	.i_clk      (clk        ),
	.i_rst_n    (rst_n      ),
	.i_wen      (DEC_wen    ),
	.i_addr     (DEC_addr   ),
	.i_wdata    (DEC_wdata  ),
	.o_rdata    (DEC_rdata  )
);

// Clock generation description
Clkgen u_clk (
    .clk(clk),
    .rst_n(rst_n)
);

endmodule


module Clkgen (
    output reg clk,
    output reg rst_n
);
    always # (`HCYCLE) clk = ~clk;

    initial begin
        clk = 1'b1;
        rst_n = 1; 
        # (1.0);
        rst_n = 0;
 
        # (4 * `CYCLE);
        rst_n = 1;

        # (`MAX_CYCLE * `CYCLE);
        $display("Error! Runtime exceeded!");
        $finish;
    end
endmodule





