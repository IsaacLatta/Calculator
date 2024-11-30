# Calculator

This project implements a basic calculator using the Basys 3 FPGA board and the Pmod KYPD 4x4 keypad. It supports arithmetic operations (addition, subtraction, multiplication, division) with two operands and displays results on the 4-digit 7-segment display.

## Features
- **Keypad Input**: Supports 4x4 matrix keypad for input.
- **Operations**: Addition, subtraction, multiplication, and division.
- **Debouncing**: Keypresses are debounced for stable input.
- **State Machine**: Manages input, operations, and result display.
- **7-Segment Display**: Displays operands and results dynamically.

## Components
- **`PmodKYPD.vhd`**: Contains the main state machine. Based on Digilent's Pmod KYPD and Basys 3 documentation.
- **`Decoder.vhd`**: Decodes keypad inputs. Unmodified from Digilent's original Basys 3 examples.
- **`Debouncer.vhd`**: Ensures stable keypress signals.
- **`DisplayController.vhd`**: Drives the 7-segment display for showing results, extended from Digilent's Pmod KYPD and Basys 3 documentation.
- **`alu.vhd`**: Arithmetic Logic Unit (ALU) for performing operations.
- **`basys3.xdc`**: Xilinx constraints file for pin mapping on Basys 3.

## Keypad Mappings
- **Digits (0-9)**: Enter numbers for operands.
- **Operators**:
  - `A (1010)`: Addition
  - `B (1011)`: Subtraction
  - `C (1100)`: Multiplication
  - `D (1101)`: Division
- **F (1111)**: Acts as "Enter" to confirm input or finalize operations.

## Usage
1. **First Operand**:
   - Enter digits using the keypad.
   - Press `F` to confirm the first operand.
2. **Operator**:
   - Press one of the operator keys (`A`, `B`, `C`, or `D`).
3. **Second Operand**:
   - Enter digits using the keypad.
   - Press `F` to confirm the second operand.
4. **Compute**:
   - The result will automatically appear on the 7-segment display.
   - Press any key to reset and start a new calculation.

## State Transitions
The project uses a state machine with the following states:
- **0**: Wait for the first operand.
- **1**: Accumulate digits for the first operand.
- **2**: Wait for the operator.
- **3**: Wait for the first digit of the second operand.
- **4**: Accumulate digits for the second operand.
- **5**: Perform the calculation using the ALU.
- **6**: Display the result and wait for reset (any key).

Transitions are triggered by keypad inputs (debounced values). For instance, the `F` key (`1111`) progresses to the next relevant state.

## Constraints
- Ensure the Pmod KYPD module is connected to the JA port.
- Correctly map pins in the `basys3.xdc` file for the 7-segment display and keypad connections.
- Repeating digits is not supported for operands.
- Signed operands and results are not supported.

## Notes
- Division by zero returns `0` as a default behavior.
- Pressing any key resets the calculator after displaying the result.

## Acknowledgments
This project builds upon and modifies resources from the following:
1. Digilent, "Basys 3 Reference Manual," Digilent Reference Documentation. [Online]. Available: [Digilent Basys 3 Manual](https://digilent.com/reference/programmable-logic/basys-3/reference-manual). [Accessed: 26-Nov-2024].
2. Digilent, "Pmod KYPD Reference Manual," Digilent Reference Documentation. [Online]. Available: [Digilent Pmod KYPD Manual](https://digilent.com/reference/pmod/pmodkypd/start). [Accessed: 26-Nov-2024].

---
