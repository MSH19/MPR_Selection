% Demo: MPR selection (OLSR-style) on a connected random graph
% Shows the full flow: graph creation, MPR selection, and a simple summary.

clc;
clearvars;
close all;

%% ---------------- User settings ----------------
total_nodes        = 15;    % total number of nodes
decision_threshold = 0.5;   % edge probability ~ (1 - decision_threshold)
                            % higher threshold => fewer edges (sparser)

% rng(1); % uncomment for fully reproducible demo

%% ---------------- Output folder (for PDF export) ----------------
outdir = 'outputs';
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

%% ---------------- Create connected network ----------------
% The graph is built as:
%   1) random spanning tree (guarantees connectivity)
%   2) extra edges added randomly to control density
[G, info] = createConnectedNetwork(total_nodes, decision_threshold);

%% ---------------- Choose the selector node ----------------
mpr_selector = randi(total_nodes);

%% ---------------- Run MPR selection ----------------
out = mpr_select(G, mpr_selector);

%% ---------------- Print key results ----------------
fprintf('Graph: N=%d, |E|=%d, density=%.3f, avg_deg=%.2f\n', ...
    info.N, info.num_edges, info.edge_density, info.degree_mean);

fprintf(['Selector=%d | N1=%d, N2=%d | MPRs=%d | reduction=%.1f%% | ' ...
         'coverage_ok=%d | stage1_MPRs=%d | stage2_MPRs=%d | runtime=%.4fs\n'], ...
    mpr_selector, out.n_firstHop, out.n_secondHop, out.n_mprs, ...
    out.reduction_pct, out.coverage_ok, ...
    out.n_mprs_stage1, out.n_mprs_stage2, out.runtime_s);

%% ---------------- Plot result (IEEE-style, vector PDF) ----------------
plot_mpr_full_ieee(G, out, info, mpr_selector, ...
    'ExportPDF', true, ...
    'OutDir', outdir, ...
    'FileName', 'mpr_demo_topology.pdf', ...
    'Layout', 'force', ...
    'FigWidth', 3.45, ...
    'FigHeight', 2.6);
