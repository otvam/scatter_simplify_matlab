function idx = get_scatter_simplify(simplify, n_split, axis, pts)
% Simplify scatter points by removing overlapping points.
%
%    Scatter plots with millions of points are slow and resource intensive.
%    However, most of the points are not visible since they are hidden by other points.
%    This code detects which points are hidden and remove them.
%
%    The used algorithm is particularly efficient and can handle millions of points:
%        - a pixel matrix is generated
%        - the points are circle occupying a given number of pixels
%        - the indices of the points are placed (in order) in the pixel matrix
%        - the points that do not appear in the pixel matrix will be invisible in the plot
%        - the invisible points are removed
%
%    In other words, this algorithm work as a virtual graphic buffer.
%    The plot is precompute and invisible elements are deleted.
%
%    This algorithm (o(1) complexity) features several advantages:
%        - no need to compute the distance between all the points
%        - the memory requirement is linearly proportional to the number of pixels
%        - the memory requirement is linearly proportional to the number of scatter points
%        - computational cost is linearly proportional to the number of scatter points 
%
%    This code has been successfully tested with large datasets:
%        - this algorithm is vectorized and many points are treated together.
%        - the number of points (chunk size) processed in a step can be selected.
%        - 100'000'000 points can be simplified in several minutes
%
%    Parameters:
%        simplify (struct): size of the pixel grid 
%            simplify.n_x (int): number of pixels in x direction
%            simplify.n_y (int): number of pixels in y direction
%            simplify.marker (float): radius of the scatter points in pixels
%        n_split (int): number of points being computed in a vectorized way
%        axis (struct): axis limit of the scatter plot iin x and y directionn 
%            axis.x_min (float): minimum x axis value
%            axis.x_max (float): maximum x axis value
%            axis.y_min (float): minimum y axis value
%            axis.y_max (float): maximum y axis value
%        pts (vector): vector with the indices of the scatter points to be handled
%            pts (first row): x coordinate of the points
%            pts (second row): y coordinate of the points
%            pts (column): % points at the are on the top (hidding other points)
%
%    Returns:
%        idx (vector): indices of the scatter points to be kept
%
%   Thomas Guillod.
%   2021 - BSD License.

% get the mask with the circle pixel indices
[mat, mask] = get_mask(simplify);

% split the scatter points into chunks
[n_chunk, idx_chunk] = get_chunk(n_split, size(pts, 2));

% for each chunk, assign the scatter point indices in the pixel matrix
for i=1:n_chunk
    mat = get_filter(mat, mask, axis, pts, idx_chunk{i});
end

% extract the scatter point indices that appear in the pixel matrix
idx = unique(mat).';

% remove the invalid indices (empty pixels)
idx(isnan(idx)) = [];

end

function [mat, mask] = get_mask(simplify)
% Get the indices of circular mask representing the pixels occupied by a point.
%
%    Create a binary mask containing the pixels occupied by a scatter point:
%        - the index (0,0) represents the center of the circle
%        - the index (i,j) represents a pixel with a shift (in cartesian coordinates)
%
%    Parameters:
%        simplify (struct): size of the pixel grid 
%
%    Returns:
%        mat (matrix): matrix with the pixels (empty)
%        mask (matrix): matrix with the x/y indices of the mask

% extract
marker = simplify.marker;
n_x = simplify.n_x;
n_y = simplify.n_y;

% get indices matrix
vec = -ceil(marker):1:+ceil(marker);
[x_idx, y_idx] = ndgrid(vec, vec);

% get the radius of the cells
r_cell = hypot(x_idx, y_idx);

% find the cell inside the ciricle
idx = r_cell<=marker;

% get the indices
mask = [x_idx(idx).' ; y_idx(idx).'];

% init pixel matrix
mat = NaN(n_x, n_y);

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

function mat = get_filter(mat, mask, axis, pts, idx_select)
% Split data into chunks with a fixed size.
%
%    Put the index of the scatter points into the pixel matrix:
%        - find all the pixels masked by the scatter points
%        - put the scatter point indices in the pixel matrix
%        - the scatter points at the end of the provided matrix are on the top (hidding other points)
%        - the scatter points at the beginning of the provided matrix are on the bottom (hidden by other points)
%        - the code is fully vectorized, no loop across the scatter points
%
%    Parameters:
%        mat (matrix): matrix with the pixels and the scatter point indices
%        mask (matrix): matrix with the x/y indices of the mask 
%        axis (struct): axis limit of the scatter plot iin x and y directionn 
%        pts (matrix): matrix with the x/y coordinates of  the scatter points
%        pts (vector): vector with the indices of the scatter points to be handled
%
%    Returns:
%        mat (matrix): updated matrix with the pixels and the scatter point indices

% extract axis
x_min = axis.x_min;
x_max = axis.x_max;
y_min = axis.y_min;
y_max = axis.y_max;

% extract pts
x_pts = pts(1, idx_select);
y_pts = pts(2, idx_select);

% extract mask
x_idx_mask = mask(1, :);
y_idx_mask = mask(2, :);
n_mask = size(mask, 2);

% extract size
n_x = size(mat, 1);
n_y = size(mat, 2);

% get a vector with the indices of the scatter points
n_idx = repmat(idx_select, [n_mask, 1]);
n_idx = n_idx(:).';

% get the pixel indices of the scatter point
x_norm = (x_pts-x_min)./(x_max-x_min);
y_norm = (y_pts-y_min)./(y_max-y_min);
x_idx = round(1+(n_x-1).*x_norm);
y_idx = round(1+(n_y-1).*y_norm);

% get the indices of all the pixels to be masked
[x_idx_mask, x_idx] = ndgrid(x_idx_mask, x_idx);
[y_idx_mask, y_idx] = ndgrid(y_idx_mask, y_idx);
x_idx = x_idx_mask+x_idx;
y_idx = y_idx_mask+y_idx;
x_idx = x_idx(:).';
y_idx = y_idx(:).';

% remove the pixels located outside the 
idx_off = (x_idx<1)|(y_idx<1)|(x_idx>n_x)|(y_idx>n_y);
x_idx(idx_off) = [];
y_idx(idx_off) = [];
n_idx(idx_off) = [];

% get the linear indices of the pixels
idx_assign = sub2ind([n_x n_y], x_idx, y_idx);

% assign scatter point indices to the pixel matrix
mat(idx_assign) = n_idx;

end