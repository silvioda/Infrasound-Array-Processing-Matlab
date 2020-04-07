README file for infrasound array processing software.

This software is provided as an example to demonstrate the application of the algorithms published in:
De Angelis et al. (2020). Uncertainty in detection of volcanic activity using infrasound arrays: examples from Mt.Etna, Italy

The code is not optimized for speed or use in real-time monitoring. USE AT YOUR OWN RISK.
For real-time implementation and/or a Python version of these codes, please, contact the corresponding author of the manuscritpt, Silvio De Angelis (silvioda@liverpool.ac.uk)

Last Version: 7 April 2020


The software folder contains: 
1) a control script, runme.m 
2) subdirectory cmaps (colormaps for plots)
3) subdirectory data (example miniseed files)
4) subdirectory src  (Matlab functions that implement infrasound array inversion)

Before executing the runme.m script the user needs to install the GISMO toolbox for Matlab, which is not provided here but freely available at:
https://geoscience-community-codes.github.io/GISMO/

Once GISMO is installed, runme.m can be executed and it will analyse infrasound array data from Mt. Etna recorded on 27 July 2019 (original day-long miniseed files are found in the data folder)
The script will create two folders in the current directory: output and figures where the output of processing will be saved in a .txt file and a plot of the results saved as a .png file.

The script can be adapted for use with the User's own miniseed files. The core functions to perform array calculations are found in the src folder for the User that wishes 
to implement their own processing workflow.


LICENSE: This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.



