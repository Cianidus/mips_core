module data_memory ( input clk_datamem,
    input we, input [31:0] addr,
    input [31:0] wd,
    output [31:0] data);

    // массив памяти данных
    reg [31:0] RAM [63:0];

    always @(posedge clk_datamem)
        if(we) RAM[addr[31:2]] <= wd;

    assign data = RAM[addr[31:2]];
	  	
endmodule


