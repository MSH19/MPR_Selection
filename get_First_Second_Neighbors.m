%=========================================================================
% Get the first-hop and second-hop neighbors of a node
% Input: index of a node, graph
% Output: array of first-hop neighbors, array of second-hop neighbors
%=========================================================================
function [firstHop_neighbors, secondHop_neighbors] = get_First_Second_Neighbors(node, graph)

% 1- Get the set of first-hop neighbors of the node
firstHop_neighbors = neighbors(graph, node);

% 2- Get the second-hop neighbors of the node 
secondHop_neighbors = [];

for i=1:length(firstHop_neighbors) 
    
    % get neighbors of each first hop neighbor
    temp_secondHop_neighbors = neighbors(graph, firstHop_neighbors(i));    
    
    % check if each neighbor can be added to the second-hop neighbors
    for j=1:length(temp_secondHop_neighbors)
        x = temp_secondHop_neighbors(j); 
        if ((~ismember(x, firstHop_neighbors)) && (x~=node) && (~ismember(x,secondHop_neighbors)))
            % append to the list of second-hop neighbors
            secondHop_neighbors = [secondHop_neighbors, x]; 
        end % end if    
    end % end for
end % end for

end %end function get_First_Second_Neighbors