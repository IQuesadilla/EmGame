----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/14/2024 12:30:54 PM
-- Design Name: 
-- Module Name: SingleCycle - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity SingleCycle is
    port(
        Clk, Rst_L: in std_logic;
        PC: out std_logic_vector(31 downto 0);
        Instr: in std_logic_vector(31 downto 0);
        DataMemAddr: out std_logic_vector(31 downto 0);
        DataMemRdEn, DataMemWrEn: out std_logic;
        DataMemRdData: in std_logic_vector(31 downto 0);
        DataMemWrData: out std_logic_vector(31 downto 0)
    );
end SingleCycle;

architecture Behavioral of SingleCycle is

    signal PCC : std_logic_vector(31 downto 0) := (others => '0');
    signal PC_4 : std_logic_vector(31 downto 0) := (others => '0');

    signal RdDataB : std_logic_vector(31 downto 0) := (others => '0');
    
    signal ImmGen : std_logic_vector(31 downto 0) := (others => '0');

    signal RdDataA : std_logic_vector(31 downto 0) := (others => '0');
    signal AluDataMuxB : std_logic_vector(31 downto 0) := (others => '0');
    signal AluCtrl: std_logic_vector(3 downto 0) := (others => '0');
    signal AluResult: std_logic_vector(31 downto 0) := (others => '0');
    signal fEqual: std_logic := '0';
    
    signal fUseImm: std_logic := '0';
    signal fJump: std_logic := '0';
    signal fBranch: std_logic := '0';
    signal fMemRdEn: std_logic := '0';
    signal fMemWrEn: std_logic := '0';
    signal fRegWrEn: std_logic := '0';
    signal RegMuxSrc: std_logic_vector(1 downto 0) := b"00";
    signal RegMuxData: std_logic_vector(31 downto 0) := (others => '0');

begin
    -- Write back source mux
    process (DataMemRdData, AluResult, PC_4, RegMuxSrc)
    begin
        case RegMuxSrc is
            when "00" => RegMuxData <= PC_4;
            when "01" => RegMuxData <= DataMemRdData;
            when "10" => RegMuxData <= AluResult;
            when others => RegMuxData <= (others => '1'); -- undefined behavior, unreachable
        end case;
    end process;
    
    -- ALU B select mux
    process (RdDataB, ImmGen, fUseImm)
    begin
        if (fUseImm = '1') then
            AluDataMuxB <= ImmGen;
        else
            AluDataMuxB <= RdDataB;
        end if;
    end process;
    
    -- The Program Counter logic
    process (Clk, Rst_L) -- Branch target mux
    begin
        if (Rst_L = '0') then
            -- Reset the program counter
            PCC <= (others => '0');
        elsif (Clk'event and Clk='1') then
            if (fJump = '1' or (fBranch = '1' and fEqual = '1')) then
                PCC <= std_logic_vector(signed(PCC) + signed(ImmGen));
            else
                PCC <= std_logic_vector(unsigned(PCC) + 4);
            end if;
        end if;
    end process;
    
    -- Complementary process that takes internal signals and maps them to the outputs
    process (ImmGen, PCC, AluResult, fMemRdEn, fMemWrEn)
    begin
        PC_4 <= std_logic_vector(unsigned(PCC) + 4);
        PC <= PCC;
        DataMemAddr <= AluResult;
        DataMemRdEn <= fMemRdEn;
        DataMemWrEn <= fMemWrEn;
        DataMemWrData <= RdDataB;
    end process;
    
    -- The entity representing the register file
    eRegs : entity work.RegisterFile port map(
        RdRegA => Instr(19 downto 15),
        RdRegB => Instr(24 downto 20),
        Clk => Clk,
        WrRegEn => fRegWrEn,
        WrReg => Instr(11 downto 7),
        WrData => RegMuxData,
        RdDataA => RdDataA,
        RdDataB => RdDataB
    );

    -- The entity representing the decoding logic for the ALU control signals
    eALUDecode : entity work.ALUDecode port map(
        Opcode => Instr(6 downto 0),
        Funct7 => Instr(31 downto 25),
        Funct3 => Instr(14 downto 12),
        ALUCtrl => AluCtrl
    );
    
    -- The entity representing the Arithmetic & Logic Unit
    eALU : entity work.ALU port map(
        AluCtrl => AluCtrl,
        AluInA => RdDataA,
        AluInB => AluDataMuxB,
        AluResult => AluResult,
        Equals => fEqual
    );
    
    -- The entity representing the Instruction Decode unit, which controls all of the flags
    eID : entity work.InstructionDecode port map(
        Opcode => Instr(6 downto 0),
        UseImm => fUseImm,
        Jump => fJump,
        Branch => fBranch,
        MemRdEn => fMemRdEn,
        MemWrEn => fMemWrEn,
        RegWrEn => fRegWrEn,
        RegSrc => RegMuxSrc
    );
    
    -- The entity representing the Immediate Decode unit, which generates the immediate field
    eImmDec : entity work.ImmediateDecoder port map(
        Instr => Instr,
        Imm => ImmGen
    );

end Behavioral;
