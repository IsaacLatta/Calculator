----------------------------------------------------------------------------------
-- Company: Digilent Inc 2011
-- Engineer: Michelle Yu  
-- Create Date: 13:28:41 08/18/2011 
--
-- Module Name:    DisplayController - Behavioral 
-- Project Name: 	 PmodKYPD
-- Target Devices: Nexys 3 
-- Tool versions: Xilinx ISE Design Suite 13.2
--
-- Description: 
-- This file defines a DisplayController that controls the seven segment display that works with 
-- the output of the Decoder
-- Revision: 
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DisplayController is
    Port ( 
        clk : in STD_LOGIC;                       -- Clock signal
        DispVal : in  STD_LOGIC_VECTOR (15 downto 0); -- 16-bit value to display
        anode : out std_logic_vector(3 downto 0); -- Anode control for four digits
        segOut : out  STD_LOGIC_VECTOR (6 downto 0)  -- Segment outputs
    );
end DisplayController;

architecture Behavioral of DisplayController is
    signal refresh_counter : unsigned(19 downto 0) := (others => '0'); -- Adjust bit width as needed
    signal digit_select : STD_LOGIC_VECTOR(1 downto 0);
    signal current_digit : STD_LOGIC_VECTOR(3 downto 0);
    signal digit1, digit2, digit3, digit4 : STD_LOGIC_VECTOR(3 downto 0);
begin
    -- Split DispVal into individual digits
    process(DispVal)
        variable temp_val : unsigned(15 downto 0);
        variable to_be_casted : unsigned(15 downto 0);
    begin
        temp_val := unsigned(DispVal);
        
        
        
        -- Casting here to convert between unsigned and integer for mod operation
        digit1 <= std_logic_vector(to_unsigned(to_integer(temp_val) mod 10, 4)); -- Rightmost digit
        temp_val := temp_val / 10;
        digit2 <= std_logic_vector(to_unsigned(to_integer(temp_val) mod 10, 4));
        temp_val := temp_val / 10;
        digit3 <= std_logic_vector(to_unsigned(to_integer(temp_val) mod 10, 4));
        temp_val := temp_val / 10;
        digit4 <= std_logic_vector(to_unsigned(to_integer(temp_val) mod 10, 4)); -- Leftmost digit
    end process;
    
    -- Refresh counter to control multiplexing frequency
    process(clk)
    begin
        if rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;
    
    -- Use higher bits of the counter for digit selection
    digit_select <= std_logic_vector(refresh_counter(19 downto 18));
    
    -- Multiplexing logic
    process(digit_select)
    begin
        case digit_select is
            when "00" =>  -- Activate Digit 1 (rightmost)
                anode <= "1110";
                current_digit <= digit1;
            when "01" =>  -- Activate Digit 2
                anode <= "1101";
                current_digit <= digit2;
            when "10" =>  -- Activate Digit 3
                anode <= "1011";
                current_digit <= digit3;
            when "11" =>  -- Activate Digit 4 (leftmost)
                anode <= "0111";
                current_digit <= digit4;
            when others =>
                anode <= "1111";  -- All digits off
                current_digit <= "0000";
        end case;
    end process;
    
    -- Seven-segment decoder for current_digit
    with current_digit select
        segOut <= "1000000" when "0000", --0
                  "1111001" when "0001", --1
                  "0100100" when "0010", --2
                  "0110000" when "0011", --3
                  "0011001" when "0100", --4
                  "0010010" when "0101", --5
                  "0000010" when "0110", --6
                  "1111000" when "0111", --7
                  "0000000" when "1000", --8
                  "0010000" when "1001", --9
                  "0111111" when others; -- Turn off all segments
end Behavioral;


