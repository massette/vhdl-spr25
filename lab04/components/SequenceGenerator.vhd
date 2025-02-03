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
--       'term' next term in the sequeunce, resets to 0
--       'lastMode' high when on the last term of the sequence
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

        term: out std_logic_vector(3 downto 0);
        lastMode: out std_logic
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
    -- counter running in background to seed random generator
    -- in : (clock, reset) holdMode
    -- out: seed
    MAKE_SEED: process (clock, reset) is
    begin
        if (reset = ACTIVE) then
            -- reset to 0
            seed <= 0;
        elsif rising_edge(clock) then
            -- dont randomize if in the middle of a sequence
            if (holdMode /= ACTIVE) then
                if (seed < MAX) then
                    -- increment count
                    seed <= seed + 1;
                else
                    -- overflow to 0
                    seed <= 0;
                end if;
            end if;
        end if;
    end process;

    -- convert seed to a sequence of 20 pseudo-random bits
    -- in : seed
    -- out: termsBits
    MAKE_SEQUENCE: process (seed) is
        variable seedBits: std_logic_vector(19 downto 0);
    begin
        -- convert random seed to bit string
        seedBits := std_logic_vector(to_unsigned(seed, 20));

        -- rearrange bits to mitigate slower effect of higher bits
        -- note, this yields a unique output for every valid seed,
        --    resulting in a uniform distribution of results

        -- term 1
        termsBits(19 downto 16) <= not seedBits(19) &     seedBits( 9)
                                 & not seedBits( 0) &     seedBits(10);
        -- term 2
        termsBits(15 downto 12) <= not seedBits( 1) &     seedBits(18)
                                 &     seedBits( 8) & not seedBits(11);
        -- term 3
        termsBits(11 downto  8) <=     seedBits(17) & not seedBits( 2)
                                 &     seedBits(12) & not seedBits( 7);
        -- term 4
        termsBits( 7 downto  4) <=     seedBits(13) & not seedBits( 3)
                                 & not seedBits( 6) &     seedBits(16);
        -- term 5
        termsBits( 3 downto  0) <= not seedBits( 5) &     seedBits(14)
                                 & not seedBits(15) &     seedBits( 4);
    end process;

    -- output next term in sequence, or select new sequence
    -- *might split into several blocks
    -- in : nextEn, termsBits
    -- out: term, holdMode, lastMode
    SELECT_TERM: process (reset, clock) is
        variable current: integer range 0 to 4;
    begin
        if (reset = ACTIVE) then
            -- reset to first term
            current := 0;
            holdMode <= not ACTIVE;
        elsif rising_edge(clock) then
            if (nextEn = ACTIVE) then
                -- select next term
                if (current < 5) then
                    -- increment current
                    current := current + 1;
                else
                    -- overflow back to zero
                    current := 0;
                end if;
            end if;
            
            -- output current term from random bits
            term <= termsBits((current*4 + 3) downto (current * 4));
            
            -- output if on the last term
            if (current = 4) then
                lastMode <= ACTIVE;
            else
                lastMode <= (not ACTIVE);
            end if;
            
            -- stop randomizing if in the middle of a sequence
            if (current /= 0) then
                holdMode <= ACTIVE;
            else
                holdMode <= not ACTIVE;
            end if;
        end if;
    end process;
end SequenceGenerator_ARCH;
