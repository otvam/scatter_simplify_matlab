function run_test()

close('all');

%% param
grid.n_x = 800;
grid.n_y = 700;

axis.x_min = 20;
axis.x_max = 100;
axis.y_min = 10;
axis.y_max = 50;

marker = 5;
n_split = 100e3;

%% data
n = 1e6;
x = 20+(100-20).*rand(1, n);
y = 10+(50-10).*rand(1, n);
c = rand(1, n);

%% run
idx_all = 1:n;
idx_dec = get_scatter_simplify(grid, axis, marker, n_split, [x ; y]);

%% disp
fprintf('n_all = %d\n', nnz(idx_all))
fprintf('n_dec = %d\n', nnz(idx_dec))
fprintf('fraction = %.3f %%\n', 1e2.*nnz(idx_dec)./nnz(idx_all))

%% plot
get_plot('original', x, y, c, idx_all)
get_plot('decimated', x, y, c, idx_dec)

end

function get_plot(name, x, y, c, idx)

%% plot
figure()
scatter(x(idx).', y(idx).', 100, c(idx).', 'filled');
colormap();
xlim([20 100])
ylim([10 50])
caxis([0 1])
grid('on')
title(sprintf('%s / n = %d', name, nnz(idx)))

end
