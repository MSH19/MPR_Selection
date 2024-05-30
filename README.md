# MPR_Selection
Demonstration of an algorithm for Multi-Point Relay (MPR) nodes selection in the Optimized Link-State Routing (OLSR) protocol.
The "Selector" script works in two main steps: 
1- Select the first-hop neighbors that cover isolated second-hop neighbors. 
2- Select additional first-hop neighbors based on maximum coverage criteria. 
The algorithm stops when all second-hop neighbors are covered by the selected MPRs.

Please cite this code as: Mahdi Saleh, “MPR Selection in OLSR protocol,” 2020, doi: 10.13140/RG.2.2.29685.60640.

[![View MPR Selection in OLSR protocol on File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)](https://www.mathworks.com/matlabcentral/fileexchange/71079-mpr-selection-in-olsr-protocol)
