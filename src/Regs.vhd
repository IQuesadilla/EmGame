---------------------------------------------------
-- This source file describes a 32x32 register file such
-- that the 0th register is always 0 and is not writeable
---------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-------------------------------------------------------------

entity RegisterFile is
port (  RdRegA: in std_logic_vector(4 downto 0);
        RdRegB: in std_logic_vector(4 downto 0);
        Clk: in std_logic;
        WrRegEn: in std_logic;
        WrReg: in std_logic_vector(4 downto 0);
        WrData: in std_logic_vector(31 downto 0);
        RdDataA: out std_logic_vector(31 downto 0);
        RdDataB: out std_logic_vector(31 downto 0)
);
end RegisterFile;

architecture rtl of RegisterFile is
    --create an array of 31 32-bit registers
    type register_array is array (1 to 31) of
        std_logic_vector (31 downto 0);
    signal Registers: register_array := (others => (others => '0'));
begin

-- describe the write functionality
    process(Clk) -- only do something if the clock changes 
    begin
        -- on the rising edge of the clock
        if (Clk'event and Clk='1') then
            -- only write if enabled and not attempting to write to 0 reg
            if (WrRegEn='1' and conv_integer(WrReg) /= 0) then
                Registers(conv_integer(WrReg)) <= WrData;
            end if;
        end if;
    end process;
    
-- describe the read functionality of port A
    process (RdRegA, Registers)
    begin
    -- If Register 0, return 0; otherwise, return register contents
        if (conv_integer(RdRegA) = 0) then 
            RdDataA <= (others => '0');
        else
            RdDataA <= Registers (conv_integer(RdRegA));
        end if;
    end process;
    
-- describe the read functionality of port B
    process (RdRegB, Registers)
    begin
    -- If Register 0, return 0; otherwise, return register contents
        if (conv_integer(RdRegB) = 0) then
            RdDataB <= (others => '0');
        else
            RdDataB <= Registers (conv_integer(RdRegB));
        end if;
    end process;

end rtl;
