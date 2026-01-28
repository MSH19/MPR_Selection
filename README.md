# A Reference Implementation of a Greedy Coverage-Based Relay Selection Algorithm
## Application to Multi-Point Relay (MPR) Selection in OLSR

This repository provides a reference implementation of the canonical greedy
coverage-based relay selection algorithm used for Multi-Point Relay (MPR)
selection in the Optimized Link-State Routing (OLSR) protocol. The implementation
demonstrates the core MPR selection logic in a clear and reusable form and is not
intended to provide a complete routing protocol implementation.

## Algorithm overview
The relay (MPR) selection process is performed in two steps:

1. First-hop neighbors that uniquely cover second-hop neighbors (i.e., second-hop
   nodes reachable via exactly one first-hop neighbor) are selected mandatorily.

2. Additional first-hop neighbors are then selected iteratively based on maximum
   remaining second-hop coverage.

The algorithm terminates once all second-hop neighbors are covered by the selected
relay (MPR) set.

This implementation operates on two-hop neighborhood information in order to match
OLSR requirements. The underlying greedy coverage formulation is not inherently
limited to two hops and can be extended to k-hop coverage by redefining the selector
and target node sets.

## Intended use
This code is intended for:
- Reference and educational use
- Reproducible evaluation of MPR selection logic
- Baseline comparison for enhanced or weighted MPR selection schemes
- Relay or forwarder selection studies in distributed and multi-hop networks

## Implementation notes and requirements
- The demo script (`Selector.m`) generates a random connected network using MATLAB
  graph utilities. Network generation may retry multiple times until a connected
  graph is obtained.
- The MPR selector node is chosen uniformly at random.
- The implementation uses the `datasample` function; therefore, the MATLAB
  Statistics and Machine Learning Toolbox is required.

If this toolbox is not available, the following equivalent base-MATLAB replacement
can be used without changing the algorithm’s behavior:
```matlab
mpr_selector = node_ids(randi(numel(node_ids)));
```

## How to cite
If you use this code in academic work, please cite:

Mahdi Saleh, *“MPR Selection in OLSR Protocol,”* 2020.  
DOI: 10.13140/RG.2.2.29685.60640

