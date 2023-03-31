----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    18:33:49 10/12/2019 
-- Design Name: 
-- Module Name:    clkgen - Behavioral 
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
--
----------------------------------------------------------------------------------
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
	
begin
	process(SYSCLK, rst)
		variable ab_count : natural range 0 to 31 := 0;
	begin
		if (rising_edge(SYSCLK)) then
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
	
			
		

