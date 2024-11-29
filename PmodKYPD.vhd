----------------------------------------------------------------------------------
-- Authors: Isaac Latta, Michael Baudin  
--
-- Module Name:    PmodKYPD - Behavioral 
-- Project Name: Calculator
-- Target Devices: Basys3
-- Description: The overlying statemachine used within the calculator. May contain fragments of code left over from Digilent's basys3 and Nexys3 documentaion, sources [1] and [2] from our report.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity PmodKYPD is
    Port ( 
		   clk : in  STD_LOGIC;
		   JA : inout  STD_LOGIC_VECTOR (7 downto 0); -- PmodKYPD is designed to be connected to JA
           an : out  STD_LOGIC_VECTOR (3 downto 0);   -- Controls which position of the seven segment display to display
           seg : out  STD_LOGIC_VECTOR (6 downto 0); -- Digit to display on the seven segment display 
           led : out STD_LOGIC_VECTOR(3 downto 0); -- Debug led's used to display the current state
           input_debug: out STD_LOGIC_VECTOR(3 downto 0)); -- Debug led's used to display the last stable input from the keyboard
end PmodKYPD;

architecture Behavioral of PmodKYPD is

component Decoder is
	Port (
		  clk : in  STD_LOGIC; 
          Row : in  STD_LOGIC_VECTOR (3 downto 0); -- Rows of the keypad
		  Col : out  STD_LOGIC_VECTOR (3 downto 0); -- Columns of the keypad
          DecodeOut : out  STD_LOGIC_VECTOR (3 downto 0)); -- Decoded output from the keypad
	end component;

component DisplayController is
    Port ( 
        clk : in STD_LOGIC;                       
        DispVal : in  STD_LOGIC_VECTOR (15 downto 0); -- 16-bit value to display
        anode : out std_logic_vector(3 downto 0); -- Anode control for four digits
        segOut : out  STD_LOGIC_VECTOR (6 downto 0)  -- Segment outputs
    );
end component;


component alu is
    Port (
        clk: in STD_LOGIC;
        done: out STD_LOGIC; -- Bit signaling the completion of compution
        ready: in STD_LOGIC; -- Bit for signaling the alu to begin computation
        a : in  STD_LOGIC_VECTOR (15 downto 0);  -- Operand a (16 bits)
        b : in  STD_LOGIC_VECTOR (15 downto 0);  -- Operand b (16 bits)
        opcode : in STD_LOGIC_VECTOR (3 downto 0);  -- Operation selector
        result : out STD_LOGIC_VECTOR (31 downto 0)  -- Result (32 bits)
    );
end component;

component Debounce is
    Port ( 
        clk : in STD_LOGIC;
        input : in STD_LOGIC_VECTOR(3 downto 0);
        debounced : out STD_LOGIC_VECTOR(3 downto 0);
        input_changed : out STD_LOGIC
    );
    end component;

signal state: unsigned(3 downto 0) := to_unsigned(0, 4);
    signal enable: STD_LOGIC := '0'; 

   	-- Signals used to connect and synchronize the Debouncer and Decoder
    signal Decode: STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal Debounced_Decode: STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal Input_Changed: STD_LOGIC := '0';

   	-- Signals used to connect and synchronize the alu
    signal opcode: STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal operand_a: STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal operand_b: STD_LOGIC_VECTOR (15 downto 0) := (others => '0');
    signal result: STD_LOGIC_VECTOR (31 downto 0);  -- For multiplication results
    signal operand_a_ready: STD_LOGIC := '0'; -- Signal completion of digit accumulation
    signal operand_b_ready: STD_LOGIC := '0'; -- Signal completion of digit accumulation
    signal compute: STD_LOGIC := '0'; --Signal alu to compute
    signal completed: STD_LOGIC := '0'; -- Signal alu completion
    signal completed_last: STD_LOGIC := '0';  -- Detect rising edge of 'completed'
begin
    C0: Decoder port map (clk=>clk, Row =>JA(7 downto 4), Col=>JA(3 downto 0), DecodeOut=> Decode);
    
    C1: DisplayController port map (
    	clk => clk,
    	DispVal => result(15 downto 0),  
    	anode => an,
    	segOut => seg
    );

    C2: alu port map (
    	clk => clk,  
    	done => completed,
    	ready => compute,
    	a => operand_a,
    	b => operand_b,
    	opcode => opcode,
    	result => result
    );

    C3: Debounce port map (
        clk => clk, 
        input => Decode, 
        debounced => Debounced_Decode,
        input_changed => Input_Changed
    );
    
    led <= STD_LOGIC_VECTOR(state);
    input_debug <= Debounced_Decode;
    
-- Main process: Handles state change logic
main_process: process(clk)
    variable digit_value: unsigned(3 downto 0);
begin
    if rising_edge(clk) then
        completed_last <= completed;  -- Update the previous 'completed' state
        case state is 
            when to_unsigned(0, 4) =>  -- Wait for first digit of operand A
                compute <= '0';
                operand_a <= (others => '0'); -- Keep operand A = "0000" until input read
                operand_a_ready <= '0';
                if Input_Changed = '1' and Debounced_Decode /= "0000" then -- Once non zero input is ready progress to reading digits
                    digit_value := unsigned(Debounced_Decode);
                    operand_a <= std_logic_vector(resize(unsigned(operand_a) * 10 + unsigned(digit_value), 16));
                    state <= to_unsigned(1, 4);
                end if;
              
            when to_unsigned(1, 4) =>  -- Accumulate digits for operand A
                if Input_Changed = '1' then
                    if Debounced_Decode /= "1111" then  -- "1111" or F key is 'Enter' 
                        digit_value := unsigned(Debounced_Decode);
                        operand_a <= std_logic_vector(resize(unsigned(operand_a) * 10 + unsigned(digit_value), 16));
                    else
                        operand_a_ready <= '1'; -- Signal complete accumulation of operand a's digits
                        state <= to_unsigned(2, 4);
                    end if;
                end if;
                
            when to_unsigned(2, 4) =>  -- Wait for operator
                if Input_Changed = '1' and Debounced_Decode >= "1010" and Debounced_Decode <= "1101" then -- Operators are A: Addition, B: Subtraction, C: Multiplication, D: Division
                    opcode <= Debounced_Decode;
                    state <= to_unsigned(3, 4);
                end if;
                
            when to_unsigned(3, 4) =>  -- Wait for first digit of operand B
                operand_b <= (others => '0');
                operand_b_ready <= '0';
                if Input_Changed = '1' and Debounced_Decode /= "0000" then
                    digit_value := unsigned(Debounced_Decode);
                    operand_b <= std_logic_vector(resize(unsigned(operand_b) * 10 + unsigned(digit_value), 16));
                    state <= to_unsigned(4, 4);
                end if;
                
            when to_unsigned(4, 4) =>  -- Accumulate digits for operand B
                if Input_Changed = '1' then
                    if Debounced_Decode /= "1111" then  -- "1111" or F key is 'Enter'
                        digit_value := unsigned(Debounced_Decode);
                        operand_b <= std_logic_vector(resize(unsigned(operand_b) * 10 + unsigned(digit_value), 16));
                    else
                        operand_b_ready <= '1';
                        compute <= '1';  -- Start computation
                        state <= to_unsigned(5, 4);
                    end if;
                end if;
                
            when to_unsigned(5, 4) =>  -- Computation state
                if completed = '1' and completed_last = '0' then  -- Detect rising edge
                    compute <= '0';  -- Deassert compute after computation
                    state <= to_unsigned(6, 4);
                end if;
                
            when to_unsigned(6, 4) =>  -- Display result state
                -- Result is displayed; wait for user to reset with any key
                if Input_Changed = '1' then
                    operand_a <= (others => '0');
                    operand_b <= (others => '0');
                    opcode <= (others => '0');
                    operand_a_ready <= '0';
                    operand_b_ready <= '0';
                    state <= to_unsigned(0, 4);
                end if;
                
            when others =>
                state <= to_unsigned(8, 4);  -- Invalid state for debugging purposes
        end case;
    end if;
end process;

end Behavioral;
