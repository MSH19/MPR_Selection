# MPR Selection in OLSR Protocol

This repository provides a reference implementation of an algorithm for selecting
Multi-Point Relay (MPR) nodes in the Optimized Link-State Routing (OLSR) protocol.

## Algorithm overview
The MPR selection process is performed in two main steps:
1. Select first-hop neighbors that uniquely cover second-hop neighbors
   reachable via exactly one first-hop neighbor.
2. Iteratively select additional first-hop neighbors based on maximum remaining
   second-hop coverage.

The algorithm terminates once all second-hop neighbors are covered by the selected MPR set.

## Citation
If you use this code in academic work, please cite:

Mahdi Saleh, *“MPR Selection in OLSR Protocol,”* 2020.  
DOI: 10.13140/RG.2.2.29685.60640

## Related resources
[![View on MATLAB File Exchange](https://www.mathworks.com/matlabcentral/images/matlab-file-exchange.svg)]
(https://www.mathworks.com/matlabcentral/fileexchange/71079-mpr-selection-in-olsr-protocol)
