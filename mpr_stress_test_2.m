clc;
clear;
close all;

% =========================================================================
% Stress test: Greedy MPR selection with randomised baseline comparison
%
% This is designed to apply stress tests for random baseline comparison.
%
% Purpose:
%   Evaluate the greedy coverage-based relay selection algorithm at the
%   algorithm level, independent of any full routing protocol stack.
%
% Metrics:
%   - Correctness: coverage_success_rate
%   - Efficiency: mean |R| and relay reduction relative to |N1|
%   - Cost: mean runtime
%   - Relay composition: Stage-1 mandatory relays vs Stage-2 greedy relays
%   - Selector stability: variability of |R| across selectors on the same graph
%   - Baseline comparison: greedy method vs randomised useful-candidate baseline
%
% For each (N, p_extra):
%   1) Generate many connected random graphs.
%   2) For each graph, test several random selector nodes.
%   3) Run both greedy and randomised baseline on the same graph/selector.
%   4) Aggregate results and export CSV + figures.
% =========================================================================

%% ---------------- Sweep settings ----------------
N_list       = [10:10:100 150 200];
p_extra_list = [0 0.01 0.02 0.05 0.1:0.1:0.9];

graphs_per_cfg  = 200;
selectors_per_g = 3;

% Fixed seed for reproducibility
rng(1);

%% ---------------- Output settings ----------------
outdir     = 'outputs';
csv_file   = 'mpr_stress_test_results_with_random.csv';
fig_prefix = 'mpr_stress_test_';

if ~exist(outdir, 'dir')
    mkdir(outdir);
end

%% ---------------- Optional demo plot ----------------
do_demo_plot  = false;
demo_N        = 15;
demo_p_extra  = 0.4;
demo_filename = 'mpr_demo_topology.pdf';

if do_demo_plot
    [G_demo, info_demo] = createConnectedNetwork(demo_N, 1 - demo_p_extra);

    assert(isfield(info_demo,'is_connected') && info_demo.is_connected, ...
        'Demo graph unexpectedly disconnected.');

    v_demo   = randi(demo_N);
    out_demo = mpr_select(G_demo, v_demo);

    plot_mpr_full_ieee(G_demo, out_demo, info_demo, v_demo, ...
        'ExportPDF', true, ...
        'OutDir', outdir, ...
        'FileName', demo_filename, ...
        'Layout', 'force', ...
        'FigWidth', 3.45, ...
        'FigHeight', 2.6);

    fprintf('Saved demo PDF: %s\n', fullfile(outdir, demo_filename));
end

%% =======================================================================
% (A) Sweep and aggregation
% =======================================================================
n_cfg        = numel(N_list) * numel(p_extra_list);
runs_per_cfg = graphs_per_cfg * selectors_per_g;

% One row of S corresponds to one (N, p_extra) configuration
S(n_cfg,1) = struct( ...
    'row',0,'N',0,'p_extra',0,'runs_per_cfg',0, ...
    'edge_density_mean',0, ...
    'R_mean',0,'R_std',0, ...
    'R_random_mean',0,'R_random_std',0, ...
    'reduction_mean',0,'reduction_std',0, ...
    'reduction_random_mean',0,'reduction_random_std',0, ...
    'runtime_mean_s',0,'runtime_std_s',0, ...
    'runtime_random_mean_s',0,'runtime_random_std_s',0, ...
    'coverage_success_rate',0, ...
    'coverage_random_success_rate',0, ...
    'mprs_stage1_mean',0,'mprs_stage2_mean',0, ...
    'R_selector_std_mean',0);

row = 1;

for N = N_list
    for p_extra = p_extra_list

        % createConnectedNetwork uses a decision threshold.
        % Larger p_extra means more extra edges and therefore higher density.
        decision_threshold = 1 - p_extra;

        % Per-run arrays: one run = one graph + one selector
        R_vals   = zeros(runs_per_cfg,1);
        red_vals = zeros(runs_per_cfg,1);
        rt_vals  = zeros(runs_per_cfg,1);
        cov_ok   = false(runs_per_cfg,1);

        % Randomised coverage baseline arrays
        R_rand_vals   = zeros(runs_per_cfg,1);
        red_rand_vals = zeros(runs_per_cfg,1);
        rt_rand_vals  = zeros(runs_per_cfg,1);
        cov_rand_ok   = false(runs_per_cfg,1);

        % Greedy internal-stage composition
        mprs1_vals = zeros(runs_per_cfg,1);   % Stage 1: mandatory relays
        mprs2_vals = zeros(runs_per_cfg,1);   % Stage 2: greedy relays

        % Per-graph metrics
        density_vals    = zeros(graphs_per_cfg,1);
        R_sel_std_graph = zeros(graphs_per_cfg,1);

        run_idx = 0;

        for g = 1:graphs_per_cfg

            % Generate one connected graph for this configuration
            [G, info] = createConnectedNetwork(N, decision_threshold);

            assert(isfield(info,'is_connected') && info.is_connected, ...
                'Generator returned disconnected graph.');

            density_vals(g) = info.edge_density;

            % Store greedy |R| values across selectors on this graph
            % for selector-stability analysis
            R_this_graph = zeros(selectors_per_g, 1);

            for s = 1:selectors_per_g
                run_idx = run_idx + 1;

                % Select a random selector node
                v = randi(N);

                % Run greedy and randomised baseline on the same graph/selector.
                % This makes the comparison fair: only the selection rule changes.
                out      = mpr_select(G, v);
                out_rand = mpr_select_random(G, v);

                % Relay-set size
                R_vals(run_idx)      = out.n_mprs;
                R_rand_vals(run_idx) = out_rand.n_mprs;

                % Relay reduction relative to selecting all one-hop neighbours.
                % Higher value means fewer relays and lower expected forwarding overhead.
                if out.n_firstHop > 0
                    red_vals(run_idx) = 1 - (out.n_mprs / out.n_firstHop);
                else
                    red_vals(run_idx) = 0;
                end

                if out_rand.n_firstHop > 0
                    red_rand_vals(run_idx) = 1 - (out_rand.n_mprs / out_rand.n_firstHop);
                else
                    red_rand_vals(run_idx) = 0;
                end

                % Runtime and coverage status
                rt_vals(run_idx)  = out.runtime_s;
                cov_ok(run_idx)   = out.coverage_ok;

                rt_rand_vals(run_idx) = out_rand.runtime_s;
                cov_rand_ok(run_idx)  = out_rand.coverage_ok;

                % Greedy relay composition by stage
                mprs1_vals(run_idx) = out.n_mprs_stage1;
                mprs2_vals(run_idx) = out.n_mprs_stage2;

                % Sanity check for the greedy method
                if (out.n_mprs_stage1 + out.n_mprs_stage2) ~= out.n_mprs
                    error('Stage split mismatch: stage1 + stage2 ~= total MPRs');
                end

                % Greedy selector stability on this graph
                R_this_graph(s) = out.n_mprs;
            end

            % Standard deviation of greedy |R| across selectors on this graph
            R_sel_std_graph(g) = std(R_this_graph);
        end

        % Aggregate all runs for this (N, p_extra)
        S(row).row          = row;
        S(row).N            = N;
        S(row).p_extra      = p_extra;
        S(row).runs_per_cfg = runs_per_cfg;

        S(row).edge_density_mean = mean(density_vals);

        S(row).R_mean        = mean(R_vals);
        S(row).R_std         = std(R_vals);
        S(row).R_random_mean = mean(R_rand_vals);
        S(row).R_random_std  = std(R_rand_vals);

        S(row).reduction_mean        = mean(red_vals);
        S(row).reduction_std         = std(red_vals);
        S(row).reduction_random_mean = mean(red_rand_vals);
        S(row).reduction_random_std  = std(red_rand_vals);

        S(row).runtime_mean_s        = mean(rt_vals);
        S(row).runtime_std_s         = std(rt_vals);
        S(row).runtime_random_mean_s = mean(rt_rand_vals);
        S(row).runtime_random_std_s  = std(rt_rand_vals);

        S(row).coverage_success_rate        = mean(cov_ok);
        S(row).coverage_random_success_rate = mean(cov_rand_ok);

        S(row).mprs_stage1_mean = mean(mprs1_vals);
        S(row).mprs_stage2_mean = mean(mprs2_vals);

        S(row).R_selector_std_mean = mean(R_sel_std_graph);

        row = row + 1;
    end
end

%% ---------------- Export CSV ----------------
T = struct2table(S);
writetable(T, csv_file);
fprintf('Saved CSV results: %s\n', csv_file);

%% =======================================================================
% (B) Summary plots
% =======================================================================
markerList = {'o','s','^','d','v','>','<','p','h','x'};
lineList   = {'-','--','-.',':'};

% Plot 1: Greedy mean relay-set size vs density
fig = figure; hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    plot(T.p_extra(mask), T.R_mean(mask), ...
        'LineStyle', lineList{mod(i-1,numel(lineList))+1}, ...
        'Marker', markerList{mod(i-1,numel(markerList))+1}, ...
        'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Mean $|R|$','Interpreter','latex');
legend('Location','best');
export_pdf(fig, outdir, [fig_prefix 'R_vs_p_extra.pdf']);

% Plot 2: Greedy relay reduction vs density
fig = figure; hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    plot(T.p_extra(mask), 100*T.reduction_mean(mask), ...
        'LineStyle', lineList{mod(i-1,numel(lineList))+1}, ...
        'Marker', markerList{mod(i-1,numel(markerList))+1}, ...
        'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Mean reduction (\%)','Interpreter','latex');
legend('Location','best');
export_pdf(fig, outdir, [fig_prefix 'reduction_vs_p_extra.pdf']);

% Plot 2b: Greedy vs randomised useful-candidate baseline.
% Values are averaged across all network sizes for each p_extra.
fig = figure; hold on;
p_vals = unique(T.p_extra);
greedy_red = zeros(numel(p_vals),1);
random_red = zeros(numel(p_vals),1);

for k = 1:numel(p_vals)
    mask = abs(T.p_extra - p_vals(k)) < 1e-12;
    greedy_red(k) = mean(100*T.reduction_mean(mask));
    random_red(k) = mean(100*T.reduction_random_mean(mask));
end

plot(p_vals, greedy_red, '-o', 'DisplayName', 'Greedy coverage-based');
plot(p_vals, random_red, '--s', 'DisplayName', 'Randomised coverage baseline');

xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Mean relay reduction (\%)','Interpreter','latex');
legend('Location','best');
grid on; box on;
export_pdf(fig, outdir, [fig_prefix 'greedy_vs_random_reduction.pdf']);

% Plot 3: Greedy runtime vs network size for selected densities
fig = figure; hold on;
p_pick = [0 0.1 0.4 0.6];
j = 1;
for p_extra = p_pick
    mask = abs(T.p_extra - p_extra) < 1e-12;

    Ns  = T.N(mask);
    rts = T.runtime_mean_s(mask);

    [Ns, idx] = sort(Ns);
    rts = rts(idx);

    plot(Ns, rts, ...
        'LineStyle', lineList{mod(j-1,numel(lineList))+1}, ...
        'Marker', markerList{mod(j-1,numel(markerList))+1}, ...
        'DisplayName', sprintf('$p_{\\mathrm{extra}}=%.2g$', p_extra));
    j = j + 1;
end
xlabel('$N$','Interpreter','latex');
ylabel('Mean runtime (s)');
legend('Location','best','Interpreter','latex');
xticks(N_list);
export_pdf(fig, outdir, [fig_prefix 'runtime_vs_N.pdf']);

% Plot 4: Greedy coverage success rate
fig = figure; hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    plot(T.p_extra(mask), 100*T.coverage_success_rate(mask), ...
        'LineStyle', lineList{mod(i-1,numel(lineList))+1}, ...
        'Marker', markerList{mod(i-1,numel(markerList))+1}, ...
        'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Coverage success (\%)','Interpreter','latex');
ylim([0 105]);
legend('Location','best');
export_pdf(fig, outdir, [fig_prefix 'coverage_vs_p_extra.pdf']);

%% =======================================================================
% (C) Internal dynamics and variability output
% =======================================================================

% Stage composition for greedy method only
fig = figure;

subplot(2,1,1); hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    plot(T.p_extra(mask), T.mprs_stage1_mean(mask), ...
        'LineStyle', lineList{mod(i-1,numel(lineList))+1}, ...
        'Marker', markerList{mod(i-1,numel(markerList))+1}, ...
        'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
ylabel('Mean Stage-1 MPRs');
grid on; box on;

subplot(2,1,2); hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    plot(T.p_extra(mask), T.mprs_stage2_mean(mask), ...
        'LineStyle', lineList{mod(i-1,numel(lineList))+1}, ...
        'Marker', markerList{mod(i-1,numel(markerList))+1}, ...
        'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Mean Stage-2 MPRs');
grid on; box on;

legend('Location','bestoutside');
export_pdf(fig, outdir, [fig_prefix 'stage_composition_vs_p_extra.pdf']);

% Export variability data for optional inspection/table generation
T_var = T(:, {'N','p_extra','R_std','R_random_std', ...
              'reduction_std','reduction_random_std', ...
              'runtime_std_s','runtime_random_std_s', ...
              'R_selector_std_mean'});

% Coefficient of variation of greedy |R|
T_var.R_cv = T_var.R_std ./ max(1e-12, T.R_mean);

var_csv = fullfile(outdir, [fig_prefix 'variability_table.csv']);
writetable(T_var, var_csv);
fprintf('Saved variability table CSV: %s\n', var_csv);

%% ---------------- Local helper ----------------
function export_pdf(fig, outdir, filename)
    set(fig, 'Color','w');
    exportgraphics(fig, fullfile(outdir, filename), 'ContentType','vector');
end