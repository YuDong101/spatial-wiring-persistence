function networks = generate_networks(points, cfg)
%GENERATE_NETWORKS Distance-weighted directed sampling without replacement.
% A(j,i)=true denotes source j -> target i. Coordinates and edge budget
% are shared across all alpha values. This function does not simulate.
if ~isnumeric(points) || ~isreal(points) || ~ismatrix(points) || ...
        size(points, 2) ~= 3 || any(~isfinite(points(:)))
    error('wmrep:InvalidCoordinates', 'Expected finite real N-by-3 coordinates.');
end
n = cfg.numNodes; m = cfg.numEdges;
if ~isscalar(n) || ~isfinite(n) || n < 2 || n ~= fix(n) || ...
        ~isscalar(m) || ~isfinite(m) || m < 0 || m ~= fix(m) || m > n*(n-1) || ...
        isempty(cfg.alpha) || any(~isfinite(cfg.alpha) | cfg.alpha < 0) || ...
        numel(cfg.networkSeeds) ~= numel(cfg.alpha)
    error('wmrep:InvalidConfig', 'Invalid node count, edge budget, alpha values or seeds.');
end
if size(points, 1) < n
    error('wmrep:TooFewCoordinates', 'At least %d coordinate rows are required.', n);
end
stream = RandStream('mt19937ar', 'Seed', cfg.coordinateSeed);
selectedRows = randperm(stream, size(points, 1), n).';
coordinates = double(points(selectedRows, :));
distance = zeros(n);
for j = 1:n
    distance(:, j) = sqrt(sum((coordinates - coordinates(j, :)).^2, 2));
end
candidate = find(~eye(n));
d = distance(candidate);
if any(d == 0)
    error('wmrep:CoincidentCoordinates', 'Selected coordinate rows must be distinct.');
end
if any(~isfinite(d))
    error('wmrep:InvalidCoordinates', 'Coordinate magnitudes overflowed Euclidean distance.');
end
adjacency = false(n, n, numel(cfg.alpha));
for k = 1:numel(cfg.alpha)
    stream = RandStream('mt19937ar', 'Seed', cfg.networkSeeds(k));
    logWeight = -cfg.alpha(k) * log(d);
    % Exponential race: first m arrivals implement successive weighted
    % sampling without replacement. Log space avoids weight underflow.
    u = max(rand(stream, numel(candidate), 1), realmin);
    logArrival = log(-log(u)) - logWeight;
    [~, order] = sort(logArrival, 'ascend');
    A = false(n); A(candidate(order(1:m))) = true;
    adjacency(:, :, k) = A;
end
networks = struct('coordinates', coordinates, 'selectedRows', selectedRows, ...
    'alpha', cfg.alpha, 'adjacency', adjacency);
end
