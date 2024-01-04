----------------------------------------------------------------------------------
-- Company:  ass consult
-- Engineer: garzol
-- 
-- Create Date: 24.10.2023 11:18:16
-- Design Name: 
-- Module Name: gpkdctrl - Behavioral
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

use work.libpps4.all;
use work.liberr.all;    -- list of error codes
use work.libfram.all;    -- list of error codes
use work.common.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gpkdctrl is
    Port (
           SYSCLK               : in    STD_LOGIC;
           nCKB                 : in    STD_LOGIC;
           CKA                  : in    STD_LOGIC;
		   DLDIR                : out   STD_LOGIC;   --set dir of ID1..4 
           X                    : out   STD_LOGIC_VECTOR(7 DOWNTO 0);
           SPO                  : in    STD_LOGIC;
           nW_IO                : in    STD_LOGIC;
           SC5                  : in    STD_LOGIC; 
           SC6                  : in    STD_LOGIC; 
           SC7                  : in    STD_LOGIC; 
		   Y                    : in    STD_LOGIC_VECTOR(7 DOWNTO 0);
		   DA                   : out   STD_LOGIC_VECTOR(4 DOWNTO 1); 
		   DB                   : out   STD_LOGIC_VECTOR(4 DOWNTO 1); 
		   DBS                  : out   STD_LOGIC; 
		   nDO                  : out   STD_LOGIC_VECTOR(8 DOWNTO 1); --10788 does not write on D5..8
		   nID                  : in    STD_LOGIC_VECTOR(8 DOWNTO 1);   --first half of in data bus added on V3 HW
		   VS0                  : out   STD_LOGIC; -- added HW V3. led control 0=lit, 1=off
		   VS1                  : out   STD_LOGIC; -- added HW V3. led control 0=lit, 1=off
		   VS2                  : out   STD_LOGIC; -- added HW V3. led control 0=lit, 1=off
		   TXp                  : out   STD_LOGIC; -- added HW V3 09/2022. Opt1_33  =fpga pin34 (IO_L05N_2).
		   RXp                  : in    STD_LOGIC;  -- added HW V3 03/2023. Optin4_33  =fpga pin39 (IP_2/VREF_2).
           SCL                  : inout STD_LOGIC;
           SDA                  : inout STD_LOGIC
		   );
end gpkdctrl;

architecture Behavioral of gpkdctrl is


--mak_ckab only for semi simulation
--provide synchronized clka and clkb for stand alone testing purpose
component mak_ckab
  Port ( c_a : out  STD_LOGIC;
         nc_b : out  STD_LOGIC;
         SYSCLK : in  STD_LOGIC;
         rst : in  STD_LOGIC);
end component;

signal simu_nCKB: STD_LOGIC;
signal simu_CKA : STD_LOGIC;
--end of things for semi simu

component clkgen 
    Port ( hiclk : in  STD_LOGIC;
	        c_a  : in  STD_LOGIC;
            nc_b : in  STD_LOGIC;
            nrst : in  STD_LOGIC;
         pps4_ph : out  pps4_ph_type;
	    diagclk  : out  STD_LOGIC);
end component;

component GPKD10788
    Port ( 
           hiclk         : in     STD_LOGIC;
           spo           : in     STD_LOGIC;
           pps4_phi      : in     pps4_ph_type;
           sc5           : in     STD_LOGIC;
           sc6           : in     STD_LOGIC;
           sc7           : in     STD_LOGIC;
           x             : out    STD_LOGIC_VECTOR (7 downto 0);
           dbs           : out    STD_LOGIC;

           status        : out    std_logic_vector (7 downto 0);
           RDA_data_st   : out    t_sreg;
           RDB_data_st   : out    t_sreg;
           dspl_A_off_st : out    std_logic;
           dspl_B_off_st : out    std_logic;
           
                      
           da : out STD_LOGIC_VECTOR (4 downto 1);
           db : out STD_LOGIC_VECTOR (4 downto 1);
           y  : in STD_LOGIC_VECTOR (7 downto 0);
           id : in STD_LOGIC_VECTOR (8 downto 1);
           wio: in STD_LOGIC;
           do : out STD_LOGIC_VECTOR (8 downto 1);
           dldir : out STD_LOGIC);
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

signal pps4_phi : pps4_ph_type;
--diagAnB=='1'=> clka and b ok and sync'd (built by clkgen)
signal diagAnB          : STD_LOGIC := '0'; 

signal GPKD_status      : std_logic_vector(7 downto 0) := (others=>'0');
signal ErrCod           : std_logic_vector(7 downto 0) := (others=>'0');

--signals for working with iic
signal is_iic_read_done : std_logic;  --value set by iic driver (1 at the begining)
signal start_iic_read   : std_logic := '0';
signal iic_command      : std_logic_vector(1 downto 0) := "00";
signal cur_nvram_nibble : std_logic_vector(3 downto 0);
signal cur_nvram_addr   : natural range 0 to 127;

--for diag through wifi
signal RDA_data_st      :  t_sreg;
signal RDB_data_st      :  t_sreg;
signal dspl_A_off_st    :  std_logic;
signal dspl_B_off_st    :  std_logic;


--uart sigs
-- constant c_CLKS_PER_BIT : integer := 2604;  --19200 bauds
constant c_CLKS_PER_BIT : integer := 434;      --115200 bauds
signal   r_TX_DV        : std_logic := '0';    -- command start transmitting
signal   r_TX_BYTE      : std_logic_vector(7 downto 0); -- byte to send
signal   w_TX_DONE      : std_logic := '0';  -- rises when finished
signal   w_TX_BUSY      : std_logic := '0';  -- 0 TX if available, 1 otherwise

begin

  mkab: mak_ckab port map ( c_a    => simu_CKA,
                            nc_b   => simu_nCKB,
                            SYSCLK => SYSCLK,
                            rst    =>  '1');

      -- following syntax requires VHDL_2008 type
      PHIGN : clkgen       port map (hiclk   => SYSCLK, 
      
                                     --real:
                                     c_a     => not CKA, nc_b=>not nCKB, 
                                     --simu:
                                     --c_a     => simu_CKA, nc_b=> simu_nCKB, 
                                     
                                     nrst    =>'1', pps4_ph=>pps4_phi, diagclk=>diagAnB); 

      GPKD  : GPKD10788    port map (hiclk=>SYSCLK, spo=>SPO, pps4_phi=>pps4_phi,
                                     sc5=>SC5, sc6=>SC6, sc7=>SC7,
                                     x=>X, dbs=>DBS,
                                     status=>GPKD_status,
                                     RDA_data_st=>RDA_data_st,
                                     RDB_data_st=>RDB_data_st,
                                     dspl_A_off_st=>dspl_A_off_st,
                                     dspl_B_off_st=>dspl_B_off_st,
                                     da=>DA, db=>DB, y=>Y,
                                     id=>nID, wio=>nW_IO,
                                     do=>nDO,
                                     dldir=>DLDIR);

      LEDCTL :  ledctrl port map    ( hiclk   => SYSCLK,
                                      ErrCod  => ErrCod,
                                      vs0     => VS0,
                                      vs1     => VS1,
                                      vs2     => VS2);
                                      
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
      o_tx_serial => TXp,        -- port tx
      o_tx_done   => w_TX_DONE   -- rises when finished (lasts 1 ticks by def)
      );

--process uart. Send display frames every 100ms
process_uart_diag: process(SYSCLK)
    variable  delay     : natural range  0 to 16777215 := 0; 
    variable  numbyt    : integer range -1 to 36       := -1;
    begin
        if (rising_edge(SYSCLK)) then
            -- wait for 100ms to have frames every 100ms
            delay := delay+1;
            if delay > 5000000 then
                delay  := 0;
                numbyt := 0;
            end if;

            if w_TX_DONE  = '1' then
                r_TX_DV <= '0';
            end if;
    
            if r_TX_DV = '0' then
                if numbyt = 0 then
                    r_TX_DV <= '1'; --say uart is busy	
                    r_TX_BYTE <= X"41";  --code of 'A' for display A (8-byte frame)
                    numbyt := 30; --we added the first byte lately, thus the value "30"...
                elsif numbyt = 30 then
                    r_TX_DV <= '1'; --say uart is busy	
                    r_TX_BYTE <= dspl_A_off_st&dspl_B_off_st&"000000";
                    numbyt := 1;
                elsif numbyt >= 1 and numbyt <= 8 then
                    r_TX_DV <= '1'; --say uart is busy	
                    r_TX_BYTE <= (RDA_data_st((8-numbyt)*2+1)) & (RDA_data_st((8-numbyt)*2));
                    numbyt := numbyt+1;
                elsif numbyt = 9 then 
                    r_TX_DV <= '1'; --say uart is busy	
                    r_TX_BYTE <= X"42";  --code of 'B' for display B (8-byte frame)
                    numbyt := 31; --we added the first byte lately, thus the value "30"...
                elsif numbyt = 31 then
                    r_TX_DV <= '1'; --say uart is busy	
                    r_TX_BYTE <= dspl_A_off_st&dspl_B_off_st&"111111";
                    numbyt := 10;
                elsif numbyt >= 10 and numbyt <= 17 then
                    r_TX_DV <= '1'; --say uart is busy	
                    r_TX_BYTE <= (RDB_data_st((17-numbyt)*2+1)) & (RDB_data_st((17-numbyt)*2)) ;
                    numbyt := numbyt+1;
                else
                    numbyt := -1;
                end if;
                
            end if;            
        end if;    
    end process process_uart_diag;    
                                      
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
              cGPKDErr       when GPKD_status /= X"00" else               
              cnoErr; 
                                                   
end Behavioral;
