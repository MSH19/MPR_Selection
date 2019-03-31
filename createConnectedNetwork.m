%==========================================================================
% Create an adjacency matrix and a connected network graph
% Input: Total number of nodes
% Output: Graph and status flag 
%==========================================================================
function [G, connected] = createConnectedNetwork(N)

% threshold for decision on connectivity (0 < decision_threshold < 1)
decision_threshold = 0.5;

% Connect nodes randomly
% 1- Define empty matrix (NxN)
A = zeros(N,N);

% 2- Fill adjacency matrix based on a random condition 
for i= 1:N                  % Loop in rows
    for j= 1:N              % Loop in columns
        if (j>i)            % if not diagonal and upper
            x= rand;        % Generate random number between 0 and 1
            if (x>=decision_threshold)
                A(i,j)= 1;  % Assign a relation
            end             % end if 
        end                 % end if upper
    end                     % end for columns
end                         % end for rows

% 3- Create graph using the upper part of the adjacency matrix 
G= graph(A,'upper');  
% 4- Check if all nodes are connected to each other
k = dfsearch(G,1);  % starting from node 1, get the IDs of connected nodes
if (length(k) == N) % check if the number of connected nodes equals N
    connected = 1;  % if true, all nodes are connected
else
    connected = 0;  % else, not all nodes are connected
end % end if

end % function createConnectedNetwork