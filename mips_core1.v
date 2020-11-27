module mips_core1(input clk, input [2:0] IRQ);
	
	wire [31:0] pctoinstr_wire;
	wire dmem_we_wire;
	wire [31:0] dmem_addr_wire;
	wire [31:0] dmem_wd_wire;
	wire [31:0] instr_wire;
	wire [31:0] dmem_data_wire;
	
	
	datapath_controller controller1 (.pc(pctoinstr_wire), .clk(clk),
	
	.instr(instr_wire), .dmem_rd(dmem_data_wire), .dmem_we(dmem_we_wire),
	
	.dmem_addr(dmem_addr_wire), .dmem_wd(dmem_wd_wire), .IRQ(IRQ));
	
	
	instr_memory instr1(.addr(pctoinstr_wire), .instr(instr_wire));
	
	
	data_memory dtmem1(.clk_datamem(clk), .addr(dmem_addr_wire), .we(dmem_we_wire), .wd(dmem_wd_wire), .data(dmem_data_wire));


	
endmodule 