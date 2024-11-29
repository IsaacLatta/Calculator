----------------------------------------------------------------------------------
-- Authors: Isaac Latta, Michael Baudin  
--
-- Module Name:   Debounce - Behavioral 
-- Project Name:  Calculator
-- Target Devices: Basys3
-- Description: This module stabilizes the input from the keypad by implementing a debouncing mechanism. 
--              It assumes a debounce period of 2.5 ms with a clock frequency of 100 MHz.
--              The input is considered stable if it remains unchanged for the entire debounce period.
--              The module outputs the stabilized input and a flag (`input_changed`) that indicates
--              when the debounced output changes.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Debounce is
    Port ( 
        clk : in STD_LOGIC;
        input : in STD_LOGIC_VECTOR(3 downto 0); -- 4 bit input read from the Decoder
        debounced : out STD_LOGIC_VECTOR(3 downto 0); -- Stabilized output
        input_changed : out STD_LOGIC -- Flag to signal a change in stabilized output
    );
end Debounce;

architecture Behavioral of Debounce is
    signal counter : unsigned(19 downto 0) := (others => '0'); -- Counter to track clock cycles
    signal stable_input : STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- Store for stable input
    signal prev_input : STD_LOGIC_VECTOR(3 downto 0) := "0000"; -- Store for previous stable input
    signal changed : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Check for input change
            if input /= stable_input then
                counter <= counter + 1;

                -- If counter reaches debounce threshold
                if counter = to_unsigned(250000, 20) then -- 250K Clock Cycles
                    stable_input <= input;
                    changed <= '1';
                    counter <= (others => '0');
                end if;
            else
                -- Reset counter if input is stable
                counter <= (others => '0');
                changed <= '0';
            end if;

            -- Update previous input
            prev_input <= input;
        end if;
    end process;

    -- Output the stable input and change flag
    debounced <= stable_input;
    input_changed <= changed;
end Behavioral;
