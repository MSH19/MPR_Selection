function [N1, N2] = get_First_Second_Neighbors(node, G)
% GET_FIRST_SECOND_NEIGHBORS First- and second-hop neighbors of a node.
%
% N1: direct (1-hop) neighbors of "node"
% N2: nodes reachable in 2 hops via any node in N1, excluding:
%     - the node itself
%     - all nodes in N1
%
% Outputs are row vectors, unique and sorted.

    % 1-hop neighbors
    N1 = sort(neighbors(G, node))';   % row, sorted

    % If node is isolated, it has no 2-hop neighbors
    if isempty(N1)
        N2 = [];
        return;
    end

    % Collect neighbors of all 1-hop neighbors
    n2_all = [];
    for k = 1:numel(N1)
        n2_all = [n2_all; neighbors(G, N1(k))];
    end

    % Keep only true 2-hop nodes (remove self and 1-hop nodes)
    n2_all = unique(n2_all(:));
    n2_all(n2_all == node) = [];
    N2 = setdiff(n2_all, N1(:), 'stable');
    N2 = sort(N2(:))';                % row, sorted
end