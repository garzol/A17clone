----------------------------------------------------------------------------------
-- Company: AA55 consulting
-- Engineer: garzol 
-- 
-- Create Date: 23.10.2023 22:27:42
-- Design Name: PPS-4 GPKD10788
-- Module Name: GPKD10788 - Behavioral
-- Project Name:PPS4 clones 
-- Target Devices: XC7S15FTGB196-1
-- Tool Versions: vivado 2023.1.1
-- Description: 
-- Module for emulation of GPKD PPS-4
-- keyboard reading not yet implemented
-- for lack of information and testing 
-- solutions since keyboard control
-- is not used in GTB sys1 CPUs
--
--
-- Note that for x, dbs, here 1 means +5V (VSS), 0 means -12V (VDD)
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
use work.libgpkd.all;
use work.common.all;

entity GPKD10788 is
    Port ( 
           hiclk         : in     STD_LOGIC;
           spo           : in     STD_LOGIC;
           pps4_phi      : in     pps4_ph_type;
           sc5           : in     STD_LOGIC;
           sc6           : in     STD_LOGIC;
           sc7           : in     STD_LOGIC;
           x             : out    STD_LOGIC_VECTOR (7 downto 0);
           dbs           : out    STD_LOGIC;
           
           status        : out    std_logic_vector (7 downto 0);
           RDA_data_st   : out    t_sreg;
           RDB_data_st   : out    t_sreg;
           dspl_A_off_st : out    std_logic;
           dspl_B_off_st : out    std_logic;
           
           da : out STD_LOGIC_VECTOR (4 downto 1);
           db : out STD_LOGIC_VECTOR (4 downto 1);
           y : in STD_LOGIC_VECTOR (7 downto 0);
           id : in STD_LOGIC_VECTOR (8 downto 1);
           wio : in STD_LOGIC;
           do : out STD_LOGIC_VECTOR (8 downto 1);  --do(8..5) are not connected (input only)
           dldir : out STD_LOGIC);
           
end GPKD10788;

architecture Behavioral of GPKD10788 is






--now we need memory to save keyboard buffer (9x8)...
signal KBD_X_9x8buffer        : integer_vector(0 to 8); --no init needed
signal KBD_Y_9x8buffer        : integer_vector(0 to 8); --no init needed
signal KBD_cur_index          : integer range 0 to 8 := 0;
signal KBD_buffer_overflow    : std_logic := '0';

--cross processes signal
signal decrement_KBD_cur_index: std_logic := '0';
 
--strobe management requires to count bit times from 0 through 1536
--we expect the compiler to be smart enough to make the optimization
constant cKbd_scan_cycl : natural  range 0 to 1536 := 1536;
signal  pps_bit_time_nb : natural  range 0 to 1536 := 0;

--now we need memory to save display digits that will be received...
--defined in common library file
--type   t_sreg is array(0 to 15) of std_logic_vector(3 downto 0);
--signal RDA_data               : t_sreg;
--signal RDB_data               : t_sreg;

--4(1) 4(10) 4(100) 4(1000) 4(10000) 4(100000)
--na(1) na(10)
--3(1) 3(10) 3(100) 3(1000) 3(10000) 3(100000)
--na(1) na(10)
signal RDB_data               : t_sreg := (
                                            "1011", "1111", "1011", "1011",   -- 0101 not A which is c (player 4)
                                            "1011", "1011", "0011", "0100",   -- 0110 not 9 which is 9
                                            "1100", "1111", "1100", "1100",   -- 0111 not 8 which is 8 (player 3)
                                            "1100", "1100", "0101", "0110");  -- 1000 not 7 which is 7

--2(1) 2(10) 2(100) 2(1000) 2(10000) 2(100000)
--credit(1) credit(10)
--1(1) 1(10) 1(100) 1(1000) 1(10000) 1(100000)
--lotery(1) lotery(10)
signal RDA_data               : t_sreg := (
                                            "1101", "0000", "1101", "1101",   -- 0001 not E which is t (player 2)
                                            "1101", "1101", "0111", "1000",   -- 0010 not D which is 5 without right leg
                                            "1110", "0000", "1110", "1110",   -- 0011 not C which is u (upper u) (player 1)
                                            "1110", "1110", "1001", "1010");  -- 0100 not B which is /c (c returned) 


signal RDB_test               : t_sreg := (
                                            "0101", "1111", "0101", "0101",   -- 0101 not A which is c (player 3)
                                            "0101", "0101", "0110", "0110",   -- 0110 not 9 which is 9
                                            "0111", "1111", "0111", "0111",   -- 0111 not 8 which is 8 (player 4)
                                            "0111", "0111", "1000", "1000");  -- 1000 not 7 which is 7
signal RDA_test               : t_sreg := (
                                            "0001", "1111", "0001", "0001",   -- 0001 not E which is t (player 1)
                                            "0001", "0001", "0010", "0010",   -- 0010 not D which is 5 without right leg
                                            "0011", "1111", "0011", "0011",   -- 0011 not C which is u (upper u) (player 2)
                                            "0011", "0011", "0100", "0100");  -- 0100 not B which is /c (c returned)

signal da_intern              : std_logic_vector(4 downto 1) := "0000";
signal db_intern              : std_logic_vector(4 downto 1) := "0000";

signal dspl_A_off             : std_logic := '1'; -- is for: DA1..4 and DB1, DB2. initial off
signal dspl_B_off             : std_logic := '1'; -- is for: DB3, DB4. initial off

-- nD0 temp value to be returned by device. Calculated during ph1, delivered during phi2
signal nDO_10788_ret          : std_logic_vector(4 downto 1) := "0000";

--cVSS is used to determine the on state of Xi and the "off" state of DAx, DBx
--By looking at the diagram figure8 of the pps4 datasheet one sees that Xi is on at VSS
--VSS is +5V. So how to set Xi output to VSS from the FPGA?
--With the current HW, Xi is controlled by a P-Channel MOSFET. To have +5V on the output,
--you must turn this MOSFET on. To turn it on you must apply an FPGA '0' logic. cqfd
--
--For the DA, DB, this is another story, while the result will be the same...
--The off state of DA, DB is VSS as well as told in the datasheet page 10 "circuit termination for ttl interface"
--Actually it is because the off state of 7448 (all 7 digits off) is when ABCD=1111 on its entry
--Then, the off state is also VSS in this case. 
--The following constant is used for both situations (X and DA,DB)
constant cVSS                 : std_logic := '0';

-- Control of dldir. to be confirmed on site
constant cSetDataLOut         : std_logic := '0';


signal nDO_int                : std_logic_vector(4 downto 1) := "0000";
signal dldir_int              : std_logic := not cSetDataLOut;


signal add2buffer             : std_logic := '0';
signal addx                   : integer range 0 to 7;
signal addy                   : integer range 0 to 7;

signal spo_int                : std_logic := '1';

--for testing purposes. status1 is 0x01 if credit window is off 
signal status1                : std_logic_vector(7 downto 0) := X"00";

begin

    --for diag through wifi
    RDA_data_st   <=  RDA_data;
    RDB_data_st   <=  RDB_data;
    dspl_A_off_st <= dspl_A_off;
    dspl_B_off_st <= dspl_B_off;

    --for testing use '0'
    spo_int <= spo; --'0';   --in real life do affect it to spo
    do(8 downto 5) <= "1111";
    dldir          <= dldir_int;
    
    --for testing
    do(4 downto 1) <= "1111";
    
--    do(4 downto 1) <= nDO_int when dldir_int = cSetDataLOut else
--                      "1111";
   
process_cmd:    process(hiclk)
        variable last_pps4    : pps4_ph_type := idlexx;
        variable isIOSel      : boolean := false;
        variable IOCmd_10788  : std_logic_vector(4 downto 1);
    begin
        if (rising_edge(hiclk)) then
            --Management of cross processes signals...
            --the decrement_KBD_cur_index signal is never set for more than 1 clock
            if decrement_KBD_cur_index = '1' then
                decrement_KBD_cur_index <= '0';
            end if;
            
            --during reset, do nothing, stay in hi-Z on ID bus
			if spo_int = '1' then --SPO is maintained by master device to -12V for 100ms min
				--do reset things
                dldir_int <= not cSetDataLOut;
            -- end of SPO = 1 			
			else
			    -- no need for handling metastability here
			    -- because it should be managed at root, in clkgen.
				if last_pps4 /= pps4_phi then
				-- change of phase
					case pps4_phi is
						when phi1A =>
                            dldir_int <= not cSetDataLOut;
							if wio = '1' then
							     -- is it us?
							     if (id(8 downto 5) = '1'&sc7&sc6&sc5) then
									IOCmd_10788 := id(4 downto 1);	 --KLA, or KLB, or etc... 								
							        isIOSel := true;
							     else
							        isIOSel := false;
							     end if;
							else
							     isIOSel := false;
							end if;
						when phi1 =>
                            null;

						when phi2 =>
						    -- we are to send data to accumulator
						    -- but if the command concerns the display... What? That is the question
                            if (isIOSel) then
                                case IOCmd_10788 is
                                    when others =>
                                       nDO_int (4 downto 1) <= nDO_10788_ret; -- provisory waiting for knowing more
                                       dldir_int <= cSetDataLOut;
                                    end case;
                            else
                                dldir_int <= not cSetDataLOut;  
                            end if;
                            
                        when phi3A =>
						   -- we think that the job is actually made during this phi1 phase
						   -- it makes sense, and yet we think it is not very important
						   -- if it is not the case
                           if    (isIOSel)  then
                                case IOCmd_10788 is
                                    when cKLA =>
                                        -- The datasheet reads : you begin with LSB loaded into MSD
                                        -- and so forth until LSB lands onto LSD after 16 KLAs
                                        for I in 15 downto 1 loop
                                            RDA_data(I-1)<=RDA_data(I);
                                        end loop;
                                        RDA_data(15)  <= ID(8 downto 5);
                                        dspl_A_off <= '1'; --read note 3 of table 1 in the original datasheet
                                        nDO_10788_ret <= "0000";  --todo: check out what the original returns here
        
                                    when cKLB =>
                                        for I in 15 downto 1 loop
                                            RDB_data(I-1)<=RDB_data(I);
                                        end loop;
                                        RDB_data(15)  <= ID(8 downto 5);
                                        dspl_B_off <= '1'; --read note 3 of table 1 in the original datasheet
                                        nDO_10788_ret <= "0000";  --todo: check out what the original returns here

                                    when cKAF =>
                                        dspl_A_off <= '1';
                                        nDO_10788_ret <= "0000";  --todo: check out what the original returns here
                                        
                                    when cKBF =>
                                        dspl_B_off <= '1';
                                        nDO_10788_ret <= "0000";  --todo: check out what the original returns here
                                        
                                    when cKDN =>
                                        dspl_A_off <= '0';
                                        dspl_B_off <= '0';
                                        nDO_10788_ret <= "0000";  --todo: check out what the original returns here
                                        
                                    when cKTS =>
                                        if KBD_cur_index < 1 then
                                            --the key buffer is empty
                                            nDO_10788_ret <= "0000";
                                        else
                                            --the key buffer is not empty.
                                            --we assume here that KTS does not modify the buffer
                                            --hence calling n times KTS will return the same result
                                            --again and again until KTR is called
                                            --this is a way to see things, maybe there are others...
                                            nDO_10788_ret <= '1'&std_logic_vector(to_unsigned(KBD_X_9x8buffer(KBD_cur_index-1), 3));
                                        end if;       
                                    when cKTR =>
                                        if KBD_cur_index < 1 then
                                            --datasheet does not explain 
                                            --if you call KTR before KTS
                                            nDO_10788_ret <= "0000";
                                        else
                                            nDO_10788_ret <= KBD_buffer_overflow&std_logic_vector(to_unsigned(KBD_Y_9x8buffer(KBD_cur_index-1), 3));
                                            --we now want to decrement KBD_cur_index
                                            --but it is not possible from here, hence the intermediate signal...
                                            decrement_KBD_cur_index <= '1';
                                            --KBD_cur_index <= KBD_cur_index-1;  --inferred by myself from implicit not said in datasheet
                                        end if;       
                                    when cKER =>
                                        --todo manage this properly
                                        --KBD_cur_index <= 0;
                                        KBD_buffer_overflow <= '0';
                                        nDO_10788_ret <= "0000";  --todo: check out what the original returns here
                                                                                                                 
                                    when others =>
                                        nDO_10788_ret <= "0000";
                                end case;
                            end if;
           
 
                        when phi3 =>
                            isIOSel := false;
                            dldir_int <= not cSetDataLOut;
						when phi4 =>
                            dldir_int <= not cSetDataLOut;
						when others =>
                            dldir_int <= not cSetDataLOut;
        			end case;
				-- end change of phase
				end if;
				last_pps4 := pps4_phi;				

            -- end of SPO = 0 						
			end if; 
        end if;
    end process process_cmd;


-- management of keyboard buffer
process_insp_kbd : process(hiclk)
variable nb_ones             : integer range 0 to 8;
variable temp_x_strobe       : integer range 0 to 7;
variable temp_y_return       : integer range -1 to 7;
variable lastdbs             : std_logic := '0';
begin
    if rising_edge(hiclk) then
        --rising or falling dbs must be in accordance with the dbs test against 1 or 0 in the above process_Y_ii's
        --first handle the decrement signal whose duration is exactly 1 clock
        if decrement_KBD_cur_index = '1' then
            if KBD_cur_index > 0 then --should never be in other case
                KBD_cur_index      <= KBD_cur_index - 1;
            end if;
        else
            if dbs = '0' and lastdbs = '1' then
                --untested version of the kbd. because no test available
                if add2buffer = '1' then
                    --is it a new key?
                    if (KBD_X_9x8buffer(0) = addx and KBD_Y_9x8buffer(0) = addy) then
                        null;
                    else
                        --yes, there is a new key to register
                        --first make room in the key buffers if they are not full
                        if KBD_cur_index < KBD_X_9x8buffer'length then
                            for I in KBD_X_9x8buffer'length-2 downto 0 loop
                            -- test full and shift the buffer xy
                                KBD_X_9x8buffer(I+1) <= KBD_X_9x8buffer(I);
                                KBD_Y_9x8buffer(I+1) <= KBD_Y_9x8buffer(I);
                            end loop;
                        else
                            --there is something to do with error flag, but we don"t realy care for now
                            KBD_buffer_overflow <= '1';
                        end if;
                        --store the new key at pos 0
                        KBD_X_9x8buffer(0) <= addx;
                        KBD_Y_9x8buffer(0) <= addy;
                        KBD_cur_index      <= KBD_cur_index + 1;
                    end if;
                end if;
            end if;
            lastdbs := dbs;
        end if;         -- decrement_KBD_cur_index
    end if;             -- rising_edge
end process process_insp_kbd;
    
 
process_X: process(hiclk)
-- when Xi is activated, it is first 20 bt at 0, then 76 bt at 1
constant cxi_on_1       : integer  range 0 to 1536 := 76;
constant cxi_on_0       : integer  range 0 to 1536 := 20;
constant cy0_offset     : integer  := 19;
variable xi_cur_nb      : integer  range 0 to 1536 := 0;
variable x_i            : integer  range 0 to X'LENGTH-1 := 0;
variable dbs_phase      : integer  range 0 to 1 := 0;
variable count_strokes  : integer  range 0 to 64;
variable temp_x_stroke  : integer  range 0 to 7;
variable temp_y_stroke  : integer  range 0 to 7;
variable last_pps4      : pps4_ph_type := idlexx;

variable flag6          : boolean := false;
variable flag7          : boolean := false;

begin
    if (rising_edge(hiclk)) then
        if spo_int = '1' then --SPO is maintained by master device to -12V for 100ms min
            -- pps_bit_time_nb <= 0;
            x <= (others=>'0');
            dbs <= cVSS;
            xi_cur_nb       := 0;
            x_i             := 0;
            dbs_phase       := 0;
        -- end of SPO = 1 			
        else
        
            if last_pps4 /= pps4_phi and pps4_phi = phi1A then
    
                -- pps_bit_time_nb <= x_i*(cxi_on_0+cxi_on_1)+xi_cur_nb + (1-dbs_phase)*(cxi_on_0+cxi_on_1)*x'LENGTH;
     
                
                -- let's update the Xs signals
                count_strokes := 0; --counts the number of strokes
                for ii in 0 to (x'LENGTH-1) loop
                    if ii = x_i then
                        dbs <=      cVSS when dbs_phase = 0 else
                               (not cVSS);
                        if xi_cur_nb < cxi_on_0 then
                            x(ii) <= not cVSS; --virtually '0'; --off state
                            
                            --basicaly da and db are null
                            da_intern <= (others => cVSS);
                            db_intern <= (others => cVSS);
                        else
                            x(ii) <= cVSS;     --virtually '1'; --on state
                            
                            -- management of da, db outputs
                            if (dbs_phase = 0) then
                                  if ii = 6 then
                                    if RDA_data(ii) = "0000" then
                                        flag6 := true;
                                    else
                                        flag6 := false;
                                    end if;
                                  end if;
                                  if ii = 7 then
                                    if RDA_data(ii) = "0000" then
                                        flag7 := true;
                                    else
                                        flag7 := false;
                                    end if;
                                  end if;
                                    
                                  da_intern <= RDA_data(ii);
                                  db_intern <= RDB_data(ii);
--                                  da_intern <= not RDA_test(ii);
--                                  db_intern <= not RDB_test(ii);
                            else
                                  da_intern <= RDA_data(ii+8);
                                  db_intern <= RDB_data(ii+8);
--                                  da_intern <= not RDA_test(ii+8);
--                                  db_intern <= not RDB_test(ii+8);
                            end if;
                            -- end da, db management 
                            
                            --start sampling of ys
                            if dbs_phase = 1 then      
                                for kk in 0 to 7 loop
                                    if xi_cur_nb = cxi_on_0 + cy0_offset + 9*kk then
                                        --sampling of return y(kk) with strobe x(ii)
                                        if y(kk) = '1' then
                                            count_strokes := count_strokes + 1;
                                            temp_x_stroke := ii;
                                            temp_y_stroke := kk;
                                        end if;
                                        if kk = 7 then
                                            --we are done with the samplings.
                                            if count_strokes = 1 then
                                                add2buffer <= '1';
                                                addx       <= temp_x_stroke;
                                                addy       <= temp_y_stroke;
                                            else
                                                add2buffer <= '0';
                                            end if;
                                        end if;
                                    end if;
                                end loop;  -- kk     
                            end if; --end if dbs=(not cVSS)      
                        end if;     --end if xi_cur_nb < cxi_on_0 then
                    else
                        x(ii) <= not cVSS; --'0';
                    end if;
                end loop;  -- ii
                              

                -- let's increment Xi_cur_nb and update all its affiliates
                xi_cur_nb := xi_cur_nb + 1;
                if (xi_cur_nb = (cxi_on_0 + cxi_on_1)) then
                    xi_cur_nb := 0;
                    if (x_i = x'LENGTH-1) then
                        x_i := 0;
                        dbs_phase := 1 - dbs_phase;
                    else 
                        x_i := x_i + 1;
                    end if;
                end if;
            end if; --transition of pps4 clock (bit time)             
 			last_pps4 := pps4_phi;	--update in the end because it is a variable here, not a signal			
 
       --flag6 and 7 are there to track when the display is completely set to blank 
       if flag6=true and flag7 = true then
            status1 <= X"01";
       else status1 <= X"00";
       end if;
       end if; -- end of SPO = 0
        
    end if;
end process process_X;



    
da <= da_intern when dspl_A_off = '0' else
       (others=>cVSS);

db(2 downto 1) <= db_intern(2 downto 1) when dspl_A_off = '0' else
       (others=>cVSS);
       
db(4 downto 3) <= db_intern(4 downto 3) when dspl_B_off = '0' else
       (others=>cVSS);
       
status <= status1;
       
end Behavioral;
