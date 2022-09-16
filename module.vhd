library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity project_reti_logiche is
    port (
        i_clk       : in    std_logic;
        i_rst       : in    std_logic;
        i_start     : in    std_logic;
        i_data      : in    std_logic_vector(7 downto 0);
        o_address   : out   std_logic_vector(15 downto 0);
        o_done      : out   std_logic;
        o_en        : out   std_logic;
        o_we        : out   std_logic;
        o_data      : out   std_logic_vector(7 downto 0)
    );
end project_reti_logiche;

architecture rtl of project_reti_logiche is
    
    signal ncolonne : std_logic_vector(7 downto 0);
    signal nrighe : std_logic_vector(7 downto 0);
    signal max_pixel : std_logic_vector(7 downto 0) := (others => '0');
    signal min_pixel : std_logic_vector(7 downto 0) := (others => '1');
    type state_type is (
        RESET,
        START,
        WAITR,
        READ,
        WAITR2,
        READ2,
        WAITW,
        DONE
    );
    signal current_state : state_type := RESET;
    signal temp_address : std_logic_vector(15 downto 0);
    signal shift_level : integer range 0 to 8;

begin

process (i_clk, i_rst) is
    variable temp_pixel : std_logic_vector(8 downto 0);
    
begin
    if i_rst = '1' then
        current_state <= RESET;
        max_pixel <= (others => '0');
        min_pixel <= (others => '1');
        o_address <= (others => '0');
        o_done <= '0';
        o_en <= '0';
        o_we <= '0';
        o_data <= (others => '0');
        shift_level <= 0;
        
    elsif i_clk'event and rising_edge(i_clk) then
        case current_state is
            when RESET =>
                max_pixel <= (others => '0');
                min_pixel <= (others => '1');
                o_address <= (others => '0');
                o_done <= '0';
                o_en <= '0';
                o_we <= '0';
                o_data <= (others => '0');
                shift_level <= 0;
                
                if i_start = '1' then
                    current_state <= START;
                end if;
            
            when START =>
                o_en <= '1';
                o_address <= "0000000000000000";
                temp_address <= "0000000000000000";
                current_state <= WAITR;
            
            when WAITR =>
                current_state <= READ;
            
            when READ =>
                if temp_address = "0000000000000000" then
                    ncolonne <= i_data;
                    temp_address <= temp_address + 1;
                    o_address <= temp_address + 1;
                    current_state <= WAITR;
                    
                elsif temp_address = "0000000000000001" then
                    nrighe <= i_data;
                    temp_address <= temp_address + 1;
                    o_address <= temp_address + 1;
                    current_state <= WAITR;
                    
                elsif ncolonne = "00000000" or nrighe = "00000000" then
                    -- vai alla fine
                    o_done <= '1';
                    current_state <= DONE;
                    
                elsif temp_address < ncolonne * nrighe + 2 then
                
                    if i_data > max_pixel then
                        max_pixel <= i_data;
                    end if;
                        
                    if i_data < min_pixel then
                        min_pixel <= i_data;
                    end if;
                    
                    temp_address <= temp_address + 1;
                    o_address <= temp_address + 1;
                    current_state <= WAITR;
                
                else                    
                    if max_pixel - min_pixel = 0 then
                        shift_level <= 8;
                    elsif max_pixel - min_pixel <= 2 then
                        shift_level <= 7;
                    elsif max_pixel - min_pixel <= 6 then
                        shift_level <= 6;
                    elsif max_pixel - min_pixel <= 14 then
                        shift_level <= 5;
                    elsif max_pixel - min_pixel <= 30 then
                        shift_level <= 4;
                    elsif max_pixel - min_pixel <= 62 then
                        shift_level <= 3;
                    elsif max_pixel - min_pixel <= 126 then
                        shift_level <= 2;
                    elsif max_pixel - min_pixel <= 254 then
                        shift_level <= 1;
                    else
                        shift_level <= 0;
                    end if;
                    
                    o_address <= "0000000000000010";
                    temp_address <= "0000000000000010";
                    current_state <= WAITR2;
                    
                end if;
                
            when WAITR2 =>
                current_state <= READ2;
                
            when READ2 =>
                if temp_address < ncolonne * nrighe + 2 then
                
                    temp_pixel := ('0' & i_data) - ('0' & min_pixel);
                    temp_pixel := std_logic_vector(shift_left(unsigned(temp_pixel), shift_level) );
                
                    if temp_pixel> 255 then
                        
                        o_data <= "11111111";
                    
                    else
                    
                        o_data <= temp_pixel(7 downto 0);
                    
                    end if;
                    
                    o_we <= '1';
                    o_address <= temp_address + ncolonne * nrighe;
                    current_state <= WAITW;
                    
                else
                    o_done <= '1';
                    current_state <= DONE;
                end if;
                
            when WAITW =>
                o_we <= '0';
                temp_address <= temp_address + 1;
                o_address <= temp_address + 1;
                current_state <= WAITR2;
            
            when DONE =>
                if i_start = '0' then
                    current_state <= RESET;
                
                end if;
        end case;
    end if;
end process;
end rtl;

