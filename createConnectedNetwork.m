function [G, info] = createConnectedNetwork(N, decision_threshold)
% CREATECONNECTEDNETWORK Create a connected random undirected graph.
%
% This uses a simple model:
%   1) Build a random spanning tree (so the graph is connected).
%   2) Add extra edges at random to control how dense the graph is.
%
% Inputs:
%   N                  - number of nodes (integer >= 2)
%   decision_threshold - in [0,1]; higher => fewer extra edges (sparser)
%
% Outputs:
%   G    - MATLAB graph object (undirected)
%   info - basic graph statistics used by the demo and evaluation

    % Default sparsity setting if not provided
    if nargin < 2 || isempty(decision_threshold)
        decision_threshold = 0.5;
    end

    % Basic input checks (keeps the function safe to call)
    validateattributes(N, {'numeric'}, {'scalar','integer','>=',2});
    validateattributes(decision_threshold, {'numeric'}, {'scalar','>=',0,'<=',1});

    % Probability of adding an extra edge between two nodes
    p_extra = 1 - decision_threshold;

    %% 1) Build a random spanning tree (guarantees connectivity)
    A = zeros(N);          % adjacency matrix (we fill upper triangle only)
    perm = randperm(N);    % random node order to randomize the tree shape

    for i = 2:N
        u = perm(i);
        v = perm(randi(i-1));           % connect to any earlier node
        A(min(u,v), max(u,v)) = 1;      % store as upper-tri entry
    end

    %% 2) Add extra random edges (controls graph density)
    for i = 1:N
        for j = i+1:N
            if A(i,j) == 0 && rand < p_extra
                A(i,j) = 1;
            end
        end
    end

    % Convert adjacency matrix into an undirected MATLAB graph
    G = graph(A, 'upper');

    %% Collect simple stats (useful for printing and plots)
    num_possible_edges = N*(N-1)/2;
    num_edges = numedges(G);
    deg = degree(G);

    info.N = N;
    info.decision_threshold = decision_threshold;
    info.p_extra = p_extra;

    info.num_possible_edges = num_possible_edges;
    info.num_edges = num_edges;
    info.edge_density = num_edges / num_possible_edges;

    info.degree_mean = mean(deg);
    info.degree_min  = min(deg);
    info.degree_max  = max(deg);

    % Should be connected by construction, but we report it anyway
    info.is_connected = (max(conncomp(G)) == 1);
    info.mean_degree_check_2E_over_N = (2*num_edges)/N;
end
