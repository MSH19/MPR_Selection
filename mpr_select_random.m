function out = mpr_select_random(G, mpr_selector)
% MPR_SELECT_RANDOM Random relay selection baseline.
%
% Purpose:
%   Provides a simple, fair baseline to compare against the greedy MPR method.
%   It randomly selects useful 1-hop neighbours until all reachable 2-hop
%   neighbours are covered (if possible).
%
% Key properties:
%   - Only selects nodes that actually improve coverage
%   - Stops when full coverage is reached OR no progress is possible
%   - No optimisation (pure random choice among useful candidates)
%
% Inputs:
%   G              : Graph object (undirected)
%   mpr_selector   : Index of selector node
%
% Output (struct):
%   selector        : selector node ID
%   firstHop_ids    : 1-hop neighbours (N1)
%   secondHop_ids   : 2-hop neighbours (N2)
%   selected_MPRs   : chosen relay set R
%   n_firstHop      : |N1|
%   n_secondHop     : |N2|
%   n_mprs          : |R|
%   coverage_ok     : true if all N2 covered
%   coverage_ratio  : fraction of N2 covered
%   runtime_s       : execution time (seconds)

    % ---------------- Initialize output ----------------
    out = struct();

    % Extract 1-hop and 2-hop neighbours
    [N1, N2] = get_First_Second_Neighbors(mpr_selector, G);

    % Ensure clean row vectors (sorted, unique)
    N1 = sort(unique(N1(:)'));
    N2 = sort(unique(N2(:)'));

    % Store basic info
    out.selector        = mpr_selector;
    out.firstHop_ids    = N1;
    out.secondHop_ids   = N2;
    out.selected_MPRs   = [];
    out.n_firstHop      = numel(N1);
    out.n_secondHop     = numel(N2);
    out.n_mprs          = 0;
    out.coverage_ok     = false;
    out.coverage_ratio  = 0;
    out.runtime_s       = 0;

    % ---------------- Edge cases ----------------
    % No 2-hop neighbours → trivially covered
    if isempty(N2)
        out.coverage_ok    = true;
        out.coverage_ratio = 1;
        return;
    end

    % No 1-hop neighbours → impossible to cover N2
    if isempty(N1)
        out.coverage_ok    = false;
        out.coverage_ratio = 0;
        return;
    end

    % ---------------- Start timing ----------------
    t_start = tic;

    % Set of uncovered 2-hop nodes
    uncovered_N2 = N2;

    % Available candidate relays (1-hop neighbours)
    available_N1 = N1;

    % Selected relay set
    R = [];

    % ---------------- Random selection loop ----------------
    while ~isempty(uncovered_N2) && ~isempty(available_N1)

        % Step 1: Find "useful" candidates
        % (nodes that cover at least one currently uncovered N2 node)
        useful_candidates = [];

        for i = 1:numel(available_N1)
            u = available_N1(i);

            % Nodes in N2 covered by candidate u
            covered_now = intersect(neighbors(G, u), uncovered_N2);

            if ~isempty(covered_now)
                useful_candidates = [useful_candidates, u]; %#ok<AGROW>
            end
        end

        % If no candidate improves coverage → stop
        if isempty(useful_candidates)
            break;
        end

        % Step 2: Randomly select one useful candidate
        idx = randi(numel(useful_candidates));
        chosen = useful_candidates(idx);

        % Add to relay set
        R = [R, chosen]; %#ok<AGROW>

        % Step 3: Update uncovered nodes
        covered_now = intersect(neighbors(G, chosen), uncovered_N2);
        uncovered_N2 = setdiff(uncovered_N2, covered_now, 'stable');

        % Step 4: Remove chosen node from future consideration
        available_N1 = setdiff(available_N1, chosen, 'stable');
    end

    % ---------------- Final outputs ----------------
    out.runtime_s       = toc(t_start);

    % Ensure unique, sorted relay set
    out.selected_MPRs   = sort(unique(R));
    out.n_mprs          = numel(out.selected_MPRs);

    % Coverage results
    out.coverage_ok     = isempty(uncovered_N2);

    % Fraction of N2 covered
    out.coverage_ratio  = 1 - numel(uncovered_N2) / max(1, numel(N2));
end