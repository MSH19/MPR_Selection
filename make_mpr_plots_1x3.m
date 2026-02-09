% Three side-by-side IEEE-style MPR demo plots.
% Exports a single vector PDF for a 2-column figure.
%
% Requires: createConnectedNetwork.m, mpr_select.m
% Outputs: outputs/mpr_demo_triptych.pdf  (vector)

clc; clear; close all;
rng(1);

outdir  = 'outputs';
outfile = fullfile(outdir, 'mpr_demo_triptych.pdf');
if ~exist(outdir,'dir'); mkdir(outdir); end

% ----- One N + three densities (keep N modest, per your preference) -----
N      = 30;
p_list = [0.00 0.20 0.60];                 % sparse, medium, dense
labels = {'Sparse','Medium','Dense'};

% ----- IEEE two-column-friendly size (≈7.16" wide) -----
figW = 7.16;    % inches
figH = 2.45;    % inches
fig = figure('Units','inches','Position',[1 1 figW figH],'Color','w');

t = tiledlayout(1,3,'TileSpacing','compact','Padding','compact');

for i = 1:numel(p_list)
    p_extra = p_list(i);
    decision_threshold = 1 - p_extra;

    [G, info] = createConnectedNetwork(N, decision_threshold);
    assert(isfield(info,'is_connected') && info.is_connected, 'Disconnected graph (unexpected).');

    v   = randi(N);
    out = mpr_select(G, v);

    ax = nexttile(t);

    % Slightly lighter edges only for the dense panel (better print readability)
    if p_extra >= 0.6
        edgeAlpha = 0.08;
    else
        edgeAlpha = 0.15;
    end

    plot_mpr_full_ieee_ax(ax, G, out, info, v, 'force', edgeAlpha);

    % ---- Short titles (move density details to caption) ----
    title(ax, sprintf('%s ($p_{\\mathrm{extra}}=%.2f$)', labels{i}, p_extra), ...
        'Interpreter','latex','FontSize',8,'FontWeight','normal');
end

exportgraphics(fig, outfile, 'ContentType','vector');
fprintf('Saved: %s\n', outfile);

% =====================================================================
function plot_mpr_full_ieee_ax(ax, G, out, info, mpr_selector, layoutName, edgeAlpha)
% Same styling logic as plot_mpr_full_ieee(), but renders into a provided axis.

    axes(ax); %#ok<LAXES>
    cla(ax);
    hold(ax,'on');

    % Defensive defaults (info)
    if ~isfield(info, 'N'), info.N = numnodes(G); end
    if ~isfield(info, 'edge_density')
        Nn = numnodes(G);
        info.edge_density = numedges(G) / (Nn*(Nn-1)/2);
    end
    if ~isfield(info, 'degree_mean'), info.degree_mean = mean(degree(G)); end

    % Defensive defaults (out) -- match your function field names
    if ~isfield(out,'firstHop_ids'),   out.firstHop_ids   = []; end
    if ~isfield(out,'secondHop_ids'),  out.secondHop_ids  = []; end
    if ~isfield(out,'selected_MPRs'),  out.selected_MPRs  = []; end

    % Node sets
    N1 = unique(out.firstHop_ids(:));
    N2 = unique(out.secondHop_ids(:));
    R  = unique(out.selected_MPRs(:));

    % Base plot
    h = plot(ax, G, 'Layout', layoutName);
    axis(ax,'off');

    h.NodeLabel  = {};
    h.MarkerSize = 3;

    h.LineWidth  = 0.30;
    h.EdgeColor  = [0.70 0.70 0.70];
    try
        h.EdgeAlpha = edgeAlpha; % use panel-specific alpha
    end

    % Baseline nodes (all grey circles)
    highlight(h, 1:numnodes(G), ...
        'Marker','o', ...
        'NodeColor',[0.55 0.55 0.55], ...
        'MarkerSize',3);

    % Emphasise edges touching selector or MPRs
    E = G.Edges.EndNodes;
    important_nodes = unique([mpr_selector; R(:)]);
    is_imp = ismember(E(:,1), important_nodes) | ismember(E(:,2), important_nodes);
    imp_eidx = find(is_imp);

    try
        highlight(h, imp_eidx, 'LineWidth', 0.85, 'EdgeColor',[0.45 0.45 0.45]);
    end

    % Group styling (same as your plot_mpr_full_ieee)
    cN2 = [0.00 0.00 0.00];   % 2-hop: black squares
    cN1 = [0.00 0.45 0.00];   % 1-hop: dark green circles
    cV  = [0.60 0.00 0.00];   % selector + ring: dark red

    if ~isempty(N2)
        highlight(h, N2, 'Marker','s', 'NodeColor',cN2, 'MarkerSize',3.5);
    end
    if ~isempty(N1)
        highlight(h, N1, 'Marker','o', 'NodeColor',cN1, 'MarkerSize',4.5);
    end
    highlight(h, mpr_selector, 'Marker','p', 'NodeColor',cV, 'MarkerSize',6.0);

    % Red ring overlay around selected relays
    if ~isempty(R)
        ringSize = 18 * (7.16 * 2.45);   % stable ring size for this figure scale
        xR = h.XData(R);
        yR = h.YData(R);

        scatter(ax, xR, yR, ringSize, 'o', ...
            'MarkerFaceColor','none', ...
            'MarkerEdgeColor',cV, ...
            'LineWidth',1.1);
    end

    hold(ax,'off');
end