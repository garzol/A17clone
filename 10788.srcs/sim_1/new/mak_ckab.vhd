----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 24.10.2023 22:03:57
-- Design Name: 
-- Module Name: mak_ckab - Behavioral
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
--library UNISIM;
--use UNISIM.VComponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mak_ckab is
    Port ( c_a : out  STD_LOGIC;
           nc_b : out  STD_LOGIC;
           SYSCLK : in  STD_LOGIC;
           rst : in  STD_LOGIC);
end mak_ckab;

architecture Behavioral of mak_ckab is

	signal CA : STD_LOGIC;
	signal nCB : STD_LOGIC;
	
	--14 ticks at 50MHz to make 3MHz clock (closest possible to original 3.579545MHz)
	--14 ticks => 3,571,428.57143 MHz
	signal CLK_3MHz : STD_LOGIC := '0';

begin
	process(SYSCLK, rst)
	    constant div50_2_3 : natural range 0 to 1024 := 7;
	    variable div_nbcou : natural range 0 to 1024 := 0;
	begin
		if (rising_edge(SYSCLK)) then
			if (rst= '1') then
                div_nbcou := div_nbcou + 1;
                if (div_nbcou = div50_2_3) then
                    div_nbcou := 0;
                    CLK_3MHz <= not CLK_3MHz;
                end if;
            end if;
        end if;
    end process;
       
    
	process(CLK_3MHz, rst)
		variable ab_count : natural range 0 to 31 := 0;
	begin
		if (rising_edge(CLK_3MHz)) then
			if (rst= '0') then
				ab_count := 0;
				CA <= '1';
				nCB <= '0';			
			elsif (ab_count = 0) then
				CA <= '0';
				nCB <= '0';
			elsif (ab_count < 5) then
				CA <= '0';
				nCB <= '1';
			elsif (ab_count < 9) then 
				CA <= '0';
				nCB <= '0';				
			elsif (ab_count < 10) then 
				CA <= '1';
				nCB <= '0';
			elsif (ab_count < 14) then 
				CA <= '1';
				nCB <= '1';
			else
				CA <= '1';
				nCB <= '0';
			end if;
			ab_count := ab_count + 1;
			if (ab_count = 18) then
				ab_count := 0;
			end if;
		
		end if;  --end if rising_edge


    end process;
	 c_a <= CA;
	 nc_b <=nCB;
end Behavioral;
	
			