----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:41:11 12/14/2019 
-- Design Name: 
-- Module Name:    manageIO - Behavioral 
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

use work.Common.all;

entity manageIO is
    Port ( IOCmd : in  STD_LOGIC_VECTOR (8 downto 1);
           Addr : in  STD_LOGIC_VECTOR (6 downto 0);
           Din : in  STD_LOGIC_VECTOR (4 downto 1);
           Dout : out  STD_LOGIC_VECTOR (4 downto 1));
           IIO_VEC : inout STD_LOGIC_VECTOR(15 DOWNTO 0);
           OIO_VEC : inout STD_LOGIC_VECTOR(15 DOWNTO 0);
           T_ENABLE_VEC : inout STD_LOGIC_VECTOR(15 DOWNTO 0);
end manageIO;

architecture Behavioral of manageIO is

begin
	devNum <= (IOCmd and "01100000")>>5;
	if not (devNum = cDEVNUM) then
		null;
	else
		null;
	end if;
		
	

end Behavioral;

