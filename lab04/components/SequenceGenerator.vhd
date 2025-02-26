--------------------------------------------------------------------------------
-- 
-- Lab 04: SequenceGenerator
-- Sean Graham
-- 
--     Generates a sequence of 5 pseudo-random 4-bit unsigned integers. Terms
--     are output one at a time but generate in groups of five. Because terms
--     are derived from a counter, time between the first 'nextEn' of each
--     sequence should vary by at least (2 ** 20) clock cycles.
--
--     Inputs:
--       'reset' when active, all sequential elements return to initial state
--       'clock' on rising edge, all sequential elements are updated
--       'nextEn' select next number in sequence, generates a new sequence upon
--          reaching end of current sequence
--     
--     Outputs:
--       'random1', 'random2', ... 'random5' terms of generated sequence
--     
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SequenceGenerator is
    port(
        reset: in std_logic;
        clock: in std_logic;
        
        nextEn: in std_logic;

        random1: out std_logic_vector(3 downto 0);
        random2: out std_logic_vector(3 downto 0);
        random3: out std_logic_vector(3 downto 0);
        random4: out std_logic_vector(3 downto 0);
        random5: out std_logic_vector(3 downto 0)
    );
end SequenceGenerator;

architecture SequenceGenerator_ARCH of SequenceGenerator is
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';

    -- number of distinct seeds for counting
    constant MAX: integer := (2 ** 20) - 1;

    -------------------------------------------------------------------SIGNALS--
    -- make seed
    signal holdMode: std_logic;
    signal seed: integer range 0 to MAX;
    
    -- make sequence
    signal termsBits: std_logic_vector(19 downto 0);
begin
    -- counter always running to generate seed
    -- in : (clock, reset)
    -- out: seed
    MAKE_SEED: process (clock, reset) is
    begin
        if (reset = ACTIVE) then
            -- reset to 0
            seed <= 0;
        elsif rising_edge(clock) then
            if (seed < MAX) then
                -- increment count
                seed <= seed + 1;
            else
                -- overflow to 0
                seed <= 0;
            end if;
        end if;
    end process;

    -- latch current random seed as bit string
    -- in : (reset, clock) nextEn
    -- out: seedBits
    process (reset, clock) is
    begin
        if (reset = ACTIVE) then
            seedBits <= (others => '0');
        elsif rising_edge(clock) then
            if (nextEn = ACTIVE) then
                -- select next seed
                seedBits <= std_logic_vector(to_unsigned(seed, 20));
            end if;
        end if;
    end process;

    -- rearrange bits to mitigate slower effect of higher bits
    -- note, this yields a unique output for every valid seed,
    --    resulting in a uniform distribution of terms
    random1 <= not seedBits(19) &     seedBits( 9)
             & not seedBits( 0) &     seedBits(10);

    random2 <= not seedBits( 1) &     seedBits(18)
             &     seedBits( 8) & not seedBits(11);

    random3 <=     seedBits(17) & not seedBits( 2)
             &     seedBits(12) & not seedBits( 7);

    random4 <=     seedBits(13) & not seedBits( 3)
             & not seedBits( 6) &     seedBits(16);

    random5 <= not seedBits( 5) &     seedBits(14)
             & not seedBits(15) &     seedBits( 4);
end PatternGenerator_ARCH;
