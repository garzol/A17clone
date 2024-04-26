----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04.11.2023 21:52:54
-- Design Name: 
-- Module Name: ramctrl - Behavioral
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
library UNISIM;
use UNISIM.VComponents.all;

use work.libpps4.all;

entity ramctrl is
    Port (
           hiclk       : in        STD_LOGIC;
           spo         : in        STD_LOGIC;
           pps4_phi    : in        pps4_ph_type;        
           rrsel       : in        std_logic;
           ab          : in        STD_LOGIC_VECTOR (8 downto 1);
           din         : in        STD_LOGIC_VECTOR (8 downto 1);
           dout        : out       STD_LOGIC_VECTOR (8 downto 1);
           wio         : in        STD_LOGIC;
           cs          : in        std_logic_vector(1 downto 0)  --cs => g_RAMSEL&g_RAMAB8)

          );
end ramctrl;

architecture Behavioral of ramctrl is

--TODO : find the right polarity of nDO
signal nDO_int                  : std_logic_vector(8 downto 1):= (others=>'Z');

signal RAM_nRW                  : STD_LOGIC_VECTOR(0 DOWNTO 0) := "0";  --read by default
signal RAM_Addr_Latch           : std_logic_vector (6 downto 0);
signal RAM_DOUT                 : STD_LOGIC_VECTOR(4 DOWNTO 1);
signal RAM_DIN                  : STD_LOGIC_VECTOR(4 DOWNTO 1);

signal is_RAM_Device_On : STD_LOGIC :='0';

COMPONENT A17INTERNRAM 
  PORT (
    clka  : IN STD_LOGIC;
    wea   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    dina  : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END COMPONENT;

--next 2 lines to avoid pointless warnings about black boxes (advice from https://www.xilinx.com/support/answers/9838.html)
attribute box_type : string; 
attribute box_type of A17INTERNRAM : component is "black_box"; 

begin

     dout <= nDO_int;
     
	 CFRAM : A17INTERNRAM PORT MAP (
	                            clka     => hiclk,
	                            wea      => RAM_nRW, 
	                            addra    => RAM_Addr_Latch(6 downto 0), 
	                            dina     => RAM_DIN, 
	                            douta    => RAM_DOUT);


    process(hiclk)
        variable lastpps4_phi : pps4_ph_type := idlexx;
    begin
        if rising_edge(hiclk) then
            if spo = '1' then           --if reset
                --reset branch
                is_RAM_Device_On <= '0';
                nDO_int          <= (others=>'Z');
            else                        --if not reset
            --not reset branch
            
            --state machine execution, based on phases of clka/clkb
                if pps4_phi /= lastpps4_phi then
                    case pps4_phi is
                        when phi1A  =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
        
                            RAM_Addr_Latch <= ab(7 downto 1); 
                            RAM_nRW <= "0";    
                            if wio = '0' then  --this is a ram access, not an IO
                                if (rrsel = cs(1)) then
                                    if (ab(8) = cs(0)) then
                                        is_RAM_Device_On <= '1';
                                    else
                                        is_RAM_device_On <= '0';
                                    end if;
                                 else
                                     is_RAM_device_On <= '0';
                                 end if;
                             else
                                 is_RAM_device_On <= '0';
                             end if;
                         
                        when phi1   =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
                        when phi2   =>
                            --from beginning of phi2 till end of phi3A we have to drive
                            --RAM D1..D4 if we are selected
                            if is_RAM_Device_On = '1' then --RAM selected (during phi1A)
                                nDO_int (4 downto 1) <= RAM_DOUT; --RAM_DOUT is read from CFRAM(RAM_ADDR_Latch)
                                --to be continued in phi3A part dedicated to ram,which means that the only thing to do is to rest T lines to 1 at the
                                --beginning of phi3. That's very simple in fact.
                            end if;
                        when phi3A  =>
                            if (is_RAM_Device_On = '1') then  
                                --do we have to write to A17's ram?
                                if wio = '1' then  --it is a write 
                                    RAM_DIN <= din(8 downto 5); 
                                    RAM_nRW <= "1";   --we will have to reset this signal to 0 the sooner the better
                                                      --need to be set for at least 1 or 2 sysclk, (2 to be sure)
                                                            --but 1 should be enough
                                                            --actually we will reset it at the next phi, that will be fine
                                end if;
                            end if;
                        when phi3   =>
                            RAM_nRW <= "0";						
                            nDO_int <= (others=>'Z');
                        
                        when phi4   =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
                        when others =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
                    end case;
                end if;                 --end if pps4_phi changed
                lastpps4_phi := pps4_phi;
            end if;                     --end if not reset else
        end if;                         --end if rising edge
    end process;
        
end Behavioral;
