function runDir = run_representative(coordinateFile, outputRoot)
%RUN_REPRESENTATIVE Generate and simulate alpha = 0.1, 0.9, 2.
% runDir = run_representative('/path/to/coordinates.csv')
% Optional outputRoot selects the parent of a new, unique run directory.
% The original coordinate data are supplied separately by the user.
if nargin < 1, coordinateFile = ''; end
packageRoot = fileparts(mfilename('fullpath'));
if nargin < 2, outputRoot = fullfile(packageRoot, 'outputs'); end
state = rng;
restoreRng = onCleanup(@() rng(state));
cfg = wmrep.config();
[points, source] = wmrep.load_coordinates(coordinateFile);
networks = wmrep.generate_networks(points, cfg);
clear points
if ~(ischar(outputRoot) && isrow(outputRoot) || isstring(outputRoot) && isscalar(outputRoot)) || ...
        ismissing(string(outputRoot)) || strlength(string(outputRoot)) == 0
    error('wmrep:InvalidOutput', 'outputRoot must be a nonempty directory path.');
end
runDir = fullfile(outputRoot, ['run_' char(java.util.UUID.randomUUID())]);
[ok, message] = mkdir(runDir);
if ~ok, error('wmrep:InvalidOutput', '%s', message); end
runtime = struct('matlabVersion', version, 'release', version('-release'), ...
    'platform', computer, 'createdUtc', char(datetime('now', 'TimeZone', 'UTC')));
names = {'run_representative.m', '+wmrep/config.m', '+wmrep/generate_networks.m', ...
    '+wmrep/load_coordinates.m', '+wmrep/sha256.m', '+wmrep/trial.m'};
code = struct;
code.files = string(names(:)); code.sha256 = strings(numel(names), 1);
for k = 1:numel(names)
    code.sha256(k) = wmrep.sha256(fullfile(packageRoot, names{k}));
end
save(fullfile(runDir, 'networks.mat'), 'cfg', 'source', 'networks', 'runtime', 'code', '-v7.3');
durationMs = nan(numel(cfg.alpha), 1);
spikeCount = zeros(numel(cfg.alpha), 1);
for k = 1:numel(cfg.alpha)
    fprintf('Simulating alpha %.15g (%d/%d)...\n', cfg.alpha(k), k, numel(cfg.alpha));
    A = double(networks.adjacency(:, :, k));
    [~, ~, ~, duration, t, neuron, rate] = wmrep.trial( ...
        cfg.gPoisson, cfg.numNodes, cfg.gAMPA_R, cfg.gAMPA_ext, ...
        cfg.gNMDA_R, cfg.gGABA_R, A);
    result = struct('alpha', cfg.alpha(k), 'durationMs', duration, ...
        'spikeTimesMs', t{1}, 'spikeNeuronIndex', neuron{1}, ...
        'postCueRateHz', rate, 'endpointRecorded', duration == 4000);
    save(fullfile(runDir, sprintf('condition_%02d.mat', k)), 'result', 'cfg', '-v7.3');
    durationMs(k) = duration; spikeCount(k) = numel(t{1});
    fprintf('alpha %.15g: duration %.2f ms; %d spikes\n', cfg.alpha(k), duration, spikeCount(k));
end
summary = table(cfg.alpha(:), durationMs, spikeCount, durationMs == 4000, ...
    'VariableNames', {'alpha', 'duration_ms', 'total_spike_count', 'endpoint_recorded'});
writetable(summary, fullfile(runDir, 'summary.csv'));
fprintf('Completed three conditions. Results: %s\n', runDir);
end
