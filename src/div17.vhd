----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:44:42 10/27/2019 
-- Design Name: 
-- Module Name:    div5 - Behavioral 
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

entity div17 is
    Port ( ckin : in  STD_LOGIC;
           ckout : out  STD_LOGIC);

end div17;


architecture Behavioral of div17 is
signal ckint : std_logic := '0';

begin
    process (ckin)
    -- clock divider
		variable ck_count : natural range 0 to 31 := 0;
    begin
        if (rising_edge(ckin)) then
				ck_count := ck_count + 1;
				if (ck_count = 9) then
					ck_count := 0;
					ckint <= not ckint;
				end if;
        end if;
    end process;
    ckout <= ckint;
end Behavioral;
