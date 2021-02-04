function run_example()
% Simplify scatter points by removing overlapping points.
%
%   Create a dataset with 1'000'000 points (randomly points).
%   Simplify the dataset removing overlapping points.
%   Plot both the original and simplified datasets.
%
%   Thomas Guillod.
%   2021 - BSD License.

close('all');

%% parameters
grid.n_x = 800; % number of pixels in x direction
grid.n_y = 700; % number of pixels in y direction

axis.x_min = 20; % minimum x axis value
axis.x_max = 100; % maximum x axis value
axis.y_min = 10; % minimum y axis value
axis.y_max = 50; % maximum y axis value

marker = 5; % radius of the scatter points in pixels
n_split = 100e3; % number of points being computed in a vectorized way

%% dataset
n_pts = 1e6; % number of points
x_pts = 20+(100-20).*rand(1, n_pts); % random points (x coordinate)
y_pts = 10+(50-10).*rand(1, n_pts); % random points (y coordinate)
c_pts = rand(1, n_pts); % random color

%% compute the indices of the point to be kept
idx_dec = get_scatter_simplify(grid, axis, marker, n_split, [x_pts ; y_pts]);

%% disp
fprintf('n_all = %d\n', n_pts)
fprintf('n_simplify = %d\n', nnz(idx_dec))
fprintf('fraction = %.3f %%\n', 1e2.*nnz(idx_dec)./n_pts)

%% plot
get_plot('Complete Dataset', x_pts, y_pts, c_pts, 1:n_pts)
get_plot('Simplified Dataset', x_pts, y_pts, c_pts, idx_dec)

end

function get_plot(name, x, y, c, idx)
% Plot the dataset (scatter plot).
%
%    Parameters:
%        name (str): title of the plot
%        x (vector): points (x coordinate)
%        y (vector): points (y coordinate)
%        c (vector): color value
%        idx (vector): indices of the points to be displayed

figure()
scatter(x(idx).', y(idx).', 75, c(idx).', 'filled');
colormap();
xlim([20 100])
ylim([10 50])
caxis([0 1])
grid('on')
title(sprintf('%s / n = %d', name, nnz(idx)))

end