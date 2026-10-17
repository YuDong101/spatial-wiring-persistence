function outputFile = generate_representative_networks(outputFile, mode)
%GENERATE_REPRESENTATIVE_NETWORKS Build the three Figure 1 example networks.
%   generate_representative_networks creates results/representative_networks.mat.
%   Each network has 200 neurons and 3879 directed edges, with exact alpha
%   values 0.1, 0.9 and 2. The neuron sample is paired across conditions.
%   The optional mode 'scan' is used by generate_scan_networks.
%
% Frozen production sources (bytes, SHA-256):
% generate_eq5_network.m: 11181,
% 62DF5C0637AEF5DDE6F51C1FABD9958AF685EE697B9EE47F3956341B08B0C8DB
% run_redo_production_generation_v2.m: 3067,
% 2570107E8219BD64A5515B7A1D3B89AA70DDAD4F2B4B4224EEA6F9F3AA11D747
% redo_production_config_v2.m: 1034,
% 29EADE2EADE4038963B5BAA73AC70A34980DCFC39EEEB086872320BC75C858FF

packageDir=fileparts(mfilename('fullpath'));
if nargin<2 || isempty(mode),mode='representative';end
mode=char(mode);
assert(any(strcmp(mode,{'representative','scan'})), ...
    'FIG1:Mode','Mode must be representative or scan.');
if nargin<1 || isempty(outputFile)
    outputFile=fullfile(packageDir,'results',[mode '_networks.mat']);
end
outputFile=safe_output(outputFile,packageDir);
assert(~isfile(outputFile) && ~isfolder(outputFile), ...
    'FIG1:Exists','Output already exists: %s',outputFile);
dataFile=fullfile(packageDir,'neuron_coordinates.mat');
assert(isfile(dataFile),'FIG1:Data','Missing neuron_coordinates.mat.');
check_no_links(dataFile);
info=dir(dataFile);
dataHash=sha256(dataFile);
assert(info.bytes==1699545 && strcmp(dataHash, ...
    'E824ACA5C47C9334A3667EF85595724DD8FC11899DF29A4E851DED3E8039057A'), ...
    'FIG1:DataIdentity','Coordinate bytes or SHA-256 differ from the released input.');
data=load(dataFile,'points','root_id');
assert(isa(data.points,'double') && isequal(size(data.points),[139255 3]) ...
    && all(isfinite(data.points),'all') && isa(data.root_id,'uint64') ...
    && isequal(size(data.root_id),[139255 1]), ...
    'FIG1:Data','Coordinate dimensions, precision or identifiers differ.');

scanAlpha=logspace(log10(.1),log10(5),60);
allAlpha=unique([scanAlpha .1 .9 2]);
if strcmp(mode,'representative')
    alpha=[.1 .9 2];globalIds=21;
else
    alpha=scanAlpha;globalIds=21:120;
end
conditionIndices=arrayfun(@(a)find(allAlpha==a),alpha);
na=numel(alpha);nr=numel(globalIds);N=200;numEdges=3879;
network=struct('kind',mode,'N',N,'num_edges',numEdges, ...
    'alpha_list',alpha,'condition_indices',conditionIndices, ...
    'global_ids',globalIds,'coordinate_seeds',20261014+globalIds, ...
    'topology_seeds',20261014+100000*conditionIndices(:)+globalIds, ...
    'input_seeds',300000000+globalIds,'data_sha256',dataHash, ...
    'generator_sha256',sha256([mfilename('fullpath') '.m']), ...
    'edge_direction','A(source,target)');
network.A_tot=false(na,nr,N,N);
network.cluster_tot=zeros(nr,N,3);
network.root_id_tot=zeros(nr,N,'uint64');
network.node_index_tot=zeros(nr,N);
% The bounding box uses the entire coordinate population, before sampling.
maxDistance=sqrt(sum((max(data.points,[],1)-min(data.points,[],1)).^2));
assert(isfinite(maxDistance) && maxDistance>0,'FIG1:Data','Degenerate coordinates.');
callerRng=rng;restoreRng=onCleanup(@()rng(callerRng)); %#ok<NASGU>
for r=1:nr
    rng(network.coordinate_seeds(r),'twister');
    idx=randperm(size(data.points,1),N)';
    xyz=data.points(idx,:);
    network.cluster_tot(r,:,:)=xyz;
    network.root_id_tot(r,:)=data.root_id(idx);
    network.node_index_tot(r,:)=idx;
    X=xyz./maxDistance;
    sqNorm=sum(X.^2,2);
    D2=sqNorm+sqNorm.'-2.*(X*X.');
    D2(D2<0 & D2>-1e-9)=0;
    D=sqrt(max(D2,0));
    positiveDistances=D(D>0 & isfinite(D));
    assert(~isempty(positiveDistances),'FIG1:Data','Degenerate neuron sample.');
    D(D==0)=min(positiveDistances);
    D(1:N+1:end)=Inf;
    for a=1:na
        rng(network.topology_seeds(a,r),'twister');
        % Preserve the frozen beta=0, lambda=0 arithmetic and draw order.
        logKernel=-alpha(a).*log(D)-0.*D;
        logKernel(1:N+1:end)=-Inf;
        logKernel(~isfinite(logKernel))=-Inf;
        K=exp(logKernel-max(logKernel(:)));
        K(~isfinite(K))=0;
        probability=K./sum(K(:));
        weights=double(probability(:));
        positive=find(weights>0 & isfinite(weights));
        keys=log(rand(numel(positive),1))./weights(positive);
        [~,order]=sort(keys,'descend');
        A=false(N,N);A(positive(order(1:numEdges)))=true;
        A(1:N+1:end)=false;
        assert(nnz(A)==numEdges && ~any(diag(A)), ...
            'FIG1:Network','Invalid directed edge count or self edge.');
        network.A_tot(a,r,:,:)=A;
    end
    fprintf('GENERATED global_id=%d realization=%d/%d conditions=%d\n', ...
        globalIds(r),r,nr,na);
end
parent=fileparts(outputFile);
if ~isfolder(parent),mkdir(parent);end
safe_output(outputFile,packageDir);
assert(~isfile(outputFile) && ~isfolder(outputFile), ...
    'FIG1:Exists','Output appeared during generation: %s',outputFile);
save(outputFile,'network','-v7.3');
fprintf('NETWORK_GENERATION_PASS kind=%s networks=%d file=%s\n',mode,na*nr,outputFile);
end

function output=safe_output(output,packageDir)
output=char(output);
root=char(java.io.File(fullfile(packageDir,'results')).getCanonicalPath());
output=char(java.io.File(output).getAbsolutePath());
check_no_links(output);
output=char(java.io.File(output).getCanonicalPath());
assert(startsWith(lower(output),lower([root filesep])), ...
    'FIG1:Path','Output must be below the package results directory.');
[~,~,ext]=fileparts(output);
assert(strcmpi(ext,'.mat'),'FIG1:Path','Output must be a MAT file.');
end

function check_no_links(path)
% Reject existing symlink/junction ancestors before canonicalisation.
while ~isempty(path)
    if isfile(path) || isfolder(path)
        if ispc
            attrs=System.IO.File.GetAttributes(path);
            assert(~contains(char(attrs.ToString()),'ReparsePoint'), ...
                'FIG1:Path','Reparse points are not allowed: %s',path);
        else
            assert(~java.nio.file.Files.isSymbolicLink(java.io.File(path).toPath()), ...
                'FIG1:Path','Symbolic links are not allowed: %s',path);
        end
    end
    parent=fileparts(path);
    if strcmp(parent,path),break;end
    path=parent;
end
end

function value=sha256(path)
fid=fopen(path,'rb');assert(fid>=0,'FIG1:Read','Cannot read %s',path);
closeFile=onCleanup(@()fclose(fid)); %#ok<NASGU>
digest=java.security.MessageDigest.getInstance('SHA-256');
while ~feof(fid)
    block=fread(fid,1024*1024,'*uint8');digest.update(block);
end
bytes=typecast(digest.digest(),'uint8');
value=upper(reshape(dec2hex(bytes,2).',1,[]));
end
