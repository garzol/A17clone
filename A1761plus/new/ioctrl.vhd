----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 21.11.2023 17:41:41
-- Design Name: 
-- Module Name: ioctrl - Behavioral
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

use work.libpps4.all;

entity ioctrl is
    Generic (
           g_iodevnum    : std_logic_vector(1 downto 0)
            );
    Port (
           hiclk       : in       STD_LOGIC;
           spo         : in       STD_LOGIC;
           pps4_phi    : in       pps4_ph_type;        
           ab          : in       STD_LOGIC_VECTOR (11 downto 1);
           din         : in       STD_LOGIC_VECTOR (8 downto 1);
           dout        : out      STD_LOGIC_VECTOR (8 downto 1);
           wio         : in       STD_LOGIC;
           seldir      : out      STD_LOGIC;     --1=input, 0=output
           inpx        : in       std_logic_vector(15 downto 0);
           outx        : out      std_logic_vector(15 downto 0)
          );
end ioctrl;

architecture Behavioral of ioctrl is
--TODO : find the right polarity of nDO
signal nDO_int                  : std_logic_vector(8 downto 1):= (others=>'Z');

signal is_IO_Device_On : STD_LOGIC :='0';

signal IOCmd  : STD_LOGIC :='0';
signal IONum  : STD_LOGIC_VECTOR(3 DOWNTO 0);
signal IOBMl  : STD_LOGIC_VECTOR(2 DOWNTO 1);

begin


    dout <= nDO_int;
     

    process(hiclk)
        variable lastpps4_phi : pps4_ph_type := idlexx;
    begin
        if rising_edge(hiclk) then
            if spo = '1' then           --if reset
                --reset branch
                is_IO_Device_On <= '0';
                nDO_int         <= (others=>'Z');
                seldir          <= '1';	--allio are input at reset. 1 is input, 0 is output
                outx            <= (others=>'1');
            else                        --if not reset
            --not reset branch
            
            --state machine execution, based on phases of clka/clkb
                if lastpps4_phi /= pps4_phi then
                    case pps4_phi is
                        when phi1A  =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
        
                            if wio = '1' then  --this is an IO access, not ram
                                if (din(8 downto 5) = '0'&g_iodevnum&'0') then
                                    --yes this is us
                                    IOCmd <= din(1);
                                    IONum(3 downto 0) <= ab(4 downto 1);
                                    IOBMl <= ab(6 downto 5);
                                    is_IO_Device_On <= '1';
                                end if;
                            end if;
                            
                         
                        when phi1   =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
                            
                        when phi2   =>
                            --
                            if is_IO_Device_On = '1' then
                                --we are to load accumulator to value of IO(IONum)
                                if IOBMl = "00" then
                                    --let's assign nDO_int (4) to not IOx(x=IONum)
                                    nDO_int (4)          <= not inpx(to_integer(unsigned(IONum(3 downto 0))));
                                    nDO_int (3 downto 1) <= "111"; --only acceptable value for recel code to work
                                    --/!\ I think we should return din(3..1) or /din, to be perfect
                                    --we'll see that later
                                    --/!\ let's try the opposite... just to see.
                                    --nDO_int (4) <= inpx(to_integer(unsigned(IONum(3 downto 0))));
                                end if;
                            end if;
                    
                            
                            
                        when phi3A  =>
                            if is_IO_Device_On = '1' then       
                                --IOCmd contains ses or sos
                                if IOCmd = cSES then -- cste cSES set at 0 which is 
                                    if din(8) = '0' then --set IOs as outputs
                                        seldir <= '0';	--allio are input at reset. 0 is output, 1 is input
                                    else
                                        --disable all outputs
                                        seldir <= '1';	--allio are input at reset. 0 is output, 1 is input
                                    end if;
                                 else
                                    --cSOS
                                    if IOBMl = "00" then
                                        -- IOx_out <=  not ID(8);  -- obsolete old hw
                                        --/!\ let's try the opposite... just to see.
                                        outx(to_integer(unsigned(IONum))) <= not din(8);
                                        --outx(to_integer(unsigned(IONum))) <=  din(8);
                                    end if;
                                 end if;             
                            end if;
                            is_IO_Device_On <= '0';
                            
                        when phi3   =>
                            nDO_int <= (others=>'Z');
                        
                        when phi4   =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
                            
                        when others =>
                            nDO_int <= (others => 'Z'); --bus data is hiz during phi1 (and also phi3)
                            
                    end case;
                end if;
                lastpps4_phi := pps4_phi;
    
            end if;                     --end if reset else
        end if;                         --end if rising edge
    end process;
       

end Behavioral;
