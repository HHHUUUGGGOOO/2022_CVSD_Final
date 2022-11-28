module LLR_mem #(
	parameter MEM_WIDTH = 32,
	parameter MEM_DEPTH = 64,
	parameter MEM_ADDRW = $clog2(MEM_DEPTH)
)
(
	input             			i_clk,
	input             			i_rst_n,
	input  [ MEM_ADDRW-1 : 0 ] 	i_addr,
	output [ MEM_WIDTH-1 : 0 ] 	o_rdata
);	
	reg  [ MEM_WIDTH-1 : 0 ] mem_r    [ 0 : MEM_DEPTH-1 ];
	reg  [ MEM_WIDTH-1 : 0 ] rdata_w, rdata_r ;

	wire [ MEM_ADDRW-1 : 0 ] vaddr	 ;

	assign o_rdata = rdata_r;
	assign vaddr = i_addr;

	always@(*) begin
		rdata_w = mem_r[vaddr];
	end

	always@(posedge i_clk or negedge i_rst_n)  begin
		if(!i_rst_n) rdata_r <= { MEM_WIDTH { 1'b0 } };
		else         rdata_r <= #(1.0) rdata_w;
	end

endmodule
