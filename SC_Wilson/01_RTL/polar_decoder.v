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
    
    


	// ---------------------------------------------------------------------------
	// Continuous Assignment
	// ---------------------------------------------------------------------------
	// ---- Add your own wire data assignments here if needed ---- //
	


	// ---------------------------------------------------------------------------
	// Combinational Blocks
	// ---------------------------------------------------------------------------
	// ---- Write your conbinational block design here ---- //
    



	// ---------------------------------------------------------------------------
	// Sequential Block
	// ---------------------------------------------------------------------------
	// ---- Write your sequential block design here ---- //





endmodule