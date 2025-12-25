library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity imem is
    generic (
        DATA_WIDTH : integer := 32;
        ADDR_WIDTH : integer := 32;
        MEM_DEPTH  : integer := 100;
        INIT_FILE  : string  := "prog_jump.hex"
    );
    port (
        clk       : in  std_logic;
        address   : in  std_logic_vector(ADDR_WIDTH-1 downto 0);
        Data_Out  : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end entity;

architecture behavior of imem is
    type mem_type is array (0 to MEM_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
    
    -- Fonction de conversion Hex Char -> Std_logic_vector (4 bits)
    function hex_char_to_slv(c : character) return std_logic_vector is
    begin
        case c is
            when '0' => return "0000";
            when '1' => return "0001";
            when '2' => return "0010";
            when '3' => return "0011";
            when '4' => return "0100";
            when '5' => return "0101";
            when '6' => return "0110";
            when '7' => return "0111";
            when '8' => return "1000";
            when '9' => return "1001";
            when 'A' | 'a' => return "1010";
            when 'B' | 'b' => return "1011";
            when 'C' | 'c' => return "1100";
            when 'D' | 'd' => return "1101";
            when 'E' | 'e' => return "1110";
            when 'F' | 'f' => return "1111";
            when others => return "0000"; -- Cas erreur
        end case;
    end function;

    impure function init_mem(filename : string) return mem_type is
        file text_file : text open read_mode is filename;
        variable text_line : line;
        variable char_buffer : string(1 to 8); -- On lit 8 caractères (32 bits / 4)
        variable temp_mem : mem_type := (others => (others => '0'));
        variable char_read : character;
        variable success : boolean;
    begin
        for i in 0 to MEM_DEPTH-1 loop
            if not endfile(text_file) then
                readline(text_file, text_line);
                -- On lit une chaine de caractères (String), pas des bits !
                read(text_line, char_buffer, success); 
                
                if success then
                    -- Conversion manuelle caractère par caractère
                    for j in 1 to 8 loop
                        temp_mem(i)((32 - (j-1)*4 - 1) downto (32 - j*4)) := hex_char_to_slv(char_buffer(j));
                    end loop;
                end if;
            end if;
        end loop;
        return temp_mem;
    end function;

    signal ram : mem_type := init_mem(INIT_FILE);

begin
    process(clk)
    begin
        if falling_edge(clk) then
            if to_integer(unsigned(address)) < MEM_DEPTH then
                Data_Out <= ram(to_integer(unsigned(address)));
            else
                Data_Out <= (others => '0');
            end if;
        end if;
    end process;
end behavior;