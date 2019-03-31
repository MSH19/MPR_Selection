%=========================================================================
% Get the neighbors of a node that are included in a reference list
%=========================================================================
function [matched_neighbors, count_matched] = getIncludedNeighbors(node, graph, referenceList)

% 1- Get the neighbors of the input node
neighbors_n = neighbors(graph, node);      

% 2- Get the included neighbors and count them 
matched_neighbors = intersect(neighbors_n, referenceList);
count_matched = length(matched_neighbors);      

end % end function getIncludedNeighbors 