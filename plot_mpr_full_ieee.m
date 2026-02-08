function plot_mpr_full_ieee(G, out, info, mpr_selector, varargin)
%PLOT_MPR_FULL_IEEE  Full-graph MPR visualisation for IEEE papers (vector PDF)
%
%   plot_mpr_full_ieee(G, out, info, mpr_selector)
%   plot_mpr_full_ieee(..., 'Name', Value)
%
% Required inputs:
%   G            - MATLAB graph object (undirected)
%   out          - output struct from mpr_select()
%   info         - graph info struct (e.g., N, edge_density, degree_mean)
%   mpr_selector - selector node index (1..numnodes(G))
%
% Optional name-value pairs:
%   'Layout'            - 'force' (default), 'circle', 'layered', ...
%   'ExportPDF'         - true/false (default true)
%   'FileName'          - output PDF filename (default 'mpr_full_ieee.pdf')
%   'OutDir'            - output directory (default 'outputs')
%   'FigWidth'          - inches (default 3.45, IEEE single column)
%   'FigHeight'         - inches (default 2.6)
%   'ShowSelectorLabel' - true/false (default false)
%   'RingSize'          - scatter size for MPR ring (default auto)
%
% Notes:
% - Styling is chosen to remain readable in grayscale: marker shapes + ring.
% - Exports vector PDF suitable for IEEE papers.

%% -------------------- Input validation --------------------
assert(isa(G,'graph'), 'G must be a MATLAB graph object.');
assert(isscalar(mpr_selector) && mpr_selector >= 1 && mpr_selector <= numnodes(G), ...
    'mpr_selector must be a valid node index (1..numnodes(G)).');

%% -------------------- Parse name-value options --------------------
p = inputParser;
p.FunctionName = 'plot_mpr_full_ieee';

addParameter(p, 'Layout', 'force');
addParameter(p, 'ExportPDF', true);
addParameter(p, 'FileName', 'mpr_full_ieee.pdf');
addParameter(p, 'OutDir', 'outputs');
addParameter(p, 'FigWidth', 3.45);
addParameter(p, 'FigHeight', 2.6);
addParameter(p, 'ShowSelectorLabel', false);
addParameter(p, 'RingSize', 0); % 0 => auto

parse(p, varargin{:});
opt = p.Results;

%% -------------------- Defensive defaults (info) --------------------
% Make the function robust even if some fields are missing.
if ~isfield(info, 'N'),           info.N = numnodes(G); end
if ~isfield(info, 'edge_density')
    N = numnodes(G);
    info.edge_density = numedges(G) / (N*(N-1)/2);
end
if ~isfield(info, 'degree_mean'), info.degree_mean = mean(degree(G)); end

%% -------------------- Defensive defaults (out) --------------------
if ~isfield(out,'firstHop_ids'),   out.firstHop_ids   = []; end
if ~isfield(out,'secondHop_ids'),  out.secondHop_ids  = []; end
if ~isfield(out,'selected_MPRs'),  out.selected_MPRs  = []; end

if ~isfield(out,'n_firstHop'),     out.n_firstHop  = numel(unique(out.firstHop_ids(:))); end
if ~isfield(out,'n_secondHop'),    out.n_secondHop = numel(unique(out.secondHop_ids(:))); end
if ~isfield(out,'n_mprs'),         out.n_mprs      = numel(unique(out.selected_MPRs(:))); end

%% -------------------- Prepare node sets --------------------
N1 = unique(out.firstHop_ids(:));     % 1-hop neighbours
N2 = unique(out.secondHop_ids(:));    % 2-hop neighbours
R  = unique(out.selected_MPRs(:));    % selected relays (subset of N1)

%% -------------------- Figure + base plot --------------------
fig = figure('Units','inches', ...
             'Position',[1 1 opt.FigWidth opt.FigHeight], ...
             'Color','w');

h = plot(G, 'Layout', opt.Layout);
axis off;

% Base appearance: edges visible but secondary
h.NodeLabel  = {};
h.MarkerSize = 3;

h.LineWidth  = 0.30;                 % avoid hairlines
h.EdgeColor  = [0.70 0.70 0.70];     % neutral grey

% EdgeAlpha is not supported in all MATLAB versions
try
    h.EdgeAlpha = 0.15;              % faint background edges
end

%% -------------------- Baseline nodes (all grey circles) --------------------
highlight(h, 1:numnodes(G), ...
    'Marker','o', ...
    'NodeColor',[0.55 0.55 0.55], ...
    'MarkerSize',3);

%% -------------------- Emphasise edges touching selector or MPRs --------------------
% Identify edges by edge index.
E = G.Edges.EndNodes;                          % [numEdges x 2]
important_nodes = unique([mpr_selector; R(:)]);

is_imp = ismember(E(:,1), important_nodes) | ismember(E(:,2), important_nodes);
imp_eidx = find(is_imp);

% Emphasise important edges (leave others at baseline)
try
    highlight(h, imp_eidx, 'LineWidth', 0.85, 'EdgeColor',[0.45 0.45 0.45]);
end

%% -------------------- Node group styling (print-safe) --------------------
% Use marker shape differences + ring for MPRs.
cN2 = [0.00 0.00 0.00];   % 2-hop: black squares
cN1 = [0.00 0.45 0.00];   % 1-hop: dark green circles
cV  = [0.60 0.00 0.00];   % selector + ring: dark red

% Two-hop neighbours
if ~isempty(N2)
    highlight(h, N2, 'Marker','s', 'NodeColor',cN2, 'MarkerSize',3.5);
end

% One-hop neighbours
if ~isempty(N1)
    highlight(h, N1, 'Marker','o', 'NodeColor',cN1, 'MarkerSize',4.5);
end

% Selector node (shown prominently)
highlight(h, mpr_selector, 'Marker','p', 'NodeColor',cV, 'MarkerSize',6.0);

%% -------------------- MPR cue: red ring overlay around selected relays --------------------
if ~isempty(R)
    hold on;

    % Ring size: keep stable across figure sizes
    if opt.RingSize > 0
        ringSize = opt.RingSize;
    else
        ringSize = 18 * (opt.FigWidth * opt.FigHeight);
    end

    xR = h.XData(R);
    yR = h.YData(R);

    scatter(xR, yR, ringSize, 'o', ...
        'MarkerFaceColor','none', ...
        'MarkerEdgeColor',cV, ...
        'LineWidth',1.1);

    hold off;
end

%% -------------------- Optional selector label --------------------
if opt.ShowSelectorLabel
    labels = repmat({''}, numnodes(G), 1);
    labels{mpr_selector} = sprintf('v=%d', mpr_selector);
    h.NodeLabel = labels;

    try
        h.NodeFontSize = 7;
    end
end

%% -------------------- Title (two lines, readable) --------------------
if out.n_firstHop > 0
    red_pct = 100 * (out.n_firstHop - out.n_mprs) / out.n_firstHop;
else
    red_pct = 0;
end

t1 = sprintf('N=%d, |N1|=%d, |N2|=%d, |R|=%d (%.0f%% reduction)', ...
    info.N, out.n_firstHop, out.n_secondHop, out.n_mprs, red_pct);

t2 = sprintf('Edge density = %.2f (mean degree = %.1f)', ...
    info.edge_density, info.degree_mean);

title({t1; t2}, 'FontSize',8, 'FontWeight','normal');

%% -------------------- Export (vector PDF) --------------------
if opt.ExportPDF
    if ~exist(opt.OutDir,'dir')
        mkdir(opt.OutDir);
    end

    exportgraphics(fig, fullfile(opt.OutDir, opt.FileName), 'ContentType','vector');
end

end
