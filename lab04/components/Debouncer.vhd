

entity Debouncer is
    generic(
        CLOCK_PERIOD: time := 10 ns;
        SAMPLE_INTERVAL: time := 2 ms;
        DEPTH: integer := 16;
    );
    port(
        reset: in std_logic;
        clock: in std_logic;
        
        asyncIn: in std_logic;
        syncOut: out std_logic
    );
end entity;

architecture Debouncer_ARCH of Debouncer is
    -- calculate range needed for desired interval
    constant MAX: integer := (DEBOUNCE_INTERVAL / CLOCK_PERIOD) - 1;
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
        variable diffCount: integer range 0 to DEPTH;
    begin
        if (reset = ACTIVE) then
            -- clear to inactive on reset
            previous <= (others => not ACTIVE);
            diffCount := 0;
        elsif rising_edge(clock) then
            -- update buffer on sample interval
            if (sampleEn = ACTIVE) then
                -- shift previous inputs
                previous(DEPTH - 2 downto 0) := previous(DEPTH - 1 downto 1);
                
                -- add next sampled input to buffer
                previous(DEPTH - 1) := asyncIn;
            end if;

            -- check ratio of same:diff signals in buffer
            diffCount := 0;

            for i in previous'range loop
                if (previous(i) /= buttonSync) then
                    diffCount := diffCount + 1;
                end if;
            end loop;
            
            -- if majority of the samples are new value, update output
            if (diffCount >= MIN_SAMPLES) then
                syncOut <= (not syncOut);
            end if;
        end if;
    end process;
end architecture;
