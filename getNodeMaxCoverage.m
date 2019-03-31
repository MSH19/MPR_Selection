%=========================================================================
% Get the node that has maximum coverage of a reference list
% Input: array of candidates, refernce list
% Output: node with max coverage, covered nodes
%=========================================================================
function [node_maxCoverage, covered_set] = getNodeMaxCoverage(candidates, reference, graph)

maxCovereage = 0;
covered_set = [];

% loop into canditaties and get the node with max coverage 
for i=1:length(candidates)
    [covered, count_covered] = getIncludedNeighbors(candidates(i), graph, reference);
    if (count_covered > maxCovereage)
        maxCovereage = count_covered;
        node_maxCoverage = candidates(i);
        covered_set = covered;
    end 
end %end for 

end %end function getNodeMaxCoverage