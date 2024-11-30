----------------------------------------------------------------------------------
-- Test Bench for Arithmetic Logic Unit (ALU)
-- 
-- Purpose: This test bench is designed to verify the functionality of the ALU.
-- It tests various operations such as addition, subtraction, multiplication, 
-- and division by providing inputs and monitoring the outputs.
--
-- Authors: Isaac Latta, Michael Baudin
-- Last Modified: [Add Last Modification Date]
--
-- Entity: calculator
--
-- Description: This entity represents the test bench for the calculator ALU.
--
-- Ports:
-- - clk: Clock signal used for synchronization.
-- - buf1: First operand for the ALU operation, 8-bit wide.
-- - buf2: Second operand for the ALU operation, 8-bit wide.
-- - operand: Operation selector, 2 bits (00 = Add, 01 = Sub, 10 = Mul, 11 = Div).
-- - result: The result of the ALU operation, 15 bits wide.
----------------------------------------------------------------------------------


library ieee;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

entity calculator is
port(
clk : in std_logic;
buf1 : in std_logic_vector(7 downto 0); -- 128-bit sized input
buf2 : in std_logic_vector(7 downto 0); -- 128-bit sized input2

operand : in std_logic_vector(1 downto 0); -- 0 - add, 1-sub, 2-mul, 3-div

result : out std_logic_vector(14 downto 0) -- 16384-bit sized output, for 99*99.
);
end calculator;

architecture logic of calculator is
signal int1 : integer := 0;
signal int2 : integer := 0;
signal result1 : integer := 0;
begin

process(clk)
begin
if rising_edge(clk) then
	int1 <= to_integer(unsigned(buf1));
	int2 <= to_integer(unsigned(buf2));
	if operand = "00" then
		result1 <= int1 + int2;

	elsif operand = "01" then
		result1 <= int1 - int2;

	elsif operand = "10" then
		result1 <= int1 * int2;

	elsif operand = "11" then
		result1 <= int1 / int2;
	else
		result1 <= 0;
end if;
end if;
end process;

process(result1)
begin
result <= std_logic_vector(to_unsigned(result1, result'length));
end process;

end logic;

entity tb_calculator is

end tb_calculator;

architecture behavior of tb_calculator is

    signal clk     : std_logic := '0';
    signal buf1    : std_logic_vector(7 downto 0);
    signal buf2    : std_logic_vector(7 downto 0);
    signal operand : std_logic_vector(1 downto 0);
    signal result  : std_logic_vector(14 downto 0);


    component calculator
        port(
            clk     : in std_logic;
            buf1    : in std_logic_vector(7 downto 0);
            buf2    : in std_logic_vector(7 downto 0);
            operand : in std_logic_vector(1 downto 0);
            result  : out std_logic_vector(14 downto 0)
        );
    end component;

begin
process
    begin
        
        buf1 <= "00001010";
        buf2 <= "00000101";
        operand <= "00";
        wait for 1 ns;

        buf1 <= "00010100";
        buf2 <= "00000101";
        operand <= "01";
        wait for 1 ns;

        buf1 <= "00000101";
        buf2 <= "00000101";
        operand <= "10";
        wait for 1 ns;

        buf1 <= "00010100";
        buf2 <= "00000101";
        operand <= "11";
        wait for 1 ns;
    end process;

testCalc : calculator
        port map (
            clk => clk,
            buf1 => buf1,
            buf2 => buf2,
            operand => operand,
            result => result
        );

end behavior;
