//////////////////////////////////////////////////////////////////////
////                                                              ////
////  Day-1 Simulation Defines for OpenCores oc8051               ////
////  Derived from rtl_reference/rtl/verilog/oc8051_defines.v     ////
////  (Selects behavioral 256B internal RAM & external ROM mode)  ////
////                                                              ////
//////////////////////////////////////////////////////////////////////

// Peripherals (all native in freecores/8051)
`define OC8051_UART
`define OC8051_TC01
`define OC8051_TC2
`define OC8051_PORTS
`define OC8051_PORT0
`define OC8051_PORT1
`define OC8051_PORT2
`define OC8051_PORT3

// External program ROM via wbi_* (ea_in=0, internal ROM disabled)
//`define OC8051_ROM
//`define OC8051_XILINX_ROM

// Memory options: leave OC8051_RAM_GENERIC, OC8051_CACHE, OC8051_WB undefined
// so oc8051_ram_256x8_two_bist uses its built-in behavioral reg [7:0] buff[0:256].
//`define OC8051_CACHE
//`define OC8051_WB
//`define OC8051_RAM_XILINX
//`define OC8051_RAM_VIRTUALSILICON
//`define OC8051_RAM_GENERIC

// Simulation display hooks
`define OC8051_SIMULATION

// ALU opcodes
`define OC8051_ALU_NOP 4'b0000
`define OC8051_ALU_ADD 4'b0001
`define OC8051_ALU_SUB 4'b0010
`define OC8051_ALU_MUL 4'b0011
`define OC8051_ALU_DIV 4'b0100
`define OC8051_ALU_DA  4'b0101
`define OC8051_ALU_NOT 4'b0110
`define OC8051_ALU_AND 4'b0111
`define OC8051_ALU_XOR 4'b1000
`define OC8051_ALU_OR  4'b1001
`define OC8051_ALU_RL  4'b1010
`define OC8051_ALU_RLC 4'b1011
`define OC8051_ALU_RR  4'b1100
`define OC8051_ALU_RRC 4'b1101
`define OC8051_ALU_INC 4'b1110
`define OC8051_ALU_XCH 4'b1111

// SFR addresses
`define OC8051_SFR_ACC     8'he0
`define OC8051_SFR_B       8'hf0
`define OC8051_SFR_PSW     8'hd0
`define OC8051_SFR_P0      8'h80
`define OC8051_SFR_P1      8'h90
`define OC8051_SFR_P2      8'ha0
`define OC8051_SFR_P3      8'hb0
`define OC8051_SFR_DPTR_LO 8'h82
`define OC8051_SFR_DPTR_HI 8'h83
`define OC8051_SFR_IP0     8'hb8
`define OC8051_SFR_IEN0    8'ha8
`define OC8051_SFR_TMOD    8'h89
`define OC8051_SFR_TCON    8'h88
`define OC8051_SFR_TH0     8'h8c
`define OC8051_SFR_TL0     8'h8a
`define OC8051_SFR_TH1     8'h8d
`define OC8051_SFR_TL1     8'h8b
`define OC8051_SFR_SCON    8'h98
`define OC8051_SFR_SBUF    8'h99
`define OC8051_SFR_SADDR   8'ha9
`define OC8051_SFR_SADEN   8'hb9
`define OC8051_SFR_PCON    8'h87
`define OC8051_SFR_SP      8'h81
`define OC8051_SFR_IE      8'ha8
`define OC8051_SFR_IP      8'hb7
`define OC8051_SFR_RCAP2H  8'hcb
`define OC8051_SFR_RCAP2L  8'hca
`define OC8051_SFR_T2CON   8'hc8
`define OC8051_SFR_TH2     8'hcd
`define OC8051_SFR_TL2     8'hcc

// SFR bit addresses
`define OC8051_SFR_B_ACC   5'b11100
`define OC8051_SFR_B_PSW   5'b11010
`define OC8051_SFR_B_P0    5'b10000
`define OC8051_SFR_B_P1    5'b10010
`define OC8051_SFR_B_P2    5'b10100
`define OC8051_SFR_B_P3    5'b10110
`define OC8051_SFR_B_B     5'b11110
`define OC8051_SFR_B_IP    5'b10111
`define OC8051_SFR_B_IE    5'b10101
`define OC8051_SFR_B_SCON  5'b10011
`define OC8051_SFR_B_TCON  5'b10001
`define OC8051_SFR_B_T2CON 5'b11001

// Carry input select
`define OC8051_CY_0   2'b00
`define OC8051_CY_PSW 2'b01
`define OC8051_CY_RAM 2'b10
`define OC8051_CY_1   2'b11
`define OC8051_CY_DC  2'b00

// Instruction decode patterns
`define OC8051_ACALL   8'bxxx1_0001
`define OC8051_AJMP    8'bxxx0_0001
`define OC8051_ADD_R   8'b0010_1xxx
`define OC8051_ADDC_R  8'b0011_1xxx
`define OC8051_ANL_R   8'b0101_1xxx
`define OC8051_CJNE_R  8'b1011_1xxx
`define OC8051_DEC_R   8'b0001_1xxx
`define OC8051_DJNZ_R  8'b1101_1xxx
`define OC8051_INC_R   8'b0000_1xxx
`define OC8051_MOV_R   8'b1110_1xxx
`define OC8051_MOV_AR  8'b1111_1xxx
`define OC8051_MOV_DR  8'b1010_1xxx
`define OC8051_MOV_CR  8'b0111_1xxx
`define OC8051_MOV_RD  8'b1000_1xxx
`define OC8051_ORL_R   8'b0100_1xxx
`define OC8051_SUBB_R  8'b1001_1xxx
`define OC8051_XCH_R   8'b1100_1xxx
`define OC8051_XRL_R   8'b0110_1xxx
`define OC8051_ADD_I   8'b0010_011x
`define OC8051_ADDC_I  8'b0011_011x
`define OC8051_ANL_I   8'b0101_011x
`define OC8051_CJNE_I  8'b1011_011x
`define OC8051_DEC_I   8'b0001_011x
`define OC8051_INC_I   8'b0000_011x
`define OC8051_MOV_I   8'b1110_011x
`define OC8051_MOV_ID  8'b1000_011x
`define OC8051_MOV_AI  8'b1111_011x
`define OC8051_MOV_DI  8'b1010_011x
`define OC8051_MOV_CI  8'b0111_011x
`define OC8051_MOVX_IA 8'b1110_001x
`define OC8051_MOVX_AI 8'b1111_001x
`define OC8051_ORL_I   8'b0100_011x
`define OC8051_SUBB_I  8'b1001_011x
`define OC8051_XCH_I   8'b1100_011x
`define OC8051_XCHD    8'b1101_011x
`define OC8051_XRL_I   8'b0110_011x
`define OC8051_ADD_D   8'b0010_0101
`define OC8051_ADD_C   8'b0010_0100
`define OC8051_ADDC_D  8'b0011_0101
`define OC8051_ADDC_C  8'b0011_0100
`define OC8051_ANL_D   8'b0101_0101
`define OC8051_ANL_C   8'b0101_0100
`define OC8051_ANL_DD  8'b0101_0010
`define OC8051_ANL_DC  8'b0101_0011
`define OC8051_ANL_B   8'b1000_0010
`define OC8051_ANL_NB  8'b1011_0000
`define OC8051_CJNE_D  8'b1011_0101
`define OC8051_CJNE_C  8'b1011_0100
`define OC8051_CLR_A   8'b1110_0100
`define OC8051_CLR_C   8'b1100_0011
`define OC8051_CLR_B   8'b1100_0010
`define OC8051_CPL_A   8'b1111_0100
`define OC8051_CPL_C   8'b1011_0011
`define OC8051_CPL_B   8'b1011_0010
`define OC8051_DA      8'b1101_0100
`define OC8051_DEC_A   8'b0001_0100
`define OC8051_DEC_D   8'b0001_0101
`define OC8051_DIV     8'b1000_0100
`define OC8051_DJNZ_D  8'b1101_0101
`define OC8051_INC_A   8'b0000_0100
`define OC8051_INC_D   8'b0000_0101
`define OC8051_INC_DP  8'b1010_0011
`define OC8051_JB      8'b0010_0000
`define OC8051_JBC     8'b0001_0000
`define OC8051_JC      8'b0100_0000
`define OC8051_JMP_D   8'b0111_0011
`define OC8051_JNB     8'b0011_0000
`define OC8051_JNC     8'b0101_0000
`define OC8051_JNZ     8'b0111_0000
`define OC8051_JZ      8'b0110_0000
`define OC8051_LCALL   8'b0001_0010
`define OC8051_LJMP    8'b0000_0010
`define OC8051_MOV_D   8'b1110_0101
`define OC8051_MOV_C   8'b0111_0100
`define OC8051_MOV_DA  8'b1111_0101
`define OC8051_MOV_DD  8'b1000_0101
`define OC8051_MOV_CD  8'b0111_0101
`define OC8051_MOV_BC  8'b1010_0010
`define OC8051_MOV_CB  8'b1001_0010
`define OC8051_MOV_DP  8'b1001_0000
`define OC8051_MOVC_DP 8'b1001_0011
`define OC8051_MOVC_PC 8'b1000_0011
`define OC8051_MOVX_PA 8'b1110_0000
`define OC8051_MOVX_AP 8'b1111_0000
`define OC8051_MUL     8'b1010_0100
`define OC8051_NOP     8'b0000_0000
`define OC8051_ORL_D   8'b0100_0101
`define OC8051_ORL_C   8'b0100_0100
`define OC8051_ORL_AD  8'b0100_0010
`define OC8051_ORL_CD  8'b0100_0011
`define OC8051_ORL_B   8'b0111_0010
`define OC8051_ORL_NB  8'b1010_0000
`define OC8051_POP     8'b1101_0000
`define OC8051_PUSH    8'b1100_0000
`define OC8051_RET     8'b0010_0010
`define OC8051_RETI    8'b0011_0010
`define OC8051_RL      8'b0010_0011
`define OC8051_RLC     8'b0011_0011
`define OC8051_RR      8'b0000_0011
`define OC8051_RRC     8'b0001_0011
`define OC8051_SETB_C  8'b1101_0011
`define OC8051_SETB_B  8'b1101_0010
`define OC8051_SJMP    8'b1000_0000
`define OC8051_SUBB_D  8'b1001_0101
`define OC8051_SUBB_C  8'b1001_0100
`define OC8051_SWAP    8'b1100_0100
`define OC8051_XCH_D   8'b1100_0101
`define OC8051_XRL_D   8'b0110_0101
`define OC8051_XRL_C   8'b0110_0100
`define OC8051_XRL_AD  8'b0110_0010
`define OC8051_XRL_CD  8'b0110_0011

// Reset defaults
`define OC8051_RST_PC     23'h0
`define OC8051_RST_ACC    8'h00
`define OC8051_RST_B      8'h00
`define OC8051_RST_PSW    8'h00
`define OC8051_RST_SP     8'b0000_0111
`define OC8051_RST_DPH    8'h00
`define OC8051_RST_DPL    8'h00
`define OC8051_RST_P0     8'b1111_1111
`define OC8051_RST_P1     8'b1111_1111
`define OC8051_RST_P2     8'b1111_1111
`define OC8051_RST_P3     8'b1111_1111
`define OC8051_RST_IP     8'b0000_0000
`define OC8051_RST_IE     8'b0000_0000
`define OC8051_RST_TMOD   8'b0000_0000
`define OC8051_RST_TCON   8'b0000_0000
`define OC8051_RST_TH0    8'b0000_0000
`define OC8051_RST_TL0    8'b0000_0000
`define OC8051_RST_TH1    8'b0000_0000
`define OC8051_RST_TL1    8'b0000_0000
`define OC8051_RST_SCON   8'b0000_0000
`define OC8051_RST_SBUF   8'b0000_0000
`define OC8051_RST_PCON   8'b0000_0000
`define OC8051_RST_RCAP2H 8'h00
`define OC8051_RST_RCAP2L 8'h00
`define OC8051_RST_T2CON  8'h00
`define OC8051_RST_T2MOD  8'h00
`define OC8051_RST_TH2    8'h00
`define OC8051_RST_TL2    8'h00

// Control encodings
`define OC8051_AS1_RAM 3'b000
`define OC8051_AS1_OP1 3'b111
`define OC8051_AS1_OP2 3'b001
`define OC8051_AS1_OP3 3'b010
`define OC8051_AS1_ACC 3'b011
`define OC8051_AS1_PCH 3'b100
`define OC8051_AS1_PCL 3'b101
`define OC8051_AS1_DC  3'b000

`define OC8051_AS2_RAM  3'b00
`define OC8051_AS2_ACC  3'b01
`define OC8051_AS2_ZERO 3'b10
`define OC8051_AS2_OP2  3'b11
`define OC8051_AS2_DC   3'b00

`define OC8051_AS3_DP 1'b0
`define OC8051_AS3_PC 1'b1
`define OC8051_AS3_DC 1'b0

`define OC8051_WRS_N    2'b00
`define OC8051_WRS_ACC1 2'b01
`define OC8051_WRS_ACC2 2'b10
`define OC8051_WRS_DPTR 2'b11

`define OC8051_RRS_RN   3'b000
`define OC8051_RRS_I    3'b001
`define OC8051_RRS_D    3'b010
`define OC8051_RRS_SP   3'b011
`define OC8051_RRS_B    3'b100
`define OC8051_RRS_DPTR 3'b101
`define OC8051_RRS_PSW  3'b110
`define OC8051_RRS_ACC  3'b111
`define OC8051_RRS_DC   3'b000

`define OC8051_RWS_RN 3'b000
`define OC8051_RWS_D  3'b001
`define OC8051_RWS_I  3'b010
`define OC8051_RWS_SP 3'b011
`define OC8051_RWS_D3 3'b101
`define OC8051_RWS_D1 3'b110
`define OC8051_RWS_B  3'b111
`define OC8051_RWS_DC 3'b000

`define OC8051_PIS_DC  3'b000
`define OC8051_PIS_AL  3'b000
`define OC8051_PIS_AH  3'b001
`define OC8051_PIS_SO1 3'b010
`define OC8051_PIS_SO2 3'b011
`define OC8051_PIS_I11 3'b100
`define OC8051_PIS_I16 3'b101
`define OC8051_PIS_ALU 3'b110

`define OC8051_CSS_AZ  2'b00
`define OC8051_CSS_DES 2'b01
`define OC8051_CSS_CY  2'b10
`define OC8051_CSS_BIT 2'b11
`define OC8051_CSS_DC  2'b01

`define OC8051_PCW_N 1'b0
`define OC8051_PCW_Y 1'b1

`define OC8051_PS_NOT 2'b00
`define OC8051_PS_CY  2'b01
`define OC8051_PS_OV  2'b10
`define OC8051_PS_AC  2'b11

`define OC8051_RAS_PC  1'b0
`define OC8051_RAS_DES 1'b1

`define OC8051_MAS_DPTR_R 3'b000
`define OC8051_MAS_DPTR_W 3'b001
`define OC8051_MAS_RI_R   3'b010
`define OC8051_MAS_RI_W   3'b011
`define OC8051_MAS_CODE   3'b100
`define OC8051_MAS_NO     3'b111

`define OC8051_MODE0 2'b00
`define OC8051_MODE1 2'b01
`define OC8051_MODE2 2'b10
`define OC8051_MODE3 2'b11

`define OC8051_INT_X0   8'h03
`define OC8051_INT_T0   8'h0b
`define OC8051_INT_X1   8'h13
`define OC8051_INT_T1   8'h1b
`define OC8051_INT_UART 8'h23
`define OC8051_INT_T2   8'h2b

`define OC8051_ILEV_L0 1'b0
`define OC8051_ILEV_L1 1'b1

`define OC8051_ISRC_NO   3'b000
`define OC8051_ISRC_IE0  3'b001
`define OC8051_ISRC_TF0  3'b010
`define OC8051_ISRC_IE1  3'b011
`define OC8051_ISRC_TF1  3'b100
`define OC8051_ISRC_UART 3'b101
`define OC8051_ISRC_T2   3'b110

`define OC8051_RW0 1'b1
`define OC8051_RW1 1'b0

`define OC8051_RMW_Y 1'b1
`define OC8051_RMW_N 1'b0
