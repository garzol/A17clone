----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    08:37:08 10/09/2019 
-- Design Name: 
-- Module Name:    rom - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity rom is
    Port ( ADDR : in  STD_LOGIC_VECTOR (10 downto 0);
           Q : out  STD_LOGIC_VECTOR (7 downto 0);
           SEL : in  STD_LOGIC);
end rom;

architecture Behavioral of rom is

begin


end Behavioral;

