#!/usr/bin/env python3
"""
The MIT License (MIT)

Copyright (c) 2024 Lovre Bogdanic, lovre.bogdanic@gmail.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
===================================================================================================
"""

import numpy as np
import matplotlib.pyplot as plt
from scipy import signal
import os

def get_window(window_type, frame_size, periodic=True):
    """Generate window function based on type"""
    if window_type in ['hann', 'hanning']:
        if periodic:
            return signal.windows.hann(frame_size, sym=False)
        else:
            return signal.windows.hann(frame_size, sym=True)
    elif window_type == 'hamming':
        if periodic:
            return signal.windows.hamming(frame_size, sym=False)
        else:
            return signal.windows.hamming(frame_size, sym=True)
    elif window_type == 'rectwin':
        return np.ones(frame_size)
    else:
        raise ValueError(f"Unsupported window type: {window_type}")

def fixed_point_round(value, value_width):
    """Simulate 16-bit fixed point arithmetic rounding"""
    tmp = np.floor(value / (2**(value_width-2)))
    if tmp % 2:  # check if (valueWidth-1)th bit is one
        return np.ceil(tmp / 2)  # discard lower 15 bits and round up
    else:
        return np.floor(tmp / 2)  # discard lower 15 bits and round down

def main():
    # Clear variables equivalent (Python doesn't need this)
    plt.close('all')
    
    #**************************************************************************
    # Main initialization
    #**************************************************************************
    value_width = 16    # number of bits in sampled audio values
    hop_size = 16       # hop size
    frame_size = 64     # frame size
    
    random_input = True
    window_type = 'hanning'
    
    output_lag = frame_size - hop_size
    
    save_inputs = True
    save_windows = True
    save_outputs = True
    
    #**************************************************************************
    # Generate stimuli signal in integer representation same as in VHDL model
    #**************************************************************************
    steps = np.arange(10000)
    
    if random_input:
        x = 2 * (np.random.rand(len(steps)) - 0.5)  # random signal in range -1 to 1
    else:
        x = np.sin(2 * np.pi / 1000 * steps)  # a simple sinus
    
    # convert it to integer values in range from -2^(value_width-1) to 2^(value_width-1)-1
    # representing signed 16 bit values
    scale = 2**(value_width-1)
    minq = -2**(value_width-1)
    maxq = 2**(value_width-1) - 1
    
    x_integer = np.zeros(len(x), dtype=int)
    for i in range(len(x)):
        tmp = round(x[i] * scale)
        if tmp > maxq:
            tmp = maxq
        if tmp < minq:
            tmp = minq
        x_integer[i] = tmp
    
    # Save inputs in text file
    if save_inputs:
        filename_input = 'anaInputs.txt'
        with open(filename_input, 'w') as fid_input:
            for i in range(len(x_integer)-1):
                fid_input.write(f'{x_integer[i]}\n')
            fid_input.write(f'{x_integer[-1]}')
    
    #**************************************************************************
    # Design filter banks
    #**************************************************************************
    if window_type in ['hann', 'hanning', 'hamming']:
        h_ana = get_window(window_type, frame_size, periodic=True)
    else:
        h_ana = get_window(window_type, frame_size, periodic=False)
    
    x_out = np.zeros(len(x_integer))
    h_win_scale = np.sum(h_ana * h_ana) / hop_size
    h_syn = h_ana / h_win_scale
    ana_buffer = np.zeros(frame_size)
    syn_buffer = np.zeros(frame_size)
    
    # Plot windows
    plt.figure()
    plt.plot(h_ana, 'b', label='Analysis')
    plt.plot(h_syn, 'g', label='Synthesis')
    plt.title('Analysis and synthesis windows')
    plt.legend()
    plt.grid(True)
    
    # convert h_ana and h_syn to fixed point arithmetic
    h_ana = np.round(h_ana * (2**(value_width-1) - 1)).astype(int)
    h_syn = np.round(h_syn * (2**(value_width-1) - 1)).astype(int)
    
    # Save windows in text files
    if save_windows:
        # Create directories if they don't exist
        os.makedirs('../../src/init_files', exist_ok=True)
        
        filename_win = '../../src/init_files/analysisWindow_initFile.txt'
        with open(filename_win, 'w') as fid_win:
            for i in range(len(h_ana)-1):
                fid_win.write(f'{h_ana[i]}\n')
            fid_win.write(f'{h_ana[-1]}')
        
        filename_win = '../../src/init_files/synthesisWindow_initFile.txt'
        with open(filename_win, 'w') as fid_win:
            for i in range(len(h_syn)-1):
                fid_win.write(f'{h_syn[i]}\n')
            fid_win.write(f'{h_syn[-1]}')
    
    # output signal
    y_out = np.zeros(len(x_integer))
    
    #**************************************************************************
    # Main loop
    #**************************************************************************
    sample_counter = 0
    ana_buffer_win_precision = np.zeros(frame_size)
    
    # Open output files
    if save_outputs:
        fid_output_ana = open('anaOutputs.txt', 'w')
        fid_output_syn = open('synOutputs.txt', 'w')
    
    for k in range(0, len(x_integer) - hop_size, hop_size):
        #**********************************************************************
        # Analysis filterbank
        #**********************************************************************
        # calculate where is the end of the current segment
        input_start = k          # latest value to process
        input_end = k + hop_size - 1  # newest value to process
        
        # extract the current segment
        if input_end < len(x_integer):
            hop_vals = x_integer[input_start:input_end+1]
        else:  # if segment end is beyond end of input signal, zero pad
            remaining_samples = len(x_integer) - input_start
            hop_vals = np.concatenate([
                x_integer[input_start:],
                np.zeros(hop_size - remaining_samples, dtype=int)
            ])
        
        ana_buffer[:-hop_size] = ana_buffer[hop_size:]  # shift left
        ana_buffer[-hop_size:] = hop_vals
        ana_buffer_win = ana_buffer * h_ana
        
        # make a value_width fixed point arithmetic rounding
        ana_buffer_win_rounded = np.zeros(frame_size, dtype=int)
        for i in range(frame_size):
            ana_buffer_win_rounded[i] = fixed_point_round(ana_buffer_win[i], value_width)
        
        # Save ana outputs in text file
        if save_outputs:
            for i in range(frame_size):
                fid_output_ana.write(f'{ana_buffer_win_rounded[i]}\n')
        
        #**********************************************************************
        # processing part (placeholder for actual processing)
        #**********************************************************************
        
        #**********************************************************************
        # Synthesis filterbank
        #**********************************************************************
        syn_buffer_win = ana_buffer_win_rounded * h_syn
        
        syn_buffer_win_rounded = np.zeros(frame_size, dtype=int)
        for i in range(frame_size):
            syn_buffer_win_rounded[i] = fixed_point_round(syn_buffer_win[i], value_width)
        
        syn_buffer = syn_buffer + syn_buffer_win_rounded
        y_write = syn_buffer[:hop_size].copy()
        syn_buffer[:-hop_size] = syn_buffer[hop_size:]  # shift remaining values
        syn_buffer[-hop_size:] = 0  # initialize rest to 0

        if save_outputs:
            for i in range(hop_size):
                fid_output_syn.write(f'{int(y_write[i])}\n')
        
        # Write to output signal
        output_start = input_start
        if output_start + hop_size <= len(y_out):
            y_out[output_start:output_start + hop_size] = y_write
    
    if save_outputs:
        fid_output_ana.close()
        fid_output_syn.close()
    
    #**************************************************************************
    # Analyses
    #**************************************************************************
    y_d = y_out[output_lag:-frame_size] if len(y_out) > frame_size + output_lag else y_out[output_lag:]
    x_cropped = x_integer[:len(y_d)]
    diff_d = x_cropped - y_d
    
    Y = np.sum(y_d**2)
    D = np.sum(diff_d**2)
    
    if D > 0:
        SNR_db = 10 * np.log10(Y / D)
    else:
        SNR_db = float('inf')
    
    # Plotting
    plt.figure(figsize=(12, 8))
    
    plt.subplot(3, 1, 1)
    plt.plot(x_integer, 'b', label='ideal')
    plt.plot(y_out, 'g', label='calculated')
    plt.title('Input output analysis')
    plt.legend()
    plt.grid(True)
    
    plt.subplot(3, 1, 2)
    plt.plot(x_cropped, 'b', label='ideal')
    plt.plot(y_d, 'g', label='calculated')
    plt.title('Input output analysis (cropped)')
    plt.legend()
    plt.grid(True)
    
    plt.subplot(3, 1, 3)
    plt.plot(diff_d, 'r', label='difference')
    txt = f'SNR: {SNR_db:.2f}dB'
    plt.title(f'Difference; {txt}')
    plt.legend()
    plt.grid(True)
    
    plt.tight_layout()
    plt.show()
    
    print('Done!')
    print(f'SNR: {SNR_db:.2f} dB')

if __name__ == "__main__":
    main()