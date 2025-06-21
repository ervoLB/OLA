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
use std.textio.all;

use work.synthesisFilter_package.all;

entity anaSynWindow_bram is
    generic (
        ADDR_WIDTH      : positive ;        -- number of address bits
        VALUE_WIDTH     : positive ;        -- number of data bits
        WIN_SRCFILE     : string
    );
    port (
        i_rdClk     : in std_logic;
        i_rdAddr    : in unsigned(ADDR_WIDTH-1 downto 0);
        o_rdData    : out std_logic_vector(VALUE_WIDTH-1 downto 0) 
    );
end entity;

architecture rtl of anaSynWindow_bram is
    constant RAM_DEPTH	: positive := 2**ADDR_WIDTH;
    subtype  type_value is std_logic_vector(VALUE_WIDTH - 1 downto 0);
    type     type_ram   is array(0 to RAM_DEPTH - 1) of type_value;
    
    -- Compute the initialization of a RAM array, if specified, from the passed file.
    function initMemory return type_ram is
        file infile        : text is in WIN_SRCFILE;
        variable inline    : line;  --line number declaration
        --variable readValue : string(type_value'high downto type_value'low);
        variable readValue : integer;
        variable res	   : type_ram;
    begin
        for i in type_ram'range loop
            if (not endfile(infile)) then   -- first read values from first image
                readline(infile, inline);  --reading a line from the file.
                --reading the data from the line and putting it in a real type variable.
                read(inline, readValue);
                res(i) := std_logic_vector(to_signed(readValue,type_value'high+1));
                --res(i) := std_logic_vector(readValue);
            end if;  
        end loop;
        return res;
    end function;
    
    signal   ram        : type_ram := initMemory;
    
    signal rdAddr_reg : unsigned(ADDR_WIDTH-1 downto 0) := (others => '0');
    
begin

    rd_process:process (i_rdClk)
    begin
        if rising_edge(i_rdClk) then
            rdAddr_reg <= i_rdAddr;
        end if;
    end process;

    o_rdData <= ram(to_integer(rdAddr_reg));
    
end rtl;