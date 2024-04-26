----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 22.11.2023 22:01:34
-- Design Name: 
-- Module Name: ioxadapter - Behavioral
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

use work.libpps4.all;


entity ioxAdapter is
     Port ( hiclk       : in    STD_LOGIC;
            pps4_phi    : in    pps4_ph_type;
            inpx_gen    : out   std_logic_vector(15 downto 0);   --yes, it's an OUT, because it is generated here 
            outx_read   : in    std_logic_vector(15 downto 0);   --yes, it's an IN, because it is generated in ioctrl 
            iox         : inout std_logic_vector( 7 downto 0); --to the extern mux interface 
            seliobank   : out   std_logic_vector( 1 downto 0);
            latchiobank : out   std_logic_vector( 1 downto 0)
          );

end ioxAdapter;

architecture Behavioral of ioxAdapter is
signal let_inp_reading : boolean := false;  
signal let_out_setting : boolean := false;  
begin


    process(hiclk)
        variable r_state              : natural range 0 to 15 := 0;
        variable last_let_inp_reading : boolean := false;
        variable last_let_out_setting : boolean := false;
        variable tempo_sig            : natural range 0 to 7 := 0; --must be reset after each use in every machine state
    begin
        if (rising_edge(hiclk)) then
            case r_state is 
                when 0      =>                 --idle state
                   seliobank    <= "11";       --disable both inputs 7-buffer
                   latchiobank  <= "11";
                   iox          <= (others=>'Z'); --set pysical port as an input
                   if     let_inp_reading = true and last_let_inp_reading = false then
                        r_state := 1;          --let start reading
                    elsif let_out_setting = true and last_let_out_setting = false then
                        r_state := 7;          --let start writing
                    end if;
                when 1      =>                 --launch reading of 1st half
                    seliobank        <= "10";  --activate 74244 bank 0
                    tempo_sig := tempo_sig + 1;
                    if tempo_sig >= 2 then
                        tempo_sig := 0;
                        r_state := 2;               
                    end if;
                    
                when 2      =>                  --read 1st half
                    inpx_gen(7 downto 0) <= iox;--let actually read
                    r_state := 3;               
                    
                when 3      =>                 --re HI-Z all input
                    seliobank        <= "11";
                    tempo_sig := tempo_sig + 1;
                    if tempo_sig >= 2 then
                        tempo_sig := 0;
                        r_state := 4;           
                    end if;

                when 4      =>                 
                    seliobank        <= "01";  --activate 74244 bank 1
                    tempo_sig := tempo_sig + 1;
                    if tempo_sig >= 2 then
                        tempo_sig := 0;
                        r_state := 5;               --let actually read
                    end if;
                    
                when 5      =>                  --read 2nd half
                    inpx_gen(15 downto 8) <= iox;
                    r_state := 6;               --let back to idle 
                    
                when 6      =>                 --read 1st half
                    seliobank        <= "11";
                    r_state := 0;               --let back to idle             

                when 7      =>                 --write 1st half on inout of fpga
                    iox <= outx_read(7 downto 0);
                    r_state := 8;

                when 8      =>                 --load 1st half to 74573 latch
                    latchiobank      <= "10";
                    tempo_sig := tempo_sig + 1;
                    if tempo_sig >= 2 then
                        tempo_sig := 0;
                        r_state := 9;               --let actually read
                    end if;

                    
                when 9      =>
                    latchiobank      <= "11";
                    r_state := 10;

                when 10     =>                  --write 2nd half
                    iox <= outx_read(15 downto 8);
                    r_state := 11;
                    
                when 11     =>
                    latchiobank      <= "01";
                    tempo_sig := tempo_sig + 1;
                    if tempo_sig >= 2 then
                        tempo_sig := 0;
                        r_state := 12;           --let write 2nd half
                    end if;
                                        
                when 12     =>
                    latchiobank      <= "11";
                    r_state := 0;           --go back to idle
                     
                when others =>
                    r_state := 0;              
                    tempo_sig := 0;
                    
             end case;

            last_let_inp_reading := let_inp_reading;    
            last_let_out_setting := let_out_setting;                
        end if;
                    
    end process; 
    
    
    
    process(pps4_phi)
    begin
        
    --state machine execution, based on phases of clka/clkb

        case pps4_phi is
            when phi1A  =>
                let_inp_reading <= false;
                let_out_setting <= false;
                
            when phi1   =>
                --reading inputs now
                --this is an arbitrary choice to sample inputs now and not elsewhen
                --we selected here because inputs are read by cpu at next phase (phi2)
                let_out_setting <= false;
                let_inp_reading <= true;
                    
                
            when phi2   =>
                --this is when ID4 is returned to the cpu (the IOx inpx reading)
                let_inp_reading <= false;
                let_out_setting <= false;
                
                
            when phi3A  =>
                --this is when output is set by cpu (outx is set or reset)
                let_inp_reading <= false;
                let_out_setting <= false;
                
            when phi3   =>
                let_inp_reading <= false;
                let_out_setting <= true;
                
            when phi4   =>
                --REreading inputs now(to make sure we capture any change asap
                --this is an arbitrary choice to sample inputs now and not elsewhen
                --we selected here because inputs are read by cpu at next phase (phi2)
                let_inp_reading <= true;
                let_out_setting <= false;
                
            when others =>
                let_inp_reading <= false;
                let_out_setting <= false;
                
        end case;

    end process;
       

end Behavioral;
