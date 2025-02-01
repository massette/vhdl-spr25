--------------------------------------------------------------------------------
-- 
-- Lab 03 Demo: Counter
-- Sean Graham
--     
--     Unidirectional 4-bit synchronous counter.
--     Count is set to zero on reset.
--
--     Inputs:
--       'reset' when active, all sequential elements return to initial state
--       'clock' on rising edge, all sequential elements are updated
--       'countEn' increment count by one 
--         
--     Outputs:
--       'countBits' stores internal count represented as a 4-bit binary string
--       'mask' a 16-bit string with the corresponding bit active
--     
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Counter is
    port(
        clock: in std_logic;
        reset: in std_logic;
        
        countEn: in std_logic;
        
        digits: out std_logic_vector(7 downto 0); -- bcd tens (15:8), ones (7:0)
        mask: out std_logic_vector(15 downto 0)
    );
end Counter;

architecture Counter_ARCH of Counter is
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';
    
    -------------------------------------------------------------------SIGNALS--
    signal count: integer range 0 to 15;

    -- digits
    signal countTens: integer range 0 to 1;
    signal countOnes: integer range 0 to 9;
begin
    -- store and update count
    -- in : countEn
    -- out: count
    MAKE_COUNT: process (reset, clock) is
    begin
        if (reset = ACTIVE) then
            -- reset to 0
            count <= 0;
        elsif rising_edge(clock) then
            -- increment on count
            if (countEn = ACTIVE) then
                if (count < 15) then
                    count <= count + 1;
                else
                    count <= 0;
                end if;
            end if;
        end if;
    end process;
    
    -- convert to decimal digits
    CALC_TENS: countTens <= (count / 10);
    CALC_ONES: countOnes <= (count mod 10);
    
    -- merge and convert to bcd
    BCD_TENS: digits(7 downto 4) <= std_logic_vector(to_unsigned(countTens, 4));
    BCD_ONES: digits(3 downto 0) <= std_logic_vector(to_unsigned(countOnes, 4));
    
    -- create mask pattern
    -- in : count
    -- out: mask
    MAKE_MASK: process (count) is
    begin
        mask <= (others => not ACTIVE);
        mask(count) <= ACTIVE;
    end process;
end Counter_ARCH;
