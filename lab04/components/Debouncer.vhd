--------------------------------------------------------------------------------
-- 
-- Debouncer
-- Sean Graham
-- 
--     Generates a debounced, synchronized signal from raw external input.
--     
--
--     Generates a sequence of 5 pseudo-random 4-bit unsigned integers. Terms
--     are output one at a time but generate in groups of five. Because terms
--     are derived from a counter, time between the first 'nextEn' of each
--     sequence should vary by at least (2 ** 20) clock cycles.
--
--     Generics:
--       'CLOCK_PERIOD' period of system clock (default: 10 ns)
--       'SAMPLE_PERIOD' time between samples of the input (default: 2 ms)
--       'DEPTH' number of samples to take (default: 16 samples)
--
--           Note, SAMPLE_PERIOD and DEPTH have affect input delay.
--           DEPTH * SAMPLE_PERIOD = 32 ms default minimum delay
--
--     Inputs:
--       'reset' when active, all sequential elements return to initial state
--       'clock' on rising edge, all sequential elements are updated
--       'asyncIn' raw, asynchronous user input
--     
--     Outputs:
--       'syncOut' synchronized, debounced signal
--     
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity Debouncer is
    generic(
        CLOCK_PERIOD: time := 10 ns;
        SAMPLE_PERIOD: time := 2 ms;
        DEPTH: integer := 16
    );
    port(
        reset: in std_logic;
        clock: in std_logic;
        
        asyncIn: in std_logic;
        syncOut: out std_logic
    );
end entity;

architecture Debouncer_ARCH of Debouncer is
    constant ACTIVE: std_logic := '1';
    
    -- calculate range needed for desired interval
    constant MAX: integer := (SAMPLE_PERIOD / CLOCK_PERIOD) - 1;
    -- number of samples that need to be different to register
    constant MIN_SAMPLES: integer := DEPTH * 3 / 4;

    -- sample
    signal sampleEn: std_logic;
begin
    -- poll raw signal at increased interval to mitigate bouncing
    -- in : (reset, clock)
    -- out: sampleEn
    SAMPLE: process (reset, clock) is
        variable count: integer range 0 to MAX;
    begin
        if (reset = ACTIVE) then
            -- ready for next sample on reset
            sampleEn <= (not ACTIVE);
            count := 0;
        elsif rising_edge(clock) then
            sampleEn <= (not ACTIVE);
            
            -- sample on increased interval
            if (count < MAX) then
                -- increment counter
                count := count + 1;
            else
                -- overflow back to 0
                count := 0;
                sampleEn <= ACTIVE;
            end if;
        end if;
    end process;

    -- sample raw signal to synchronize and further debounce
    -- in : (reset, clock) sampleEn, buttonRaw
    -- out: syncOut
    DEBOUNCE: process (reset, clock) is
        variable previous: std_logic_vector(DEPTH-1 downto 0);
        variable count: integer range 0 to DEPTH;
    begin
        if (reset = ACTIVE) then
            -- clear to inactive on reset
            previous := (others => not ACTIVE);
            count := 0;
        elsif rising_edge(clock) then
            -- update buffer on sample interval
            if (sampleEn = ACTIVE) then
                -- shift previous inputs
                previous(DEPTH - 2 downto 0) := previous(DEPTH - 1 downto 1);
                
                -- add next sampled input to buffer
                previous(DEPTH - 1) := asyncIn;
            end if;

            -- count number of current value of signal
            count := 0;

            for i in previous'range loop
                if (previous(i) = previous(0)) then
                    count := count + 1;
                end if;
            end loop;
            
            -- if majority of the samples match new value, update output
            if (count >= MIN_SAMPLES) then
                syncOut <= previous(0);
            end if;
        end if;
    end process;
end Debouncer_ARCH;
