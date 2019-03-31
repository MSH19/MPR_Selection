% ========================================================================
% Mobile Ad-hoc Networks
% Optimized Link State Routing (OLSR) protocol 
% Iterative algorithm for selecting Multipoint Relays (MPRs)
% ========================================================================
% Clearing
clc;
clear all;
close all;

total_nodes = 10;           % total number of nodes 
node_ids = 1:total_nodes;   % array to store node IDs (1 x total)

%% Create a randomly-connected network
attempts_threshold = 100;   % threshold to stop creation attempts
created_flag = 0;           % indicate creation of a connected network
exit_flag = 0;              % indicate failure in creating the network
attempts = 0;               % count number of attempts 
while (created_flag == 0)
    % call function createConnectedNetwork
    [G, created_flag] = createConnectedNetwork (total_nodes);
    % increment count of attempts
    attempts = attempts + 1; 
    % Check if threshold reached and network is not created
    if ((attempts >= 100) && (created_flag == 0))
        % set exit flag 
        exit_flag = 1; 
        % break from while loop
        break; 
    end % end if 
end % end while

% Check if exit flag is set
if (exit_flag == 1) 
    % If exit flag set, display a message and exit the program  
    disp ('Cannot create a connected network graph');
    disp ('Try changing the decision_threshold in the createConnectedNetwork method');
    disp ('Program stopped');
else
    %% Sample mpr selector, extract first-hop and second-hop neighbors
    % If a connected network was created, continue
    disp (strcat('A connected network was created with number of attempts = ', int2str(attempts)));

    % Select the MPR selector node (randomly)
    mpr_selector = datasample(node_ids, 1);
    disp (strcat('MPR selector node: ', int2str(mpr_selector)));

    % Get the first-hop and second-hop neighbors of the MPR selector node
    [firstHop_ids, secondHop_ids] = get_First_Second_Neighbors(mpr_selector, G);
    disp ('First-hop neighbors:');
    disp (firstHop_ids');
    disp ('Second-hop neighbors:');
    disp (secondHop_ids);
    
    % Check if the mpr selector has second-hop neighbors
    if (isempty(secondHop_ids))
        disp ('No second-hop neighbors exist');
        disp('try re-creating the network');
        disp('Program stopped');
    else
        %% Start MPRs selection algorithm 
        % Define empty array to store the selected MPRs 
        selected_MPRs = [];
     
        % 1- Detect second-hop neighbors that are connected to a single 
        % first-hop neighbor only 
        for i=1:length(secondHop_ids)  
            % call function getIncludedNeighbors
            [included, count_included] = getIncludedNeighbors(secondHop_ids(i), G, firstHop_ids);
            if ((count_included == 1) && (~ismember(included(1), selected_MPRs)))
                % append the first-hop neighbor to the selected MPRs
                selected_MPRs = [selected_MPRs, included];
            end % end if      
        end % end for
       
        % Set available first-hop ids 
        available_firstHop = firstHop_ids;
        if (~isempty(selected_MPRs))
            disp ('selected MPRs in step 1:');
            disp (selected_MPRs);
            % Remove selected MPRs from available first-hop neighbors
            selected_ids= ismember(available_firstHop, selected_MPRs);
            available_firstHop(selected_ids)=[];
        else
            disp ('No MPRs selected in step 1');
        end % end if
        
        % if all first-hop neighbors were selected, no need to continue
        if (isempty(available_firstHop))
            disp('All first-hop neighbors were selected in step 1');
            disp('Program stopped');
        else 
            disp ('First-hop neighbors available for selection:');
            disp (available_firstHop');
            
            %% 2- Add additional MPRs based on coverage criteria
            
            % update uncovered second-hop ids
            uncovered_secondHop = secondHop_ids;
            
            if (~isempty(selected_MPRs))
                for i=1:length(selected_MPRs)
                    m = selected_MPRs(i);
                    % get what does the mpr covers from the uncovered set
                    [temp, count_temp] = getIncludedNeighbors(m, G, uncovered_secondHop);
                    % update the uncovered second-hop set
                    ids= ismember(uncovered_secondHop, temp);
                    uncovered_secondHop(ids)=[];
                end % end for
            end % end if 
        
            if (isempty(uncovered_secondHop))
                disp('All second-hop neighbors are covered');
                disp('Program stopped');
            else
                disp('uncovered second-hop neighbors');
                disp(uncovered_secondHop);
                
                % While still some second-hop neighbors are uncovered
                while (~isempty(uncovered_secondHop))
                    
                    disp('selecting the first-hop neighbor with max coverage');
                    
                    % 1- Select the first-hop neighbor with max coverage
                    [selected_node, covered_nodes] = getNodeMaxCoverage(available_firstHop, uncovered_secondHop, G);
                    
                    % 2- Append the selected node to selected MPRs
                    selected_MPRs = [selected_MPRs, selected_node];
                    
                    disp ('selected MPRs changed to:');
                    disp (selected_MPRs);
                    
                    % 3- Update the remaining first-hop neighbors
                    idx= ismember(available_firstHop, selected_MPRs);
                    available_firstHop(idx)=[];
                    
                    % 4- Update the uncovered set of second hop neighbors
                    ids= ismember(uncovered_secondHop, covered_nodes);
                    uncovered_secondHop(ids)=[];
                    disp ('Uncovered second-hop neighbors changed to:');
                    disp (uncovered_secondHop);
                
                end % end while
            end % end if 
       
        end %end if
        
        % Display the result (selected MPRs) 
        disp('Overall Selected MPRs:');
        disp(selected_MPRs);
        
        % Calculate and display the saving due to the algorithm 
        saving = length(firstHop_ids) - length(selected_MPRs);
        disp('First-hop nodes used for broadcasting decreased by:');
        disp(saving);
        disp ('end');
    
        % Draw the graph highliting MPR selector, first,second-hop neighbors, and selected MPRs 
        title_s = 'MPR Selector (Red), First-hop (Green), Second-hop (Black), selected MPRs (Yellow)';
    
        %% Plot graph
        % set figure to full screen 
        figure('units','normalized','outerposition',[0 0 1 1])
        % plot graph
        h = plot(G);
        % Highlight MPR selector node with red color   
        highlight(h, mpr_selector, 'NodeColor', 'r');
        % Highlight first-hop neighbors with green color
        highlight(h, firstHop_ids,'NodeColor', 'g');
        % Highlight second-hop neighbors with black color
        highlight(h, secondHop_ids,'NodeColor', 'k');
        % Highlight selected MPRs with yellow color
        highlight(h, selected_MPRs,'NodeColor', 'y');
        % set the title 
        title(title_s);
    end % end if 
end % end if