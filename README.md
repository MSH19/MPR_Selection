# A Reference Implementation of a Greedy Coverage-Based Relay Selection Algorithm
## Applied to Multi-Point Relay (MPR) Selection in OLSR

This repository provides a reference implementation of a greedy coverage-based relay
selection algorithm, applied to Multi-Point Relay (MPR) selection in the Optimized
Link-State Routing (OLSR) protocol. The implementation follows the canonical two-stage
MPR selection heuristic and is intended as a clear, reusable demonstration rather than
a full protocol implementation.

## Algorithm overview
The relay (MPR) selection process is performed in two main steps:
1. Select first-hop neighbors that uniquely cover second-hop neighbors reachable via
   exactly one first-hop neighbor.
2. Iteratively select additional first-hop neighbors based on maximum remaining
   second-hop coverage.

The algorithm terminates once all second-hop neighbors are covered by the selected
relay (MPR) set.

While this reference implementation operates on two-hop neighborhood information to
match OLSR requirements, the underlying greedy coverage formulation is not inherently
limited to two hops and can be extended to k-hop coverage by redefining the selector
and target node sets.

## Implementation notes and requirements
- The demo script (`Selector.m`) generates a random connected network using MATLAB graph
  utilities. Network generation may retry multiple times until a connected graph is
  obtained.
- The relay (MPR) selector node is chosen uniformly at random.
- The implementation uses the `datasample` function; therefore, the **MATLAB Statistics
  and Machine Learning Toolbox is required**.

If this toolbox is not available, the following drop-in replacement can be used:
```matlab
mpr_selector = node_ids(randi(numel(node_ids)));
