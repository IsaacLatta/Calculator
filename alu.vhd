library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Updated ALU Entity with clk
entity alu is
    Port (
        clk: in STD_LOGIC;
        done: out STD_LOGIC;
        ready: in STD_LOGIC;
        a : in  STD_LOGIC_VECTOR (3 downto 0);  -- Operand a (4 bits)
        b : in  STD_LOGIC_VECTOR (3 downto 0);  -- Operand b (4 bits)
        opcode : in STD_LOGIC_VECTOR (3 downto 0);  -- Operation selector (4 bits)
        result : out STD_LOGIC_VECTOR (7 downto 0)  -- Result (8 bits)
    );
end alu;

-- ALU Module
architecture Behavioral of alu is
    signal internal_done: STD_LOGIC := '0';
    signal internal_result: STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
begin
    done <= internal_done;
    result <= internal_result;
    
    process(clk)
    begin
        if rising_edge(clk) then
            if ready = '1' and internal_done = '0' then
                -- Perform the computation based on opcode
                case opcode is
                    when "1010" =>  -- Key A: Addition
                        internal_result <= std_logic_vector(resize(unsigned(a) + unsigned(b), 8));
                    when "1011" =>  -- Key B: Subtraction
                        internal_result <= std_logic_vector(resize(unsigned(a) - unsigned(b), 8));
                    when "1100" =>  -- Key C: Multiplication
                        internal_result <= std_logic_vector(resize(unsigned(a) * unsigned(b), 8));
                    when "1101" =>  -- Key D: Division
                        if b /= "0000" then
                            internal_result <= std_logic_vector(resize(unsigned(a) / unsigned(b), 8));
                        else
                            internal_result <= (others => '0');  -- Handle division by zero
                        end if;
                    when others =>  -- Default case
                        internal_result <= (others => '0');
                end case;
                internal_done <= '1';  -- Indicate computation is done
            elsif ready = '0' then
                internal_done <= '0';  -- Reset done when ready is deasserted
            end if;
        end if;
    end process;
end Behavioral;

