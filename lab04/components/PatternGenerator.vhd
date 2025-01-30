--------------------------------------------------------------------------------
-- 
-- Lab 04: SequenceGenerator
-- Sean Graham
-- 
--     Generates a sequence of 5 pseudo-random 16-bit integers.
--
--     Inputs:
--       'reset' when active, all sequential elements put in their initial state
--       'clock' on rising edge, all sequential elements are updated
--       'holdMode' when active, outputs will not be randomized, holding their
--         current values
--     
--     Outputs:
--       'random1' ... 'random5' pseudo-random outputs. not guaranteed stable
--         unless outputs are held
--     
--------------------------------------------------------------------------------

entity PatternGenerator is
    port(
        reset: in std_logic;
        clock: in std_logic;
        
        holdMode: in std_logic;

        random1: out std_logic_vector(15 downto 0);
        random2: out std_logic_vector(15 downto 0);
        random3: out std_logic_vector(15 downto 0);
        random4: out std_logic_vector(15 downto 0);
        random5: out std_logic_vector(15 downto 0)
    );
end PatternGenerator;

architecture PatternGenerator_ARCH of PatternGenerator is
    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';

    constant MAX: integer := (2 ** 20) - 1;

    -------------------------------------------------------------------SIGNALS--
    signal seedCount: integer range MAX downto 0;
    signal seedCount: std_logic_vector(19 downto 0);
begin
    -- quickly move through all valid states, so that when stopped arbitrarilly,
    --   the resulting value is practically random.
    -- in : holdMode
    -- out: seedCount
    MAKE_SEED: process (clock, reset) is
    begin
        if (reset = ACTIVE) then
            -- initialize counter to 0
            seedCount <= 0;
        elsif rising_edge(clock) then
            -- do not randomize when holding current value
            if (holdMode = not ACTIVE) then
                -- otherwise, increment counter
                if (seedCount < MAX) then
                    seedCount <= seedCount + 1;
                else
                    -- overflow back to 0
                    seedCount <= 0;
                end if;
            end if;
        end if;
    end process;

    -- convert random seed to bit string
    seed <= std_logic_vector(to_unsigned(seedCount, 20));

    -- rearrange seed to mitigate slower effect on higher bits
    -- note, this yields a unique output for every valid seed,
    --    resulting in a uniform distribution
    random1 <= seed(19) & seed( 9) & seed( 0) & seed(10);
    random2 <= seed( 1) & seed(18) & seed( 8) & seed(11);
    random3 <= seed(17) & seed( 2) & seed(12) & seed( 7);
    random4 <= seed(13) & seed( 3) & seed( 6) & seed(16);
    random5 <= seed( 5) & seed(14) & seed(15) & seed( 4);
end architecture;
