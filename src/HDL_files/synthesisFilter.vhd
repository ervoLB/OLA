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

use work.synthesisFilter_package.all;

entity synthesisFilter is
generic (
    SIMULATION      : boolean;
    VALUE_WIDTH     : integer;
    HOP_SIZE        : integer;
    FRAME_SIZE      : integer;
    ADDR_WIDTH      : integer;  -- this generic is dependent from FRAME_SIZE -> ADDR_WIDTH = ceil(log2(FRAME_SIZE))
    SYN_WIN_SRCFILE : string
);
port(
    i_clk   : in  std_logic;  
    i_sF    : in sF_inputs_type;
    o_sF    : out sF_outputs_type
);
end synthesisFilter;

architecture rtl of synthesisFilter is
    
    signal slvX_winValue          : std_logic_vector(VALUE_WIDTH-1 downto 0);
    signal slvX_mulVal            : std_logic_vector(VALUE_WIDTH-1 downto 0);
    signal slvX_addVal            : std_logic_vector(VALUE_WIDTH-1 downto 0);
    signal slvX_bram_dataValue_rd : std_logic_vector(VALUE_WIDTH-1 downto 0) := (others => '0');
    signal slvX_bram_dataValue_wr : std_logic_vector(VALUE_WIDTH-1 downto 0) := (others => '0');

    signal o_sfPr : sF_proc_outputs_type;

begin

    -- =====================================
    -- Window BRAM 
    synWin_inst : entity work.anaSynWindow_bram
    generic map (
        VALUE_WIDTH  => VALUE_WIDTH,
        ADDR_WIDTH   => ADDR_WIDTH,
        WIN_SRCFILE  => SYN_WIN_SRCFILE
    )
    port map(
        i_rdClk    => i_clk,
        i_rdAddr   => o_sfPr.usX_winAddr,
        o_rdData   => slvX_winValue
    );
    -- =====================================

    -- =====================================
    -- Multiplier  
    mult_inst : entity work.signedMultiplier
    generic map (
        VALUE_WIDTH     => VALUE_WIDTH
    )
    port map(
        i_clk       => i_clk,
        i_slvX_op1  => i_sF.slvX_dataValue,
        i_slvX_op2  => slvX_winValue,
        o_slvX_res  => slvX_mulVal
    );
    -- =====================================

    -- =====================================
    -- Synthesis buffer
    bram_inst : entity work.synthesisFilter_buffer_bram
    generic map (
        VALUE_WIDTH  => VALUE_WIDTH,
        ADDR_WIDTH   => ADDR_WIDTH
    )
    port map(
        i_clk      => i_clk,
        i_wrEnable => o_sfPr.sl_buffWrEn,
        i_wrAddr   => o_sfPr.usX_buffAddrWr,
        i_wrData   => slvX_bram_dataValue_wr,

        i_rdAddr   => o_sfPr.usX_buffAddrRd,
        o_rdData   => slvX_bram_dataValue_rd
    );

    -- -------------------------------------
    -- Data Mux
    slvX_bram_dataValue_wr <= slvX_addVal when o_sfPr.sl_outputValid = '0'
                        else (others => '0');
    -- =====================================

    -- =====================================
    -- Adder  
    adder_inst : entity work.signedAdder
    generic map (
        VALUE_WIDTH  => VALUE_WIDTH
    )
    port map(
        i_clk       => i_clk,
        i_slvX_op1  => slvX_bram_dataValue_rd,
        i_slvX_op2  => slvX_mulVal,
        o_slvX_res  => slvX_addVal
    );
    -- =====================================


    -- =====================================
    -- Synthesis Filter processing logic
    processing_inst : entity work.synthesisFilter_process
    generic map (
        VALUE_WIDTH  => VALUE_WIDTH,
        HOP_SIZE     => HOP_SIZE,
        FRAME_SIZE   => FRAME_SIZE,
        ADDR_WIDTH   => ADDR_WIDTH
    )
    port map(
        i_clk                     => i_clk,
        i_sfPr.sl_reset_slow      => i_sF.sl_reset_slow,
        
        i_sfPr.sl_dataValid       => i_sF.sl_dataValid,
        
        o_sfPr                    => o_sfPr
    );
    -- =====================================

    o_sF.sl_dataValid   <= o_sfPr.sl_outputValid;
    o_sF.slvX_dataValue <= slvX_addVal;

end rtl;

