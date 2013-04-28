function create_test_path(filename)

x = [0:0.1:1 1:-0.1:0];
y = x;
z = ones(size(x));
alpha = linspace(0, 45, length(x));
beta = alpha;
gamma = zeros(size(x));

csvwrite(filename,[x' y' z' alpha' beta' gamma']);
end