-- The MIT License (MIT)
--
-- Copyright (c) 2024 Lovre Bogdanic, lovre.bogdanic@gmail.com
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.analysisFilter_package.all;
--
entity analysisFilter_readProcess is
generic (
    VALUE_WIDTH     : integer;
    HOP_SIZE        : integer;
    FRAME_SIZE      : integer;
    ADDR_WIDTH      : integer;
    ANA_WIN_SRCFILE : string
);
port(
    i_clk  : in  std_logic;
    i_afRp : in  aF_rp_inputs_type;
    o_afRp : out aF_rp_outputs_type
);
end entity analysisFilter_readProcess;

architecture rtl of analysisFilter_readProcess is


    type reg_type is record
        usX_dataAddr       : unsigned(ADDR_WIDTH-1 downto 0);  -- address for reading data values
        usX_valueCounter   : unsigned(ADDR_WIDTH-1 downto 0);  -- for counting processed values in each processing cycle
        slv3_dataValid_D   : std_logic_vector(3 downto 0);
        sl_processingFlag  : std_logic;
    end record;
    
    constant reg_type_Init : reg_type := (
        usX_dataAddr       => to_unsigned(HOP_SIZE, ADDR_WIDTH),
        --usX_dataAddr      => (others=>'0'),
        usX_valueCounter   => (others=>'0'),
        slv3_dataValid_D   => (others=>'0'),
        sl_processingFlag  => '0');

    signal r, c                : reg_type;
    signal sl_hopDone_p_sync   : std_logic;
    signal slvX_winValue       : std_logic_vector(VALUE_WIDTH-1 downto 0);
    signal slvX_mulVal         : std_logic_vector(VALUE_WIDTH-1 downto 0);

begin

    -- =====================================
    -- Window BRAM 
    anaWin_inst : entity work.anaSynWindow_bram
    generic map (
        VALUE_WIDTH  => VALUE_WIDTH,
        ADDR_WIDTH   => ADDR_WIDTH,
        WIN_SRCFILE  => ANA_WIN_SRCFILE
    )
    port map(
        i_rdClk    => i_clk,
        i_rdAddr   => r.usX_valueCounter,
        o_rdData   => slvX_winValue
    );
    -- =====================================
    
    -- =====================================
    -- Multiplier  
    mult_inst : entity work.signedMultiplier
    generic map (
        VALUE_WIDTH  => VALUE_WIDTH
    )
    port map(
        i_clk       => i_clk,
        i_slvX_op1  => i_afRp.slvX_dataValue,
        i_slvX_op2  => slvX_winValue,
        o_slvX_res  => slvX_mulVal
    );
    -- =====================================

    -- =====================================
    -- hopDone pulse sync
    syncPulse_inst : entity work.syncPulse
    port map(
        Clock  => i_clk,
        Input  => i_afRp.sl_hopDone_p_async,
        Output => sl_hopDone_p_sync
    );
    -- =====================================

    combinational_part : process(r,i_afRp,sl_hopDone_p_sync)
        variable v : reg_type;
    begin
        v := r;
        
        v.slv3_dataValid_D(3 downto 1) := r.slv3_dataValid_D(2 downto 0);
        v.slv3_dataValid_D(0) := r.sl_processingFlag and i_afRp.sl_readRequest;
        
        -- if there are hop event occurred, read complete frame and process it
        if sl_hopDone_p_sync = '1' then 
            v.sl_processingFlag := '1';                        -- start with reading/processing written values
        end if;

        if r.sl_processingFlag = '1' and i_afRp.sl_readRequest = '1' then
            v.usX_dataAddr := r.usX_dataAddr + 1;            -- every clock increment reading address 
            if r.usX_valueCounter < FRAME_SIZE-1 then
                v.usX_valueCounter := r.usX_valueCounter +1; -- every hop cycle we have FRAME_SIZE number of values to process
            else
                v.sl_processingFlag := '0';                           -- all values are read/processed
                v.usX_valueCounter  := (others => '0');               -- reset sample counter
                v.usX_dataAddr      := r.usX_dataAddr + HOP_SIZE +1;  -- update starting read address by jumping over new values
            end if;
        end if;    
        
        if i_afRp.sl_reset_slow = '1' then
            v := reg_type_Init;
        end if;
        
        c <= v;            -- variables to combinatorial signal
    end process;

    synchronous_part : process(i_clk)
    begin
        if rising_edge(i_clk) then
            r <= c;
        end if;
    end process;
    
    -- set outputs
    o_afRp.usX_dataAddr   <= r.usX_dataAddr;
    o_afRp.sl_hopDone_p   <= sl_hopDone_p_sync;
    o_afRp.sl_dataValid   <= r.slv3_dataValid_D(3);
    o_afRp.slvX_dataValue <= slvX_mulVal; 

end rtl;
