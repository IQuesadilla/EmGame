----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/04/2024 06:47:40 PM
-- Design Name: 
-- Module Name: Root - rtl
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

entity Root is
port (
    sw: in std_logic_vector(3 downto 0);
    led: out std_logic_vector(3 downto 0);
    sysclk: in std_logic
    );
end Root;

architecture rtl of Root is
    
    signal divider: std_logic_vector(31 downto 0);
    signal sOutput: std_logic_vector(31 downto 0);
    signal Clk: std_logic;

begin
    process (sysclk)
    begin
        if (sysclk'event and sysclk='1') then
        divider <= std_logic_vector(unsigned(divider) + 1);
        end if;
    end process;
    
    process (divider)
    begin
        Clk <= divider(0);
    end process;
    
    process (sOutput)
    begin
        led <= sOutput(24 downto 21);
    end process;
    
    eSoC : entity work.Soc port map (
        Clk => Clk,
        Output => sOutput,
        Reset => sw(0)
        );
end rtl;
