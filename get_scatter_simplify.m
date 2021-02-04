function idx = get_scatter_simplify(grid, axis, marker, n_split, pts)

% get the mask with the circle pixel indices
mask = get_mask(marker);

% init pixel matrix
mat = NaN(grid.n_x, grid.n_y);

% split
[n_chunk, idx_chunk] = get_chunk(n_split, size(pts, 2));

% solve
for i=1:n_chunk
    mat = get_filter(mat, grid, axis, mask, pts, idx_chunk{i});
end

% extract
idx = unique(mat).';
idx(isnan(idx)) = [];

end

function mask = get_mask(marker)

% get indices matrix
[x_idx, y_idx] = ndgrid(-marker:+marker, -marker:+marker);

% get the radius of the cells
r_cell = hypot(x_idx, y_idx);

% find the cell inside the ciricle
idx = r_cell<=marker;

% get the indices
mask = [x_idx(idx).' ; y_idx(idx).'];

end

function [n_chunk, idx_chunk] = get_chunk(n_split, n_sol)
% Split data into chunks with a fixed size.
%
%    Parameters:
%        n_split (int): number of data per chunk
%        n_sol (int): number of data to be splitted in chunks
%
%    Returns:
%        n_chunk (int): number of created chunks
%        idx_chunk (cell): cell with the indices of the chunks

% init the data
idx = 1;
idx_chunk = {};

% create the chunks indices
while idx<=n_sol
    idx_new = min(idx+n_split,n_sol+1);
    vec = idx:(idx_new-1);
    idx_chunk{end+1} = vec;
    idx = idx_new;
end

% count the chunks
n_chunk = length(idx_chunk);

end

function mat = get_filter(mat, grid, axis, mask, pts, idx_select)

% extract pts
x_pts = pts(1, idx_select);
y_pts = pts(2, idx_select);

% extract mask
x_idx_mask = mask(1, :);
y_idx_mask = mask(2, :);
n_mask = size(mask, 2);

% design idx 
n_idx = repmat(idx_select, [n_mask, 1]);
n_idx = n_idx(:).';

% parse
x_norm = (x_pts-axis.x_min)./(axis.x_max-axis.x_min);
y_norm = (y_pts-axis.y_min)./(axis.y_max-axis.y_min);
x_n_idx = round(1+(grid.n_x-1).*x_norm);
y_n_idx = round(1+(grid.n_y-1).*y_norm);

% grid
[x_idx_mask, x_n_idx] = ndgrid(x_idx_mask, x_n_idx);
[y_idx_mask, y_n_idx] = ndgrid(y_idx_mask, y_n_idx);
x_idx = x_idx_mask+x_n_idx;
y_idx = y_idx_mask+y_n_idx;
x_idx = x_idx(:).';
y_idx = y_idx(:).';

% clamp
idx_off = (x_idx<1)|(y_idx<1)|(x_idx>grid.n_x)|(y_idx>grid.n_y);
x_idx(idx_off) = [];
y_idx(idx_off) = [];
n_idx(idx_off) = [];

% get pixel indices
idx_assign = sub2ind([grid.n_x grid.n_y], x_idx, y_idx);

% assign design numbers
mat(idx_assign) = n_idx;

end