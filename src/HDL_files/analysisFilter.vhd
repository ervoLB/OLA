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

entity analysisFilter is
generic (
    SIMULATION      : boolean;
    VALUE_WIDTH     : integer;
    HOP_SIZE        : integer;
    FRAME_SIZE      : integer;
    ADDR_WIDTH      : integer;  -- this generic is dependent from FRAME_SIZE -> ADDR_WIDTH = ceil(log2(FRAME_SIZE))
    ANA_WIN_SRCFILE : string
);
port(
    -- =========================================
    -- clocks
    i_wrClk : in  std_logic;
    i_rdClk : in  std_logic;
    
    -- =========================================
    -- inputs
    i_af    : in aF_inputs_type;
    
    -- =========================================
    -- outputs
    o_af    : out aF_outputs_type  -- TODO: will here be different width because of multiplication e.g. VALUE_WIDTH+2?
    );
end analysisFilter;

architecture rtl of analysisFilter is
    
    signal slvX_dpram_dataValue : std_logic_vector(VALUE_WIDTH-1 downto 0) := (others => '0');
    
    signal o_afWp : aF_wp_outputs_type;
    signal o_afRp : aF_rp_outputs_type;

begin

    -- ADD records for module in-out ports (in package)
    write_inst : entity work.analysisFilter_writeProcess
    generic map (
        VALUE_WIDTH  => VALUE_WIDTH,
        HOP_SIZE     => HOP_SIZE,
        FRAME_SIZE   => FRAME_SIZE,
        ADDR_WIDTH   => ADDR_WIDTH
    )
    port map(
        i_clk                     => i_wrClk,
        i_afWp.sl_reset_slow      => i_af.sl_reset_slow,
        
        i_afWp.sl_dataValid       => i_af.sl_dataValid,
        i_afWp.slvX_dataValue     => i_af.slvX_dataValue,
        
        o_afWp                    => o_afWp
    );
    
    
    -- =====================================
    -- Dual port BRAM
    dpbram_inst : entity work.analysisFilter_buffer_dpram
    generic map (
        VALUE_WIDTH  => VALUE_WIDTH,
        ADDR_WIDTH   => ADDR_WIDTH
    )
    port map(
        i_wrClk    => i_wrClk,
        i_wrEnable => o_afWp.sl_wrEnable,
        i_wrAddr   => o_afWp.usX_dataAddr,
        i_wrData   => o_afWp.slvX_dataValue,
        
        i_rdClk    => i_rdClk,
        i_rdAddr   => o_afRp.usX_dataAddr,
        o_rdData   => slvX_dpram_dataValue
    );
    
    -- =====================================    
    
    -- ADD records for module in-out ports (in package)
    read_inst : entity work.analysisFilter_readProcess
    generic map (
        VALUE_WIDTH     => VALUE_WIDTH,
        HOP_SIZE        => HOP_SIZE,
        FRAME_SIZE      => FRAME_SIZE,
        ADDR_WIDTH      => ADDR_WIDTH,
        ANA_WIN_SRCFILE => ANA_WIN_SRCFILE
    )
    port map(
        i_clk                      => i_rdClk,
        i_afRp.sl_reset_slow       => i_af.sl_reset_slow,
        
        i_afRp.sl_hopDone_p_async  => o_afWp.sl_hopDone_p,
        i_afRp.slvX_dataValue      => slvX_dpram_dataValue,
 
        i_afRp.sl_readRequest      => i_af.sl_readRequest, -- there are four clocks delay between readRequest and valid data  on analysisFilter output
        o_afRp                     => o_afRp
    );
    
    o_af.sl_hopDone_p   <= o_afRp.sl_hopDone_p;            -- this pulse precedes valid data by 5 clocks (if read request is 1 at the time)
    o_af.sl_dataValid   <= o_afRp.sl_dataValid;
    o_af.slvX_dataValue <= o_afRp.slvX_dataValue;


    -- ===================================== 
    -- Probes
    af_probe: if SIMULATION = true generate
    begin
        af_probe_inst: entity work.simProbe_lite
        generic map (
            VALUE_WIDTH  => VALUE_WIDTH,
            fileName     => "..\..\..\..\verification\IO_files\anaOutputs_probe.txt"
        )
        port map(
            i_clk         => i_rdClk,
            i_dataValid   => o_afRp.sl_dataValid,
            i_dataValue   => o_afRp.slvX_dataValue            
        );

    end generate;

end rtl;

