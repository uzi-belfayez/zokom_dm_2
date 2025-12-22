library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;

entity alu is
    generic (
        dataWidth       : integer:=32;
        aluOpWidth      :   integer:=4
    );
    port (
    opA     :   in std_logic_vector (dataWidth - 1 downto 0);
    opB     :   in std_logic_vector (dataWidth - 1 downto 0);
    aluOp   :   in std_logic_vector (aluOpWidth - 1 downto 0);
    res     :   out std_logic_vector (dataWidth - 1 downto 0)
    );
end entity alu;

architecture behav of alu is

    signal aluOpLoc : std_logic_vector ( 3 downto 0);
    signal opAExt64      : std_logic_vector ( 2*dataWidth - 1 downto 0);
    begin

    aluOpLoc    <=  aluOp(3 downto 0);
    opAExt64 <= (63 downto 32 => opA(31)) & opA;

  process(opA, opB, aluOpLoc,opAExt64)
    variable src_comp : std_logic;
    variable opAExt64a     : std_logic_vector ( 2*dataWidth - 1 downto 0);
    begin
      res <= (others => '0');
    case aluOpLoc    is
          when  "0000" =>  -- ADDs  
              res <= std_logic_vector(signed(opA) + signed(opB));
          when  "1000" =>  -- SUBs  
                res <= std_logic_vector(signed(opA) - signed(opB));
          when  "0001" =>  -- SLLs  
                res <= std_logic_vector(shift_left(unsigned(opA), to_integer(unsigned(opB(4 downto 0)))));
          when  "0010" =>  -- SLTs  
                if(opA(31) = opB(31)) then
                    if (opA < opB) then
                        src_comp := '1';
                    else
                        src_comp := '0';
                    end if;
                    res <= (31 downto 1 => '0') & src_comp;
                else
                    res <= (31 downto 1 => '0') & opA(31);
                end if;
            when  "0011" =>  -- SLTUs 
                if (unsigned(opA) < unsigned(opB)) then
                    src_comp := '1';
                else
                    src_comp := '0';
                end if;
                res <= (31 downto 1 => '0') & src_comp;
            when  "0100" =>  -- XORs  
                res <= opA xor opB;
            when  "0101" =>  -- SRLs  
                res <= std_logic_vector(shift_right(unsigned(opA), to_integer(unsigned(opB(4 downto 0)))));
            when  "1101" =>  -- SRAs  
                opAExt64a :=  std_logic_vector(shift_right(signed(opAExt64), to_integer(unsigned(opB(4 downto 0)))));
                res <= opAExt64a(31 downto 0);
            when  "0110" =>  -- ORs   
                res <= opA or opB;
            when  "0111" =>  -- ANDs  
                res <= opA and opB;
            when  others        =>  res   <=     (others => '0');
    end case;
    end process;

end behav;