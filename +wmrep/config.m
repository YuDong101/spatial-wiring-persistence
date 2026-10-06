function cfg = config()
%CONFIG Parameters for three new coordinate-matched example networks.
cfg.schemaVersion = 'representative-simulation-v1';
cfg.alpha = [0.1 0.9 2];
cfg.numNodes = 200;
cfg.numEdges = 2000;
cfg.coordinateSeed = 20261006;
cfg.networkSeeds = [101 102 103];
cfg.simulationSeed = 1; % Fixed inside the preserved trial implementation.
cfg.gPoisson = 1;
cfg.gAMPA_R = 0.135;
cfg.gAMPA_ext = 0.3;
cfg.gNMDA_R = 0.14;
cfg.gGABA_R = 0.4;
cfg.timeStepMs = 0.01;
cfg.maximumTimeMs = 5000;
cfg.cueOffsetMs = 1000;
cfg.silenceWindowMs = 100;
end
