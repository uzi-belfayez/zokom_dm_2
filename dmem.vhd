-- Quartus II VHDL Template
-- Single port RAM with single read/write address 

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dmem is

	generic 
	(
		DATA_WIDTH : natural := 32;
		ADDR_WIDTH : natural := 32;
        MEM_DEPTH  : natural := 32
	);

	port 
	(
		addr	: in std_logic_vector(ADDR_WIDTH-1 downto 0);
		data	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		write		: in std_logic := '1';
        clk     :   in  std_logic;
		q		: out std_logic_vector((DATA_WIDTH -1) downto 0)
	);

end entity;

architecture rtl of dmem is

	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
	type memory_t is array(MEM_DEPTH-1 downto 0) of word_t;
	function init_ram
		return memory_t is 
		variable tmp : memory_t := (others => (others => '0'));
	begin 
		-- Initialisation de la ROM avec le programme
		-- Quartus générera un fichier mif associé
		tmp(0):= x"000011FA";
		tmp(1):= x"00000008";	 
		tmp(2):= x"A0000002";	
		tmp(3):= x"00000007";	 
		tmp(4):= x"00000000";	
		tmp(5):= x"00000000";	
		tmp(6):= x"00000000";	
		tmp(7):= x"01234567";	
		tmp(8):= x"01234567";	
		return tmp;
	end init_ram;	 


	signal ram : memory_t:=init_ram;


    signal addr_int : integer range 0 to MEM_DEPTH - 1;
    signal sig1 : std_logic;
    signal sig2 : std_logic;

    signal addr_uns : unsigned (ADDR_WIDTH - 1 downto 0);

begin
    addr_uns <= unsigned(addr);

    addr_int <= to_integer(addr_uns) when (addr_uns < MEM_DEPTH) and (addr_uns > 0) else 0;
    sig1 <= '1' when addr_uns < MEM_DEPTH else '0';
    sig2 <= '1' when addr_uns > 0 else '0';

	process(clk)
	begin
        if rising_edge(clk) then
            if(write = '1') then

                    ram(addr_int) <= data;
  
            end if; 
        end if;
end process;

q <= ram(addr_int);

end rtl;
