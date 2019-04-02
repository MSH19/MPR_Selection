# MPR_Selection
Demonstration of an algorithm for Multi-Point Relay (MPR) nodes selection in the Optimized Link-State Routing (OLSR) protocol.
The "Selector" script works in two main steps: 
1- Select the first-hop neighbors that cover isolated second-hop neighbors. 
2- Select additional first-hop neighbors based on maximum coverage criteria. 
The algorithm stops when all second-hop neighbors are covered by the selected MPRs.
