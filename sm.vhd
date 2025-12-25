architecture behav of sm is
    -- No aliases needed for data, we access it directly

    alias q_0 : std_logic_vector(7 downto 0) is q(7 downto 0);
    alias q_1 : std_logic_vector(7 downto 0) is q(15 downto 8);
    alias q_2 : std_logic_vector(7 downto 0) is q(23 downto 16);
    alias q_3 : std_logic_vector(7 downto 0) is q(31 downto 24);

    -- Internal signals for the aligned data
    signal data_to_write : std_logic_vector(31 downto 0);
    
    -- Masks (Active LOW to write, as per your previous logic seems to suggest, 
    -- BUT let's stick to standard: '1' = Keep Memory, '0' = Overwrite with Data)
    signal m : std_logic_vector(3 downto 0);

begin

    -------------------------------------------------------------------------
    -- 1. DATA ALIGNMENT
    -- Shift the LSB of the register (data) to the target byte lane
    -------------------------------------------------------------------------
    process (data, res, funct3)
    begin
        data_to_write <= data; -- Default (for SW)

        if funct3(1 downto 0) = "00" then -- SB (Store Byte)
            case res is
                when "00"   => data_to_write <= data;                        -- Byte 0
                when "01"   => data_to_write <= data(23 downto 0) & data(7 downto 0); -- Byte 1 position (Hack to place bits 7-0 at 15-8)
                               -- Cleaner way:
                               data_to_write(15 downto 8) <= data(7 downto 0);
                when "10"   => data_to_write(23 downto 16) <= data(7 downto 0);
                when "11"   => data_to_write(31 downto 24) <= data(7 downto 0);
                when others => null;
            end case;
        elsif funct3(1 downto 0) = "01" then -- SH (Store Half)
            if res(1) = '1' then -- Upper Half
                data_to_write(31 downto 16) <= data(15 downto 0);
            else                 -- Lower Half
                data_to_write(15 downto 0) <= data(15 downto 0);
            end if;
        end if;
    end process;

    -------------------------------------------------------------------------
    -- 2. MASK GENERATION (Keep old Logic, it was mostly fine)
    -------------------------------------------------------------------------
    process (res, funct3)
    begin
        m <= "1111"; -- Default: Keep all memory (Write nothing)
        
        case funct3(1 downto 0) is
            when "00" => -- SB
                case res is
                    when "00" => m <= "1110"; -- Write Byte 0
                    when "01" => m <= "1101"; -- Write Byte 1
                    when "10" => m <= "1011"; -- Write Byte 2
                    when "11" => m <= "0111"; -- Write Byte 3
                    when others => null;
                end case;
            when "01" => -- SH
                if res(1) = '0' then m <= "1100"; -- Write Lower Half
                else                 m <= "0011"; -- Write Upper Half
                end if;
            when "10" => -- SW
                m <= "0000"; -- Write All
            when others => null;
        end case;
    end process;

    -------------------------------------------------------------------------
    -- 3. FINAL MERGE
    -------------------------------------------------------------------------
    -- Using the ALIGNED data (data_to_write) instead of raw 'data'
    dataOut(7 downto 0)   <= q_0 when m(0) = '1' else data_to_write(7 downto 0);
    dataOut(15 downto 8)  <= q_1 when m(1) = '1' else data_to_write(15 downto 8);
    dataOut(23 downto 16) <= q_2 when m(2) = '1' else data_to_write(23 downto 16);
    dataOut(31 downto 24) <= q_3 when m(3) = '1' else data_to_write(31 downto 24);

end behav;