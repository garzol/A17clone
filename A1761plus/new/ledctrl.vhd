----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 27.10.2023 11:17:01
-- Design Name: 
-- Module Name: ledctrl - Behavioral
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

use work.liberr.all;    -- list of error codes


entity ledctrl is
    Port ( 
           hiclk       : in     STD_LOGIC;
           ErrCod      : in     std_logic_vector(7 downto 0);
           vs0         : out    STD_LOGIC;
           vs1         : out    STD_LOGIC;
           vs2         : out    STD_LOGIC);
end ledctrl;

architecture Behavioral of ledctrl is

-- vs0 is red led. lit when 0
signal vs0_int : std_logic := '1';
-- vs1 is yellow led. lit when 0
signal vs1_int : std_logic := '1';
-- vs2 is green led. lit when 0
signal vs2_int : std_logic := '1';

signal CLK_DIV0 : unsigned (26 downto 0):=(others=>'0');

begin
    vs0 <= vs0_int;
    vs1 <= vs1_int;
    vs2 <= vs2_int;
    
    
    
-- clock divider
    process (hiclk)
    begin
        if (rising_edge(hiclk)) then
            CLK_DIV0 <= CLK_DIV0 + "1";
        end if;
    end process;

-- error code management
    process (hiclk)
    begin
        if (rising_edge(hiclk)) then
        case ErrCod is 
            when cnoErr         =>
                vs0_int <= CLK_DIV0(26);
                vs1_int <= '1';
                vs2_int <= '1';
            when cSysClkSyncErr =>
                vs0_int <= CLK_DIV0(23);
                vs1_int <= '1';
                vs2_int <= '1';
            when cResetErr      =>
                vs0_int <= CLK_DIV0(23);
                vs1_int <= CLK_DIV0(23);          
                vs2_int <= '1';
            when others =>
                vs0_int <= CLK_DIV0(23);
                vs1_int <= not CLK_DIV0(23);
                vs2_int <= CLK_DIV0(23);
        end case;

        end if;
    end process;

end Behavioral;
