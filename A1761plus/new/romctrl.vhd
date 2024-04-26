----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 19.11.2023 21:52:54
-- Design Name: 
-- Module Name: romctrl - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created derived from ramctrl
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
library UNISIM;
use UNISIM.VComponents.all;

use work.libpps4.all;

entity romctrl is
    generic (
           g_ref         : natural  := 16#53CD#
    );
    Port (
           hiclk       : in        STD_LOGIC;
           spo         : in        STD_LOGIC;
           pps4_phi    : in        pps4_ph_type;        
           rrsel       : in        std_logic;
           ab          : in        STD_LOGIC_VECTOR (11 downto 1);
           dout        : out       STD_LOGIC_VECTOR (8 downto 1);
           cs          : in        std_logic  --cs => g_ROMSEL

          );
end romctrl;

architecture Behavioral of romctrl is

--TODO : find the right polarity of nDO
signal nDO_int                  : std_logic_vector(8 downto 1):= (others=>'Z');

signal ROM_Addr_Latch           : std_logic_vector (10 downto 0);
signal ROM_DOUT                 : STD_LOGIC_VECTOR(8 DOWNTO 1);

signal is_ROM_Device_On : STD_LOGIC :='0';

--all possible types of rom here
COMPONENT A1752CFINTERNROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;
COMPONENT A1752EFINTERNROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;
COMPONENT A1753CEINTERNROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;
COMPONENT A1753CDINTERNROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;
COMPONENT A1761INTERNROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;
COMPONENT A1762INTERNROM
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(10 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;

--next  lines to avoid pointless warnings about black boxes (advice from https://www.xilinx.com/support/answers/9838.html)
attribute box_type : string; 
attribute box_type of A1752CFINTERNROM : component is "black_box"; 
attribute box_type of A1752EFINTERNROM : component is "black_box"; 
attribute box_type of A1753CDINTERNROM : component is "black_box"; 
attribute box_type of A1753CEINTERNROM : component is "black_box"; 
attribute box_type of A1761INTERNROM   : component is "black_box"; 
attribute box_type of A1762INTERNROM   : component is "black_box"; 

begin

     dout <= nDO_int;
    
     --will require vhdl-2008
     gc : case g_ref generate
        when 16#52EF#       =>
             CFROM : A1752EFINTERNROM PORT MAP (
                                        clka     => hiclk,
                                        addra    => ROM_Addr_Latch(10 downto 0), 
                                        douta    => ROM_DOUT);
        when 16#53CE#       =>
             CFROM : A1753CEINTERNROM PORT MAP (
                                        clka     => hiclk,
                                        addra    => ROM_Addr_Latch(10 downto 0), 
                                        douta    => ROM_DOUT);
        when 16#53CD#       =>
             CFROM : A1753CDINTERNROM PORT MAP (
                                        clka     => hiclk,
                                        addra    => ROM_Addr_Latch(10 downto 0), 
                                        douta    => ROM_DOUT);
        when 16#61#       =>
             CFROM : A1761INTERNROM   PORT MAP (
                                        clka     => hiclk,
                                        addra    => ROM_Addr_Latch(10 downto 0), 
                                        douta    => ROM_DOUT);
        when 16#62#       =>
             CFROM : A1762INTERNROM   PORT MAP (
                                        clka     => hiclk,
                                        addra    => ROM_Addr_Latch(10 downto 0), 
                                        douta    => ROM_DOUT);
        when others         =>
             CFROM : A1752CFINTERNROM PORT MAP (
                                        clka     => hiclk,
                                        addra    => ROM_Addr_Latch(10 downto 0), 
                                        douta    => ROM_DOUT);
     end generate gc;


    process(hiclk)
        variable lastpps4_phi : pps4_ph_type := idlexx;
    begin
        if rising_edge(hiclk) then
            if spo = '1' then           --if reset
                --reset branch
                is_ROM_Device_On <= '0';
                nDO_int          <= (others=>'Z');
            else                        --if not reset
            --not reset branch
            
            --state machine execution, based on phases of clka/clkb
                if lastpps4_phi /= pps4_phi then
                    case pps4_phi is
                        when phi1A  =>
                            is_ROM_Device_On <= '0'; --next clock this signal will be unconditionnaly reset
                         
                        when phi1   =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
                            
                        when phi2   =>
                            nDO_int <= (others=>'Z');
                            
                        when phi3A  =>
                            nDO_int <= (others=>'Z');
                            ROM_Addr_Latch <= ab;
                            if cs = rrsel then
                                is_ROM_Device_On <= '1';
                            else 
                                is_ROM_Device_On <= '0';				
                            end if;
        
                        when phi3   =>
                            nDO_int <= (others=>'Z');
                        
                        when phi4   =>
                            --A17 push rom data on the bus from begin of phi4 thru end of phi1A
                            if (is_ROM_Device_On = '1') then
                                nDO_int <= ROM_DOUT; -- expose rom values as input of iobufs
                                --this value set continues in phi1A. bus will be deactivated in phi1
                            else
                                nDO_int <= (others=>'Z');
                            end if;
                        when others =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
                    end case;
                end if;                 --end if pps4_phi changed
                lastpps4_phi := pps4_phi;
            end if;                     --end if reset else
        end if;                          --end if rising_edge
    end process;
        
end Behavioral;
