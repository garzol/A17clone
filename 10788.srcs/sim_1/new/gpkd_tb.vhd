----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.10.2023 21:42:15
-- Design Name: 
-- Module Name: gpkd_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gpkd_tb is
end;

architecture bench of gpkd_tb is

  component gpkdctrl
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
           SDA                  : inout  STD_LOGIC
		   );
  end component;

  component mak_ckab
      Port ( c_a : out  STD_LOGIC;
             nc_b : out  STD_LOGIC;
             SYSCLK : in  STD_LOGIC;
             rst : in  STD_LOGIC);
  end component;
    
  -- signal SYSCLK: STD_LOGIC;
  signal nCKB: STD_LOGIC;
  signal CKA: STD_LOGIC;
  signal DLDIR: STD_LOGIC;
  signal X: STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal SPO: STD_LOGIC;
  signal nW_IO: STD_LOGIC;
  signal SC5: STD_LOGIC;
  signal SC6: STD_LOGIC;
  signal SC7: STD_LOGIC;
  signal Y: STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal DA: STD_LOGIC_VECTOR(4 DOWNTO 1);
  signal DB: STD_LOGIC_VECTOR(4 DOWNTO 1);
  signal DBS: STD_LOGIC;
  signal nDO: STD_LOGIC_VECTOR(8 DOWNTO 1);
  signal nID: STD_LOGIC_VECTOR(8 DOWNTO 1);
  signal VS0: STD_LOGIC;
  signal VS1: STD_LOGIC;
  signal VS2: STD_LOGIC;
  signal TXp: STD_LOGIC;
  signal RXp: STD_LOGIC;
  signal SCL: STD_LOGIC;
  signal SDA: STD_LOGIC ;

  signal clk : std_logic := '0';
  constant clk_period : time := 20 ns;

  signal CKB: STD_LOGIC;
  signal nCKA: STD_LOGIC;
begin
  CKB <= not nCKB;
  nCKA <= not CKA;
  mkab: mak_ckab port map ( c_a    => CKA,
                            nc_b   => nCKB,
                            SYSCLK => clk,
                            rst    =>  '1');

  uut:  gpkdctrl port map ( SYSCLK     => clk,
                           nCKB        =>  not nCKB,
                           CKA         =>  not CKA,
                           DLDIR       => DLDIR,
                           X           => X,
                           SPO         => SPO,
                           nW_IO       => nW_IO,
                           SC5         => SC5,
                           SC6         => SC6,
                           SC7         => SC7,
                           Y           => Y,
                           DA          => DA,
                           DB          => DB,
                           DBS         => DBS,
                           nDO         => nDO,
                           nID         => nID,
                           VS0         => VS0,
                           VS1         => VS1,
                           VS2         => VS2,
                           TXp         => TXp,
                           RXp         => RXp,
                           SCL         => SCL,
                           SDA         => SDA );

  stimulus: process
  begin
  
    -- Put initialisation code here
    SPO <= '1';
    SC5 <= '1';
    SC6 <= '0';
    SC7 <= '1';

    
    wait for 10 us;
    -- Put test bench stimulus code here
    SPO <= '0';
    
    wait;
  end process;

   -- Clock process definitions( clock with 50% duty cycle is generated here.
   clk_process :process
   begin
        clk <= '0';
        wait for clk_period/2;  --for 10 ns signal is '0'.
        clk <= '1';
        wait for clk_period/2;  --for next 10 ns signal is '1'.
   end process;

   dspl_process:process
        variable display_data : STD_LOGIC_VECTOR(4 DOWNTO 1) := "0000";
   begin
        for ii in 0 to 15 loop
            wait for 50us;
            wait until rising_edge(CKA);
            --this is necessarily a phi1A
             wait until falling_edge(nCKB);
             --start of a phi4
            nID <= "11011110"; --kla
            --nID <= "11011101"; --klb
            nW_IO <= '1';
            wait until rising_edge(nCKB);
            --now: next phi1
            nID <= "11111111";
            nW_IO <= '0';
            wait until falling_edge(nCKB);
            --now: phi2
            display_data := std_logic_vector( to_unsigned(ii, 4));
            nID <= display_data&"ZZZZ";
            wait until rising_edge(nCKB);
            --now: phi3
             nID <= "11111111";
        end loop;  --ii   
        
        for ii in 0 to 15 loop
            wait for 50us;
            wait until rising_edge(CKA);
            --this is necessarily a phi1A
             wait until falling_edge(nCKB);
             --start of a phi4
            --nID <= "11011110"; --kla
            nID <= "11011101"; --klb
            nW_IO <= '1';
            wait until rising_edge(nCKB);
            --now: next phi1
            nID <= "11111111";
            nW_IO <= '0';
            wait until falling_edge(nCKB);
            --now: phi2
            display_data := std_logic_vector( to_unsigned(15-ii, 4));
            nID <= display_data&"ZZZZ";
            wait until rising_edge(nCKB);
            --now: phi3
             nID <= "11111111";
        end loop;  --ii           
        
 
        --turn on display
        wait for 250us;
        wait until rising_edge(CKA);
        --this is necessarily a phi1A
         wait until falling_edge(nCKB);
         --start of a phi4
        --nID <= "11011110"; --kla
        nID <= "11010011"; --kdn
        nW_IO <= '1';
        wait until rising_edge(nCKB);
        --now: next phi1
        nID <= "11111111";
        nW_IO <= '0';
        wait until falling_edge(nCKB);
        --now: phi2
        nID <= "0000"&"ZZZZ";
        wait until rising_edge(nCKB);
        --now: phi3
         nID <= "11111111";
   
        
        wait;    
   end process;
end;
  