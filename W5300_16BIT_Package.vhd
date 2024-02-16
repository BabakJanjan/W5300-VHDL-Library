--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 CONSTANTs, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

PACKAGE W5300_package IS
	TYPE 		Array_8Bit IS ARRAY(NATURAL RANGE<>) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
	--- Mode Register
	CONSTANT MR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"00"; -- Mode Register
--------------------------------------------------------------------------
--- Indirect Mode Registers
	CONSTANT IDM_AR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"02"; -- Indirect Mode Address Register
	CONSTANT IDM_DR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"04"; -- ndirect Mode Data Register
--------------------------------------------------------------------------
--- COMMON registers
	CONSTANT IR_Addr				: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"02"; -- Interrupt Register
	CONSTANT IMR_Addr				: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"04"; -- nterrupt Mask Register
	-- x"06" ,x"07" Reserved
	CONSTANT SHAR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"08"; -- Source Hardware Address Register
	CONSTANT SHAR2_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"0A";
	CONSTANT SHAR4_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"0C";
	-- x"0E" ,x"0F" Reserved
	CONSTANT GAR_Addr				: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"10"; -- Gateway Address Register
	CONSTANT GAR2_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"12";
	
	CONSTANT SUBR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"14"; -- Subnet Mask Register
	CONSTANT SUBR2_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"16";
	
	CONSTANT SIPR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"18"; -- Source IP Address Regsiter
	CONSTANT SIPR2_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"1A";
	
	CONSTANT RTR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"1C"; -- Retransmission Timeout-value Register
		
	CONSTANT RCR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"1E"; -- Retransmission Retry-count Register
	
	CONSTANT TMSR01_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"20"; -- Transmit Memory Size Register of SOCKET0
	CONSTANT TMSR23_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"22"; -- Transmit Memory Size Register of SOCKET2
	CONSTANT TMSR45_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"24"; -- Transmit Memory Size Register of SOCKET4
	CONSTANT TMSR67_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"26"; -- Transmit Memory Size Register of SOCKET6
	
	CONSTANT RMSR01_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"28"; -- Receive Memory Size Register of SOCKET0
	CONSTANT RMSR23_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"2A"; -- Receive Memory Size Register of SOCKET2
	CONSTANT RMSR45_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"2C"; -- Receive Memory Size Register of SOCKET4
	CONSTANT RMSR67_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"2E"; -- Receive Memory Size Register of SOCKET6
	
	CONSTANT MTYPER_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"30"; -- Memory Block Type Register
	
	CONSTANT PATR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"32"; -- PPPoE Authentication Register
	-- x"34" ,x"35" Reserved
	CONSTANT PTIMER_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"36"; -- PPP LCP Request Time Register
	CONSTANT PMAGICR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"38"; -- PPP LCP Magic Number Register
	-- x"3A" ,x"3B" Reserved
	CONSTANT PSIDR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"3C"; -- PPP Session ID Register
	-- x"3E" ,x"3F" Reserved
	CONSTANT PDHAR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"40"; -- PPP Destination Hardware Address Register
	CONSTANT PDHAR2_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"42";
	CONSTANT PDHAR4_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"44";
	-- x"46" ,x"47" Reserved
	CONSTANT UIPR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"48"; -- Unreachable IP Address Register
	CONSTANT UIPR2_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"4A";
	CONSTANT UPORT_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"4C"; -- Unreachable Port Number Register
	CONSTANT FMTUR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"4E"; -- Fragment MTU Register
	-- x"50" to x"5F" Reserved	
	CONSTANT P0_BRDYR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"60"; -- PIN "BRDY0" Configure Register
	CONSTANT P0_BDPTHR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"62"; -- PIN "BRDY0" Buffer Depth Register
	CONSTANT P1_BRDYR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"64"; -- PIN "BRDY1" Configure Register
	CONSTANT P1_BDPTHR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"66"; -- PIN "BRDY1" Buffer Depth Register
	CONSTANT P2_BRDYR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"68"; -- PIN "BRDY2" Configure Register
	CONSTANT P2_BDPTHR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"6A"; -- PIN "BRDY2" Buffer Depth Register
	CONSTANT P3_BRDYR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"6C"; -- PIN "BRDY3" Configure Register
	CONSTANT P3_BDPTHR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"6E"; -- PIN "BRDY3" Buffer Depth Register
	-- x"70" to x"FD" Reserved	
	CONSTANT IDR_Addr				: STD_LOGIC_VECTOR (9 DOWNTO 0) := "00"&x"FE"; -- W5300 ID Register
--------------------------------------------------------------------------
--- SOCKET registers
	CONSTANT Sn_MR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"00";
	
	CONSTANT Sn_CR_Addr  		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"02"; -- Reserved
	
	CONSTANT Sn_IMR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"04";
	
	CONSTANT Sn_IR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"06";
	
	CONSTANT Sn_SSR_Addr			: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"08";
	
	CONSTANT Sn_PORTR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"0A";
	
	CONSTANT Sn_DHAR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"0C";
	CONSTANT Sn_DHAR2_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"0E";
	CONSTANT Sn_DHAR4_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"10";
	
	CONSTANT Sn_DPORTR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"12";
	
	CONSTANT Sn_DIPR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"14";
	CONSTANT Sn_DIPR2_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"16";
	
	CONSTANT Sn_MSSR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"18";
	
	CONSTANT Sn_KPALVTR_Addr	: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"1A";
	
	CONSTANT Sn_PROTOR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"1B";
	
	CONSTANT Sn_TOSR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"1C";
	
	CONSTANT Sn_TTLR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"1E";
	
	CONSTANT Sn_TX_WRSR_Addr	: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"20";
	CONSTANT Sn_TX_WRSR2_Addr	: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"22";
	
	CONSTANT Sn_TX_FSR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"24";
	CONSTANT Sn_TX_FSR2_Addr	: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"26";
	
	CONSTANT Sn_RX_RSR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"28"; -- Reserved
	CONSTANT Sn_RX_RSR2_Addr	: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"2A";
	
	CONSTANT Sn_FRAGR_Addr		: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"2C";
	
	CONSTANT Sn_TX_FIFOR_Addr	: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"2E";
	
	CONSTANT Sn_RX_FIFOR_Addr	: STD_LOGIC_VECTOR (9 DOWNTO 0) := "10"&x"30";
	--
	-- Socket0 Start From x"200". Address x"232" to x"23F" Reserved.
	-- Socket1 Start From x"240". 
	-- Socket2 Start From x"280". 
	-- Socket3 Start From x"2C0". 
	-- Socket4 Start From x"300". 
	-- Socket5 Start From x"340". 
	-- Socket6 Start From x"380". 
	-- Socket7 Start From x"3C0". 
	
--------------------------------------------------------------------------	
-- The values of Sn_IR defintion 
-- *********************************
	CONSTANT Sn_IR_PRECV        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0080";   -- PPP receive bit of Sn_IR 
	CONSTANT Sn_IR_PFAIL        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0040";   -- PPP fail bit of Sn_IR 
	CONSTANT Sn_IR_PNEXT        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0020";   -- PPP next phase bit of Sn_IR 
	CONSTANT Sn_IR_SENDOK       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0010";   -- Send OK bit of Sn_IR 
	CONSTANT Sn_IR_TIMEOUT      : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0008";   -- Timout bit of Sn_IR 
	CONSTANT Sn_IR_RECV         : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0004";   -- Receive bit of Sn_IR 
	CONSTANT Sn_IR_DISCON       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0002";   -- Disconnect bit of Sn_IR 
	CONSTANT Sn_IR_CON          : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0001";   -- Connect bit of Sn_IR 

--	The values of Sn_SSR defintion 
--	**********************************
	CONSTANT SOCK_CLOSED        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000";   -- SOCKETn is released 
	CONSTANT SOCK_ARP           : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0001";   -- ARP-request is transmitted in order to acquire destination hardware address. 
	CONSTANT SOCK_INIT          : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0013";   -- SOCKETn is open as TCP mode. 
	CONSTANT SOCK_LISTEN        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0014";   -- SOCKETn operates as "TCP SERVER" and waits for connection-request (SYN packet) from "TCP CLIENT". 
	CONSTANT SOCK_SYNSENT       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0015";   -- Connect-request(SYN packet) is transmitted to "TCP SERVER". 
	CONSTANT SOCK_SYNRECV       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0016";   -- Connect-request(SYN packet) is received from "TCP CLIENT". 
	CONSTANT SOCK_ESTABLISHED   : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0017";   -- TCP connection is established. 
	CONSTANT SOCK_FIN_WAIT      : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0018";   -- SOCKETn is closing. 
	CONSTANT SOCK_CLOSING       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"001A";   -- SOCKETn is closing. 
	CONSTANT SOCK_TIME_WAIT     : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"001B";   -- SOCKETn is closing. 
	CONSTANT SOCK_CLOSE_WAIT    : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"001C";   -- Disconnect-request(FIN packet) is received from the peer. 
	CONSTANT SOCK_LAST_ACK      : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"001D";   -- SOCKETn is closing. 
	CONSTANT SOCK_UDP           : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0022";   -- SOCKETn is open as UDP mode. 
	CONSTANT SOCK_IPRAW         : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0032";   -- SOCKETn is open as IPRAW mode. 
	CONSTANT SOCK_MACRAW        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0042";   -- SOCKET0 is open as MACRAW mode. 
	CONSTANT SOCK_PPPoE         : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"005F";   -- SOCKET0 is open as PPPoE mode. 
                                                                           
	--	 The values of Sn_CR defintion                                     
	--	****************************
	CONSTANT Sn_CR_OPEN        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0001" ;   -- OPEN command value of Sn_CR.
	CONSTANT Sn_CR_LISTEN      : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0002" ;   -- LISTEN command value of Sn_CR.
	CONSTANT Sn_CR_CONNECT     : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0004" ;   -- CONNECT command value of Sn_CR.
	CONSTANT Sn_CR_DISCON      : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0008" ;   -- DISCONNECT command value of Sn_CR.
	CONSTANT Sn_CR_CLOSE       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0010" ;   -- CLOSE command value of Sn_CR.
	CONSTANT Sn_CR_SEND        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0020" ;   -- SEND command value of Sn_CR.
	CONSTANT Sn_CR_SEND_MAC    : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0021" ;   -- SEND_MAC command value of Sn_CR.
	CONSTANT Sn_CR_SEND_KEEP   : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0022" ;   -- SEND_KEEP command value of Sn_CR .
	CONSTANT Sn_CR_RECV        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0040" ;   -- RECV command value of Sn_CR .
	CONSTANT Sn_CR_PCON        : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0023" ;   -- PCON command value of Sn_CR .
	CONSTANT Sn_CR_PDISCON     : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0024" ;   -- PDISCON command value of Sn_CR .
	CONSTANT Sn_CR_PCR         : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0025" ;   -- PCR command value of Sn_CR .
	CONSTANT Sn_CR_PCN         : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0026" ;   -- PCN command value of Sn_CR .
	CONSTANT Sn_CR_PCJ         : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0027" ;   -- PCJ command value of Sn_CR .
--------------------------------------------------------------------------	
	CONSTANT Sn_MR_CLOSE       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0000" ;     -- Protocol bits of Sn_MR.
	CONSTANT Sn_MR_TCP         : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0001" ;     -- Protocol bits of Sn_MR.
	CONSTANT Sn_MR_UDP         : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0002" ;     -- Protocol bits of Sn_MR.
	CONSTANT Sn_MR_IPRAW       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0003" ;     -- Protocol bits of Sn_MR.
	CONSTANT Sn_MR_MACRAW      : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0004" ;     -- Protocol bits of Sn_MR.
	CONSTANT Sn_MR_PPPoE       : STD_LOGIC_VECTOR(15 DOWNTO 0) := x"0005" ;     -- Protocol bits of Sn_MR.

end W5300_package;

package body W5300_package is


 
end W5300_package;
