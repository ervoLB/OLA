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

use work.ola_package.all;
use work.analysisFilter_package.all;
use work.synthesisFilter_package.all;

entity ola_top is
generic (
    SIMULATION      : boolean := SIMULATION_INIT;
    VALUE_WIDTH     : integer := VALUE_WIDTH_INIT;
    HOP_SIZE        : integer := HOP_SIZE_INIT;
    FRAME_SIZE      : integer := FRAME_SIZE_INIT;
    ADDR_WIDTH      : integer := ADDR_WIDTH_INIT;  -- this generic is dependent from FRAME_SIZE -> ADDR_WIDTH = ceil(log2(FRAME_SIZE))
    ANA_WIN_SRCFILE : string  := ANA_WIN_SRCFILE_INIT;
    SYN_WIN_SRCFILE : string  := SYN_WIN_SRCFILE_INIT
);
port(
    -- =========================================
    -- clocks
    i_wrClk : in  std_logic;
    i_rdClk : in  std_logic;
    
    -- =========================================
    -- inputs
    i_ola    : in ola_inputs_type;
    
    -- =========================================
    -- outputs
    o_ola    : out ola_outputs_type  -- TODO: will here be different width because of multiplication e.g. VALUE_WIDTH+2?
    );
end ola_top;

architecture rtl of ola_top is
    
    signal o_af   : aF_outputs_type;
    signal o_sF   : sF_outputs_type;

begin

    -- =====================================
    -- Analysis Filter
    anaFilter_inst : entity work.analysisFilter
    generic map (
        SIMULATION      => SIMULATION,
        VALUE_WIDTH     => VALUE_WIDTH,
        HOP_SIZE        => HOP_SIZE,
        FRAME_SIZE      => FRAME_SIZE,
        ADDR_WIDTH      => ADDR_WIDTH,
        ANA_WIN_SRCFILE => ANA_WIN_SRCFILE
    )
    port map(
        i_wrClk              => i_wrClk,
        i_rdClk              => i_rdClk,
        i_af.sl_reset_slow   => i_ola.sl_reset_slow,

        i_af.sl_readRequest  => '1',
        
        i_af.sl_dataValid    => i_ola.sl_dataValid,
        i_af.slvX_dataValue  => i_ola.slvX_dataValue,
        
        o_af                 => o_af
    );
    -- =====================================
    
    -- =====================================
    -- Synthesis Filter
    synFilter_inst : entity work.synthesisFilter
    generic map (
        SIMULATION      => SIMULATION,
        VALUE_WIDTH     => VALUE_WIDTH,
        HOP_SIZE        => HOP_SIZE,
        FRAME_SIZE      => FRAME_SIZE,
        ADDR_WIDTH      => ADDR_WIDTH,
        SYN_WIN_SRCFILE => SYN_WIN_SRCFILE
    )
    port map(
        i_clk                    => i_rdClk,
        i_sF.sl_reset_slow       => i_ola.sl_reset_slow,
        
        i_sF.sl_dataValid        => o_af.sl_dataValid,
        i_sF.slvX_dataValue      => o_af.slvX_dataValue,
 
        o_sF                     => o_sF
    );
    -- =====================================

    o_ola.sl_dataValid   <= o_sF.sl_dataValid;
    o_ola.slvX_dataValue <= o_sF.slvX_dataValue;
    

end rtl;

