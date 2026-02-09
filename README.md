# A Reference Implementation of a Greedy Coverage-Based Relay Selection Algorithm
## Application to Multi-Point Relay (MPR) Selection

This repository provides a **clear, auditable reference implementation** of the canonical greedy
coverage-based relay selection algorithm used for **Multi-Point Relay (MPR)** selection in the
**Optimized Link-State Routing (OLSR)** protocol.

The goal is **not** to implement a full routing protocol, but to expose the **core relay selection
logic** as a standalone, deterministic graph algorithm suitable for inspection, reuse, and fair
comparison.

---

## Algorithm overview

Relay (MPR) selection is performed using a **two-stage greedy process** based solely on two-hop
neighbourhood information:

1. **Mandatory relay selection**  
   One-hop neighbours that are the *only* nodes capable of reaching specific two-hop neighbours
   are selected mandatorily to guarantee full coverage.

2. **Greedy completion**  
   Remaining uncovered two-hop neighbours are covered iteratively by selecting the one-hop
   neighbour that provides the **maximum additional coverage**.  
   Ties are resolved deterministically by selecting the **lowest-index node**.

The algorithm terminates once all reachable two-hop neighbours are covered or no further progress
is possible.

While this implementation matches the **two-hop requirement of OLSR**, the underlying formulation
is general and can be extended to *k-hop* coverage by redefining candidate and target sets.

---

## Repository contents

- `mpr_select.m`  
  Core reference implementation of the coverage-based relay selection algorithm.

- `get_First_Second_Neighbors.m`  
  Utility to extract one-hop and two-hop neighbourhoods for a given selector node.

- `getNodeMaxCoverage.m`  
  Helper function used during greedy selection to determine maximum uncovered coverage.

- `createConnectedNetwork.m`  
  Generates random connected undirected graphs for controlled experiments.

- `demo_mpr_select.m`  
  Minimal demo illustrating relay selection on a single random topology.

- `mpr_stress_test.m`  
  Systematic stress-test framework sweeping network size and connectivity and exporting evaluation
  results.

- `make_mpr_plots_1x3.m`  
  Script to generate the three-panel illustrative figure (sparse, medium, dense connectivity)
  used in the accompanying paper to visualise the effect of topology density on relay selection.

- `plot_mpr_full_ieee.m`  
  IEEE-style plotting utility for publication-quality figures (vector PDF output).

---

## Intended use

This code is intended for:

- Reference and educational purposes  
- Reproducible evaluation of MPR / relay selection logic  
- Baseline comparison for enhanced, weighted, or learning-based relay selection schemes  
- Algorithm-level studies of broadcast optimisation in distributed and multi-hop networks  

The implementation is **protocol-agnostic** and deliberately isolated from MAC, routing, mobility,
and traffic models.

---

## Determinism and reproducibility

- All algorithmic choices are **deterministic** given a fixed graph and selector node.
- Ties during greedy selection are resolved using a **fixed, documented rule**.
- Randomised experiments rely on controlled seeding in the stress-test scripts.
- Figures are exported as **vector PDF** for reproducible publication use.

---

## Software and environment

The code was developed and evaluated using:

- MATLAB R2024b  
- Windows 11  
- Intel Core i7-1250U (10 cores), 16 GB RAM  

Only **base MATLAB functionality** is required for the current codebase.

---

## Relation to the paper

This repository accompanies the paper:

**A Reference Implementation of a Greedy Coverage-Based Relay Selection Algorithm**

The code and evaluation framework are intended to support:
- independent verification of results,
- fair comparison against alternative relay-selection strategies,
- and reuse in future protocol and systems research.

---

## Citation

A formal citation will be added **once the preprint is released**.  
Until then, please reference this repository and the accompanying paper.
