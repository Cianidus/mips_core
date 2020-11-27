

//Программный счетчик
module pc(input clk,
    
    input [31:0] pc_next, output reg [31:0] pc);
	 
	 initial
	 
		begin		
			pc <= 0;		
		end

	 always @(posedge clk)
	     pc <= pc_next;

endmodule 



//Файл регистров
module regfile(input clk, 
    
    input [4:0] ra1, input [4:0] ra2,
	 output [31:0] rd1, output [31:0] rd2,
	 
	 
	 input we, input [4:0] wa, input [31:0] wd
	 );
	 
	 reg [31:0] rf [31:0];
	 
	 always @(posedge clk)
	     if(we) rf[wa] <= wd;
		  
	 assign rd1 = ra1 ? rf[ra1] : 0; // reg[0] is zero
	 assign rd2 = ra2 ? rf[ra2] : 0; // reg[0] is zero	 
endmodule 
			

//Ядро (Controller and Datapath)

module datapath_controller(input clk,
    output [31:0] pc, 
	 input [31:0] instr, //Вход инструкции
	 input [2:0] IRQ,
	
	 output reg dmem_we, 
	 output reg [31:0] dmem_addr, 
	 output reg [31:0] dmem_wd, 
	 input [31:0] dmem_rd);
	 
	 reg [31:0] pc_next;
	
	 
	 // Программный счетчик
	 pc pcount(clk, pc_next, pc);
	 
	 	 
	 // Файл регистров
	 reg [4:0] rf_ra1, rf_ra2;
	 wire [31:0] rf_rd1, rf_rd2;
	 
	 reg rf_we;
	 reg [4:0] rf_wa;
	 reg [31:0] rf_wd;
	 
	 regfile rf(clk, rf_ra1, rf_ra2, rf_rd1, rf_rd2, rf_we, rf_wa, rf_wd);
	
	 wire [5:0] instr_op;
	 
	 assign instr_op=instr[31:26]; //Выделение первых 6 бит иструкции (opcode) в шину    
	 wire [4:0] instr_rtype_rs; //Регистр источник 1
	 wire [4:0] instr_rtype_rt; //Регистр источник 2
	 wire [4:0] instr_rtype_rd; //Регистр назначение
	 wire [5:0] instr_rtype_funct; //Тип операции для АЛУ
	 wire [15:0] instr_rtype_imm;

	 //Объявление шин полей инструкции
	
	 //Выделение битовых полей инструкции в отдельные шины 
	 assign instr_rtype_rs=instr[25:21]; // Регистр-источник 1
	 assign instr_rtype_rt=instr[20:16]; // Регистр-источник 2
	 assign instr_rtype_rd=instr[15:11]; // Регистр-назначение 2
	 assign instr_rtype_funct=instr[5:0]; // Тип операции для R команд
	 assign instr_rtype_addr=instr[25:0]; // Адрес перехода для J команд
	 
	 //I-instruction ** [6 bits] [5 bits] [5 bits] [16 bits] **          
	 //				  ** opcode     rs       rt        imm    **
	 
	 //Выделение битовых полей инструкции в отдельные шины 
	 assign instr_rtype_op=instr[31:26];
	 assign instr_rtype_rs=instr[25:21];
	 assign instr_rtype_rt=instr[20:16];
	 assign instr_rtype_imm=instr[15:0];
	 
	 parameter INSTR_OP_LW=6'b100011; //Загрузка из памяти в регистр
	 parameter INSTR_OP_SW=6'b101011; // Загрузка из регистра в память
	 parameter INSTR_OP_LUI=6'b001111; // 
	 parameter INSTR_OP_ADDI=6'b001000; //Добавить константу к содержимому регистра
	 parameter INSTR_OP_BEQ=6'b000100; //Условный переход если не равно
	 parameter INSTR_OP_BNE=6'b000101; // Условный переход если равно
	 
	 //R-instruction ** [000000] [5 bits] [5 bits] [5bits] [00000] [6 bits] **          
	 //				  ** opcode     rs       rt      rd     shamt    funct    **
	 
	 parameter INSTR_OP_RTYPE=6'b000000;  
	 parameter INSTR_RTYPE_FUNCT_ADD=6'b100000; //Сложение
	 parameter INSTR_RTYPE_FUNCT_SUB=6'b100010; //Вычитание
	 parameter INSTR_RTYPE_FUNCT_JR=6'b001000;  //Переход по регистру
	 parameter INSTR_RTYPE_FUNCT_SRL=6'b000010; //Логический сдвиг вправо 
	 parameter INSTR_RTYPE_FUNCT_SLL=6'b000000; //Логический сдвиг влево	
	 parameter INSTR_RTYPE_FUNCT_MULT=6'b011000; //Умножение 
	 parameter INSTR_RTYPE_FUNCT_DIV=6'b011001; //Деление 
	 
	 //J-instruction ** [6 bits] [26 bits] **          
	 //				  ** opcode     addr     **
	 parameter INSTR_OP_J=6'b000010; //Переход
	 parameter INSTR_OP_JAL=6'b000011; //Переход с возвратом
	 
	 always @(*) //Инициализация
	 begin
	 
		  //Инициализация
		  pc_next=pc+4;
		  rf_we = 0;
		  dmem_we = 0;
		  
		  // Сброс входов
		  rf_ra1 = 0;
		  rf_ra2 = 0;
		  rf_wa = 0;
		  rf_wd = 0;
		  
		  dmem_addr = 0;
		  dmem_wd = 0;
		  	
		  // Контроллер прерываний
		  case (IRQ)
		  
				3'h0: pc_next = 32'h80;
				3'h1: pc_next = 32'h100;
				3'h2: pc_next = 32'h180;
				3'h3: pc_next = 32'h200;
				3'h4: pc_next = 32'h280;
				3'h5: pc_next = 32'h300;
				3'h6: pc_next = 32'h380;
				3'h7: pc_next = 32'h400;
				
		  endcase
		  
		  
		  case (instr_op)
		  
				INSTR_OP_RTYPE:
				
					case (instr_rtype_funct)
//////////////////////////////////////////////////////////////////////////////////////////////						
						INSTR_RTYPE_FUNCT_ADD: 
						
							begin
								 
							 //Выполнение команды add $s0, $s1, $s2
								//$s0=$s1+$s2  $s0=rd $s1=rs $s2=rt
							   // Загрузка адресов регистров-источников
								rf_ra1 = instr_rtype_rs;
								rf_ra2 = instr_rtype_rt;
								
								//Чтение данных из регистров-источников и запись результата в регистр-назначение
								rf_wa=instr_rtype_rd;
								rf_wd=rf_rd1+rf_rd2;
								rf_we=1;
								
							end
//////////////////////////////////////////////////////////////////////////////////////////////								
					   INSTR_RTYPE_FUNCT_SUB:	
						
							begin
							
							 //Выполнение команды sub $s0, $s1, $s2
								//$s0=$s1-$s2  $s0=rd $s1=rs $s2=rt
							   // Загрузка адресов регистров-источников
								rf_ra1 = instr_rtype_rs;
								rf_ra2 = instr_rtype_rt;
								
								//Чтение данных из регистров-источников и запись результата в регистр-назначение
								rf_wa=instr_rtype_rd;
								rf_wd=rf_rd1-rf_rd2;
								rf_we=1;
								
						   end
//////////////////////////////////////////////////////////////////////////////////////////////								
						INSTR_RTYPE_FUNCT_MULT: 
						
							begin
								 
							 //Выполнение команды MULT $s0, $s1, $s2
								//$s0=$s1+$s2  $s0=rd $s1=rs $s2=rt
							   // Загрузка адресов регистров-источников
								rf_ra1 = instr_rtype_rs;
								rf_ra2 = instr_rtype_rt;
								
								//Чтение данных из регистров-источников и запись результата в регистр-назначение
								rf_wa=instr_rtype_rd;
								rf_wd=rf_rd1*rf_rd2;
								rf_we=1;
								
							end
//////////////////////////////////////////////////////////////////////////////////////////////								
						INSTR_RTYPE_FUNCT_DIV: 
						
							begin
								 
							 //Выполнение команды DIV $s0, $s1, $s2
								//$s0=$s1+$s2  $s0=rd $s1=rs $s2=rt
							   // Загрузка адресов регистров-источников
								rf_ra1 = instr_rtype_rs;
								rf_ra2 = instr_rtype_rt;
								
								//Чтение данных из регистров-источников и запись результата в регистр-назначение
								rf_wa=instr_rtype_rd;
								rf_wd=rf_rd1/rf_rd2;
								rf_we=1;
								
							end
//////////////////////////////////////////////////////////////////////////////////////////////								
						INSTR_RTYPE_FUNCT_JR: 
		
							begin
								
								//Выполнение команды JR (Переход по регистру)
								
								rf_ra1 = instr_rtype_rs;
								
								pc_next = rf_rd1;
								
							end
//////////////////////////////////////////////////////////////////////////////////////////////								
						INSTR_RTYPE_FUNCT_SLL: 
		
							begin
								
								//Выполнение команды SLL (Логический сдвиг влево)
								
								rf_ra1 = instr_rtype_rt;
								
								rf_wa=instr_rtype_rd;
								rf_wd=rf_rd1 << 1 ;
								rf_we=1;
								
							end
//////////////////////////////////////////////////////////////////////////////////////////////								
						INSTR_RTYPE_FUNCT_SRL: 
		
							begin
								
								//Выполнение команды SLL (Логический сдвиг вправо)
								
								rf_ra1 = instr_rtype_rt;
								
								rf_wa=instr_rtype_rd;
								rf_wd=rf_rd1 >> 1 ;
								rf_we=1;
								
							end
								
					endcase
//////////////////////////////////////////////////////////////////////////////////////////////					
				INSTR_OP_LW:
				
					begin
					
					   //Выполнение команды LW (загрузка слова в регистр из памяти ) $s0, $s1, $s2 
						
						rf_ra1=instr_rtype_rs;
						dmem_addr=rf_rd1+instr_rtype_imm;
						
						rf_wa=instr_rtype_rt;
						rf_we=1;
						rf_wd=dmem_rd;
						
					end
//////////////////////////////////////////////////////////////////////////////////////////////						
				INSTR_OP_SW:
				
					begin
					
					   //Выполнение команды SW (загрузка слова в память) $s0, $s1, $s2 
						
						rf_ra1=instr_rtype_rs;
						rf_ra2=instr_rtype_rt;
						
						dmem_addr=rf_rd1+instr_rtype_imm;
						dmem_we=1;
						dmem_wd=rf_rd2;											
						
					end					
//////////////////////////////////////////////////////////////////////////////////////////////								
				INSTR_OP_ADDI:
				
					begin
					
					   //Выполнение команды ADDI (Сложение непосредственного операнда с содержимым регистра $s0 и запись результата в регистр $s1 ) $rs, $rt, imm
						
						rf_ra1=instr_rtype_rs;
						
						rf_wa=instr_rtype_rt;
						rf_wd=rf_rd1+instr_rtype_imm;
						rf_we=1;											
						
					end	
//////////////////////////////////////////////////////////////////////////////////////////////						
				INSTR_OP_BEQ:
			
					begin
				
						//Выполнение команды BEQ (Переход по адресу если содержимое сравниваемых регистров равно между собой) $rs, $rt, imm
						
						rf_ra1=instr_rtype_rs;
						rf_ra2=instr_rtype_rt;
						
						if (rf_rd1 == rf_rd2);
						
							pc_next = instr_rtype_imm;
																							
					end	
//////////////////////////////////////////////////////////////////////////////////////////////						
				INSTR_OP_BNE:
			
					begin
				
						//Выполнение команды BNE (Переход по адресу если содержимое сравниваемых регистров неравно между собой) $rs, $rt, imm
						
						rf_ra1=instr_rtype_rs;
						rf_ra2=instr_rtype_rt;
						
						if (rf_rd1 != rf_rd2);
						
							pc_next = instr_rtype_imm;
																			
					end	
//////////////////////////////////////////////////////////////////////////////////////////////						
				INSTR_OP_LUI: 
				
					begin
						
						//Запись непосредственного  операнда в старшие 16 бит регистра, младшие 16 бит заполняются нулями
						
						rf_wa=instr_rtype_rt+instr_rtype_rs;
						rf_wd={instr_rtype_imm, 16'b0};
						rf_we=1;
						
					end
//////////////////////////////////////////////////////////////////////////////////////////////						
				INSTR_OP_J: 
			
					begin
						
						//Переход по адресу
						
						pc_next = instr_rtype_addr;
						
					end				
//////////////////////////////////////////////////////////////////////////////////////////////							
				INSTR_OP_JAL: 
			
					begin
						
						//Переход по адресу с возвратом
						
						rf_wa=5'h1F;
						rf_wd=pc_next+4;
						rf_we=1;
						
						pc_next = instr_rtype_addr;
															
					end
//////////////////////////////////////////////////////////////////////////////////////////////																
		endcase
		
	end
	

		
		
endmodule 


