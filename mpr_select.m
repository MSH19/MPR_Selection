function out = mpr_select(G, mpr_selector)
% MPR_SELECT Greedy MPR selection (OLSR-style) for one selector node.
%
% Two-stage procedure:
%   1) Mandatory relays:
%      If a 2-hop node is reachable through only one 1-hop node,
%      that 1-hop node must be selected.
%   2) Greedy completion:
%      Keep adding the 1-hop node that covers the most still-uncovered
%      2-hop nodes until coverage is complete (or no progress is possible).
%
% Extra outputs (for analysis):
%   - n_mprs_stage1: number of mandatory relays selected in Stage 1
%   - n_mprs_stage2: number of greedy relays added in Stage 2

    % -------------------- Outputs (default) --------------------
    out = struct();
    out.selector = mpr_selector;

    out.firstHop_ids = [];
    out.secondHop_ids = [];
    out.selected_MPRs = [];
    out.uncovered_secondHop = [];

    out.exit_flag = 0;   % 0=success, 1=nothing to cover, 2=stuck
    out.msg = "";

    out.n_firstHop = 0;
    out.n_secondHop = 0;
    out.n_mprs = 0;
    out.reduction_abs = 0;
    out.reduction_pct = 0;
    out.coverage_ok = false;
    out.coverage_ratio = 0;
    out.runtime_s = 0;

    % NEW: relay composition per stage (minimal + useful)
    out.n_mprs_stage1 = 0;
    out.n_mprs_stage2 = 0;

    % -------------------- Get N1 and N2 --------------------
    [N1, N2] = get_First_Second_Neighbors(mpr_selector, G);
    N1 = sort(unique(N1(:)'));
    N2 = sort(unique(N2(:)'));

    out.firstHop_ids  = N1;
    out.secondHop_ids = N2;
    out.n_firstHop  = numel(N1);
    out.n_secondHop = numel(N2);

    % Nothing to cover
    if isempty(N2)
        out.exit_flag = 1;
        out.coverage_ok = true;
        out.coverage_ratio = 1.0;
        out.msg = "No second-hop neighbors exist (nothing to cover).";
        return;
    end

    % No relays available
    if isempty(N1)
        out.exit_flag = 2;
        out.coverage_ok = false;
        out.coverage_ratio = 0.0;
        out.uncovered_secondHop = N2;
        out.msg = "No first-hop neighbors; cannot cover second-hop neighbors.";
        return;
    end

    t_start = tic;

    % -------------------- Stage 1: Mandatory relays --------------------
    MPR = [];

    for i = 1:numel(N2)
        w = N2(i);

        % 1-hop neighbors that can cover w (adjacent to w)
        coverers = intersect(neighbors(G, w), N1);

        % If only one coverer exists, it must be selected
        if numel(coverers) == 1
            MPR = [MPR, coverers(1)]; %#ok<AGROW>
        end
    end

    MPR = sort(unique(MPR(:)'));
    out.n_mprs_stage1 = numel(MPR);                 % NEW

    available_N1 = setdiff(N1, MPR, 'stable');

    % -------------------- Stage 2: Greedy completion --------------------
    uncovered_N2 = N2;

    % Remove what mandatory relays already cover
    for i = 1:numel(MPR)
        m = MPR(i);
        covered_now = intersect(neighbors(G, m), uncovered_N2);
        uncovered_N2 = setdiff(uncovered_N2, covered_now, 'stable');
    end

    % Count how many relays we add in the greedy stage
    stage2_count = 0;

    while ~isempty(uncovered_N2) && ~isempty(available_N1)

        [best_node, covered_nodes] = getNodeMaxCoverage(available_N1, uncovered_N2, G);

        if isempty(best_node) || isempty(covered_nodes)
            out.exit_flag = 2;
            out.msg = "No progress possible: uncovered second-hop nodes remain.";
            break;
        end

        stage2_count = stage2_count + 1;            % NEW
        MPR = [MPR, best_node]; %#ok<AGROW>
        available_N1 = setdiff(available_N1, best_node, 'stable');
        uncovered_N2 = setdiff(uncovered_N2, covered_nodes, 'stable');
    end

    out.n_mprs_stage2 = stage2_count;               % NEW
    out.runtime_s = toc(t_start);

    % -------------------- Final outputs --------------------
    out.selected_MPRs = sort(unique(MPR(:)'));
    out.uncovered_secondHop = sort(unique(uncovered_N2(:)'));

    out.n_mprs = numel(out.selected_MPRs);
    out.reduction_abs = out.n_firstHop - out.n_mprs;
    out.reduction_pct = (out.n_firstHop > 0) * (100 * out.reduction_abs / out.n_firstHop);

    out.coverage_ok = isempty(out.uncovered_secondHop);
    out.coverage_ratio = 1 - numel(out.uncovered_secondHop) / max(1, out.n_secondHop);

    if out.exit_flag == 0 && out.coverage_ok
        out.msg = "All second-hop neighbors are covered.";
    elseif out.exit_flag == 0 && ~out.coverage_ok
        out.exit_flag = 2;
        out.msg = "Stopped with uncovered second-hop neighbors remaining.";
    elseif strlength(out.msg) == 0
        out.msg = "Stopped with uncovered second-hop neighbors remaining.";
    end
end