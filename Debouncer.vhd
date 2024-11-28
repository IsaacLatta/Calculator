library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Debounce is
    Port ( 
        clk : in STD_LOGIC;
        input : in STD_LOGIC_VECTOR(3 downto 0);
        debounced : out STD_LOGIC_VECTOR(3 downto 0);
        input_changed : out STD_LOGIC
    );
end Debounce;

architecture Behavioral of Debounce is
    signal counter : unsigned(19 downto 0) := (others => '0');
    signal stable_input : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal prev_input : STD_LOGIC_VECTOR(3 downto 0) := "0000";
    signal changed : STD_LOGIC := '0';
begin
    process(clk)
    begin
        if rising_edge(clk) then
            -- Check for input change
            if input /= stable_input then
                counter <= counter + 1;

                -- If counter reaches debounce threshold
                if counter = to_unsigned(250000, 20) then
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
