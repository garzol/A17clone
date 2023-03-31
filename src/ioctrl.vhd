----------------------------------------------------------------------------------
-- Company: AA55
-- Engineer: Pipo
-- 
-- Create Date:    22:22:37 10/09/2019 
-- Design Name: 
-- Module Name:    ioctrl - Behavioral 
-- Project Name: 
-- Target Devices: xc3S50
-- Tool versions: ISE14.7
-- Description:    emulation of A1752CF = ROM(2048x8)+RAM(128x4)+IO
--
-- Dependencies:   to be implemented with PCB: A1752_base V4 version 80 pins connector
--
-- Revision: 
-- Revision 0.01 - File Created
-- Revision 0.02 - File modified for new IOs
-- Additional Comments: 
--

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.Common.all;

-- use work.str_utils.all;   --conversion string<>slv

--how IOBUF works:
  --IO <= I when T = '0' else 'Z';
  --O <= IO;
  
--T   I   IO    O
--1   X   Z    IO
--0   1   1    1
--0   0   0    0

-- SelIOBank(0) : pin 89 (IO8_33)
-- SelIOBank(1) : pin 88 (IO9_33)

-- LatchIOBank(0) : pin 32 (IO10_33)
-- LatchIOBank(1) : pin 86 (IO11_33)

-- SELIODir : Pin 84 (IO12_33)

-- IOx(0) : P93  (IO0_33)
-- IOx(1) : P20  (IO1_33)
-- IOx(2) : P40  (IO2_33)
-- IOx(3) : P41  (IO3_33)
-- IOx(4) : P49  (IO4_33)
-- IOx(5) : P50  (IO5_33)
-- IOx(6) : P33  (IO6_33)
-- IOx(7) : P52  (IO7_33)




entity ioctrl is
    Port (
		SelIOBank   : out STD_LOGIC_VECTOR(1 DOWNTO 0);   --which bank is read in: 
			                                               --0 ==> 8 channels of bank are on the IOx bus
		LatchIOBank : out STD_LOGIC_VECTOR(1 DOWNTO 0);   --which bank to latch: 
		                                                  --apply a 0 for at least 20ns will latch
																		  --the 8 corresponding channels of IOx
		SELIODir    : out STD_LOGIC;                      --control the gate mosfet for actual output. 
		                                                  --0=>output active. Opposite of previous version                  
      IOx         : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);
      SYSCLK      : in  STD_LOGIC;
           nCKB : in  STD_LOGIC;
           CKA : in  STD_LOGIC;
           SPO : in  STD_LOGIC;
           nRRSEL : in  STD_LOGIC;
           nW_IO : in  STD_LOGIC;
			  nAB : IN STD_LOGIC_VECTOR(11 DOWNTO 1);
			  nDO : out STD_LOGIC_VECTOR(8 DOWNTO 1); --reverted to out only since ID HW modif
			  nID : IN STD_LOGIC_VECTOR(8 DOWNTO 1);   --first half of in data bus added on V3 HW
			  VS0 : out STD_LOGIC; -- added HW V3. led control
			  VS1 : out STD_LOGIC; -- added HW V3. led control
			  VS2 : out STD_LOGIC; -- added HW V3. led control
			  IDZ : out STD_LOGIC; -- added HW V3. To set ID bus in Hi-Z. 1=>HiZ, O=>Active
			  -- OUT_OPT1 : out STD_LOGIC; -- added HW V3.
			  OUT_OPT2 : out STD_LOGIC; -- added HW V3.
			  TXp : out STD_LOGIC; -- added HW V3 09/2022. Opt1_33  =fpga pin34 (IO_L05N_2).
			  RXp : in STD_LOGIC  -- added HW V3 03/2023. Optin4_33  =fpga pin39 (IP_2/VREF_2).
			  );
			   
end ioctrl;

architecture Behavioral of ioctrl is


component mak_ckab
    Port ( c_a : out  STD_LOGIC;
           nc_b : out  STD_LOGIC;
           SYSCLK : in  STD_LOGIC;
           rst : in  STD_LOGIC);
end component;

component clkgen 
    Port ( hiclk : in  STD_LOGIC;
	        c_a  : in  STD_LOGIC;
           nc_b : in  STD_LOGIC;
           nrst : in  STD_LOGIC;
           pps4_ph : out  pps4_ph_type;
			  diagclk  : out  STD_LOGIC);
end component;

COMPONENT TXFIFO
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC
  );
END COMPONENT;

COMPONENT A17INTERNROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

COMPONENT A17INTERNRAM 
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END COMPONENT;


component uart_rx is
 generic (
	g_CLKS_PER_BIT : integer := 2604   -- i.e. 19200bauds if clock at 50MHz Needs to be set correctly
	);
 port (
	i_clk       : in  std_logic;
	i_rx_serial : in  std_logic;
	o_rx_dv     : out std_logic;
	o_rx_byte   : out std_logic_vector(7 downto 0)
	);
end component uart_rx;
  

component uart_tx is
 generic (
	g_CLKS_PER_BIT : integer := 2604   -- Needs to be set correctly
	);
 port (
	i_clk       : in  std_logic;
	i_tx_dv     : in  std_logic;
	i_tx_byte   : in  std_logic_vector(7 downto 0);
	o_tx_active : out std_logic;
	o_tx_serial : out std_logic;
	o_tx_done   : out std_logic
	);
end component uart_tx;

component seta17io is
	port (
    i_Clk             : in  std_logic;
    i_SET_DV          : in  std_logic;
    o_TIO_ENABLE_SIG  : out std_logic; -- '0'->fpga io as output
	 o_IOLatchSig      : out std_logic_vector (1 downto 0); --'11' ensure output latches latched 
	 -- o_IOSelSig        : out std_logic_vector (1 downto 0); --'11' ensure input latches in HIZ 
	 -- o_SELIODir        : out std_logic; -- command of the general gate MOSFET 0->powered (ie output)
    o_IIO_VEC         : out std_logic_vector(7 downto 0); 
	 i16_Val           : in  std_logic_vector(15 downto 0) 
	);
end component seta17io;

signal CLK_DIV0 : unsigned (26 downto 0):=(others=>'0');
--signal last_clk22 : STD_LOGIC :='0';
signal last_clk23 : STD_LOGIC :='0';
signal last_clk24 : STD_LOGIC :='0';
signal ROM_Addr_Latch : std_logic_vector (10 downto 0);
signal is_ROM_Device_On : STD_LOGIC :='0';
signal ROM_used_at_least_once : STD_LOGIC :='0';
--signal IOD_used_at_least_once : STD_LOGIC :='0';

signal ROM_DOUT : STD_LOGIC_VECTOR(8 DOWNTO 1);

signal RAM_Addr_Latch : std_logic_vector (6 downto 0);
signal is_RAM_Device_On : STD_LOGIC :='0';
signal is_some_RAM_Device_On : STD_LOGIC :='0';
--signal RAMIOSEL : STD_LOGIC :='0';
signal RAM_nRW : STD_LOGIC_VECTOR(0 DOWNTO 0) := "0";  --read by default
signal RAM_DOUT : STD_LOGIC_VECTOR(4 DOWNTO 1);
signal RAM_DIN : STD_LOGIC_VECTOR(4 DOWNTO 1);

--management of the 10788 spying
signal is_10788_On : STD_LOGIC :='0';
signal IOCmd_10788 : STD_LOGIC_VECTOR(4 DOWNTO 1) := "0000";

--these signals are made for IO_xx working with IOBUF
signal is_IODevice_On : STD_LOGIC :='0';
signal IOCmd : STD_LOGIC :='0';
signal IONum : STD_LOGIC_VECTOR(3 DOWNTO 0);
signal IOBMl : STD_LOGIC_VECTOR(2 DOWNTO 1);
signal IIO_VEC : STD_LOGIC_VECTOR(7 DOWNTO 0) := "11111111";
--signal IIO_VEC_TST : STD_LOGIC_VECTOR(15 DOWNTO 0) := "1010101010101010";
signal OIO_VEC : STD_LOGIC_VECTOR(7 DOWNTO 0);
-- signal TIO_ENABLE_VEC : STD_LOGIC_VECTOR(7 DOWNTO 0); (obsolete in new hw)

-- TIO_ENABLE_SIG is an internal signal to a bunch of 8 T IOBUF that determines
-- the directions of IOs
-- TIO_ENABLE_SIG=0 determine the direction as FPGA writes to the port. 
-- but caution : seliodir will determine if actually the port is activated
-- TIO_ENABLE_SIG=1==>FPGA reads external port at init
signal TIO_ENABLE_SIG : STD_LOGIC :='1';




signal nDO_int : STD_LOGIC_VECTOR(8 DOWNTO 1);

--signal bugiosel3 : STD_LOGIC;

-----------------------------
--signals for controlling IOs
--IIO_MEM is the control value for IOs (set values)
--    it is named "I" because of I meaning of IOBUF which is actually an out
--    it is initialized with 1 because 
--    applying 1 to the individual MOSFET implies Z on the output
signal IIO_MEM : STD_LOGIC_VECTOR(15 DOWNTO 0) := "1111111111111111";

--OIO_MEM are the values read on the port
--    initial values are don't care since they are set by the port
--    as soon as they are read physically
--
--    This signal is probably useless
-- signal OIO_MEM : STD_LOGIC_VECTOR(15 DOWNTO 0) := "1111111111111111";
-----------------------------

--signal CK3MHZ : STD_LOGIC :='0';
signal pps4_phi : pps4_ph_type;


--when it's time to read an io
--start the process by setting callloadio to 1
--effect : 8 bits are given to the fpga
--then from callloadio routine callreadio is set 
--then the byte is actually latch
signal callloadio : STD_LOGIC :='0';
signal callreadio : STD_LOGIC :='0';
signal callclrdio : STD_LOGIC :='0';

--



--signal invCKA  : STD_LOGIC;
--signal invnCKB : STD_LOGIC;

--AB, W_IO, RRSEL, DO is negative logic
signal AB : std_logic_vector (11 downto 1);
signal ID : std_logic_vector (8 downto 1);
signal W_IO : STD_LOGIC;
signal RRSEL : STD_LOGIC;

--signal caintern  : STD_LOGIC;
--signal ncbintern : STD_LOGIC;

--uart sigs
-- constant c_CLKS_PER_BIT : integer := 2604;  --19200 bauds
constant c_CLKS_PER_BIT : integer := 434;      --115200 bauds

signal r_TX_DV     : std_logic := '0';    -- command start transmitting
signal r_TX_BYTE   : std_logic_vector(7 downto 0); -- byte to send
signal w_TX_DONE   : std_logic := '0';  -- rises when finished
signal w_TX_BUSY   : std_logic := '0';  -- 0 TX if available, 1 otherwise

signal w_RX_DV     : std_logic := '0';  --signal a byte received (stay 1 for 4 ticks)
signal w_RX_BYTE   : std_logic_vector(7 downto 0); -- byte read

signal RX_CMD      : std_logic_vector(7 downto 0) := (others=>'0'); -- byte command

type t_SM_Main is (s_Idle, s_Activate, s_Running);
signal r_SM_Main : t_SM_Main := s_Idle;
 
signal start_rx : STD_LOGIC :='0';




--signal dynDEVNUM : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0010"; --match against io device num (for test)

--IOLatchSig is the signal which is routed to outputs LatchIOBank
--LatchIOBank latches data on negative pulse -\_/- 
--Thus, rest is '1' for this signal
signal IOLatchSig : std_logic_vector (1 downto 0) := "11"; 
--idem for reading
signal IOSelSig   : std_logic_vector (1 downto 0) := "11"; 

signal last_pps4 : pps4_ph_type := idlexx;

signal diagAnB : STD_LOGIC := '0'; 

signal   diagnABzeroes : STD_LOGIC_VECTOR(11 DOWNTO 1) := (others => '0');
constant cdiagnABall1s : STD_LOGIC_VECTOR(11 DOWNTO 1) := (others => '1');
signal     diagnABones : STD_LOGIC_VECTOR(11 DOWNTO 1) := (others => '0');

signal diagbadram       :STD_LOGIC := '0';
signal diagbadrom       :STD_LOGIC := '0';
signal diagbadio        :STD_LOGIC := '0';
--signal diagio13rd       :STD_LOGIC := '1';
--signal diagio15rd       :STD_LOGIC := '1';
--signal diagioxxrd       :STD_LOGIC := '1';
signal diagioflsh       :STD_LOGIC := '0';
signal diagabflsh       :STD_LOGIC := '0';


--signal     diagIO0x2 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
--signal     diagIO0x3 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
--signal     diagIO0x4 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
--signal     diagIO0x6 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
--signal     diagIO0xD : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
signal     diagIDROM  : STD_LOGIC_VECTOR(7 DOWNTO 0) := (others => '0');
signal     diagIDRAM : STD_LOGIC_VECTOR(4 DOWNTO 1) := (others => '0');

--signal msglength : integer range 0 to 33 := 33;
-- constant Acc_msg   : String(1 to 44) := "A17 Clone V1.3"&CR&LF&"2023-02-20"&CR&LF&"rev 2"&CR&LF&"A1752CF"&CR&LF;
-- constant Acc_msg : std_logic_vector(0 to 71) := X"41"&X"42"&X"43"&X"44"&X"45"&X"46"&X"47"&X"13"&X"0A";
signal mystdmsg  : std_logic_vector(1 to 35*8) := (others=>'1');
--constant idstring: std_logic_vector(1 to 13*8) := X"56"&  --1er
--                                                  X"41"&
--                                                  X"31"&
--																  X"37"&
--																  X"35"&
--																  X"32"&
--																  X"43"&
--																  X"46"&  --8eme
--																  X"20"&   
--																  X"31"&
--																  X"32"&
--																  X"33"&
--																  X"13";  --13eme


--now we need memory to save display digits that will be snatched...
type   t_sreg is array(0 to 15) of std_logic_vector(3 downto 0);
signal RDA_data               : t_sreg;
signal RDB_data               : t_sreg;

--now we need memory to save RAM snatched...
type   t_sram is array(0 to 127) of std_logic_vector(3 downto 0);
signal RAM_data               : t_sram;


--signals for tx fifo
signal FIFO_DIN   : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal FIFO_DOUT  : STD_LOGIC_VECTOR(7 DOWNTO 0);

signal ISFIFOFULL : STD_LOGIC;
signal ISFIFOVOID : STD_LOGIC;
signal FIFORD : STD_LOGIC := '0';
signal FIFOWR : STD_LOGIC := '0';

-- Creates a 4x3 array for switch matrix 0 to 4 (S0..S4), 0 to 7 (R0..R7)
-- S0..S4<=>O0..O4
-- R0..R7<=>08..O15
type t_Row_Col   is array (0 to 4, 0 to 7) of integer range 0 to 3;
type t_BitSwitches is array (0 to 4)         of std_logic_vector(7 downto 0);
signal r_BitSwitches : t_BitSwitches := (others => (others => '0'));

--next 2 lines to avoid pointless warnings about black boxes (advice from https://www.xilinx.com/support/answers/9838.html)
attribute box_type : string; 
attribute box_type of A17INTERNROM : component is "black_box"; 
attribute box_type of A17INTERNRAM : component is "black_box"; 
attribute box_type of TXFIFO       : component is "black_box"; 

begin
	 --inversed logic -12V=1, 5V=0 but P-channel input => inverted signal
	 AB      <=  nAB;
	 W_IO    <=  nW_IO;
	 RRSEL   <=  nRRSEL;
	 ID      <=  nID;
	  
	 LatchIOBank <= IOLatchSig;  -- initialized at 11	 
    SelIOBank   <= IOSelSig;    -- initialized at 11  
	 
	 
	 
--  temporaire to avoid errors in generation
--  IDZ      <= '1'; --1=>HI-Z
--  OUT_OPT1 <= 'Z';
    OUT_OPT2 <= 'Z';
	 
	 
 -- clock divider
    process (SYSCLK)
    begin
        if (rising_edge(SYSCLK)) then
            CLK_DIV0 <= CLK_DIV0 + "1";
        end if;
    end process;
	 	 
	 process (SYSCLK)
	    variable pipovar : integer range 0 to 255 := 0;
		 variable IOLatchTime : integer range 0 to 8 := 0;
		 variable IOrdTime : integer range 0 to 8 := 0;
		 variable enlargesigbadram : integer range 0 to 1023 := 0;
		 variable enlargesigbadrom : integer range 0 to 511 := 0;
		 variable enlargesigbadio : integer range 0 to 511 := 0;
		 
		 -- variable delay_uart_start : integer range 0 to 1024 := 0;
		 variable index0 : integer range 0 to 2064 := 0;

		 variable iomem : unsigned (15 downto 0);

		 variable nbflsh : integer range 0 to 16 := 0;
		 
		 variable Sx : integer range 0 to 4;
		 variable Rx : integer range 0 to 7;
		 
		 variable r_switches : t_Row_Col;

		 
	 begin
	   if (rising_edge(SYSCLK)) then
			-- diag of nAB inputs
			-- we just check that all ABx inputs are bagotting
			diagnABzeroes <= diagnABzeroes or nAB;
			diagnABones   <= diagnABones   or (not nAB);

			if last_clk23 /= CLK_DIV0(23) and CLK_DIV0(23) = '1' then
				for S in 4 downto 0 loop
					for R in 7 downto 0 loop
						if r_switches(S, R) > 0 then
							r_switches(S, R) := r_switches(S, R)-1;
							r_BitSwitches(S)(R) <= '1';
						else
							r_BitSwitches(S)(R) <= '0';						
						end if;
					end loop;
				end loop;
			end if;
			-- last_clk22 <= CLK_DIV0(22);
			
			last_clk23 <= CLK_DIV0(23);
			if nbflsh > 0 then
				if last_clk23 /= CLK_DIV0(23) and CLK_DIV0(23) = '1' then
				   nbflsh := nbflsh - 1;
				end if;	
				if nbflsh > 6 then
					diagioflsh <= CLK_DIV0(23);
				else
					diagioflsh <= '0';
				end if;
         else				
				diagioflsh <= '0';
			end if;



			
			if SPO = '1' then --SPO is maintained by master device to -12V for 100ms min
				--do reset things
				RAM_nRW <= "0";
				is_some_RAM_Device_On <= '0';
				is_RAM_Device_On <= '0';
				is_ROM_Device_On <= '0';
				ROM_used_at_least_once  <= '0';
				--IOD_used_at_least_once  <= '0';
				is_IODevice_On <= '0';
				is_10788_On <= '0';
				last_pps4 <= idlexx;
				nDO_int <= (others => '0');
				IDZ     <= '1'; --1=>HI-Z
--				nDO_int <= (others => pinJ8);
				
				IOSelSig <= "11"; --It is probably initialized already
				SELIODir <= '1';	--allio are input at reset. 1 is input, 0 is output
--				TIO_ENABLE_VEC(15 downto 8) <= (others=>'0');	--all perso io are outputs at reset
				
				callloadio <= '0';
				callreadio <= '0';
				callclrdio <= '0';
				
				-- this part for initializing all IOs to 1
				if IOLatchSig = "11" then
					
					IOLatchSig <= "00"; --this is the only case where both lines should be activated
					-- because normally only 1 line is activated at a time, except at init where everything must 
					-- be set to 1 which is also the init value of IIO_MEM
					-- which is the location where the current value is retained in memory
					IIO_VEC <= "11111111";  -- Please, ensure this is consistent with IIO_MEM at init
					TIO_ENABLE_SIG <= '0';  --set internal IOs as outputs
					
				else
					IOLatchTime := IOLatchTime +1;
					if IOLatchTime = 2 then
					    IOLatchTime := 0;
						 IOLatchSig <= "11";
					    TIO_ENABLE_SIG <= '1'; --relax the IOs as inputs
					end if;
				end if;				
			
         -- end of SPO = 1 			
			else

				--start of latch management of IO on write
				--IOLatch is maintained to 1 for 2 clock cycles 
				if IOLatchSig /= "11" then
					IOLatchTime := IOLatchTime +1;
					if IOLatchTime = 4 then
					    IOLatchTime := 0;
						 IOLatchSig <= "11";
					    TIO_ENABLE_SIG <= '1';  --set internal IOs as inputs (IOx bus)
					end if;
				end if;
				--end of latch management of IO on write
				
				--start of IO reading
				if callloadio = '1' then
					callloadio <= '0'; --this is a state machine
					callreadio <= '1';					
					--disable latches
					IOLatchSig <= "11";
					--set T sig of fpga in read mode
					TIO_ENABLE_SIG <= '1'; --set IOs internally as input
					if IONum(3) = '1' then
						IOSelSig <= "01";   --activate IO8..15 bank
					else
						IOSelSig <= "10";   --activate IO0..7 bank
					end if;
				end if;
				if callreadio = '1' then
					callclrdio <= '1';
					callreadio <= '0'; --this is a state machine. reset
					--final step. We assign the accumulator with the right value
					nDO_int (4) <= not OIO_VEC(to_integer(unsigned(IONum(2 downto 0))));

					--internal diag, not used 
					--diagioxxrd <= not OIO_VEC(to_integer(unsigned(IONum(2 downto 0))));

					if OIO_VEC(to_integer(unsigned(IONum(2 downto 0)))) = '0' and nbflsh = 0 then
					   if to_integer(unsigned(IONum)) > 7 then
							nbflsh := to_integer(unsigned(IONum)) + 1;					  
						end if;
					end if;
					
					--logging
					if IIO_MEM(4) = '0' then
						Sx := 4;
					elsif IIO_MEM(3) = '0' then
						Sx := 3;
					elsif IIO_MEM(2) = '0' then
						Sx := 2;
					elsif IIO_MEM(1) = '0' then
						Sx := 1;
					elsif IIO_MEM(0) = '0' then
						Sx := 0;
					else 
						Sx := 4;
					end if;
					
					if IIO_MEM(4 downto 0) /= "11111" then
						Rx := to_integer(unsigned(IONum(2 downto 0)));
						if OIO_VEC(Rx) = '0' then
							--we now check that we are in IOx>7 (receivers) and not in reading senders
							if to_integer(unsigned(IONum)) > 7 then
								r_switches(Sx, Rx) := 3;
							end if;
						end if;
					end if;
					
					--for diag intern only
--					if IONum = "1111" then
--						diagio15rd <= not OIO_VEC(to_integer(unsigned(IONum(2 downto 0))));
--					elsif IONum = "1101" then
--						diagio13rd <= not OIO_VEC(to_integer(unsigned(IONum(2 downto 0))));
--					end if;
					--IOSelSig <= "11";   --deactivate IO0..7 bank

				end if;
				if callclrdio = '1' then
					IOrdTime := IOrdTime +1;
					if IOrdTime = 4 then
					    IOrdTime := 0;
						 callclrdio <= '0';

						--final step. We close enble sig
						IOSelSig <= "11";   --deactivate IO0..7 bank
						end if;
				end if;

				--end of IO reading
				
				if diagbadrom = '1' then
					enlargesigbadrom := enlargesigbadrom +1;
					if enlargesigbadrom = 255 then
					    enlargesigbadrom := 0;
						 diagbadrom <= '0';
					end if;
				end if;

				if diagbadram = '1' then
					enlargesigbadram := enlargesigbadram +1;
					if enlargesigbadram = 63 then
					    enlargesigbadram := 0;
						 diagbadram <= '0';
					end if;
				end if;
			
				if diagbadio = '1' then
					enlargesigbadio := enlargesigbadio +1;
					if enlargesigbadio = 63 then
					    enlargesigbadio := 0;
						 diagbadio <= '0';
					end if;
				end if;

			
				
				
				last_pps4 <= pps4_phi;
				
				if last_pps4 /= pps4_phi then

					case pps4_phi is
						when phi1A =>
--							  diagphi1A <= '1';

----                   3 next lines are not required. The value was latched in phi4
----                   and will be reset unconditionnaly in phi1
--							if (is_ROM_Device_On = '1') then
--								nDO_int <= ROM_DOUT; -- expose rom values as input of iobufs
--								--this value set started in phi4. bus will be deactivated in phi1
                     --I think that next instruction is useless but I am not sure
							is_ROM_Device_On <= '0'; --next clock this signal will be unconditionnaly reset
							if (is_ROM_Device_On = '1') then
								-- IDZ      <= '0'; --0=>active
--								--following lines for diag rom
--								diagADDRW <= ROM_Addr_Latch;
--								diagRAM_DIN <= ID;
								diagIDROM <= (nDO_int xor ID) or diagIDROM;
								if nDO_int /=  ID then
									diagbadrom <= '1';
								end if;
							end if;

							--we don't read AB8 anymore
							RAM_Addr_Latch <= AB(7 downto 1); 
                     --RAM is always in read mode unless specifically decided
							--during phi2 (at phi3A when sampling W_IO to see if its a write, to be precise)
							RAM_nRW <= "0";    
--							
--							RAMIOSEL <= W_IO; --0 means RAM, 1 means IO
							if W_IO = '0' then
								--all IO devices to be staying off
								is_IODevice_On <= '0';
								is_10788_On <= '0';
								--a RAM device is on. Is it us?
--								if (RRSEL = cRAMSEL) and (AB(8) = pinJ8) then
								if (RRSEL = cRAMSEL) then
									is_some_RAM_Device_On <= '1';
									if (AB(8) = cRAMAB8) then
										--yes, this is our RAM de
										is_RAM_Device_On <= '1';
									else
										is_RAM_Device_On <= '0';						
									end if;
								else
									is_some_RAM_Device_On <= '0';
									is_RAM_Device_On <= '0';	
								end if;
							else
								is_RAM_Device_On <= '0';						
								is_some_RAM_Device_On <= '0';
--								IOD_used_at_least_once <= '1'; --provisoire TEST
								--an IO device is called. We will know if it's us
								--by reading rom data value
--								case ID(8 downto 5) is
--									when "0010" =>
--										diagIO0x2 <= std_logic_vector(unsigned(diagIO0x2)+1);
--									when "0011" =>
--										diagIO0x3 <= std_logic_vector(unsigned(diagIO0x3)+1);
--									when "0100" =>
--										diagIO0x4 <= std_logic_vector(unsigned(diagIO0x4)+1);
--									when "0110" =>
--										diagIO0x6 <= std_logic_vector(unsigned(diagIO0x6)+1);
--									when "1101" =>
--										diagIO0xD <= std_logic_vector(unsigned(diagIO0xD)+1);
--									when others =>
--										null;
--								end case;
								
								
								if (ID(8 downto 5) = cDEVNUM) then
--								if (ID(8 downto 5) = dynDEVNUM) then
									--yes this is our io device id...
									--get the command from ODO_VEC(0): 0:SES or 1:SOS
									--command which will be executed at next phi2
									IOCmd <= ID(1);
									IONum(3 downto 0) <= AB(4 downto 1);
--									bugiosel3 <= not AB(4);
									IOBMl <= AB(6 downto 5);
									is_10788_On <= '0';
									is_IODevice_On <= '1';
									--IOD_used_at_least_once <= '1';
								elsif (ID(8 downto 5) = "1101") then
									--let's snatch the 10788									
									is_IODevice_On <= '0';
									is_10788_On <= '1';
									--cmd KLA=1110, KLB=1101, KDN=0011, KER=0110
									IOCmd_10788 <= ID(4 downto 1);	 --KLA, or KLB, or etc... 								
								else
									is_IODevice_On <= '0';
									is_10788_On <= '0';								
								end if;
							end if;
--							
						when phi1 =>
--							  diagphi1 <= '1';

--							is_ROM_Device_On <= '0';

							nDO_int <= (others => '0'); --bus data is hiz during phi1 (and also phi3)
							IDZ      <= '1'; --1=>HI-Z

--							nDO_int <= (others => pinJ8); --bus data is hiz during phi1 (and also phi3)
						when phi2 =>
--							  diagphi2 <= '1';

							--from beginning of phi2 till end of phi3A we have to drive
							--RAM D1..D4 or I/O D1..D4 or nothing
							if is_RAM_Device_On = '1' then --RAM selected (during phi1A)
--								RAM_nRW <= "0"; --was already set unconditonnaly during phi1A, with ram addr
								IDZ      <= '0'; --0=>active
								pipovar := to_integer(unsigned(RAM_Addr_Latch));
								nDO_int (4 downto 1) <= RAM_Data(pipovar); 
								nDO_int (4 downto 1) <= RAM_DOUT; --RAM_DOUT is read from CFRAM(RAM_ADDR_Latch)
								--to be continued in phi3A part dedicated to ram,which means that the only thing to do is to rest T lines to 1 at the
								--beginning of phi3. That's very simple in fact.
							
							elsif is_IODevice_On = '1' then
								--we are to load accumulator to value of IO(IONum)
								if IOBMl = "00" then
									--let's activate the reading of IOx(x=IONum)
									--then, we will assign nDO_int (4) to not this value
									--nDO_int (4) <= not IOx_in; 
									callloadio <= '1';
									IDZ        <= '0'; --0=>active
									--diag the problem that i had once
--									if IONum(3 downto 0) = "1000" then
--										null;
----										if pinJ9 = IOx_in then
----											calltoio0 <= '1';
----										end if;
--									elsif IONum(3 downto 0) = "0000" then
--										calltoio8 <= not calltoio8;
--									end if;
									--end diag
								end if;
							end if;
							
						when phi3A =>
--							  diagphi3A <= '1';
							--A17 samples addr for next rom delivering
							ROM_Addr_Latch <= AB;
							if RRSEL = cROMSEL then
								is_ROM_Device_On <= '1';
								ROM_used_at_least_once <= '1'; 
							else 
								is_ROM_Device_On <= '0';				
							end if;
							--RAM device selected? (tested during previous phi1A)
							if (is_RAM_Device_On = '1') then  
								--do we have to write to A17's ram?
								if W_IO = '1' then  --it is a write 
									--added for spying and displaying infos to wifi  RAM_Addr_Latch is vector 6 downto 0
									--we use pipovar to avoid a weird warning
									pipovar := to_integer(unsigned(RAM_Addr_Latch));
									RAM_Data(pipovar) <= ID(8 downto 5);
									RAM_DIN <= ID(8 downto 5); 
									RAM_nRW <= "1";   --we will have to reset this signal to 0 the sooner the better
									                  --need to be set for at least 1 or 2 sysclk, (2 to be sure)
															--but 1 should be enough
															--actually we will reset it at the next phi, that will be fine
								end if;
								diagIDRAM <= (nDO_int(4 downto 1) xor ID(4 downto 1)) or diagIDRAM;
								if nDO_int(4 downto 1) /=   ID(4 downto 1) then
									diagbadram <= '1';
								end if;
							elsif is_IODevice_On = '1' then
								--starts by diag io
								if IOBMl = "00" then
									if nDO_int (4) /= ID(4) then
										diagbadio <= '1';
									end if;
								end if;
								--lets read the accumulator from DO8 
								--to get the param
								--IOCmd contains ses or sos
								if IOCmd = cSES then -- cste cSES set at 0 which is 
									--D04=1 :  enable all outputs
									--DO4=0 : disable all outputs ==> all Ts configured as input (T=1)
									--(T=0: outputs, T=1: inputs)
									--CtrlIODIR=1: IOs as input, CtrlIODIR=0: IOs as output
									if ID(8) = '0' then --set IOs as outputs
										--That means : set IOs as output if out from fpga=1
										--When fpga out is 0, out mosfet is off then we shall be in input mode
										--in order to catch the state of the pin coming from the outside
										--Thus, we have to set T(x)<=0 if OIO_VEC=1 and T(x)<=1 otherwise
										-- which is equiv to T<=not OIO
--										TIO_ENABLE_VEC <= not OIO_VEC; 
										SELIODir <= '0';	--allio are input at reset. 0 is output, 1 is input
									else
										--disable all outputs
										SELIODir <= '1';	--allio are input at reset. 0 is output, 1 is input
									end if;								
								else
									--cSOS
									if IOBMl = "00" then
										
										-- IOx_out <=  not ID(8);  -- obsolete old hw
										iomem := unsigned(IIO_MEM);
										iomem(to_integer(unsigned(IONum))) := not ID(8);
										IIO_MEM <= std_logic_vector(iomem);  
										
										
										
										--we need to initiate the latching (2 cycles at 50MHz should be enough)
										--signal will be reset after counting 2 clock cycles
										IOLatchSig(1) <= not IONum(3);
										IOLatchSig(0) <= IONum(3);
					               TIO_ENABLE_SIG <= '0'; --set IOs internally as outputs
										if IONum(3) = '1' then
											IIO_VEC <= std_logic_vector(iomem(15 downto 8));
										else
											IIO_VEC <= std_logic_vector(iomem(7 downto 0));
										end if;
--										IIO_VEC(to_integer(unsigned(IONum))) <=  ID(8);
--										IIO_VEC(to_integer(unsigned(IONum))) <= not IIO_VEC(to_integer(unsigned(IONum)));
									end if;
								end if; --endif of if cSES
							end if; --endif of if is_RAM_Device_On else is_IODevice_On
							
							--management of 10788 snatching
							if is_10788_On = '1' then
								if    IOCmd_10788 = cKLA then
									for I in 14 downto 0 loop
										RDA_data(I+1)<=RDA_data(I);
									end loop;
									RDA_data(0)  <= ID(8 downto 5);

								elsif IOCmd_10788 = cKLB then
									for I in 14 downto 0 loop
										RDB_data(I+1)<=RDB_data(I);
									end loop;
									RDB_data(0)  <= ID(8 downto 5);

								end if;
							end if;
							is_some_RAM_Device_On <= '0';
							is_RAM_Device_On <= '0';
							is_IODevice_On <= '0';
							is_10788_On <= '0';
							
							
						when phi3 =>
--							 diagphi3 <= '1';
							--we just have to put DO in input mode
							nDO_int <= (others => '0');
							IDZ     <= '1'; --1=>HI-Z

--							nDO_int <= (others => pinJ8);
							RAM_nRW <= "0";						
--							IONum(3) <= '1';    --je comprends pas cette ligne ==>comment (20220306) 
						when phi4 =>
--							  diagphi4 <= '1';
							  
							  
							--A17 push rom data on the bus from begin of phi4 thru end of phi1A
							if (is_ROM_Device_On = '1') then
								IDZ      <= '0'; --0=>active
								nDO_int <= ROM_DOUT; -- expose rom values as input of iobufs
								--this value set continues in phi1A. bus will be deactivated in phi1
							
							end if;
							RAM_nRW <= "0";	 --just in case, but it is not necessary					
							 
						when others =>
							null;					
					end case;
				end if;
			end if;
		end if;
	 end process;



--	



-- trigger text sending
-- commented out for souvenir
--	 process (SYSCLK)
--		 variable local_last_clk23 : STD_LOGIC := '0';
--		 -- variable first_time       : STD_LOGIC := '1';
--	 begin	 
--	   if (rising_edge(SYSCLK)) then
--			if local_last_clk23 /= CLK_DIV0(23) and CLK_DIV0(23) = '1' then
----				if first_time = '1' then
----					msglength <= Acc_msg'LENGTH;
----					mystdmsg(1 to 8*Acc_msg'LENGTH) <= str_to_slv(Acc_msg);					
----					first_time := '0';
----				else
--					msglength <= 33;
--					--5 bytes, rank 1
--					mystdmsg(1 to 8*5) <= X"44"&diagIDROM&"0000"&diagIDRAM&"10101"&(diagnABzeroes and diagnABones);				
--					--1 byte, rank 6
--					mystdmsg(8*5+1 to 8*6) <= X"41";
--					--8 bytes, rank 7
--					for K in 0 to 15 loop
--						mystdmsg(8*6+1+4*K to 8*6+4*(K+1)) <= RDA_data(K);
--					end loop;
--					--1 byte, rank 15
--					mystdmsg(8*14+1 to 8*15) <= X"42";
--					--8 bytes, rank 16
--					for K in 0 to 15 loop
--						mystdmsg(8*15+1+4*K to 8*15+4*(K+1)) <= RDB_data(K);
--					end loop;
--					mystdmsg(8*23+1 to 8*27) <= X"43"&RAM_Data(16#0A#)&RAM_Data(16#0B#)&RAM_Data(16#6A#)&RAM_Data(16#7B#)&RAM_Data(16#2A#)&RAM_Data(16#2B#);
--					-- S for switches (hex 53)
--					mystdmsg(8*27+1 to 8*33) <= X"53"&r_BitSwitches(0)&r_BitSwitches(1)&r_BitSwitches(2)&r_BitSwitches(3)&r_BitSwitches(4);
--					
--				-- end if;
--				start_rx <= '1';
--			else
--				start_rx <= '0';
--			end if;
--			local_last_clk23 := CLK_DIV0(23);
--		end if;
--	 end process;
-- end commented out for souvenir

-- send text actions
-- commented out for souvenir
--	 process (SYSCLK)
--
--	    constant mLF       : std_logic_vector(1 to 8) := X"0A"; --mLF because LF already exists for chars
--	    constant mCR       : std_logic_vector(1 to 8) := X"13";
--		 variable ichar     : integer range 0 to 1024 := 0;
--       -- constant Message1  : String(1 to 13) := "Hello, World!";
--       -- constant Message2  : String(1 to 14) := "ABCDEFGHIJKLMN";
--       -- constant Message3  : String(1 to 16) := "1234567890123456";
--       -- constant Mesprompt : String(1 to 5) := CR&LF&" > ";
--       -- constant Mesrrsel1 : String(1 to 11) := "SET RRSEL"&CR&LF;
--       -- constant Mesrrsel0 : String(1 to 13) := "RESET RRSEL"&CR&LF;
--		 -- constant Messagerr : String(1 to 16) := "Start rom read"&CR&LF;
--		 -- variable Message   : String(1 to 64);
--		 -- variable mychar    : Character;
--		 -- variable mystring2 : String(1 to 1) := "x";
--		 -- variable message5  : String(1 to 10) := "12345"&"67890";
--	 begin
--      if rising_edge(SYSCLK) then
--			case r_SM_Main is
--				 when s_Idle =>
--					if start_rx = '1' then 
--						r_SM_Main <= s_Activate;
--
--						ichar := 0;
--						-- msglength := Acc_msg'LENGTH;
--						-- mystdmsg(1 to 8*msglength) := str_to_slv(Acc_msg);
--
--					else
--						null;
--					end if;  --	end if start_rx 
--
--				 when s_Activate =>      --set parameters for transfer
--					  ichar := ichar + 1;
--					  if ichar <= msglength then -- there are chars left to send
--						  r_TX_DV <= '1';
--						  r_TX_BYTE <= mystdmsg(8*ichar-7 to 8*ichar);
--						  r_SM_Main <= s_Running;
--					  else
--						  r_TX_DV <= '0';
--						  r_SM_Main <= s_Idle;
--								
--					  end if;
--						
--				 when s_Running =>
--						if w_TX_DONE = '1' then -- previous char has been sent
--							r_TX_DV <= '0';
--							r_SM_Main <= s_Activate;
--						else
--							r_SM_Main <= s_Running;
--						end if;													
--				 when others =>
--					r_TX_DV <= '0';
--					r_SM_Main <= s_Idle;
--				 
--				 
--			end case;
--		end if;	
--			
--	 end process;
-- end of commented out for souvenir


	 process (SYSCLK)
		 variable local_last_clk23 : STD_LOGIC := '0';
		 -- variable first_time       : STD_LOGIC := '1';
		 variable byt_num          : integer range 0 to 127 := 0;
		 variable bn2              : integer range 0 to 31  := 0;
	 begin	 
	   if (rising_edge(SYSCLK)) then
			if local_last_clk23 /= CLK_DIV0(23) and CLK_DIV0(23) = '1' then
				byt_num := 0;
--				if first_time = '1' then
--					msglength <= Acc_msg'LENGTH;
--					mystdmsg(1 to 8*Acc_msg'LENGTH) <= str_to_slv(Acc_msg);					
--					first_time := '0';
--				else
					--msglength <= 33;
					--5 bytes, rank 1
					mystdmsg(1 to 8*5) <= X"44"&diagIDROM&"0000"&diagIDRAM&"10101"&(diagnABzeroes and diagnABones);				
					--1 byte, rank 6
					mystdmsg(8*5+1 to 8*6) <= X"41";
					--8 bytes, rank 7
					for K in 0 to 15 loop
						mystdmsg(8*6+1+4*K to 8*6+4*(K+1)) <= RDA_data(K);
					end loop;
					--1 byte, rank 15
					mystdmsg(8*14+1 to 8*15) <= X"42";
					--8 bytes, rank 16
					for K in 0 to 15 loop
						mystdmsg(8*15+1+4*K to 8*15+4*(K+1)) <= RDB_data(K);
					end loop;
					mystdmsg(8*23+1 to 8*27) <= X"43"&RAM_Data(16#0A#)&RAM_Data(16#0B#)&RAM_Data(16#6A#)&RAM_Data(16#7B#)&RAM_Data(16#2A#)&RAM_Data(16#2B#);
					-- S for switches (hex 53)
					mystdmsg(8*27+1 to 8*33) <= X"53"&r_BitSwitches(0)&r_BitSwitches(1)&r_BitSwitches(2)&r_BitSwitches(3)&r_BitSwitches(4);
					-- V for version
					mystdmsg(8*33+1 to 8*35) <= X"56"&X"55";
					
				-- end if;
				-- start_rx <= '1';
			else
				-- start_rx <= '0';
				if FIFOWR = '1' then
					FIFOWR <= '0';
				else
					if byt_num < 35 then
						FIFOWR <= '1';
						FIFO_DIN <= mystdmsg(1+byt_num*8 to (byt_num+1)*8);
						byt_num := byt_num+1;	
--					elsif byt_num < 33+13 then
--						bn2 := byt_num - 33;
--						FIFOWR <= '1';
--						FIFO_DIN <= idstring(1+bn2*8 to (bn2+1)*8);
--						byt_num := byt_num+1;						
					end if;
				end if;
				
			end if;
			local_last_clk23 := CLK_DIV0(23);
		end if;
	 end process;


-- send uart by reading fifo
-- set by user : r_TX_DV; to be set to '0' when w_TX_DONE is read to '1' (or at init)
--                        to be set to '1' for transmitting
-- In the uart impl, one sees that after w_TX_DONE goes to 1 it is kept to 1 for one cycle before reset to 0

	 process (SYSCLK)
	 begin
      if rising_edge(SYSCLK) then
			-- reset this signal 1 clock after setting it
			if FIFORD  = '1' then
				FIFORD <= '0';
				r_TX_DV <= '1'; --say uart is busy	
				r_TX_BYTE <= FIFO_DOUT;
			else
				-- get ready to send another byte because the uart is free
				if w_TX_DONE  = '1' then
					r_TX_DV <= '0';
				elsif r_TX_DV = '0' and ISFIFOVOID = '0' then
					-- the fifo contains bytes and the uart is available
					-- send byte
					FIFORD <= '1';		
				end if;
			end if;
		end if;
	 
	 end process;

    --RX handling
	 process (SYSCLK)
	 begin
      if rising_edge(SYSCLK) then
			if w_RX_DV = '1' then
				RX_CMD <= w_RX_BYTE;
				-- RX_CMD <= X"30";
--				if RX_CMD = X"30" then
--					RX_CMD <= X"31";
--				else
--					RX_CMD <= X"30";
--				end if;
			end if;			
		end if;
	 end process;
	

	
	GEN_IO: 
		for I in 0 to 7 generate
			iobufx : iobuf port map
						 (O=>OIO_VEC(I), IO=>IOx(I), I=> IIO_VEC(I), T=>TIO_ENABLE_SIG);  
		end generate GEN_IO;
	
	
--  IIO_VEC_TST(0) <= diagbadrom; --diago0;
--	 IIO_VEC_TST(1) <= is_ROM_Device_On;
--	 IIO_VEC_TST(2) <= diagbadram;
--	 IIO_VEC_TST(3) <= is_RAM_Device_On;
--	 IIO_VEC_TST(14) <= not CLK_DIV0(23);

--    bugiosel3 <= not IONum(3);
--	 IOSel <= IONum;
--	 IIO_VEC(15) <= notIONum(3);
	 
--	 IIO_VEC(14) <= not CLK_DIV0(23);
--	 IIO_VEC(13) <= CLK_DIV0(22);
--	 IIO_VEC(12) <= not CLK_DIV0(22);
--	 IIO_VEC(11) <= is_10788_On;
--	 IIO_VEC(10) <= is_IODevice_On;
--	 IIO_VEC(9)  <= is_RAM_Device_On;
--	 IIO_VEC(8)  <= is_ROM_Device_On;
--	 IIO_VEC(8)  <= calltoio8;
--	 IODIR <= calltoio8;   -- IODIR is deceiving name. No mean was OPTO in the past
	 	 
	 
--	 D5    : div5 PORT MAP(SYSCLK, CK3MHZ);
	 CFROM : A17INTERNROM PORT MAP (SYSCLK, ROM_Addr_Latch, ROM_DOUT);
	 CFRAM : A17INTERNRAM PORT MAP (SYSCLK, RAM_nRW, RAM_Addr_Latch(6 downto 0), RAM_DIN, RAM_DOUT);
	 

    TXBUF : TXFIFO       PORT MAP (
										    clk => SYSCLK,
										    rst => '0',
										    din => FIFO_DIN,
										    wr_en => FIFOWR,
										    rd_en => FIFORD,
										    dout => FIFO_DOUT,
										    full =>  ISFIFOFULL,
										    empty => ISFIFOVOID
									       );
  
--	 CFROMCE : A17INTERNROMCE PORT MAP (SYSCLK, ROM_Addr_Latch, ROMCE_DOUT);
--	 CFRAMCE : A17INTERNRAMCE PORT MAP (SYSCLK, RAMCE_nRW, RAM_Addr_Latch, RAM_DIN, RAMCE_DOUT);

--    GENAB : mak_ckab     PORT MAP (caintern, ncbintern, CK3MHZ, '1');
--	 PHIGN : clkgen       port map (hiclk=>SYSCLK, c_a=> not CKA, nc_b=> not nCKB, 
	 PHIGN : clkgen       port map (hiclk=>SYSCLK, c_a=> not CKA, nc_b=> not nCKB, 
	                                nrst=>'1', pps4_ph=>pps4_phi, diagclk=>diagAnB); 



  -- Instantiate UART transmitter
  UART_TX_INST : uart_tx
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
      i_clk       => SYSCLK,
      i_tx_dv     => r_TX_DV,    -- command start transmitting
      i_tx_byte   => r_TX_BYTE,  -- byte to send
      o_tx_active => w_TX_BUSY,  -- on s'en fout c'est l'image des bits a transmettre
      o_tx_serial => TXp,         -- port tx
      o_tx_done   => w_TX_DONE   -- rises when finished (lasts 1 ticks by def)
      );



  -- Instantiate UART receiver
  UART_RX_INST : uart_rx
    generic map (
      g_CLKS_PER_BIT => c_CLKS_PER_BIT
      )
    port map (
      i_clk       => SYSCLK,
      i_rx_serial => RXp,         -- port tx
      o_rx_dv     => w_RX_DV,    -- command start transmitting
      o_rx_byte   => w_RX_BYTE  -- byte to read
      );



--	DIAGRAM : A17DGRAM
--	  PORT MAP (
--		 clka => SYSCLK,
--		 wea => diagRAM_nRW,
--		 addra => diagADDR,
--		 dina => diagRAM_DIN,
--		 douta => diagRAM_DOUT
--	  );
--

--	DIAGRAM : A17DGRAM
--	  PORT MAP (
--		 clka => SYSCLK,
--		 wea => "1",
--		 addra => diagADDRW,
--		 dina => diagRAM_DIN,
--		 clkb => SYSCLK,
--		 addrb => diagADDRR,
--		 doutb => diagRAM_DOUT
--	  );
	  
	  
--	 nDO <= (others=>'1'); --to be replace by nDO_int when it's working 
--	 nDO <= (others=>CLK_DIV0(7)); --to be replace by nDO_int when it's working 
	 nDO <= not nDO_int;  
--	 TESTLED <= '0' when pps4_phi = phi3A else '1'; 
--	 TESTLED <= not is_IODevice_On; 
--	 TESTLED <= is_IODevice_On; 
--	 TESTLED <= is_RAM_Device_On; --CLK_DIV0(23); 
--	 TESTLED <= is_ROM_Device_On; --CLK_DIV0(23); 

--	 VS0     <= diagbadio; --diagses;
--	 VS0     <= (not diagbadio or not CLK_DIV0(23)) and (IOD_used_at_least_once or not CLK_DIV0(25));
--  VS0     <= IOLatchSig(0);
	 
--	 VS1     <= is_RAM_Device_On;
--  VS1     <= IIO_VEC(3);


 -- diag management with VSs leds
    process (SYSCLK)
	 	  variable nbflshab : integer range 0 to 32 := 0;
    begin
        if (rising_edge(SYSCLK)) then
		       --in VHDL2008 (and vectorx) is the bitwise and of all bits of vectors
				 --but it rises an error
				 last_clk24 <= CLK_DIV0(24);
				 if nbflshab > 0 then
					 if last_clk24 /= CLK_DIV0(24) and CLK_DIV0(24) = '1' then
						 nbflshab := nbflshab - 1;
					 end if;	
					 if nbflshab > 4 then
						 diagabflsh <= CLK_DIV0(24);
					 else
						 diagabflsh <= '0';
					 end if;
				 else				
					 diagabflsh <= '0';
				 end if;
				 if (diagnABzeroes and diagnABones) /= cdiagnABall1s and nbflshab = 0 then
						for J in 11 downto 1 loop
							if (diagnABzeroes(J) and diagnABones(J)) = '0' then
								nbflshab	:= J+4;
							end if;
						
						end loop;	
				 end if;



             if nbflshab > 0 then
						VS1 <= not diagabflsh;
				 else
						VS1 <= (not diagbadrom) and (ROM_used_at_least_once or not CLK_DIV0(23));
				 end if;
				 
				 if SPO = '1' then
						VS0 <= CLK_DIV0(21);
				 else
						VS0 <= ((not diagAnB) and  CLK_DIV0(23)) or ((diagAnB) and  CLK_DIV0(26));
				 end if;
        end if;
    end process;

	 VS2 <= '0' when RX_CMD = X"30" else
	        '1' when RX_CMD = X"31" else
--			  not RXp;
			  not diagioflsh;
			   


--	 VS2 <=  RXp;
--	 VS2 <= not diagio13rd;
--	 VS1 <= not diagio15rd;

--  diagAnB = 1 if clk A and B are OK
--	 VS0     <= ((not diagAnB) and  CLK_DIV0(23)) or ((diagAnB) and  CLK_DIV0(26));

--	 INITLED <= diagAnB; -- or ( pinJ8 and CLK_DIV0(24) ) or ( pinJ9 and CLK_DIV0(27) ); 
--	 INITLED <= not diagbadram; 


--
end Behavioral;
