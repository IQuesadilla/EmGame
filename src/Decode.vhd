----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2024 06:25:03 PM
-- Design Name: 
-- Module Name: InstructionDecode - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity InstructionDecode is
Port (
    Opcode: in std_logic_vector( 6 downto 0); -- 7 bit op field
    UseImm: out std_logic; -- asserted when the immediate field is input to ALU
    Jump: out std_logic; -- asserted when the instruction is a jump
    Branch: out std_logic; -- asserted when the instruction is a branch
    MemRdEn: out std_logic; -- asserted when loading from memory
    MemWrEn: out std_logic; -- asserted when storing to memory
    RegWrEn: out std_logic; -- asserted when overwriting a register
    RegSrc: out std_logic_vector(1 downto 0) -- selects the source for writing into the register file
    -- 00 is PC+4 (the "and link" part of jal)
    -- 01 is the data memory (loads)
    -- 10 is ALU
);
end InstructionDecode;

architecture rtl of InstructionDecode is

begin
    process(Opcode)
    begin
        case Opcode is
            -- U-type instructions
            when b"0110111" | b"0010111" => -- LUI | AUIPC
                UseImm <= '1';
                Jump <= '0';
                Branch <= '0';
                MemRdEn <= '0';
                MemWrEn <= '0';
                RegWrEn <= '1';
                RegSrc <= b"10"; -- ALU
            -- J-type instructios
            when b"1101111" => -- JAL
                UseImm <= '1';
                Jump <= '1';
                Branch <= '0';
                MemRdEn <= '0';
                MemWrEn <= '0';
                RegWrEn <= '1';
                RegSrc <= b"00"; -- PC+4
            -- I-type instructions
            when b"1100111" => -- JALR
                UseImm <= '1';
                Jump <= '1';
                Branch <= '0';
                MemRdEn <= '0';
                MemWrEn <= '0';
                RegWrEn <= '1';
                RegSrc <= b"00"; -- PC+4
            -- B-type instructions
            when b"1100011" => -- BEQ, BNE, BLT, BGE, BLTU, BGEU
                UseImm <= '1';
                Jump <= '0';
                Branch <= '1';
                MemRdEn <= '0';
                MemWrEn <= '0';
                RegWrEn <= '0';
                RegSrc <= b"00"; -- Unused in B-type
            -- I-type instructions
            when b"0000011" => -- LB, LH, LW, LBU, LHU
                UseImm <= '1';
                Jump <= '0';
                Branch <= '0';
                MemRdEn <= '1';
                MemWrEn <= '0';
                RegWrEn <= '1';
                RegSrc <= b"01"; -- Data Memory
            -- S-type instructions
            when b"0100011" => -- SB, SH, SW
                UseImm <= '1';
                Jump <= '0';
                Branch <= '0';
                MemRdEn <= '0';
                MemWrEn <= '1';
                RegWrEn <= '0';
                RegSrc <= b"00"; -- Unused in S-type
            -- I-type instructions
            when b"0010011" => -- ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
                UseImm <= '1';
                Jump <= '0';
                Branch <= '0';
                MemRdEn <= '0';
                MemWrEn  <= '0';
                RegWrEn <= '1';
                RegSrc <= b"10"; -- ALU
            -- R-type instructions
            when b"0110011" => -- ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                UseImm <= '0';
                Jump <= '0';
                Branch <= '0';
                MemRdEn <= '0';
                MemWrEn <= '0';
                RegWrEn <= '1';
                RegSrc <= b"10"; -- ALU
            -- when b"0001111" => -- FENCE (unknown)
            -- when b"1110011" => -- ECALL, EBREAK (unknown)
            when others => -- Any unsupported instructions
                UseImm <= '0';
                Jump <= '0';
                Branch <= '0';
                MemRdEn <= '0';
                MemWrEn <= '0';
                RegWrEn <= '0';
                RegSrc <= b"10";--(others => '-');
        end case;
    end process;

end rtl;
