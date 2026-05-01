function [best_node, covered_set] = getNodeMaxCoverage(candidates, reference, G)
% This function picks the candidate node that covers the most uncovered nodes.
%
%
% candidates: possible relay nodes (e.g., remaining N1 nodes)
% reference : nodes we still need to cover (uncovered N2 nodes)
%
% Output:
%   best_node   - N1 candidate with maximum coverage (empty if no progress)
%   covered_set - which reference nodes (N2 nodes) it covers

    % initialization
    best_node = [];
    covered_set = [];

    % validation 
    if isempty(candidates) || isempty(reference)
        return;
    end

    candidates = unique(candidates(:)');   % row
    reference  = unique(reference(:)');    % row

    maxCoverage = 0;

    % find the candidate that covers the largest number of N2 neighbors 
    for i = 1:numel(candidates)
        % Nodes in "reference" that this candidate can reach in one hop
        covered = intersect(neighbors(G, candidates(i)), reference);
        n_cov = numel(covered);

        % Strict '>' gives deterministic tie-break (first max wins)
        if n_cov > maxCoverage
            maxCoverage = n_cov;
            best_node = candidates(i);
            covered_set = covered(:)';     % row
        end
    end

    % If nobody covers anything, return empty to signal "stuck"
    if maxCoverage == 0
        best_node = [];
        covered_set = [];
    end
end
