clc;
clear; 
close all;

% =========================================================================
% Minimal stress test: Greedy MPR selection (OLSR-style) - algorithm-level
%
% Paper aims (keep minimal):
%   - Correctness: coverage_success_rate
%   - Efficiency: mean |R|, mean reduction vs |N1|
%   - Cost: mean runtime
%   - Relay composition: mean Stage-1 MPRs (mandatory) vs Stage-2 MPRs (greedy)
%   - Selector stability: how much |R| varies across selectors on the same graph
%
% For each (N, p_extra):
%   1) Generate many CONNECTED graphs (spanning tree + extra edges).
%   2) For each graph, test a few random selectors v.
%   3) Aggregate means (+ simple std where useful).
% =========================================================================

%% ---------------- Sweep settings ----------------
N_list          = [10:10:100 150 200];
p_extra_list    = [0 0.01 0.02 0.05 0.1:0.1:0.9];

graphs_per_cfg  = 200;
selectors_per_g = 3;

rng(1);

%% ---------------- Output ----------------
outdir     = 'outputs';
csv_file   = 'mpr_stress_test_results.csv';
fig_prefix = 'mpr_stress_test_';

% Ensure output folder exists
if ~exist(outdir, 'dir')
    mkdir(outdir);
end

%% ---------------- Optional demo plot ----------------
% do_demo_plot  = true;
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
% (A) Sweep + aggregation
% =======================================================================
n_cfg        = numel(N_list) * numel(p_extra_list);
runs_per_cfg = graphs_per_cfg * selectors_per_g;

% Keep fields minimal + the analysis outputs
S(n_cfg,1) = struct( ...
    'row',0,'N',0,'p_extra',0,'runs_per_cfg',0, ...
    'edge_density_mean',0, ...
    'R_mean',0,'R_std',0, ...
    'reduction_mean',0,'reduction_std',0, ...
    'runtime_mean_s',0,'runtime_std_s',0, ...
    'coverage_success_rate',0, ...
    'mprs_stage1_mean',0,'mprs_stage2_mean',0, ...
    'R_selector_std_mean',0);

row = 1;

for N = N_list
    for p_extra = p_extra_list

        decision_threshold = 1 - p_extra;

        % Per-run arrays (run = one graph + one selector)
        R_vals      = zeros(runs_per_cfg,1);
        red_vals    = zeros(runs_per_cfg,1);
        rt_vals     = zeros(runs_per_cfg,1);
        cov_ok      = false(runs_per_cfg,1);
        mprs1_vals  = zeros(runs_per_cfg,1);   % Stage 1: mandatory relays
        mprs2_vals  = zeros(runs_per_cfg,1);   % Stage 2: greedy relays

        % Per-graph arrays
        density_vals     = zeros(graphs_per_cfg,1);
        R_sel_std_graph  = zeros(graphs_per_cfg,1); % selector stability per graph

        run_idx = 0;

        for g = 1:graphs_per_cfg

            % ---- 1) Generate one connected graph ----
            [G, info] = createConnectedNetwork(N, decision_threshold);
            assert(isfield(info,'is_connected') && info.is_connected, ...
                'Generator returned disconnected graph (unexpected).');

            density_vals(g) = info.edge_density;

            % Collect |R| across selectors for *this* graph (stability metric)
            R_this_graph = zeros(selectors_per_g, 1);

            % ---- 2) Evaluate multiple selectors on the same graph ----
            for s = 1:selectors_per_g
                run_idx = run_idx + 1;

                v   = randi(N);
                out = mpr_select(G, v);

                % Core outcomes
                R_vals(run_idx) = out.n_mprs;

                if out.n_firstHop > 0
                    red_vals(run_idx) = 1 - (out.n_mprs / out.n_firstHop);
                else
                    red_vals(run_idx) = 0;
                end

                rt_vals(run_idx) = out.runtime_s;
                cov_ok(run_idx)  = out.coverage_ok;

                % Gap-filling: relay composition per stage
                mprs1_vals(run_idx) = out.n_mprs_stage1;
                mprs2_vals(run_idx) = out.n_mprs_stage2;

                % Sanity: total should match stage split
                if (out.n_mprs_stage1 + out.n_mprs_stage2) ~= out.n_mprs
                    error('Stage split mismatch: stage1+stage2 ~= total MPRs');
                end

                % For selector stability on this graph
                R_this_graph(s) = out.n_mprs;
            end

            % Selector stability for this graph: std(|R|) across selector nodes
            R_sel_std_graph(g) = std(R_this_graph);
        end

        % ---- 3) Aggregate this (N, p_extra) configuration ----
        S(row).row               = row;
        S(row).N                 = N;
        S(row).p_extra           = p_extra;
        S(row).runs_per_cfg      = runs_per_cfg;

        S(row).edge_density_mean = mean(density_vals);

        S(row).R_mean            = mean(R_vals);
        S(row).R_std             = std(R_vals);

        S(row).reduction_mean    = mean(red_vals);
        S(row).reduction_std     = std(red_vals);

        S(row).runtime_mean_s    = mean(rt_vals);
        S(row).runtime_std_s     = std(rt_vals);

        S(row).coverage_success_rate = mean(cov_ok);

        % Relay composition (means)
        S(row).mprs_stage1_mean  = mean(mprs1_vals);
        S(row).mprs_stage2_mean  = mean(mprs2_vals);

        % Selector stability (mean across graphs)
        S(row).R_selector_std_mean = mean(R_sel_std_graph);

        row = row + 1;
    end
end

%% ---------------- Export CSV ----------------
T = struct2table(S);
writetable(T, csv_file);
fprintf('Saved CSV results: %s\n', csv_file);

%% =======================================================================
% (B) Summary plots (markers kept to differentiate curves)
% =======================================================================
markerList = {'o','s','^','d','v','>','<','p','h','x'};
lineList   = {'-','--','-.',':'};

% Plot 1: Mean |R| vs p_extra
fig = figure; hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    mk = markerList{mod(i-1,numel(markerList))+1};
    ls = lineList{mod(i-1,numel(lineList))+1};

    plot(T.p_extra(mask), T.R_mean(mask), ...
        'LineStyle', ls, 'Marker', mk, ...
        'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Mean $|R|$','Interpreter','latex');
legend('Location','best');
export_pdf(fig, outdir, [fig_prefix 'R_vs_p_extra.pdf']);

% Plot 2: Mean reduction (%) vs p_extra
fig = figure; hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    mk = markerList{mod(i-1,numel(markerList))+1};
    ls = lineList{mod(i-1,numel(lineList))+1};

    plot(T.p_extra(mask), 100*T.reduction_mean(mask), ...
        'LineStyle', ls, 'Marker', mk, ...
        'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Mean reduction (\%)','Interpreter','latex');
legend('Location','best');
export_pdf(fig, outdir, [fig_prefix 'reduction_vs_p_extra.pdf']);

% Plot 3: Mean runtime vs N (selected p_extra values)
fig = figure; hold on;
p_pick = [0 0.1 0.4 0.6];
j = 1;
for p_extra = p_pick
    mask = abs(T.p_extra - p_extra) < 1e-12;

    Ns  = T.N(mask);
    rts = T.runtime_mean_s(mask);

    [Ns, idx] = sort(Ns);
    rts = rts(idx);

    mk = markerList{mod(j-1,numel(markerList))+1};
    ls = lineList{mod(j-1,numel(lineList))+1};

    plot(Ns, rts, 'LineStyle', ls, 'Marker', mk, ...
        'DisplayName', sprintf('$p_{\\mathrm{extra}}=%.2g$', p_extra));
    j = j + 1;
end
xlabel('$N$','Interpreter','latex');
ylabel('Mean runtime (s)');
legend('Location','best','Interpreter','latex');
xticks(N_list);
export_pdf(fig, outdir, [fig_prefix 'runtime_vs_N.pdf']);

% Plot 4: Coverage success rate (%)
fig = figure; hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    mk = markerList{mod(i-1,numel(markerList))+1};
    ls = lineList{mod(i-1,numel(lineList))+1};

    plot(T.p_extra(mask), 100*T.coverage_success_rate(mask), ...
        'LineStyle', ls, 'Marker', mk, ...
        'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Coverage success (\%)','Interpreter','latex');
ylim([0 105]);
legend('Location','best');
export_pdf(fig, outdir, [fig_prefix 'coverage_vs_p_extra.pdf']);

%% =======================================================================
% (C) Internal dynamics (composition only) + variability table (no plot)
% =======================================================================

% ---- Figure: Stage-1 vs Stage-2 relay composition (2 subplots only) ----
fig = figure;

% Subplot 1: Mandatory relays selected (Stage 1)
subplot(2,1,1); hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    mk = markerList{mod(i-1,numel(markerList))+1};
    ls = lineList{mod(i-1,numel(lineList))+1};

    plot(T.p_extra(mask), T.mprs_stage1_mean(mask), ...
        'LineStyle', ls, 'Marker', mk, 'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
ylabel('Mean Stage-1 MPRs');
grid on; box on;

% Subplot 2: Greedy relays selected (Stage 2)
subplot(2,1,2); hold on;
i = 1;
for N = N_list
    mask = (T.N == N);
    mk = markerList{mod(i-1,numel(markerList))+1};
    ls = lineList{mod(i-1,numel(lineList))+1};

    plot(T.p_extra(mask), T.mprs_stage2_mean(mask), ...
        'LineStyle', ls, 'Marker', mk, 'DisplayName', sprintf('N=%d', N));
    i = i + 1;
end
xlabel('$p_{\mathrm{extra}}$','Interpreter','latex');
ylabel('Mean Stage-2 MPRs');
grid on; box on;

legend('Location','bestoutside');
export_pdf(fig, outdir, [fig_prefix 'stage_composition_vs_p_extra.pdf']);

% ---- Table: variability / stability metrics (instead of plotting) ----
% Keep only the variability fields you care about
T_var = T(:, {'N','p_extra','R_std','reduction_std','runtime_std_s','R_selector_std_mean'});

% (Optional) add one more: coefficient of variation of |R|
T_var.R_cv = T_var.R_std ./ max(1e-12, T.R_mean);

% Write a dedicated CSV for the paper table
var_csv = fullfile(outdir, [fig_prefix 'variability_table.csv']);
writetable(T_var, var_csv);
fprintf('Saved variability table CSV: %s\n', var_csv);


%% ---------------- Local helper ----------------
function export_pdf(fig, outdir, filename)
    set(fig, 'Color','w');
    exportgraphics(fig, fullfile(outdir, filename), 'ContentType','vector');
end
