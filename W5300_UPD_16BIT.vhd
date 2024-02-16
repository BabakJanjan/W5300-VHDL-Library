----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:11:42 11/16/2021 
-- Design Name: 
-- Module Name:    LAN_5300_UDP - arch 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments:
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_signed.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives IN this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.W5300_package.all;

ENTITY LAN_5300_UDP IS
	GENERIC(G_CLK_FREQUENCY			: INTEGER 								:= 50;														-- CLOCK FREQUENCY IN MHz
			G_NUM_BYTE_TO_SEND		: INTEGER  								:= 30; 														-- BYTE OF INPUT DATA
			G_MAC_SOURCE_ADDRESS	: Array_8Bit(0 to 5) 					:= (x"00", x"08", x"DC", x"01", x"02", x"03");				-- HARDWARE SOURCE ADDRESS
			G_IP_SOURCE_ADDRESS 	: Array_8Bit(0 to 3) 					:= (x"C0", x"A8", x"00", x"14"); 							-- IP = 192.168.0.20
			G_SUB_MASK_ADDRESS 		: Array_8Bit(0 to 3) 				:= (x"FF", x"FF", x"FF", x"00"); 							-- SUB= 255.255.255.0
			G_GATWAY_ADDRESS 		: Array_8Bit(0 to 3) 					:= (x"C0", x"A8", x"00", x"01"); 							-- GTW = 192.168.0.1
			G_SOCKET_TX_SIZE_KB 	: Array_8Bit(0 to 7) 					:= (x"40", x"00", x"00", x"00",x"00", x"00", x"00", x"00"); -- Transmit Memory Size Register of SOCKET 0 to 7 (Multiple of 8, Max is 64)
			G_SOCKET_RX_SIZE_KB 	: Array_8Bit(0 to 7) 					:= (x"40", x"00", x"00", x"00",x"00", x"00", x"00", x"00"); -- Transmit Memory Size Register of SOCKET 0 to 7
			G_MEM_BLOCK_TYPE 		: Array_8Bit(0 to 1) 					:= (x"00", x"FF"); 											-- Memory Block Type Register
			G_SOCKET_NUM 			: STD_LOGIC_VECTOR(2 DOWNTO 0)  		:= "000"; 													-- Socket Number 0 to 7
			G_PORT_NUMBER 			: STD_LOGIC_VECTOR(15 DOWNTO 0) 		:= x"040B"; 												-- Port Number 040B=1035( this 2byte write to Sn_PORTR) c_POROTOCOL 			
			G_DESTENATION_IP		: Array_8Bit(0 to 3) 					:= (x"C0", x"A8", x"00", x"1E"); 							-- IP = 192.168.0.20
			G_DESTENATION_PORT_NUM  : STD_LOGIC_VECTOR(15 DOWNTO 0) 	:= x"040B" 												-- Port Number 040B=1035( this 2byte write to Sn_PORTR) c_POROTOCOL 			
			);
			
    PORT (	i_CLK 			: IN    	STD_LOGIC;
			i_RESET 				: IN    	STD_LOGIC;
			i_TX_START 			: IN    	STD_LOGIC;
			i_ETH_IR 			: IN    	STD_LOGIC;
			i_DATA				: IN 		STD_LOGIC_VECTOR (G_NUM_BYTE_TO_SEND*8 -1 DOWNTO 0);
			o_ETH_CS 			: OUT   	STD_LOGIC;
			o_ETH_RD 			: OUT   	STD_LOGIC;
			o_ETH_WR 			: OUT   	STD_LOGIC;
			o_ETH_RST 			: OUT		STD_LOGIC;
			o_ETH_ADD 			: OUT  	STD_LOGIC_VECTOR (9 DOWNTO 0);
			o_ETH_DATA 			: INOUT 	STD_LOGIC_VECTOR (15 DOWNTO 0);
			o_BUSY				: OUT 	STD_LOGIC;
			o_ERROR				: OUT 	STD_LOGIC
			);
END LAN_5300_UDP;

ARCHITECTURE ARCH OF LAN_5300_UDP IS
	CONSTANT c_RESET_DELAY			: INTEGER := 200*G_CLK_FREQUENCY;			--AT LEAST 2us
	CONSTANT c_PLL_DELAY				: INTEGER := 1000*G_CLK_FREQUENCY*1000;	--AT LEAST 10 ms
	CONSTANT c_SETUPT_HOLD_DELAY	: INTEGER := 100*G_CLK_FREQUENCY/1000;
	CONSTANT c_READ_DELAY			: INTEGER := 200*G_CLK_FREQUENCY/1000;
	CONSTANT c_WRITE_DELAY			: INTEGER := 200*G_CLK_FREQUENCY/1000;
	CONSTANT c_BYTE_NUM_TO_SEND	: STD_LOGIC_VECTOR(31 DOWNTO 0) := STD_LOGIC_VECTOR(TO_UNSIGNED(G_NUM_BYTE_TO_SEND, 32));
----------------------------------------------------------------------------------------------------------------------
	TYPE Array_8Bit IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	TYPE Array_26Bit IS ARRAY (NATURAL RANGE <>) OF STD_LOGIC_VECTOR(25 DOWNTO 0);
------------------------------------------------------------------------------------------------------------
	TYPE t_CONTROL IS RECORD
		CS	: STD_LOGIC;
		RD	: STD_LOGIC;
		WR	: STD_LOGIC;
		DIR	: STD_LOGIC;
	END RECORD t_CONTROL;
	
	CONSTANT c_IDLE_OPERATION 		: t_CONTROL := (CS => '1', RD => '1',  WR => '1', DIR => '1');
	CONSTANT c_WR_SETUP_OPERATION	: t_CONTROL := (CS => '0', RD => '1',  WR => '1', DIR => '0');
	CONSTANT c_WR_OPERATION			: t_CONTROL := (CS => '0', RD => '1',  WR => '0', DIR => '0');
	CONSTANT c_WR_HOLD_OPERATION	: t_CONTROL := (CS => '0', RD => '1',  WR => '1', DIR => '0');
	CONSTANT c_RD_SETUP_OPERATION	: t_CONTROL := (CS => '0', RD => '1',  WR => '1', DIR => '1');
	CONSTANT c_RD_OPERATION			: t_CONTROL := (CS => '0', RD => '0',  WR => '1', DIR => '1');
	CONSTANT c_RD_HOLD_OPERATION	: t_CONTROL := (CS => '0', RD => '1',  WR => '1', DIR => '1');
	
	SIGNAL s_OPERATION_REG, s_OPERATION_NEXT 	: t_CONTROL;
	
	TYPE t_CONTROL_STATE IS (IDLE_OP, WR_SETUP_OP, WRITE_OP, RD_SETUP_OP, READ_OP, WR_HOLD_OP, RD_HOLD_OP);
	SIGNAL s_OPERATION_STATE_REG, s_OPERATION_STATE_NEXT	: t_CONTROL_STATE;
------------------------------------------------------------------------------------------------------------	
	TYPE t_CONFIG IS RECORD
		WR_EN	: STD_LOGIC;
		RD_EN	: STD_LOGIC;
		ADDRESS	: STD_LOGIC_VECTOR(9 DOWNTO 0);
		DATA	: STD_LOGIC_VECTOR(15 DOWNTO 0);
	END RECORD t_CONFIG;
	
	SIGNAL s_CONFIG_REG, s_CONFIG_NEXT			: t_CONFIG;
	CONSTANT c_CONFIG_RESET 						: t_CONFIG := (WR_EN => '0', RD_EN => '0', ADDRESS => (OTHERS => 'Z') , DATA => (OTHERS => 'Z'));
	CONSTANT c_CONFIG_SOCKET_CLOSE 				: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_MR_Addr	  , DATA => Sn_CR_CLOSE);
	CONSTANT c_CONFIG_SOCKET_MODE					: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_MR_Addr	  , DATA => Sn_MR_UDP);
	CONSTANT c_CONFIG_SOCKET_PORT_NUM			: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_PORTR_Addr	  , DATA => G_PORT_NUMBER);
	CONSTANT c_CONFIG_SOCKET_OPEN					: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_CR_Addr	  , DATA => Sn_CR_OPEN);
	CONSTANT c_CONFIG_SOCKET_READ_Sn_SSR		: t_CONFIG := (WR_EN => '0', RD_EN => '1', ADDRESS => Sn_SSR_Addr	  , DATA => (OTHERS =>'Z'));
	CONSTANT c_CONFIG_SOCKET_READ_Sn_Rx_RSR1	: t_CONFIG := (WR_EN => '0', RD_EN => '1', ADDRESS => Sn_RX_RSR_Addr  , DATA => (OTHERS =>'Z'));
	CONSTANT c_CONFIG_SOCKET_READ_Sn_Rx_RSR2	: t_CONFIG := (WR_EN => '0', RD_EN => '1', ADDRESS => Sn_RX_RSR2_Addr , DATA => (OTHERS =>'Z'));
	CONSTANT c_CONFIG_SOCKET_READ_Sn_RX_FIFOR	: t_CONFIG := (WR_EN => '0', RD_EN => '1', ADDRESS => Sn_RX_FIFOR_Addr, DATA => (OTHERS =>'Z'));
	CONSTANT c_CONFIG_SOCKET_WRITE_Sn_TX_FIFOR: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_TX_FIFOR_Addr, DATA => (OTHERS =>'Z'));
	CONSTANT c_CONFIG_SOCKET_SET_RECEIVE_CMD	: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_CR_Addr	  , DATA => Sn_CR_RECV);
	CONSTANT c_CONFIG_SOCKET_SET_DIPR1			: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_DIPR_Addr	  , DATA => G_DESTENATION_IP(0) & G_DESTENATION_IP(1));
	CONSTANT c_CONFIG_SOCKET_SET_DIPR2			: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_DIPR2_Addr	  , DATA => G_DESTENATION_IP(2) & G_DESTENATION_IP(3));
	CONSTANT c_CONFIG_SOCKET_SET_DPORTR			: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_DPORTR_Addr  , DATA => G_DESTENATION_PORT_NUM);
	CONSTANT c_CONFIG_SOCKET_SET_WRSR1			: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_TX_WRSR_Addr , DATA => c_BYTE_NUM_TO_SEND(31 DOWNTO 16));
	CONSTANT c_CONFIG_SOCKET_SET_WRSR2			: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_TX_WRSR2_Addr , DATA => c_BYTE_NUM_TO_SEND(15 DOWNTO 0));
	CONSTANT c_CONFIG_SOCKET_SET_SEND			: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_CR_Addr	  , DATA => Sn_CR_SEND);
	CONSTANT c_CONFIG_SOCKET_READ_IR				: t_CONFIG := (WR_EN => '0', RD_EN => '1', ADDRESS => Sn_IR_Addr	  , DATA => (OTHERS =>'Z'));
	CONSTANT c_CONFIG_SOCKET_CLEAR_IR_SENDOK	: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_IR_Addr	  , DATA => (4=> '1', OTHERS =>'0'));
	CONSTANT c_CONFIG_SOCKET_CLEAR_IR_TIMEOUT	: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_IR_Addr	  , DATA => (3=> '1', OTHERS =>'0'));
	CONSTANT c_CONFIG_SOCKET_CLEAR_IR_ALL		: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => Sn_IR_Addr	  , DATA => ( OTHERS =>'1'));
	CONSTANT c_CONFIG_SOCKET_CLEAR_IRn_ALL		: t_CONFIG := (WR_EN => '1', RD_EN => '0', ADDRESS => IR_Addr	  	  , DATA => ( OTHERS =>'1'));
	CONSTANT c_CONFIG_SOCKET_DUMMY_READ			: t_CONFIG := (WR_EN => '0', RD_EN => '1', ADDRESS => MR_Addr	  	  , DATA => ( OTHERS =>'1'));


	TYPE t_CONFIG_OPERATION IS ARRAY (0 TO 25) OF t_CONFIG;
	--Configuration Ethernet parameters,
	CONSTANT c_CONFIG	: t_CONFIG_OPERATION := (0  =>(WR_EN => '1', RD_EN => '0', ADDRESS => MR_Addr, 		DATA => x"B900"),
															1  =>(WR_EN => '1', RD_EN => '0', ADDRESS => IR_Addr, 		DATA => x"00FF"),
															2  =>(WR_EN => '1', RD_EN => '0', ADDRESS => IMR_Addr, 	DATA => x"00FF"),
														 3  =>(WR_EN => '1', RD_EN => '0', ADDRESS => Sn_IMR_Addr, 	DATA => x"00FF"),
														 4  =>(WR_EN => '1', RD_EN => '0', ADDRESS => SHAR_Addr, 	DATA => G_MAC_SOURCE_ADDRESS(0) & G_MAC_SOURCE_ADDRESS(1)),
														 5  =>(WR_EN => '1', RD_EN => '0', ADDRESS => SHAR2_Addr, 	DATA => G_MAC_SOURCE_ADDRESS(2) & G_MAC_SOURCE_ADDRESS(3)),
														 6  =>(WR_EN => '1', RD_EN => '0', ADDRESS => SHAR4_Addr, 	DATA => G_MAC_SOURCE_ADDRESS(4) & G_MAC_SOURCE_ADDRESS(5)),
														 7  =>(WR_EN => '1', RD_EN => '0', ADDRESS => GAR_Addr, 	DATA => G_GATWAY_ADDRESS(0) & G_GATWAY_ADDRESS(1)),
														 8  =>(WR_EN => '1', RD_EN => '0', ADDRESS => GAR2_Addr, 	DATA => G_GATWAY_ADDRESS(2) & G_GATWAY_ADDRESS(3)),
														 9  =>(WR_EN => '1', RD_EN => '0', ADDRESS => SUBR_Addr, 	DATA => G_SUB_MASK_ADDRESS(0) & G_SUB_MASK_ADDRESS(1)),
														 10 =>(WR_EN => '1', RD_EN => '0', ADDRESS => SUBR2_Addr, 	DATA => G_SUB_MASK_ADDRESS(2) & G_SUB_MASK_ADDRESS(3)),
														 11 =>(WR_EN => '1', RD_EN => '0', ADDRESS => SIPR_Addr, 	DATA => G_IP_SOURCE_ADDRESS(0) & G_IP_SOURCE_ADDRESS(1)),
														 12 =>(WR_EN => '1', RD_EN => '0', ADDRESS => SIPR2_Addr, 	DATA => G_IP_SOURCE_ADDRESS(2) & G_IP_SOURCE_ADDRESS(3)),
														 13 =>(WR_EN => '1', RD_EN => '0', ADDRESS => MTYPER_Addr, 	DATA =>	G_MEM_BLOCK_TYPE(0) & G_MEM_BLOCK_TYPE(1)),
														 14 =>(WR_EN => '1', RD_EN => '0', ADDRESS => TMSR01_Addr, 	DATA => G_SOCKET_TX_SIZE_KB(0) & G_SOCKET_TX_SIZE_KB(1)),
														 15 =>(WR_EN => '1', RD_EN => '0', ADDRESS => TMSR23_Addr, 	DATA => G_SOCKET_TX_SIZE_KB(2) & G_SOCKET_TX_SIZE_KB(3)),
														 16 =>(WR_EN => '1', RD_EN => '0', ADDRESS => TMSR45_Addr, 	DATA => G_SOCKET_TX_SIZE_KB(4) & G_SOCKET_TX_SIZE_KB(5)),
														 17 =>(WR_EN => '1', RD_EN => '0', ADDRESS => TMSR67_Addr, 	DATA => G_SOCKET_TX_SIZE_KB(6) & G_SOCKET_TX_SIZE_KB(7)),
														 18 =>(WR_EN => '1', RD_EN => '0', ADDRESS => RMSR01_Addr, 	DATA => G_SOCKET_RX_SIZE_KB(0) & G_SOCKET_RX_SIZE_KB(1)),
														 19 =>(WR_EN => '1', RD_EN => '0', ADDRESS => RMSR23_Addr, 	DATA => G_SOCKET_RX_SIZE_KB(2) & G_SOCKET_RX_SIZE_KB(3)),
														 20 =>(WR_EN => '1', RD_EN => '0', ADDRESS => RMSR45_Addr, 	DATA => G_SOCKET_RX_SIZE_KB(4) & G_SOCKET_RX_SIZE_KB(5)),
														 21 =>(WR_EN => '1', RD_EN => '0', ADDRESS => RMSR67_Addr, 	DATA => G_SOCKET_RX_SIZE_KB(6) & G_SOCKET_RX_SIZE_KB(7)),
														 22 =>(WR_EN => '1', RD_EN => '0', ADDRESS => RTR_Addr, 	DATA => X"0FA0"),
														 23 =>(WR_EN => '1', RD_EN => '0', ADDRESS => RCR_Addr, 	DATA => x"000F"),
														 24 =>(WR_EN => '1', RD_EN => '0', ADDRESS => Sn_CR_Addr,	DATA => Sn_CR_CLOSE),
														 25 =>(WR_EN => '1', RD_EN => '0', ADDRESS => Sn_IMR_Addr, 	DATA => x"00FF")
														);
														
	TYPE	t_MAIN_STATE IS (RESET, PLL_DELAY, CONFIGURE, SOCKET_IDLE, SOCKET_OPEN, SOCKET_CLOSE,
								  SOCKET_REC_DATA_CHECK,  SOCKET_REC_PACKET_INFO, SOCKET_REC_PACKET_DATA, 
								  SOCKET_SEND_DATA_CHECK, SOCKET_SEND_PACKET_INFO, SOCKET_SEND_PACKET_DATA, 
								  SOCKET_SEND_PACKET_SIZE, SOCKET_FINISH, SOCKET_COMPLETE_SENDING,
								  SOCKET_WRITE_READ_WAIT
								  );
								
	SIGNAL s_MAIN_STATE_REG, 				s_MAIN_STATE_NEXT 							: t_MAIN_STATE;
	SIGNAL s_MAIN_STATE_NEXT_REG,			s_MAIN_STATE_NEXT_NEXT 						: t_MAIN_STATE;
	SIGNAL s_Eth_RST_REG, 					s_Eth_RST_NEXT									: STD_LOGIC := '0';
	SIGNAL s_INDEX_CONFIG_REG, 			s_INDEX_CONFIG_NEXT							: UNSIGNED(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL s_CNT_CLK_REG, 					s_CNT_CLK_NEXT									: UNSIGNED(7 DOWNTO 0);
	SIGNAL s_CLK_DIV_REG, 					s_CLK_DIV_NEXT									: INTEGER RANGE 0 TO 50000000;
	SIGNAL s_DATA_READ_REG,					s_DATA_READ_NEXT								: STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL s_WR_DONE_REG,					s_WR_DONE_NEXT									: STD_LOGIC := '0';
	SIGNAL s_RD_DATA_VALID_REG,				s_RD_DATA_VALID_NEXT						: STD_LOGIC := '0';
	SIGNAL s_ETH_IR_REG,					s_ETH_IR_NEXT										: STD_LOGIC := '0';
	SIGNAL s_TICK																					: STD_LOGIC := '0';
	SIGNAL s_BUSY_REG,						s_BUSY_NEXT										: STD_LOGIC := '0';
	SIGNAL s_ERROR_REG,						s_ERROR_NEXT									: STD_LOGIC := '0';
	SIGNAL s_PACKET_SIZE_REG,				s_PACKET_SIZE_NEXT							: UNSIGNED(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL s_PACKET_IP_REG,					s_PACKET_IP_NEXT								: STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
	SIGNAL s_PACKET_PORT_REG,				s_PACKET_PORT_NEXT							: STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL s_DATA_IN																				: STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
	SIGNAL s_DIR_REG																				: STD_LOGIC := '0';
	SIGNAL s_Sn_RSR_REG,						s_Sn_RSR_NEXT									: STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0'); 
------------------------------------------------------------------------------------------------------------------------------------	
BEGIN
	IOBUF_GENERATE :FOR I IN 15 DOWNTO 0 GENERATE
		BEGIN
			IOBUF_INST : IOBUF
			GENERIC MAP (-- DRIVE => 12,
							 IOSTANDARD => "LVCMOS33",
							 SLEW => "FAST"
							 )
			PORT MAP (O 	=> s_DATA_IN(i),     	 -- Buffer output
						 IO 	=> O_ETH_DATA(i),   		 -- Buffer inout port (connect directly to top-level port)
						 I 	=> s_CONFIG_REG.DATA(i), -- Buffer input
						 T 	=> s_OPERATION_REG.DIR      		 -- 3-state enable input, high=input, low=output 
				       );
			END GENERATE;
-----------------------------------------------------------------------------------------------------------------------			
	
	PROCESS(i_CLK,i_RESET)
	BEGIN
		IF(i_RESET = '0') THEN
			s_CONFIG_REG						<= c_CONFIG_RESET;
			s_MAIN_STATE_REG 					<= RESET;
			s_MAIN_STATE_NEXT_REG			<= RESET;
			s_OPERATION_REG					<= c_IDLE_OPERATION;
			s_INDEX_CONFIG_REG				<= (OTHERS => '0');
			s_Eth_RST_REG						<= '1';
			s_CNT_CLK_REG						<= (OTHERS => '0');
			s_CLK_DIV_REG						<= 0;
			s_ETH_IR_REG						<= '1';
			s_WR_DONE_REG						<= '0';
			s_RD_DATA_VALID_REG				<= '0';
			s_OPERATION_STATE_REG			<= IDLE_OP;
			s_DATA_READ_REG					<= (OTHERS => '0');
			s_PACKET_SIZE_REG					<= (OTHERS => '0');
			s_PACKET_IP_REG					<= (OTHERS => '0');
			s_PACKET_PORT_REG					<= (OTHERS => '0');
			s_BUSY_REG							<= '0';
			s_ERROR_REG							<= '0';
			s_Sn_RSR_REG						<= (OTHERS => '0');
		ELSIF (i_CLK'EVENT AND i_CLK = '1' ) THEN
			s_CONFIG_REG						<= s_CONFIG_NEXT;
			s_MAIN_STATE_REG					<= s_MAIN_STATE_NEXT;
			s_MAIN_STATE_NEXT_REG			<= s_MAIN_STATE_NEXT_NEXT;
			s_OPERATION_REG					<= s_OPERATION_NEXT;
			s_INDEX_CONFIG_REG				<= s_INDEX_CONFIG_NEXT;
			s_Eth_RST_REG						<= s_Eth_RST_NEXT;
			s_DATA_READ_REG					<= s_DATA_READ_NEXT;
			s_CNT_CLK_REG						<= s_CNT_CLK_NEXT;
			s_CLK_DIV_REG						<= s_CLK_DIV_NEXT;
			s_WR_DONE_REG						<= s_WR_DONE_NEXT;
			s_RD_DATA_VALID_REG				<= s_RD_DATA_VALID_NEXT;
			s_OPERATION_STATE_REG			<= s_OPERATION_STATE_NEXT;
			s_ETH_IR_REG						<= s_ETH_IR_NEXT;
			s_PACKET_SIZE_REG					<= s_PACKET_SIZE_NEXT;
			s_PACKET_IP_REG					<= s_PACKET_IP_NEXT;
			s_PACKET_PORT_REG					<= s_PACKET_PORT_NEXT;
			s_BUSY_REG							<= s_BUSY_NEXT;
			s_ERROR_REG							<= s_ERROR_NEXT;
			s_Sn_RSR_REG						<= s_Sn_RSR_NEXT;
		END IF;
	END PROCESS;
	
	PROCESS(s_MAIN_STATE_REG, s_CONFIG_REG, s_MAIN_STATE_NEXT_REG, i_TX_START,s_Eth_RST_REG,  
			s_WR_DONE_REG, s_DATA_READ_REG, s_CLK_DIV_REG, s_RD_DATA_VALID_REG, s_DATA_IN,
			s_ETH_IR_REG, i_ETH_IR, s_TICK, s_BUSY_REG, s_INDEX_CONFIG_REG, s_PACKET_SIZE_REG,
			s_PACKET_IP_REG, s_PACKET_PORT_REG, s_ERROR_REG, s_Sn_RSR_REG, i_DATA
			)
	BEGIN
		s_BUSY_NEXT							<= '0';
		s_ERROR_NEXT						<= '0';
		s_CONFIG_NEXT.ADDRESS				<= s_CONFIG_REG.ADDRESS;
		s_CONFIG_NEXT.DATA					<= s_CONFIG_REG.DATA;
		s_CONFIG_NEXT.WR_EN					<= '0';
		s_CONFIG_NEXT.RD_EN					<= '0';
		s_INDEX_CONFIG_NEXT					<= s_INDEX_CONFIG_REG;
		s_Eth_RST_NEXT						<= '1';
		s_DATA_READ_NEXT					<= s_DATA_READ_REG;
		s_CLK_DIV_NEXT						<= s_CLK_DIV_REG;
		s_ETH_IR_NEXT						<= i_ETH_IR;
		s_TICK								<= '0';
		s_PACKET_SIZE_NEXT					<= s_PACKET_SIZE_REG;
		s_PACKET_IP_NEXT					<= s_PACKET_IP_REG;
		s_PACKET_PORT_NEXT					<=	s_PACKET_PORT_REG;
		s_MAIN_STATE_NEXT 					<= s_MAIN_STATE_REG;
		s_MAIN_STATE_NEXT_NEXT				<= s_MAIN_STATE_NEXT_REG;
		s_Sn_RSR_NEXT						<= s_Sn_RSR_REG;
		
		CASE s_MAIN_STATE_REG	IS
			WHEN RESET =>									--Reset Cycle Time
				s_CONFIG_NEXT	<= c_CONFIG_RESET;
				s_Eth_RST_NEXT 	<= '0';
				--s_BUSY_NEXT		<= '1';
				IF (s_CLK_DIV_REG = c_RESET_DELAY - 1 )  THEN		--  WAIT FOR AL LEAST 2us
					s_Eth_RST_NEXT 		<= '1';
					s_CLK_DIV_NEXT 		<= 0;
					s_MAIN_STATE_NEXT	<= PLL_DELAY;
				ELSE
					s_CLK_DIV_NEXT 		<= s_CLK_DIV_REG + 1;
				END IF;
-------------------------------------------------------------------------------
			WHEN PLL_DELAY =>
				s_CONFIG_NEXT		<= c_CONFIG_RESET;
				IF (s_CLK_DIV_REG = c_PLL_DELAY - 1) THEN		-- WAIT FOR AL LEAST 10ms
					s_CLK_DIV_NEXT 		<= 0;
					s_INDEX_CONFIG_NEXT	<= (OTHERS => '0');
					s_MAIN_STATE_NEXT 	<= CONFIGURE;
				ELSE
					s_CLK_DIV_NEXT 		<= s_CLK_DIV_REG + 1;
				END IF;
-------------------------------------------------------------------------------
			WHEN CONFIGURE =>
				IF (s_INDEX_CONFIG_REG = c_CONFIG'LENGTH - 1) THEN
					s_INDEX_CONFIG_NEXT 	<=  (OTHERS => '0');
					s_MAIN_STATE_NEXT 	<= SOCKET_IDLE;
				ELSE
					s_CONFIG_NEXT				<= c_CONFIG(TO_INTEGER(s_INDEX_CONFIG_REG));
					s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
					s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
					s_MAIN_STATE_NEXT_NEXT	<= CONFIGURE;
				END IF;
-------------------------------------------------------------------------------
			WHEN SOCKET_IDLE =>
				s_CONFIG_NEXT				<= c_CONFIG_RESET;
				s_MAIN_STATE_NEXT 		<= SOCKET_OPEN;
-------------------------------------------------------------------------------
			WHEN SOCKET_OPEN =>
				s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_OPEN;
				CASE s_INDEX_CONFIG_REG IS 
					WHEN x"0000" =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_MODE;
					WHEN x"0001" =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_PORT_NUM;
					WHEN x"0002" =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_OPEN;
					WHEN x"0003" =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_READ_Sn_SSR;
					WHEN x"0004" =>
						s_INDEX_CONFIG_NEXT	<= (OTHERS => '0');
						IF (s_DATA_READ_REG(7 DOWNTO 0) = SOCK_UDP(7 DOWNTO 0)) THEN
							s_MAIN_STATE_NEXT	<= SOCKET_REC_DATA_CHECK;		
						ELSE
							s_CONFIG_NEXT		<= c_CONFIG_SOCKET_CLOSE;
						END IF;
					WHEN OTHERS =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLOSE;
						s_MAIN_STATE_NEXT 		<= SOCKET_IDLE;
				END CASE;
-----------------------------------------------------------------------------------
			WHEN SOCKET_REC_DATA_CHECK =>
				s_ERROR_NEXT			<= '1';
				s_Sn_RSR_NEXT			<= s_Sn_RSR_REG(15 DOWNTO 0) & s_DATA_READ_REG;
				s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_REC_DATA_CHECK;
				CASE s_INDEX_CONFIG_REG IS
					WHEN x"0000" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_READ_Sn_Rx_RSR1;
					WHEN x"0001" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_READ_Sn_Rx_RSR2;
					WHEN x"0002" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_DUMMY_READ;
					WHEN x"0003" =>
						s_INDEX_CONFIG_NEXT	<= (OTHERS => '0');
						IF ( s_Sn_RSR_REG(23 DOWNTO 0)  /= x"000000") THEN
							s_MAIN_STATE_NEXT	<= SOCKET_REC_PACKET_INFO;
						ELSE
							s_MAIN_STATE_NEXT	<= SOCKET_SEND_DATA_CHECK;
						END IF;
					WHEN OTHERS =>
						s_INDEX_CONFIG_NEXT		<= (OTHERS => '0');
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLOSE;
						s_MAIN_STATE_NEXT 		<= SOCKET_IDLE;
				END CASE;
-------------------------------------------------------------------------------				
			WHEN SOCKET_REC_PACKET_INFO =>
				s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_REC_PACKET_INFO;
				CASE s_INDEX_CONFIG_REG IS 
					WHEN x"0000" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_READ_Sn_RX_FIFOR;
					WHEN x"0001" =>
						s_CONFIG_NEXT						<= c_CONFIG_SOCKET_READ_Sn_RX_FIFOR;
						s_PACKET_IP_NEXT(31 DOWNTO 16) 		<= s_DATA_READ_REG;
					WHEN x"0002" =>
						s_CONFIG_NEXT						<= c_CONFIG_SOCKET_READ_Sn_RX_FIFOR;
						s_PACKET_IP_NEXT(15 DOWNTO 0) 		<= s_DATA_READ_REG;
					WHEN x"0003" =>
						s_CONFIG_NEXT						<= c_CONFIG_SOCKET_READ_Sn_RX_FIFOR;
						s_PACKET_PORT_NEXT					<= s_DATA_READ_REG;
					WHEN x"0004" =>
						IF (s_DATA_READ_REG(0) = '0') THEN
							s_PACKET_SIZE_NEXT					<= UNSIGNED(s_DATA_READ_REG)/2;
						ELSE
							s_PACKET_SIZE_NEXT					<= (UNSIGNED(s_DATA_READ_REG) + 1)/2;
						END IF;
						s_INDEX_CONFIG_NEXT					<= (OTHERS => '0');
						s_MAIN_STATE_NEXT					<= SOCKET_REC_PACKET_DATA;
					WHEN OTHERS =>
						s_INDEX_CONFIG_NEXT		<= (OTHERS => '0');
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLOSE;
						s_MAIN_STATE_NEXT 		<= SOCKET_IDLE;
				END CASE;
--------------------------------------------------------------------------------------------------------------
			WHEN SOCKET_REC_PACKET_DATA =>
				s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_REC_PACKET_DATA;
				IF (s_INDEX_CONFIG_REG > s_PACKET_SIZE_REG) THEN
					s_CONFIG_NEXT			<= c_CONFIG_SOCKET_SET_RECEIVE_CMD;
					s_INDEX_CONFIG_NEXT		<= (OTHERS => '0');
					s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
					s_MAIN_STATE_NEXT_NEXT	<= SOCKET_SEND_DATA_CHECK;
				ELSE
					s_CONFIG_NEXT		<= c_CONFIG_SOCKET_READ_Sn_RX_FIFOR;
				END IF;
------------------------------------------------------------------------------------------
			WHEN SOCKET_SEND_DATA_CHECK =>
				IF (i_TX_START = '1') THEN
					s_MAIN_STATE_NEXT 		<= SOCKET_SEND_PACKET_INFO;
				END IF;
------------------------------------------------------------------------------------------
			WHEN SOCKET_SEND_PACKET_INFO =>
				s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_SEND_PACKET_INFO;
				CASE s_INDEX_CONFIG_REG IS 
					WHEN x"0000" =>
						s_CONFIG_NEXT	<= c_CONFIG_SOCKET_SET_DIPR1;
					WHEN x"0001" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_SET_DIPR2;
					WHEN x"0002" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_SET_DPORTR;
					WHEN x"0003" =>
						s_INDEX_CONFIG_NEXT	<= x"0010";
						s_MAIN_STATE_NEXT		<= SOCKET_SEND_PACKET_DATA;
					WHEN OTHERS =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLOSE;
						s_MAIN_STATE_NEXT 		<= SOCKET_IDLE;
				END CASE;
------------------------------------------------------------------------------------------
			WHEN SOCKET_SEND_PACKET_DATA => 
				s_BUSY_NEXT					<= '1';
				s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 16;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_SEND_PACKET_DATA;
				IF (s_INDEX_CONFIG_REG > G_NUM_BYTE_TO_SEND * 8) THEN
					s_INDEX_CONFIG_NEXT		<= (OTHERS => '0');
					s_MAIN_STATE_NEXT		<= SOCKET_SEND_PACKET_SIZE;
				ELSE
					s_CONFIG_NEXT.WR_EN		<= '1';
					s_CONFIG_NEXT.ADDRESS	<= Sn_TX_FIFOR_Addr;
					s_CONFIG_NEXT.DATA		<= i_DATA(TO_INTEGER(s_INDEX_CONFIG_REG)-1 DOWNTO TO_INTEGER(s_INDEX_CONFIG_REG)-16);
				END IF;
------------------------------------------------------------------------------------------
			WHEN SOCKET_SEND_PACKET_SIZE =>
				s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_SEND_PACKET_SIZE;
				CASE s_INDEX_CONFIG_REG IS
					WHEN x"0000" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_SET_WRSR1;
					WHEN x"0001" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_SET_WRSR2;
					WHEN x"0002" =>
						s_CONFIG_NEXT		<= c_CONFIG_SOCKET_SET_SEND;
					WHEN x"0003" =>
						s_INDEX_CONFIG_NEXT	<= (OTHERS => '0');
						s_MAIN_STATE_NEXT	<= SOCKET_COMPLETE_SENDING;
					WHEN OTHERS =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLOSE;
						s_MAIN_STATE_NEXT 		<= SOCKET_IDLE;
				END CASE;
-------------------------------------------------------------------------------
			WHEN SOCKET_COMPLETE_SENDING	=>
				s_CONFIG_NEXT			<= c_CONFIG_SOCKET_READ_IR;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_COMPLETE_SENDING;
				IF (s_DATA_READ_REG(4) = '0') THEN
					IF (s_DATA_READ_REG(3) = '1') THEN 
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLEAR_IR_TIMEOUT;
						--s_ERROR_NEXT			<= '1';
						s_MAIN_STATE_NEXT_NEXT	<= SOCKET_FINISH;
						--s_BUSY_NEXT				<= '0';
					END IF;
				ELSE
					s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLEAR_IR_SENDOK;
					--s_BUSY_NEXT				<= '0';
					s_MAIN_STATE_NEXT_NEXT	<= SOCKET_FINISH;
				END IF;				
-------------------------------------------------------------------------------			
			WHEN SOCKET_FINISH =>
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_FINISH;
				CASE s_INDEX_CONFIG_REG IS 
					WHEN x"0000" =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLEAR_IR_ALL;
						s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
					WHEN x"0001" =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLEAR_IRn_ALL;
						s_INDEX_CONFIG_NEXT		<= s_INDEX_CONFIG_REG + 1;
						s_MAIN_STATE_NEXT_NEXT	<= SOCKET_REC_DATA_CHECK;
					WHEN OTHERS =>
						s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLOSE;
						s_MAIN_STATE_NEXT 		<= SOCKET_IDLE;
				END CASE;
-------------------------------------------------------------------------------				
			WHEN SOCKET_CLOSE	=>
				s_CONFIG_NEXT			<= c_CONFIG_SOCKET_CLOSE;
				s_MAIN_STATE_NEXT 		<= SOCKET_WRITE_READ_WAIT;
				s_MAIN_STATE_NEXT_NEXT	<= SOCKET_OPEN;
---------------------------------------------------------------------------------------------------
			WHEN SOCKET_WRITE_READ_WAIT =>
				IF (s_WR_DONE_REG = '1') THEN
					s_MAIN_STATE_NEXT <= s_MAIN_STATE_NEXT_REG;
				END IF;
				IF (s_RD_DATA_VALID_REG = '1') THEN
					s_DATA_READ_NEXT	<= s_DATA_IN;
					s_MAIN_STATE_NEXT 				<= s_MAIN_STATE_NEXT_REG;
				END IF;
		END CASE;
	END PROCESS;
	
---------------------------------------------------------------------------------------------------------	
---------------------------------------------------------------------------------------------------------
	PROCESS(s_OPERATION_STATE_REG, s_OPERATION_REG, s_CNT_CLK_REG,
			  s_RD_DATA_VALID_REG, s_WR_DONE_REG, s_CONFIG_REG
			  )
	BEGIN
		s_OPERATION_STATE_NEXT			<= s_OPERATION_STATE_REG;
		s_OPERATION_NEXT				<= s_OPERATION_REG;
		s_CNT_CLK_NEXT					<= s_CNT_CLK_REG;
		s_RD_DATA_VALID_NEXT			<= '0';
		s_WR_DONE_NEXT					<= '0';
		CASE s_OPERATION_STATE_REG IS 
			WHEN IDLE_OP =>
				s_OPERATION_NEXT		<= c_IDLE_OPERATION;
				IF (s_CONFIG_REG.WR_EN = '1') THEN
					s_CNT_CLK_NEXT			<= (OTHERS => '0');
					s_OPERATION_STATE_NEXT 	<= WR_SETUP_OP;
				ELSIF (s_CONFIG_REG.RD_EN = '1') THEN
					s_CNT_CLK_NEXT			<= (OTHERS => '0');
					s_OPERATION_STATE_NEXT 	<= RD_SETUP_OP;
				END IF;
-------------------------------------------------------------------------------
			WHEN WR_SETUP_OP=>
				s_OPERATION_NEXT	<= c_WR_SETUP_OPERATION;
				IF (s_CNT_CLK_REG = c_SETUPT_HOLD_DELAY - 1) THEN
					s_CNT_CLK_NEXT				<= (OTHERS => '0');
					s_OPERATION_STATE_NEXT		<= WRITE_OP;
				ELSE 
					s_CNT_CLK_NEXT <= s_CNT_CLK_REG+1;
				END IF;
-------------------------------------------------------------------------------
			WHEN WRITE_OP => 
				s_OPERATION_NEXT	<= c_WR_OPERATION;
				IF (s_CNT_CLK_REG = c_WRITE_DELAY - 1) THEN
					s_CNT_CLK_NEXT				<= (OTHERS => '0');
					s_OPERATION_STATE_NEXT		<= WR_HOLD_OP;
				ELSE 
					s_CNT_CLK_NEXT <= s_CNT_CLK_REG+1;
				END IF;	
-------------------------------------------------------------------------------	
			WHEN WR_HOLD_OP => 
				s_OPERATION_NEXT	<= c_WR_HOLD_OPERATION;
				IF (s_CNT_CLK_REG = c_SETUPT_HOLD_DELAY - 1) THEN
					s_WR_DONE_NEXT				<= '1';
					s_OPERATION_STATE_NEXT		<= IDLE_OP;
				ELSE 
					s_CNT_CLK_NEXT <= s_CNT_CLK_REG+1;
				END IF;
-------------------------------------------------------------------------------	
			WHEN RD_SETUP_OP =>
				s_OPERATION_NEXT	<= c_RD_SETUP_OPERATION;
				IF (s_CNT_CLK_REG = c_SETUPT_HOLD_DELAY - 1) THEN
					s_CNT_CLK_NEXT				<= (OTHERS => '0');
					s_OPERATION_STATE_NEXT		<= READ_OP;
				ELSE 
					s_CNT_CLK_NEXT <= s_CNT_CLK_REG+1;
				END IF;
-------------------------------------------------------------------------------
			WHEN READ_OP => 
				s_OPERATION_NEXT	<= c_RD_OPERATION;
				IF (s_CNT_CLK_REG = c_READ_DELAY - 1) THEN
					s_CNT_CLK_NEXT				<= (OTHERS => '0');
					s_OPERATION_STATE_NEXT		<= RD_HOLD_OP;
				ELSE 
					s_CNT_CLK_NEXT <= s_CNT_CLK_REG+1;
				END IF;	
-------------------------------------------------------------------------------	
			WHEN RD_HOLD_OP => 
				s_OPERATION_NEXT	<= c_RD_HOLD_OPERATION;
				IF (s_CNT_CLK_REG = c_SETUPT_HOLD_DELAY - 1) THEN
					s_RD_DATA_VALID_NEXT		<= '1';
					s_OPERATION_STATE_NEXT		<= IDLE_OP;
				ELSE 
					s_CNT_CLK_NEXT <= s_CNT_CLK_REG+1;
				END IF;
		END CASE;
	END PROCESS;
-----------------------------------------------------------------------------------
	--ASSIGN DATA TO OUTPUT
	o_ETH_RST			<=	s_Eth_RST_REG;
	o_ETH_CS				<= s_OPERATION_REG.CS;
	o_ETH_RD 			<= s_OPERATION_REG.RD;
	o_ETH_WR 			<= s_OPERATION_REG.WR;
	o_ETH_ADD 			<= s_CONFIG_REG.ADDRESS;
	o_BUSY				<= s_BUSY_REG;
	o_ERROR				<= s_ERROR_REG;

END ARCH;


