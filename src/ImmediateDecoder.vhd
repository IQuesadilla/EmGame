----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/16/2024 08:54:49 PM
-- Design Name: 
-- Module Name: ImmediateDecoder - rtl
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ImmediateDecoder is
    port (
        Instr: in std_logic_vector(31 downto 0);
        Imm: out std_logic_vector(31 downto 0)
    );
end ImmediateDecoder;

architecture rtl of ImmediateDecoder is

begin
    process(Instr)
        begin
        case Instr(6 downto 0) is
            when b"0110111" | b"0010111" => -- U-Type : LUI | AUIPC
                Imm <= Instr(31 downto 12) & b"000000000000";
            when b"1101111" => -- J-Type : JAL
                Imm <= (10 downto 0 => Instr(31)) & Instr(31) & Instr(19 downto 12) & Instr(20) & Instr(30 downto 21) & b"0";
            when b"1100111" | b"0000011" | b"0010011" => -- I-type : JALR | LB, LH, LW, LBU, LHU | ADDI, SLTI, SLTIU, XORI, ORI, ANDI
                Imm <= (19 downto 0 => Instr(31)) & Instr(31 downto 20);
            when b"1100011" => -- B-Type : BEQ, BNE, BLT, BGE, BLTU, BGUE
                Imm <= (18 downto 0 => Instr(31)) & Instr(31) & Instr(7) & Instr(30 downto 25) & Instr(11 downto 8) & b"0";
            when b"0100011" => -- S-Type : SB, SH, SW
                Imm <= (19 downto 0 => Instr(31)) & Instr(31 downto 25) & Instr(11 downto 7);
            when others =>
                Imm <= (31 downto 0 => '0');--std_logic_vector(to_unsigned(0,32));
        end case;
    end process;

end rtl;
