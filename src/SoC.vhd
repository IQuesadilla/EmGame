----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/04/2024 07:50:20 PM
-- Design Name: 
-- Module Name: SoC - rtl
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity SoC is
port (
    Clk : in std_logic;
    Output : out std_logic_vector(31 downto 0);
    Reset: in std_logic
    );
end SoC;

architecture rtl of SoC is

    type mem_array is array (0 to 63) of
        std_logic_vector (31 downto 0);
    
    --signals for Instruction memory
    constant InstrMem: mem_array :=(
--loop:
     0 => X"000000b3",
     1 => X"00108093", --addi x1,x1,1
     2 => X"00102023", --sw x1, 0(x0)
     3 => X"ff9ff06f", --j loop
     others => X"00000000" --nop
);

    signal PC : std_logic_vector(31 downto 0);
    signal sOutput : std_logic_vector(31 downto 0);
    signal MemWrEn, MemRdEn : std_logic := '0';
    signal MemAddr : std_logic_vector(31 downto 0);

begin

    eSingleCycle : entity work.SingleCycle port map(
        Clk => Clk,
        Rst_L => not Reset,
        PC => PC,
        Instr => InstrMem(conv_integer(PC(31 downto 2))),
        DataMemAddr => MemAddr,
        DataMemRdEn => MemRdEn,
        DataMemWrEn => MemWrEn,
        DataMemRdData => (31 downto 0 => '0'),
        DataMemWrData => sOutput
    );
    
    --process (PC)
    --begin
    --    Output <= PC(5 downto 2); 
    --end process;
    
    process (sOutput, MemWrEn)
    begin 
        if (MemWrEn = '1') then
            Output <= sOutput;
        end if;
    end process;

end rtl;
