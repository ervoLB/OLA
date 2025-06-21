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


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

entity signedMultiplier is
generic (
    VALUE_WIDTH      : integer
);
port (  
    i_clk      : in std_logic;
    i_slvX_op1 : in std_logic_vector(VALUE_WIDTH-1 downto 0);
    i_slvX_op2 : in std_logic_vector(VALUE_WIDTH-1 downto 0);
    o_slvX_res : out std_logic_vector(VALUE_WIDTH-1 downto 0)
);
end entity signedMultiplier;

architecture rtl of signedMultiplier is

    type reg_type is record
        slvX_mulVal     : std_logic_vector (2*VALUE_WIDTH-1 downto 0);
        slvX_res        : std_logic_vector (VALUE_WIDTH-1 downto 0);
        slvX_op1        : std_logic_vector (VALUE_WIDTH-1 downto 0);
        slvX_op2        : std_logic_vector (VALUE_WIDTH-1 downto 0);
    end record;

    signal r, c  : reg_type;

begin

    combinational_part : process(r, i_slvX_op1, i_slvX_op2)
        variable v : reg_type;
    begin
        v := r;

        v.slvX_op1 := i_slvX_op1;
        v.slvX_op2 := i_slvX_op2;

        v.slvX_mulVal := r.slvX_op1 * r.slvX_op2;

        if r.slvX_mulVal(2*VALUE_WIDTH-1) /= r.slvX_mulVal(2*VALUE_WIDTH-1) then -- saturation logic
            -- if -1 is multiplied with -1 we should get 1 or maximum positive value 
            v.slvX_res := (others => '1');
            v.slvX_res(VALUE_WIDTH-1) := '0';

        elsif r.slvX_mulVal(VALUE_WIDTH-2) = '1' then -- truncation logic
            -- if discarded value is 0.5 or higher, round up
            v.slvX_res := std_logic_vector(r.slvX_mulVal(2*VALUE_WIDTH-2 downto VALUE_WIDTH-1)+1);
        else
            -- if discarded value is lower then 0.5, round down
            v.slvX_res := r.slvX_mulVal(2*VALUE_WIDTH-2 downto VALUE_WIDTH-1);
        end if;
        
        c <= v;                              -- variables to combinatorial signal
    end process;

    synchronous_part : process(i_clk)
    begin
        if rising_edge(i_clk) then
            r <= c;
        end if;
    end process;

    o_slvX_res <= r.slvX_res; 
    
end rtl;