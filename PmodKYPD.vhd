----------------------------------------------------------------------------------
-- Company: Digilent Inc 2011
-- Engineer: Michelle Yu  
-- Create Date:    17:05:39 08/23/2011 
--
-- Module Name:    PmodKYPD - Behavioral 
-- Project Name:  PmodKYPD
-- Target Devices: Nexys3
-- Tool versions: Xilinx ISE 13.2 
-- Description: 
--	This file defines a project that outputs the key pressed on the PmodKYPD to the seven segment display
--
-- Revision: 
-- Revision 0.01 - File Created
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity PmodKYPD is
    Port ( 
			  clk : in  STD_LOGIC;
			  JA : inout  STD_LOGIC_VECTOR (7 downto 0); -- PmodKYPD is designed to be connected to JA
           an : out  STD_LOGIC_VECTOR (3 downto 0);   -- Controls which position of the seven segment display to display
           seg : out  STD_LOGIC_VECTOR (6 downto 0); -- digit to display on the seven segment display 
           led : out STD_LOGIC_VECTOR(3 downto 0);
           input_debug: out STD_LOGIC_VECTOR(3 downto 0));
end PmodKYPD;

architecture Behavioral of PmodKYPD is

component Decoder is
	Port (
			 clk : in  STD_LOGIC;
            Row : in  STD_LOGIC_VECTOR (3 downto 0);
			 Col : out  STD_LOGIC_VECTOR (3 downto 0);
          DecodeOut : out  STD_LOGIC_VECTOR (3 downto 0));
	end component;

component DisplayController is
	Port (
			  DispVal : in  STD_LOGIC_VECTOR (3 downto 0);
           anode: out std_logic_vector(3 downto 0);
           segOut : out  STD_LOGIC_VECTOR (6 downto 0));
	end component;

component alu is
        Port ( 
            clk : in STD_LOGIC;
            done : out STD_LOGIC;
            ready : inout STD_LOGIC; 
            a : in  STD_LOGIC_VECTOR (3 downto 0);  -- Operand a
               b : in  STD_LOGIC_VECTOR (3 downto 0);  -- Operand b
               opcode : in  STD_LOGIC_VECTOR (3 downto 0);  -- Opcode for operation
               result : out  STD_LOGIC_VECTOR (7 downto 0));  -- Result of operation
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

    signal Decode: STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal Debounced_Decode: STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal Input_Changed: STD_LOGIC := '0';

    signal operand_a: STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal operand_b: STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal opcode: STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal result: STD_LOGIC_VECTOR (7 downto 0);

    signal compute: STD_LOGIC := '0';
    signal completed: STD_LOGIC := '0';
    signal completed_last: STD_LOGIC := '0';  -- To detect rising edge of 'completed'
begin
    C0: Decoder port map (clk=>clk, Row =>JA(7 downto 4), Col=>JA(3 downto 0), DecodeOut=> Decode);
    C1: DisplayController port map (DispVal=>result(3 downto 0), anode=>an, segOut=>seg);
    C2: alu port map (
    clk => clk,  -- Pass the clock signal
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
    opcode <= "0000";  -- Always addition

   

main_process: process(clk)
begin
    if rising_edge(clk) then
        completed_last <= completed;  -- Update the previous 'completed' state
        case state is 
            when to_unsigned(0, 4) =>  -- Wait for first operand
                compute <= '0';
                if Input_Changed = '1' and Debounced_Decode /= "0000" then
                    operand_a <= Debounced_Decode;
                    state <= to_unsigned(1, 4);
                end if;
                
            when to_unsigned(1, 4) =>  -- Wait for second operand
                if Input_Changed = '1' and Debounced_Decode /= "0000" then
                    operand_b <= Debounced_Decode;
                    compute <= '1';  -- Start computation
                    state <= to_unsigned(2, 4);
                end if;
                
            when to_unsigned(2, 4) =>  -- Computation state
                if completed = '1' and completed_last = '0' then  -- Detect rising edge
                    compute <= '0';  -- Deassert compute after computation
                    state <= to_unsigned(3, 4);
                end if;
                
            when to_unsigned(3, 4) =>  -- Display result state
                -- Result is displayed; wait for user to reset
                if Input_Changed = '1' then
                    operand_a <= (others => '0');
                    operand_b <= (others => '0');
                    --result <= (others => '0');
                    state <= to_unsigned(0, 4);
                end if;
                
            when others =>
                state <= to_unsigned(8, 4);  -- Invalid state for debugging
        end case;
    end if;
end process;

end Behavioral;
