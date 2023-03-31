----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:21:46 10/08/2019 
-- Design Name: 
-- Module Name:    testled - Behavioral 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity testled is
    Port ( clk : in  STD_LOGIC;
           led : out  STD_LOGIC);
end testled;


architecture Behavioral of testled is
signal CLK_DIV : std_logic_vector (21 downto 0);
begin
    -- clock divider
    process (clk)
    begin
        if (rising_edge(clk)) then
            CLK_DIV <= CLK_DIV + '1';
        end if;
    end process;
    
    led <= CLK_DIV(20); -- connect LED 2 to divided clock
end Behavioral;

