--------------------------------------------------------------------------------
-- 
-- Lab 04: SequenceGenerator
-- Sean Graham
-- 
--     Generates a sequence of 5 pseudo-random 16-bit integers.
--
--     Inputs:
--       'reset' when active, all sequential elements return to initial state
--       'clock' on rising edge, all sequential elements are updated
--       'nextEn' select next number in sequence, begins a new sequence after
--          reaching the end of current sequence
--     
--     Outputs:
--       'random' next term in the sequeunce, resets to 0
--     
--------------------------------------------------------------------------------

entity PatternGenerator is
    port(
        reset: in std_logic;
        clock: in std_logic;
        
        nextEn: in std_logic;

        random: out std_logic_vector(15 downto 0)
    );
end PatternGenerator;

architecture PatternGenerator_ARCH of PatternGenerator is
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';

    -- number of distinct seeds for counting
    constant MAX: integer := (2 ** 20) - 1;

    -------------------------------------------------------------------SIGNALS--
    signal seed: integer range 0 to MAX;
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
            if (holdMode = ACTIVE) then
            if (seed < MAX) then
                -- increment count
                seed <= seed + 1;
            else
                -- overflow to 0
                seed <= 0;
            end if;
        end if;
    end process;

    -- convert seed to a sequence of 20 'random' bits
    -- in : seed
    -- out: termsBits
    MAKE_SEQUENCE: process (seed) is
        variable seedBits: std_logic_vector(19 downto 0);
    begin
        -- convert random seed to bit string
        seedBits <= std_logic_vector(to_unsigned(seed, 20));

        -- rearrange bits to mitigate slower effect of higher bits
        -- note, this yields a unique output for every valid seed,
        --    resulting in a uniform distribution of results

        -- term 1
        termsBits(19 downto 16) <=  seedBits(19) & !seedBits( 9)
                                 &  seedBits( 0) & !seedBits(10);
        -- term 2
        termsBits(15 downto 12) <= !seedBits( 1) &  seedBits(18)
                                 & !seedBits( 8) &  seedBits(11);
        -- term 3
        termsBits(11 downto  8) <=  seedBits(17) & !seedBits( 2)
                                 &  seedBits(12) & !seedBits( 7);
        -- term 4
        termsBits( 7 downto  4) <= !seedBits(13) &  seedBits( 3)
                                 & !seedBits( 6) &  seedBits(16);
        -- term 5
        termsBits( 3 downto  0) <=  seedBits( 5) & !seedBits(14)
                                 &  seedBits(15) & !seedBits( 4);
    end process;

    -- output next term in sequence, or select new sequence
    -- in : nextEn, termsBits
    -- out: random, holdMode
    SELECT_TERM: process (reset, clock) is
        variable current: integer range 0 to 5;
    begin
        if (reset = ACTIVE) then
            -- reset to first term
            current := 0;
            holdMode <= not ACTIVE;
        elsif rising_edge(clock) then
            if (nextEn = ACTIVE) then
                -- select next term
                if (current < N) then
                    -- increment current
                    current := current + 1;
                else
                    -- overflow back to zero
                    current := 0;
                end if;
            end if;
            
            -- select term from random bits
            random <= termsBits((current*4 + 3) downto (current * 4));
            
            -- stop randomizing if in the middle of a sequence
            if (current = 0) then
                holdMode <= ACTIVE;
            else
                holdMode <= not ACTIVE;
            end if;
        end if;
    end process;
end architecture;
