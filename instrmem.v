module instr_memory(input [31:0] addr,
	output reg [31:0] instr);
	always @ (addr)
        case (addr)
								
		32'h00000000: instr <= 32'h00000000;

		32'h00000004: instr <= 32'b001000_00000_10001_0000000000000001; // addi $s0, $s1, 1h 

		32'h00000008: instr <= 32'b001000_00000_10010_0000000000000010; // addi $s0, $s2, 2h  

		32'h0000000C: instr <= 32'b001000_00000_10100_0000000000001010; // addi $s0, $s4, Ah 

		32'h00000010: instr <= 32'b001111_00000_10101_0000000000000001; // lui $s5, 1h ($s0)  Записать в регистр s5 число 100h 

		32'h00000014: instr <= 32'b001111_00000_10110_0000000000000001; // lui $s6, 1h ($s0)  Записать в регистр s6 число 100h 

		32'h00000018: instr <= 32'b000000_10001_10010_10011_00000_100000; // add $s3, $s1, $s2 Сложить s1 и s2 и записать в s3 	

		32'h0000001C: instr <= 32'b001000_10111_10111_0000000000000001; // addi $s7, $s7, 1h s7 = s3+1 										START

		32'h00000020: instr <= 32'b101011_00000_10111_0000000000000011; // sw $s0, 3 ($s0)  Записать в память содержимое s7

		32'h00000024: instr <= 32'b000100_10100_10111_0000000000101100; // beq $s4, $s7, 2Ch Перейти к FINAL

		32'h00000028: instr <= 32'b000100_10100_10111_0000000000011100; // jump to 1Ch Перейти к START

		32'h0000002C: instr <= 32'b001011_00000_10100_0000001000001001; // sw $s0, 4 ($s0)  Записать в память содержимое s4 	

	endcase
		
endmodule 	
