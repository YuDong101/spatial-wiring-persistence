function tests = test_public_package
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
testCase.TestData.root = fileparts(fileparts(mfilename('fullpath')));
addpath(testCase.TestData.root);
end

function testPublicEntryExists(testCase)
verifyEqual(testCase, exist('run_representative', 'file'), 2);
verifyNotEmpty(testCase, which('wmrep.config'));
end

function testExactRequestedConditions(testCase)
c = wmrep.config();
verifyEqual(testCase, c.alpha, [0.1 0.9 2]);
verifyEqual(testCase, c.numNodes, 200);
verifyEqual(testCase, c.numEdges, 2000);
verifyEqual(testCase, c.simulationSeed, 1);
end

function testMatchedGeometryBudgetAndReproducibility(testCase)
c = wmrep.config(); c.numNodes = 12; c.numEdges = 30;
p = fixture_points(20);
state = rng;
first = wmrep.generate_networks(p, c);
verifyEqual(testCase, rng, state);
second = wmrep.generate_networks(p, c);
verifyEqual(testCase, first, second);
verifySize(testCase, first.adjacency, [12 12 3]);
verifyEqual(testCase, first.coordinates, p(first.selectedRows, :));
verifyEqual(testCase, numel(unique(first.selectedRows)), 12);
for k = 1:3
    A = first.adjacency(:, :, k);
    verifyClass(testCase, A, 'logical');
    verifyEqual(testCase, nnz(A), 30);
    verifyFalse(testCase, any(diag(A)));
end
verifyFalse(testCase, isequal(first.adjacency(:, :, 1), first.adjacency(:, :, 3)));
end

function testUniformUnitChangePreservesTopology(testCase)
c = wmrep.config(); c.numNodes = 12; c.numEdges = 30;
a = wmrep.generate_networks(fixture_points(20), c);
b = wmrep.generate_networks(1000 * fixture_points(20), c);
verifyEqual(testCase, a.adjacency, b.adjacency);
end

function testInvalidGeometryAndBudgetAreRejected(testCase)
c = wmrep.config(); c.numNodes = 12; c.numEdges = 30;
verifyError(testCase, @() wmrep.generate_networks(zeros(12, 3), c), 'wmrep:CoincidentCoordinates');
verifyError(testCase, @() wmrep.generate_networks(fixture_points(11), c), 'wmrep:TooFewCoordinates');
c.numEdges = 133;
verifyError(testCase, @() wmrep.generate_networks(fixture_points(20), c), 'wmrep:InvalidConfig');
end

function testMatAndCsvCoordinateInputs(testCase)
d = tempname; mkdir(d); clean = onCleanup(@() rmdir(d, 's'));
points = fixture_points(205);
f = fullfile(d, 'coordinates.mat'); save(f, 'points');
[actual, source] = wmrep.load_coordinates(f);
verifyEqual(testCase, actual, points);
verifyEqual(testCase, strlength(source.sha256), 64);
csv = fullfile(d, 'coordinates.csv');
writetable(array2table(points, 'VariableNames', {'x', 'y', 'z'}), csv);
verifyEqual(testCase, wmrep.load_coordinates(csv), points, 'AbsTol', 1e-11);
whole_v783 = struct('points', points);
f2 = fullfile(d, 'original.mat'); save(f2, 'whole_v783');
verifyEqual(testCase, wmrep.load_coordinates(f2), points);
clear clean
end

function testMissingOrMalformedCoordinatesAreRejected(testCase)
verifyError(testCase, @() wmrep.load_coordinates([tempname '.mat']), 'wmrep:CoordinateFileMissing');
d = tempname; mkdir(d); clean = onCleanup(@() rmdir(d, 's'));
points = [1 2 NaN]; f = fullfile(d, 'invalid.mat'); save(f, 'points');
verifyError(testCase, @() wmrep.load_coordinates(f), 'wmrep:InvalidCoordinates');
clear clean
end

function testMissingInputCreatesNoRunDirectory(testCase)
target = tempname;
verifyError(testCase, @() run_representative([tempname '.mat'], target), 'wmrep:CoordinateFileMissing');
verifyFalse(testCase, isfolder(target));
end

function testSilentNetworkSimulator(testCase)
[~, ~, ~, duration, t, n, rate] = wmrep.trial(0, 2, 0, 0, 0, 0, zeros(2));
verifyEqual(testCase, duration, 0.01, 'AbsTol', 1e-9);
verifyEmpty(testCase, t{1}); verifyEmpty(testCase, n{1});
verifyEqual(testCase, rate, [0 0]);
end

function p = fixture_points(count)
q = (1:count)';
p = [q, mod(q.^2, 97), mod(q.^3, 131)];
end
