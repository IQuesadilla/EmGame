----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/02/2024 07:27:47 PM
-- Design Name: 
-- Module Name: ALUDecode - Behavioral
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

entity ALUDecode is
Port (
    Opcode: in std_logic_vector(6 downto 0);
    Funct7: in std_logic_vector(6 downto 0);
    Funct3: in std_logic_vector(2 downto 0);
    ALUCtrl: out std_logic_vector(3 downto 0)
);
end ALUDecode;

architecture rtl of ALUDecode is

begin
    process(Opcode, Funct7, Funct3)
    begin
        case Opcode is
            when b"0110111" => ALUCtrl <= b"1110"; -- LUI
            when b"1101111" => ALUCtrl <= b"0010"; -- JAL
            when b"1100011" => -- BEQ, BNE, BLT, BGE, BLTU, BGEU
                if Funct3 = b"000" then ALUCtrl <= b"0010"; -- BEQ (ADD)
                end if;
            when b"0000011" => -- LB, LH, LW, LBU, LHU
                if Funct3 = b"010" then ALUCtrl <= b"0010"; -- LW (ADD)
                end if;
            when b"0100011" => -- SB, SH, SW
                if Funct3 = b"010" then ALUCtrl <= b"0010"; -- SW (ADD)
                end if;
            when b"0010011" => -- ADDI, SLTI, SLTIU, XORI, ORI, ANDI, SLLI, SRLI, SRAI
                case Funct3 is
                    when b"000" => ALUCtrl <= b"0010"; -- ADDI
                    when b"010" => ALUCtrl <= b"0111"; -- SLTI
                    when b"011" => ALUCtrl <= b"1011"; -- SLTIU
                    when b"110" => ALUCtrl <= b"1010"; -- XORI
                    when b"111" => ALUCtrl <= b"0000"; -- ANDI
                    when b"001" => ALUCtrl <= b"0011"; -- SLLI
                    when b"101" =>
                        if Funct7 = b"0000000" then ALUCtrl <= b"0100"; -- SRLI
                        else ALUCtrl <= b"1101"; -- SRAI
                        end if;
                    when others => ALUCtrl <= b"0000";--(others => '-'); -- anything
                end case;
            when b"0110011" => -- ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND
                case Funct7 is
                    when b"0000000" => -- ADD, SLL, SLT, SLTU, XOR, SRL, OR, AND
                        case Funct3 is 
                            when b"000" => ALUCtrl <= b"0010"; -- ADD
                            when b"001" => ALUCtrl <= b"0011"; -- SLL
                            when b"010" => ALUCtrl <= b"0111"; -- SLT
                            when b"011" => ALUCtrl <= b"1011"; -- SLTU
                            when b"100" => ALUCtrl <= b"1010"; -- XOR
                            when b"101" => ALUCtrl <= b"0100"; -- SRL
                            when b"110" => ALUCtrl <= b"0001"; -- OR
                            when b"111" => ALUCtrl <= b"0000"; -- AND
                            when others => ALUCtrl <= (others => '-');
                        end case;
                    when b"0100000" => -- SUB, SRA
                        case Funct3 is
                            when b"000" => ALUCtrl <= b"0110"; -- SUB
                            when b"101" => ALUCtrl <= b"1101"; -- SRA
                            when others => ALUCtrl <= b"0000";--(others => '-'); -- anything
                        end case;
                    when others => ALUCtrl <= (others => '-'); -- anything
                end case;
            when others => ALUCtrl <= b"0010";--(others => '-'); -- anything
        end case;
    end process;

end rtl;
