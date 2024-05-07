---------------------------------------------------
-- Takes an opcode and up to two 32-bit values as inputs
-- and performs a mathematical or logical operation based
-- on the opcode; produces a 32-bit value and sets an
-- equals flag if the two inputs are equivalent
---------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;


entity ALU is
port (  AluCtrl: in std_logic_vector(3 downto 0);
        AluInA, AluInB: in std_logic_vector(31 downto 0);
        AluResult: out std_logic_vector(31 downto 0);
        Equals: out std_logic
);
end ALU;

architecture rtl of ALU is

begin
    op_mux : process(AluCtrl,AluInA,AluInB)
    begin
        if (AluInA = AluInB) then -- Set the Equals output
            Equals <= '1';
        else
            Equals <= '0';
        end if;
        
        case AluCtrl is
            when "0000" => AluResult <= AluInA and AluInB; -- AND
            when "0001" => AluResult <= AluInA or AluInB; -- OR
            when "0010" => AluResult <= std_logic_vector(unsigned(AluInA) + unsigned(AluInB)); -- ADD
            when "0011" => AluResult <= to_stdlogicvector(to_bitvector(AluInA) sll conv_integer(AluInB)); -- SLL
            when "0100" => AluResult <= to_stdlogicvector(to_bitvector(AluInA) srl conv_integer(AluInB)); -- SRL
            when "0110" => AluResult <= AluInA - AluInB; -- SUB
            when "0111" => -- SLT
            -- Zero the result buffer and then fill 1 in the LSB if signed less than
                AluResult <= (others => '0');
                if signed(AluInA) < signed(AluInB) then
                    AluResult(0) <= '1';
                end if;
            when "1010" => AluResult <= AluInA xor AluInB; -- XOR
            when "1011" => -- SLTU
            -- Zero the result buffer and then fill 1 in the LSB if unsigned less than
                AluResult <= (others => '0');
                if (unsigned(AluInA) < unsigned(AluInB)) then
                    AluResult(0) <= '1';
                end if;
            when "1101" => AluResult <= to_stdlogicvector(to_bitvector(AluInA) sra conv_integer(AluInB)); -- SRA
            when "1110" => -- LUI
            -- Zero the result buffer, shift AluInA to the upper 20 bits, and load it into the result buffer
                --AluResult <= (others => '0');
                AluResult <= AluInB;
            when others => AluResult <= (others => '0');
        end case;
    end process op_mux;

end rtl;
