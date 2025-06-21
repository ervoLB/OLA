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
--
entity synthesisFilter_process is
generic (
    VALUE_WIDTH   : integer;
    HOP_SIZE      : integer;
    FRAME_SIZE    : integer;
    ADDR_WIDTH    : integer
);
port(
    i_clk  : in  std_logic;
    i_sfPr : in  sF_proc_inputs_type;
    o_sfPr : out sF_proc_outputs_type
);
end entity synthesisFilter_process;

architecture rtl of synthesisFilter_process is


    type reg_type is record
        usX_winAddr     : unsigned(ADDR_WIDTH-1 downto 0);  -- address/counter for reading window values
        usX_buffAddrRd  : unsigned(ADDR_WIDTH-1 downto 0);  -- address for reading buffer values
        usX_buffRdCntr  : unsigned(ADDR_WIDTH-1 downto 0);  -- counter that counts how many values we have read from buffer 
        usX_buffAddrWr  : unsigned(ADDR_WIDTH-1 downto 0);  -- address for writing buffer values
        usX_buffWrCntr  : unsigned(ADDR_WIDTH-1 downto 0);  -- counter that counts how many values we have written in buffer 
        sl_buffWrEn     : std_logic;
        sl_outputValid  : std_logic;
        slv3_validDelay : std_logic_vector(2 downto 0);    
    end record;
    
    constant reg_type_Init : reg_type := (
        usX_winAddr     => (others=>'0'),  -- counter that counts read window values; it's never reseted because it counts in modulo
        usX_buffAddrRd  => (others=>'0'),
        usX_buffRdCntr  => (others=>'0'),  -- counter that counts values read from buffer; it's never reseted because it counts in modulo
        usX_buffAddrWr  => (others=>'0'),
        usX_buffWrCntr  => (others=>'0'),
        sl_buffWrEn     => '0',
        sl_outputValid  => '0',
        slv3_validDelay => (others=>'0')
        );

    signal r, c                : reg_type;

begin    
    combinational_part : process(r,i_sfPr)
        variable v : reg_type;
    begin
        v := r;

        v.slv3_validDelay(2 downto 1) := r.slv3_validDelay(1 downto 0);
        v.slv3_validDelay(0) := i_sfPr.sl_dataValid;

        -- window read addressing
        if i_sfPr.sl_dataValid = '1' then          -- if data is valid process it 
            v.usX_winAddr    := r.usX_winAddr + 1; 
        end if;  

   
        -- buffer read
        if r.slv3_validDelay(1) = '1' then  -- if this is valid value that was processed, update the read address
            if r.usX_buffRdCntr = FRAME_SIZE-1 then  
                v.usX_buffAddrRd := r.usX_buffAddrRd + HOP_SIZE + 1;  -- if this was last value in the frame, set the read address for the next frame
            else
                v.usX_buffAddrRd := r.usX_buffAddrRd + 1; 
            end if;
            v.usX_buffRdCntr := r.usX_buffRdCntr + 1; -- increment value counter
        end if;        

        
        -- buffer write
        v.sl_buffWrEn := '0';
        if r.slv3_validDelay(2) = '1' then -- check if there is a value to be written
            v.sl_buffWrEn    := '1';
        end if;    

        if r.sl_buffWrEn = '1' then  -- if we wrote something, update the write address 
            if r.usX_buffWrCntr = FRAME_SIZE-1 then -- if usX_buffRdCntr is 1 it means that next value is the first value of the new frame
                v.usX_buffAddrWr := r.usX_buffAddrWr + HOP_SIZE + 1; -- if that was the last value in the frame, set the write address for the next frame
            else
                v.usX_buffAddrWr := r.usX_buffAddrWr + 1; -- if the next value is not first value of the next frame, increment write address by 1
            end if;
            v.usX_buffWrCntr := r.usX_buffWrCntr + 1;
        end if;    
            

        v.sl_outputValid := '0';
        -- only first hop size number of values are valid in each frame, because we are using counter coupled to
        -- the buffer read process it has one clock delay and because of that values between 1 and HOP_SIZE are valid  
        if (r.slv3_validDelay(2) = '1') and ((r.usX_buffRdCntr > 0) and (r.usX_buffRdCntr <= HOP_SIZE))  then 
            v.sl_outputValid := '1';
        end if;

        
        if i_sfPr.sl_reset_slow = '1' then         -- reset the unit
            v := reg_type_Init;
        end if;
        
        c <= v;                              -- variables to combinatorial signal
    end process;

    synchronous_part : process(i_clk)
    begin
        if rising_edge(i_clk) then
            r <= c;
        end if;
    end process;

    -- set outputs
    o_sfPr.usX_winAddr     <= c.usX_winAddr;
    o_sfPr.usX_buffAddrRd  <= r.usX_buffAddrRd;
    o_sfPr.sl_buffWrEn     <= r.sl_buffWrEn;
    o_sfPr.usX_buffAddrWr  <= r.usX_buffAddrWr;
    o_sfPr.sl_outputValid  <= r.sl_outputValid;
 
end rtl;