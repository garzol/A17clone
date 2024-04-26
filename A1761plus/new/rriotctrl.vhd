----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03.11.2023 21:50:41
-- Design Name: 
-- Module Name: rriotctrl - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

use work.libpps4.all;
use work.liberr.all;    -- list of error codes
use work.libfram.all;    -- list of error codes


entity rriotctrl is
    Port (
		SelIOBank   : out STD_LOGIC_VECTOR(1 DOWNTO 0);   --which bank is read in: 
			                                               --0 ==> 8 channels of bank are on the IOx bus
		LatchIOBank : out STD_LOGIC_VECTOR(1 DOWNTO 0);   --which bank to latch: 
		                                                  --apply a 0 for at least 20ns will latch
																		  --the 8 corresponding channels of IOx
		SELIODir    : out STD_LOGIC;                      --control the gate mosfet for actual output. 
		                                                  --0=>output active. Opposite of previous version                  
        IOx         : inout  STD_LOGIC_VECTOR(7 DOWNTO 0);
        
           SYSCLK   : in  STD_LOGIC;
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
			  SetDDirL : out STD_LOGIC; -- added HW V3. To set ID bus 1..4 in Hi-Z. 1=>HiZ, O=>Active (ball D4)
			  SetDDirH : out STD_LOGIC; -- added HW V3B. To set ID bus 5..8 in Hi-Z. 1=>HiZ, O=>Active (ball J2)
			  -- OUT_OPT1 : out STD_LOGIC; -- added HW V3.
			  OUT_OPT2 : out STD_LOGIC; -- added HW V3.
			  TXp : out STD_LOGIC; -- added HW V3 09/2022. Opt1_33  =fpga pin34 (IO_L05N_2).
			  RXp : in STD_LOGIC;  -- added HW V3 03/2023. Optin4_33  =fpga pin39 (IP_2/VREF_2).
              SCL : inout  STD_LOGIC;
              SDA : inout  STD_LOGIC
			  );
end rriotctrl;

architecture Behavioral of rriotctrl is


-- generate phases from clockA and B
component clkgen 
    Port ( hiclk : in  STD_LOGIC;
	        c_a  : in  STD_LOGIC;
           nc_b : in  STD_LOGIC;
           nrst : in  STD_LOGIC;
           pps4_ph : out  pps4_ph_type;
		   diagclk  : out  STD_LOGIC);
end component;


component ioxAdapter
     Port ( hiclk       : in    STD_LOGIC;
            pps4_phi    : in    pps4_ph_type;
            --this not an error, this is logical that inpx is out, and conversely with outx
            inpx_gen    : out   std_logic_vector(15 downto 0); --to the standard pps4 ios manager module 
            outx_read   : in    std_logic_vector(15 downto 0); --to the standard pps4 ios manager module 
            iox         : inout std_logic_vector( 7 downto 0); --to the extern mux interface 
            seliobank   : out   std_logic_vector( 1 downto 0);
            latchiobank : out   std_logic_vector( 1 downto 0)
          );
end component;                                            

            
component RRIOTA17
    Generic (
           g_IODEVNUM  : std_logic_vector(1 downto 0);
           g_RAMSEL    : std_logic;
           g_RAMAB8    : std_logic;
           g_ROMSEL    : std_logic;
           g_ref       : natural
           );
    Port ( 
           hiclk       : in     STD_LOGIC;
           spo         : in     STD_LOGIC;
           pps4_phi    : in     pps4_ph_type;
           seliodir    : out    std_logic;
           inpx        : in     std_logic_vector(15 downto 0);
           outx        : out    std_logic_vector(15 downto 0);
           rrsel       : in     std_logic;
           ab          : in     STD_LOGIC_VECTOR (11 downto 1);
           din         : in     STD_LOGIC_VECTOR (8 downto 1);
           dout        : out    STD_LOGIC_VECTOR (8 downto 1);
           wio         : in     STD_LOGIC);
end component;


component ledctrl
    Port ( 
           hiclk       : in     STD_LOGIC;
           ErrCod      : in     std_logic_vector(7 downto 0);
           vs0         : out    STD_LOGIC;
           vs1         : out    STD_LOGIC;
           vs2         : out    STD_LOGIC);
end component;

component nvramMng 
            Generic (
                   g_size        : natural;
                   g_baseAddr    : std_logic_vector(15 downto 0)
                    );
            Port (
                   hiclk       : in     STD_LOGIC;
                   start       : in     std_logic; -- rising edge to start
                   command     : in     std_logic_vector(1 downto 0); -- command to be executed
                   done        : out    std_logic; -- set to 0 on start until finished
                   cur_nibble  : out    std_logic_vector(3 downto 0);
                   cur_addr    : in     natural range 0 to 2*g_size-1;  --cur address of the nibble in #nibbles
                   scl         : inout STD_LOGIC;
                   sda         : inout  STD_LOGIC
		          );
end component;

component pps4TR
    Port ( 
           hiclk       : in     STD_LOGIC;
           spo         : in     STD_LOGIC;
           pps4_phi    : in     pps4_ph_type;
		   TXp         : out    STD_LOGIC; 
		   RXp         : in     STD_LOGIC; 
           rrsel       : in     std_logic;
           ab          : in     STD_LOGIC_VECTOR (11 downto 1);
           din         : in     STD_LOGIC_VECTOR (8 downto 1);
           status      : out    std_logic_vector(7 downto 0);
           hm_user_sel : out    std_logic;
           inpx        : in     STD_LOGIC_VECTOR (15 downto 0);
           outx        : in     STD_LOGIC_VECTOR (15 downto 0);
           wio         : in     STD_LOGIC);
end component;

component hmsys
    Port (
           hiclk       : in        STD_LOGIC;
           nEn         : in        std_logic;
           aClk        : in        STD_LOGIC;
           aReset      : in        STD_LOGIC;
           dout        : out       STD_LOGIC;
           din         : in        STD_LOGIC;
           wEn         : in        STD_LOGIC
          );
end component hmsys;

--COMPONENT TXFIFO
--  PORT (
--    clk : IN STD_LOGIC;
--    rst : IN STD_LOGIC;
--    din : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
--    wr_en : IN STD_LOGIC;
--    rd_en : IN STD_LOGIC;
--    dout : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
--    full : OUT STD_LOGIC;
--    empty : OUT STD_LOGIC;
--    wr_rst_busy : OUT STD_LOGIC;
--    rd_rst_busy : OUT STD_LOGIC
--  );
--END COMPONENT;



--component uart_rx is
-- generic (
--	g_CLKS_PER_BIT : integer := 2604   -- i.e. 19200bauds if clock at 50MHz Needs to be set correctly
--	);
-- port (
--	i_clk       : in  std_logic;
--	i_rx_serial : in  std_logic;
--	o_rx_dv     : out std_logic;
--	o_rx_byte   : out std_logic_vector(7 downto 0)
--	);
--end component uart_rx;
  

--component uart_tx is
-- generic (
--	g_CLKS_PER_BIT : integer := 2604   -- Needs to be set correctly
--	);
-- port (
--	i_clk       : in  std_logic;
--	i_tx_dv     : in  std_logic;
--	i_tx_byte   : in  std_logic_vector(7 downto 0);
--	o_tx_active : out std_logic;
--	o_tx_serial : out std_logic;
--	o_tx_done   : out std_logic
--	);
--end component uart_tx;


signal pps4_phi : pps4_ph_type;

signal diagAnB  : STD_LOGIC := '0'; 
signal ErrCod   : std_logic_vector(7 downto 0) := (others=>'0');
signal UserCod  : std_logic_vector(7 downto 0) := (others=>'0');

signal tracer_status    : std_logic_vector(7 downto 0);

--signals for working with iic
signal is_iic_read_done : std_logic;  --value set by iic driver (1 at the begining)
signal start_iic_read   : std_logic := '0';
signal iic_command      : std_logic_vector(1 downto 0) := "00";
signal cur_nvram_nibble : std_logic_vector(3 downto 0);
signal cur_nvram_addr   : natural range 0 to 127;

--signals for IOs management
--InpX_int_alt is like InpX_int 
--  except it will hold input from real or simulated hm in (0)
signal InpX_int          : std_logic_vector(15 downto 0) := (others => 'Z');
signal InpX_int_alt      : std_logic_vector(15 downto 0);
signal OutX_int          : std_logic_vector(15 downto 0) := (others => '1');
--doutfrominternhm is the dout from the simlated intern HM6508
--to be selected in place of inpx(0) which comes from the real hm6805
signal doutfrominternhm  : STD_LOGIC;


signal conditionedinp00  : STD_LOGIC;

--hm_user_sel can be changed from the user HMI, sending appropriate command
signal hm_user_sel       : STD_LOGIC;   --0 is default for simulated hm, 1 for real hm



--signals for data bus management
signal nDO_int           : std_logic_vector(8 downto 1)  := (others => 'Z');
signal SetDDirL_int      : STD_LOGIC := '1';
signal SetDDirH_int      : STD_LOGIC := '1'; 


--signals for tx fifo
signal FIFO_DIN   : STD_LOGIC_VECTOR(7 DOWNTO 0);
signal FIFO_DOUT  : STD_LOGIC_VECTOR(7 DOWNTO 0);

signal ISFIFOFULL : STD_LOGIC;
signal ISFIFOVOID : STD_LOGIC;
signal FIFORD : STD_LOGIC := '0';
signal FIFOWR : STD_LOGIC := '0';


--next 2 lines to avoid pointless warnings about black boxes (advice from https://www.xilinx.com/support/answers/9838.html)
attribute box_type : string; 
--attribute box_type of TXFIFO       : component is "black_box"; 

begin

	SetDDirL_int    <= '0'                  when nDO_int(4 downto 1) /= "ZZZZ" else
	                   '1';	 
	SetDDirH_int    <= '0'                  when nDO_int(8 downto 5) /= "ZZZZ" else
	                   '1';	 
	                   
	SetDDirL        <= SetDDirL_int;
	SetDDirH        <= SetDDirH_int;
	                 
    nDO(4 downto 1) <= not nDO_int(4 downto 1)  when SetDDirL_int = '0' else
                       (others=>'1');
    
    nDO(8 downto 5) <= not nDO_int(8 downto 5)  when SetDDirH_int = '0' else
                       (others=>'1');

    --the first part of equation for selftest of IOs...
    conditionedinp00 <= '0'              when OutX_int(0)='0' else                     --line held by B1 to 0
                        doutfrominternhm when OutX_int(1)='1' and OutX_int(2)='0' and OutX_int(3)='1' else
                        '1';
                        
    InpX_int_alt(15 downto 1) <= InpX_int(15 downto 1);
    InpX_int_alt(0) <= InpX_int(0) when  hm_user_sel = '1' else
                       conditionedinp00; --default
                         
--    TXBUF : TXFIFO       PORT MAP (
--										    clk => SYSCLK,
--										    rst => '0',
--										    din => FIFO_DIN,
--										    wr_en => FIFOWR,
--										    rd_en => FIFORD,
--										    dout => FIFO_DOUT,
--										    full =>  ISFIFOFULL,
--										    empty => ISFIFOVOID,
--										    wr_rst_busy => open,
--										    rd_rst_busy => open
--									       );
  


      PHIGN : clkgen       port map (hiclk    => SYSCLK, 
                                     c_a      => not CKA, 
                                     nc_b     => not nCKB, 
                                     nrst     => '1', 
                                     pps4_ph  => pps4_phi, 
                                     diagclk  => diagAnB); 


                                             
      IOXADAPT : ioxAdapter port map (
                    hiclk       => SYSCLK,
                    pps4_phi    => pps4_phi,
                    inpx_gen    => InpX_int,       --to the standard pps4 ios manager module 
                    outx_read   => OutX_int,       --to the standard pps4 ios manager module 
                    iox         => IOx,            --to the extern mux interface 
                    seliobank   => SelIOBank,
                    latchiobank => LatchIOBank
                    );      



      A17xx    : RRIOTA17    
                Generic map(
                   --config for A1752:
                   --g_RAMSEL = '0'; g_RAMAB8 = '0'; g_ROMSEL => '0'
                   --config for A1761:
                   --g_IODEVNUM ="10"   (4 is 0 10 0)
                   --g_RAMSEL = '0'; g_RAMAB8 = '0'; g_ROMSEL => '0'
                   --config for A1762:
                   --g_IODEVNUM ="01"   (4 is 0 10 0)
                   --g_RAMSEL = '0'; g_RAMAB8 = '1'; g_ROMSEL => '1'
                   --config for A1753:
                   --g_RAMSEL = '0'; g_RAMAB8 = '1'; g_ROMSEL => '1'
                   g_IODEVNUM => "10",
                   g_RAMSEL   => '0',
                   g_RAMAB8   => '0',
                   g_ROMSEL   => '0',
                   g_ref      =>  16#61#  -- select the A1761 recel rom content
                   --g_ref    =>  16#52CF#  -- select the A1752CF rom content
                   )
                Port map (
                    hiclk    =>  SYSCLK,
                    spo      =>  SPO,
                    pps4_phi =>  pps4_phi,
                    seliodir =>  SELIODir,
                    inpx     =>  InpX_int_alt,  --we take into account the HM source
                    outx     =>  OutX_int,
                    rrsel    =>  nRRSEL,
                    ab       =>  nAB,
                    din      =>  nID,
                    dout     =>  nDO_int,
                    wio      =>  nW_IO);

      -- IO00: Data out C2->B1. IOL 41 (A=8) returns A=0 if DATA out is 0 TTL
      --                                     returns A=1 if DATA out is 1 TTL
      --                                     returns A=1 if DATA out is Z
      -- during selftest        IOL 41 (A=0) will force line to +5V
      
      -- IO01: DATA IN B1->C2. IOL 41 (A=0): write TTL 1 into C2
      --                       IOL 41 (A=8): write TTL 0 into C2
      -- Actual write only occurs after C2 is enabled and /WE=0
      -- the return value goes into A, and is the value of the previous call

      -- IO02: Enable C2. IOL 41 (A=0): enable C2
      --                  IOL 41 (A=8): disable C2

      -- IO03: C2 write enable IOL 41 (A=0), immediatly followed by a 2nd IOL41
      
      -- IO04: Advance CD4040 clock IOL 41 (A=0), immediatly followed by a 2nd IOL41

      -- IO05: CD4040. IOL 41 (A=0): reset is released
      --               IOL 41 (A=8): CD4040 address held in reset

      
      MYRAMCMOS :  hmsys
                Port map (
                    hiclk    => SYSCLK,
                    nEn      => OutX_int(2),              -- IO2 is HM6508 enable signal  (active low)
                    aClk     => OutX_int(4),              -- IO4 is 4040 clock
                    aReset   => OutX_int(5),              -- IO5 is 4040 reset (active high)
                    dout     => doutfrominternhm,         -- IO0 is data in (read from HM6508, thru T2)
                    din      => OutX_int(1),              -- IO1 is data out (write to HM6508)
                    wEn      => OutX_int(3)               -- IO3 is HM6508 write enable signal  (active low)
                          );


     --not used at the moment. TODO: validate the I2C FRAM accesses
     NVRAMR  :  nvramMng generic map ( g_size     => 64,      --number of bytes, not nibbles
                                       g_baseAddr => X"0000"  --to be set cleverly, there is no verif
                                     )
                         port map (  hiclk      => SYSCLK,
                                     start      => start_iic_read,
                                     command    => iic_command,
                                     done       => is_iic_read_done,
                                     cur_nibble => cur_nvram_nibble,
                                     cur_addr   => cur_nvram_addr,
                                     scl        => SCL,
                                     sda        => SDA);


      LEDCTL :  ledctrl port map    ( hiclk   => SYSCLK,
                                      ErrCod  => ErrCod,
                                      vs0     => VS0,
                                      vs1     => VS1,
                                      vs2     => VS2);
                                      
      --used by serendipity for diagnostic of system and not required for the A17 model
      --this tracer contains an entire RAM spy copy, a passive GPKD (don't forget to select right config id), etc...
      PPS4TRACE : pps4TR    
                Port map (
                    hiclk       =>  SYSCLK,
                    spo         =>  SPO,
                    pps4_phi    =>  pps4_phi,
                    TXp         =>  TXp,
                    RXp         =>  RXp,
                    rrsel       =>  nRRSEL,
                    ab          =>  nAB,
                    din         =>  nID,
                    status      =>  tracer_status,
                    hm_user_sel =>  hm_user_sel,
                    inpx        =>  InpX_int_alt,
                    outx        =>  OutX_int,
                    wio         =>  nW_IO);



                                      
-- reset iic then write values to fram for testing                                     
process_iic:    process(SYSCLK)
    variable state : integer range 0 to 15 := 0;
    begin
        if (rising_edge(SYSCLK)) then
            case state is 
                when 0 =>
                    start_iic_read <= '1'; --edge sensitive, was initialized to 0
                    iic_command <= cFramReset;
                    state := 1;
                when 1 =>
                    start_iic_read <= '0'; --reset signal to be able to start a new command later
                    if  is_iic_read_done = '0' then
                        state := 2;
                    end if;
                when 2 =>
                     if  is_iic_read_done = '1' then
                        state := 3;
                    end if;
               
                when 3 =>
                    start_iic_read <= '1'; --edge sensitive, was initialized to 0
                    iic_command <= cFramWrite;
                    state := 4;
                when 4 =>
                    start_iic_read <= '0'; --reset signal to be able to start a new command later
                    if  is_iic_read_done = '0' then
                        state := 5;
                    end if;
                when 5 =>
                    if  is_iic_read_done = '1' then
                        state := 6;
                    end if;
                when others =>
                    null;                 
                    
            end case;
                    
                     
        end if; --end of rising_edge
    end process process_iic;           
 
    ErrCod <= cResetErr      when SPO = '1'      else
              cSysClkSyncErr when diagAnB = '0'  else                  
              cnoErr; 


    UserCod <= tracer_status;

                                  
end Behavioral;
