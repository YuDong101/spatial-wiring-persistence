function outputFile = generate_scan_networks(outputFile)
%GENERATE_SCAN_NETWORKS Generate 60 alpha conditions x 100 realisations.
%   The logarithmic alpha grid spans 0.1 to 5. Global realisation IDs are
%   21:120, paired across alpha; each network has 200 neurons and 3879 edges.
%   Output defaults to results/scan_networks.mat. Existing files are retained.
if nargin<1,outputFile=[];end
outputFile=generate_representative_networks(outputFile,'scan');
end
