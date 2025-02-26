--------------------------------------------------------------------------------
-- 
-- Lab 04 Demo: SequenceGenerator_BASYS3
-- Sean Graham
--
--     Wrapper implementing the SequenceGenerator entity on the BASYS3 board.
--     For each sequence generated, the terms are displayed one at a time,
--       switching at 4Hz. Upon reaching the end of a sequence, awaits input.
--
--     Inputs:
--       'clk' system clock
--       'btnD' on-board push button. resets generator to first seed
--       'btnR' on-board push button. if ready, selects next sequence
--                                    otherwise, does nothing
--
--     Outputs:
--       'seg' on-board seven-segment display. shows current term
--       'led' on-board leds. shows current term
--
--             all outputs blanked when no sequence is selected
--     
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SequenceGenerator_BASYS3 is
    port(
        clk: in std_logic;
        
        btnD: std_logic;
        btnR: std_logic;

        led: std_logic_vector(15 downto 0)
        seg: std_logic_vector(15 downto 0)
        an: std_logic_vector(15 downto 0)
    );
end SequenceGenerator_BASYS3;

architecture SequenceGenerator_BASYS3_ARCH of SequenceGenerator_BASYS3 is
    ----------------------------------------------------------TYPE DEFINITIONS--
    type t_SEQ_STATE is (AWAIT_INPUT, START_SEQ, SHOW_SEQ);

    -----------------------------------------------------------------CONSTANTS--
    constant ACTIVE: std_logic := '1';

    -- timers
    constant CLOCK_PERIOD: time := 1 ns;
    constant TIMER_PERIOD: time := 200 ms;
    
    ----------------------------------------------------------------COMPONENTS--
    -- uut
    component SequenceGenerator is
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
    end component;

    -------------------------------------------------------------------SIGNALS--
    -- async signals
    signal reset: std_logic;
    signal clock: std_logic;
    
    -- handle inputs
    signal readyEn: std_logic;

    -- timer
    signal timerEn: std_logic;

    -- sequence state
    signal currentState: t_SEQ_STATE;
    signal nextState: t_SEQ_STATE;
    
    signal loadSeqEn: std_logic;
    signal showSeqMode: std_logic;

    -- sequence generator
    signal readyEn: std_logic;
    signal seqTerm1: std_logic_vector(3 downto 0);
    signal seqTerm2: std_logic_vector(3 downto 0);
    signal seqTerm3: std_logic_vector(3 downto 0);
    signal seqTerm4: std_logic_vector(3 downto 0);
    signal seqTerm5: std_logic_vector(3 downto 0);

    -- multiplex terms
    signal currentTerm: integer range 0 to 15;
    signal lastTermMode: std_logic;
begin
    -- map asynchronous signals
    reset <= btnD;
    clock <= clk;

    -- synchronize and debounce asynchronous button input
    -- in : (reset, clock) btnD
    -- out: readyEn
    SYNC_READY: ButtonTrigger port map(
        reset => reset,
        clock => clock,

        buttonRaw => btnR,
        pulseEn => readyEn
    );

    -- store and update state
    -- in : (reset, clock) nextState
    -- out: currentState
    SEQ_REG: process (reset, clock) is
    begin
        if (reset = ACTIVE) then
            -- wait for next input after reset
            currentState <= AWAIT_INPUT;
        elsif rising_edge(clock) then
            -- update state every clock cycle
            currentState <= nextState;
        end if;
    end process;

    -- determine state outputs and next state
    -- in : currentState, readyEn, nextEn, lastTermMode
    -- out: loadSeqEn, 
    SEQ_TRANS: process (currentState) is
    begin
        -- set defaults
        nextState <= currentState;
        loadSeqEn <= (not ACTIVE);
        showSeqMode <= (not ACTIVE);
        
        -- do current state logic
        case currentState is
            -------------------------------------------------------AWAIT_INPUT--
            when AWAIT_INPUT =>
                -- transition on next user input
                if (readyEn = ACTIVE) then
                    nextState <= START_SEQ;
                end if;

            ---------------------------------------------------------START_SEQ--
            when START_SEQ =>
                -- load next sequence, prepare to display 
                loadSeqEn <= ACTIVE;
                nextState <= SHOW_SEQ;

            ----------------------------------------------------------SHOW_SEQ--
            when SHOW_SEQ =>
                seqMode <= ACTIVE;
                
                -- wait for last term to be displayed
                if (timerEn = ACTIVE) and (lastTermMode = ACTIVE) then
                    nextState <= AWAIT_INPUT;
                end if;
        end case;
    end process;
    
    -- generate 5Hz pulse signal
    -- in : (reset, clock) loadSeqEn
    -- out: nextEn
    MAKE_TIMER: process (reset, clock) is
        variable count: integer range 0 to (TIMER_PERIOD / CLOCK_PERIOD);
    begin
        if (reset = ACTIVE) then
            -- reset to low
            count := 0;
            nextEn <= (not ACTIVE);
        elsif rising_edge(clock) then
            -- set default
            nextEn <= (not ACTIVE);

            if (loadSeqEn = ACTIVE) then
                -- clear when loading a new sequence
                count := 0;
            elsif (count < (TIMER_PERIOD / CLOCK_PERIOD)) then
                -- otherwise, increment counter
                count := count + 1;
            else
                -- set ready on overflow
                count := 0;
                nextEn <= ACTIVE;
            end if;
        end if;
    end process;

    -- map sequence generator to hardware
    -- in : (reset, clock) loadSeqEn
    -- out: seqTerm1, seqTerm2, seqTerm3, seqTerm4, seqTerm5
    UUT: SequenceGenerator port map(
        reset => reset,
        clock => clock,

        nextEn => loadSeqEn,

        random1 => seqTerm1,
        random2 => seqTerm2,
        random3 => seqTerm3,
        random4 => seqTerm4,
        random5 => seqTerm5
    );

    -- select current term in sequence
    -- in : (reset, clock) nextEn
    -- out: currentTerm, lastTermMode
    SELECT_TERM: process (reset, clock) is
        -- index of current term
        variable i: integer range 1 to 5;
    begin
        if (reset = ACTIVE) then
            i := 1;
            currentTerm <= 0;
            lastTermMode <= (not ACTIVE);
        elsif rising_edge(clock) then
            -- set default
            lastTermMode <= (not ACTIVE);
            
            -- update index
            if (loadSeqTerm = ACTIVE) then
                -- clear when reading new sequence
                i := 1;
            elsif (nextEn = ACTIVE) then
                -- increment index
                if (i < 5) then
                    i := i + 1;
                else
                    i := 1;
                end if;
            end if;

            -- set current term
            case (i) is
                when 1 =>
                    currentTerm <= seqTerm1;
                when 2 =>
                    currentTerm <= seqTerm2;
                when 3 =>
                    currentTerm <= seqTerm3;
                when 4 =>
                    currentTerm <= seqTerm4;
                when others =>
                    currentTerm <= seqTerm5;
                    lastTermMode <= ACTIVE;
            end case;
        end if;
    end process;

    -- drive led outputs
    -- in : currentTerm
    -- out: led
    DRIVE_LED: process (seqTerm) is
        variable index: integer range 0 to 15;
    begin
        -- convert to integer index
        index := to_integer(unsigned(seqTerm));
        
        -- turn off all leds, except current term
        led <= (others => not ACTIVE);
        led(currentTerm) <= ACTIVE;
    end process;

    -- todo: drive seven seg output
    DRIVE_SEG: SevenSegmentDriver port map(
        reset => reset,
        clock => clock,

        -- ... digits

        -- ... blanks

        sevenSegs => seg,
        anodes => an
    );
end SequenceGenerator_BASYS3_ARCH;
