function [outputDir, summary] = simulate_representative_networks(networkFile, outputDir, workers, maxNewJobs)
%SIMULATE_REPRESENTATIVE_NETWORKS Run the three representative networks.
%   simulate_representative_networks() uses representative_networks.mat.
%   The same solver is called by compute_fig1c for the scan networks.
%   Optional WORKERS (default 1) enables parallel execution when >1.
%   MAXNEWJOBS limits new simulations per call; repeating the call resumes.
here=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(networkFile),networkFile=fullfile(here,'results','representative_networks.mat');end
assert(isfile(networkFile),'fig1:MissingNetwork','Generate the network file first: %s',networkFile);
networkFile=safePath(networkFile);
loaded=load(networkFile,'network'); net=loaded.network;
assert(ismember(net.kind,{'representative','scan'}) && net.N==200 && net.num_edges==3879);
assert(strcmpi(net.data_sha256,fileHash(fullfile(here,'neuron_coordinates.mat'))) && ...
    strcmpi(net.generator_sha256,fileHash(fullfile(here,'generate_representative_networks.m'))), ...
    'fig1:Identity','Network coordinates or generator differ; use a new output file');
if nargin<2 || isempty(outputDir),outputDir=fullfile(here,'results',[net.kind '_simulation']);end
if nargin<3 || isempty(workers),workers=1;end
if nargin<4 || isempty(maxNewJobs),maxNewJobs=Inf;end
validateattributes(workers,{'numeric'},{'scalar','integer','positive'});
assert(isscalar(maxNewJobs) && maxNewJobs>=0 && (isinf(maxNewJobs)||fix(maxNewJobs)==maxNewJobs));
outputDir=safePath(outputDir); resultRoot=safePath(fullfile(here,'results'));
assert(startsWith(lower(outputDir),lower([resultRoot filesep])),'fig1:OutputPath','Output must be below results/');
na=numel(net.alpha_list); nr=numel(net.global_ids);
assert(isequal(size(net.A_tot),[na nr 200 200]));
allAlpha=unique([logspace(log10(.1),log10(5),60),.1,.9,2]);
assert(isequal(net.alpha_list(:),allAlpha(net.condition_indices(:))'));
if strcmp(net.kind,'representative')
    assert(isequal(net.alpha_list(:),[.1;.9;2]) && isequal(net.global_ids(:),21));
else
    assert(isequal(net.alpha_list(:),logspace(log10(.1),log10(5),60)') && isequal(net.global_ids(:),(21:120)'));
end
options=struct('gAMPA',.125,'gNMDA',.14,'randomSeed',0, ...
    'stopOnSilence',false,'totalMs',5000,'confirmationMs',100);
contract=struct('network_sha256',fileHash(networkFile), ...
    'solver_sha256',fileHash([mfilename('fullpath') '.m']), ...
    'data_sha256',net.data_sha256,'kind',net.kind,'options',options);
infoFile=safePath(fullfile(outputDir,'run_info.mat'));
if isfolder(outputDir)
    assert(isfile(infoFile),'fig1:Incomplete','Existing directory has no run_info.mat');
    checkSeal(infoFile); old=load(infoFile,'contract');
    assert(isequaln(old.contract,contract),'fig1:Identity','Stored run belongs to different inputs or code');
else
    assert(~isfile(outputDir),'fig1:OutputPath','Output path is a file');
    mkdir(outputDir);save(infoFile,'contract');writeSeal(infoFile);
end
checkpoints=safePath(fullfile(outputDir,'checkpoints'));if ~isfolder(checkpoints),mkdir(checkpoints);end
ids=cell(na*nr,1); paths=cell(na*nr,1); pending=[];
for r=1:nr
    for a=1:na
        k=(r-1)*na+a;
        assert(net.input_seeds(r)==300000000+net.global_ids(r));
        id=struct('alpha',net.alpha_list(a),'condition',net.condition_indices(a), ...
            'global_id',net.global_ids(r),'input_seed',net.input_seeds(r), ...
            'network_sha256',contract.network_sha256,'solver_sha256',contract.solver_sha256);
        ids{k}=id; paths{k}=safePath(fullfile(checkpoints,sprintf('c%03d_g%03d.mat',id.condition,id.global_id)));
        safePath([paths{k} '.sha256']);
        if isfile(paths{k})
            checkSeal(paths{k}); R=load(paths{k},'id');
            assert(isequaln(R.id,id),'fig1:Identity','Checkpoint identity differs: %s',paths{k});
        else
            assert(~isfile([paths{k} '.sha256']),'fig1:Incomplete','Orphan checkpoint seal');
            pending(end+1)=k; %#ok<AGROW>
        end
    end
end
scheduled=pending(1:min(numel(pending),maxNewJobs));
fprintf('SIMULATION_READY verified=%d pending=%d scheduled=%d workers=%d\n',na*nr-numel(pending),numel(pending),numel(scheduled),workers);
oldRng=rng; rngCleanup=onCleanup(@()rng(oldRng));
if workers>1 && ~isempty(scheduled)
    assert(license('test','Distrib_Computing_Toolbox'),'fig1:Toolbox','Use workers=1 for base MATLAB');
    pool=gcp('nocreate');if isempty(pool),pool=parpool('Processes',workers);end
    assert(isa(pool,'parallel.ProcessPool'),'fig1:Workers','Use a process pool for parallel simulation');
    assert(pool.NumWorkers>=workers,'fig1:Workers','The existing pool has too few workers');
    parfor (j=1:numel(scheduled),workers)
        k=scheduled(j); a=mod(k-1,na)+1;r=floor((k-1)/na)+1;
        simulateOne(squeeze(net.A_tot(a,r,:,:)),ids{k},paths{k},options);
    end
else
    for k=scheduled
        a=mod(k-1,na)+1;r=floor((k-1)/na)+1;
        simulateOne(squeeze(net.A_tot(a,r,:,:)),ids{k},paths{k},options);
    end
end
summary=table;
if numel(scheduled)<numel(pending)
    fprintf('SIMULATION_PARTIAL completed=%d total=%d; repeat the call to resume\n',na*nr-numel(pending)+numel(scheduled),na*nr);
    return
end
rows=cell(na*nr,1);
for k=1:numel(paths)
    checkSeal(paths{k}); R=load(paths{k},'id','duration','strict');
    assert(isequaln(R.id,ids{k}));
    rows{k}=struct('alpha',R.id.alpha,'condition',R.id.condition,'global_id',R.id.global_id, ...
        'duration_ms',R.duration,'strict_endpoint',R.strict);
end
summary=struct2table(vertcat(rows{:}));
csv=safePath(fullfile(outputDir,'summary.csv'));
if ~isfile(csv),writeSummaryCsv(summary,csv);writeSeal(csv);else,checkSeal(csv);end
if strcmp(net.kind,'representative')
    plotRepresentatives(paths,net,outputDir);
end
fprintf('SIMULATION_COMPLETE networks=%d output=%s\n',height(summary),outputDir);
end

function simulateOne(A,id,file,options)
file=safePath(file);safePath([file '.sha256']);
assert(~isfile(file) && ~isfile([file '.sha256']),'fig1:Exists','Checkpoint already exists');
assert(islogical(A) && isequal(size(A),[200 200]) && nnz(A)==3879 && ~any(diag(A)));
options.randomSeed=id.input_seed;
out=standardTrial(A,options);
% Independent event-grid duration, matching the Figure 1c analysis.
ix=round(out.spike_time(:)*100);
assert(all(abs(out.spike_time(:)-ix/100)<1e-9));
counts=accumarray(ix,1,[510000 1]);cs=[0;cumsum(counts)];ends=(110001:510000)';
first=find(cs(ends+1)-cs(ends-9999)==0,1);
if isempty(first),uncapped=4100;else,uncapped=ends(first)/100-1100;end
duration=min(uncapped,4000);strict=isempty(first)||uncapped>4000;
assert(abs(duration-out.observed_duration_ms)<1e-8 && strict==out.strict_duration_gt_4000);
assert(out.ended_ms==5100 && out.refractory_event_count==0 && out.standard_hold_violations==0);
save(file,'out','id','duration','strict','-v7');writeSeal(file);
fprintf('SIMULATED alpha=%.17g global=%d duration=%.5f ms elapsed=%.2f s\n',id.alpha,id.global_id,duration,out.elapsed_seconds);
end

function plotRepresentatives(paths,net,folder)
target=safePath(fullfile(folder,'Fig1b.pdf'));png=safePath(fullfile(folder,'Fig1b.png'));
if isfile(target)||isfile(png)||isfile([target '.sha256'])||isfile([png '.sha256'])
    assert(isfile(target)&&isfile(png),'fig1:Incomplete','Representative figure export is incomplete');
    checkSeal(target);checkSeal(png);return
end
f=figure('Visible','off','Color','w','Units','centimeters','Position',[1 1 18 8]);
cleanup=onCleanup(@()close(f)); colors=[0 114 178;213 94 0;0 158 115]/255;
styles={'-','--','-.'}; rates=zeros(3,100);R=cell(3,1);
for k=1:3
    R{k}=load(paths{k},'out','duration');t=R{k}.out.spike_time;
    rates(k,:)=histcounts(t(t>=0&t<5000),0:50:5000)/(200*.05);
end
for k=1:3
    t=R{k}.out.spike_time;n=R{k}.out.spike_neuron; keep=t>=0&t<5000;
    ax=subplot(2,3,k,'Parent',f);scatter(ax,t(keep),n(keep),1,colors(k,:),'filled');
    hold(ax,'on');xline(ax,500,':');xline(ax,1000,':');xlim(ax,[0 5000]);ylim(ax,[0 200]);
    title(ax,sprintf('\\alpha = %g; T_{obs} = %.0f ms',net.alpha_list(k),R{k}.duration),'FontWeight','normal');
    set(ax,'FontName','Arial','FontSize',8,'Box','off','XTickLabel',[]);if k==1,ylabel(ax,'Neuron');end
    ax=subplot(2,3,k+3,'Parent',f);plot(ax,25:50:4975,rates(k,:),styles{k},'Color',colors(k,:));
    hold(ax,'on');xline(ax,500,':');xline(ax,1000,':');xlim(ax,[0 5000]);ylim(ax,[0 max(rates,[],'all')*1.08]);
    xlabel(ax,'Time (ms)');if k==1,ylabel(ax,'Population rate (Hz)');end
    set(ax,'FontName','Arial','FontSize',8,'Box','off');
end
exportgraphics(f,target,'ContentType','vector');writeSeal(target);
assert(~isfile(png));exportgraphics(f,png,'Resolution',300);writeSeal(png);
end

function writeSummaryCsv(T,p)
fid=fopen(p,'w');assert(fid~=-1);cleanup=onCleanup(@()fclose(fid));
fprintf(fid,'alpha,condition,global_id,duration_ms,strict_endpoint\n');
for k=1:height(T)
    fprintf(fid,'%.17g,%d,%d,%.17g,%d\n',T.alpha(k),T.condition(k),T.global_id(k),T.duration_ms(k),T.strict_endpoint(k));
end
end

function writeSeal(p)
p=safePath(p);seal=safePath([p '.sha256']);assert(~isfile(seal),'fig1:Exists','Seal exists');
fid=fopen(seal,'w');assert(fid~=-1);cleanup=onCleanup(@()fclose(fid));fprintf(fid,'%s\n',fileHash(p));
end
function checkSeal(p)
p=safePath(p);safePath([p '.sha256']);
assert(isfile([p '.sha256']),'fig1:Incomplete','Checkpoint has no seal: %s',p);
expected=strtrim(fileread([p '.sha256']));actual=fileHash(p);
assert(strcmpi(expected,actual),'fig1:Integrity','Hash mismatch %s expected=%s actual=%s',p,expected,actual);
end
function h=fileHash(p)
fid=fopen(p,'rb');assert(fid~=-1);cleanup=onCleanup(@()fclose(fid));md=java.security.MessageDigest.getInstance('SHA-256');
while true,b=fread(fid,1048576,'*uint8');if isempty(b),break,end;md.update(typecast(b(:),'int8'));end
h=upper(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
function p=safePath(p)
node=java.io.File(char(p)).toPath().toAbsolutePath().normalize();p=char(node.toString());
while ~isempty(node)
    assert(~java.nio.file.Files.isSymbolicLink(node),'fig1:UnsafePath','Symbolic link: %s',p);
    if ispc && java.io.File(char(node.toString())).exists()
        attrs=System.Convert.ToInt32(System.IO.File.GetAttributes(char(node.toString())));
        flag=System.Convert.ToInt32(System.IO.FileAttributes.ReparsePoint);
        assert(bitand(int32(attrs),int32(flag))==0,'fig1:UnsafePath','Reparse point: %s',p);
    end
    node=node.getParent();
end
end

% Numerical kernel retained from redo_standard_trial_v1, SHA256 A01D50C49E66CAAA6F889A99DC20F27A3D243BDD4FF3F82266E2EDF3060D5264.
function out=standardTrial(matrixR,options)
rule='standard_refractory_first';
% Versioned three-arm sensitivity kernel. Legacy arithmetic is retained.
% No historical file is modified. Event intervention is named explicitly.
if nargin<2,options=struct;end
defaults=struct('totalMs',5000,'confirmationMs',100,'initialVoltage',-70,'initialLastSpike',0,'baselineHz',800,'cueHz',1600,'stopOnSilence',true,'captureVoltage',false,'randomSeed',1,'gAMPA',.135,'gNMDA',.14);
fields=fieldnames(defaults);for k=1:numel(fields),if ~isfield(options,fields{k}),options.(fields{k})=defaults.(fields{k});end,end
assert(any(strcmp(rule,{'legacy','refractory_gated_events','standard_refractory_first'})));
N=size(matrixR,1);assert(size(matrixR,2)==N && all(isfinite(matrixR),'all'));
matrixR=double(matrixR);rng(options.randomSeed,'twister');step=.01;
time=step:step:options.totalMs;
if options.confirmationMs>0,time=[time,(options.totalMs+step):step:(options.totalMs+options.confirmationMs)];end
Nt=numel(time);vR=ones(1,N)*options.initialVoltage;t_fring_R=ones(1,N)*options.initialLastSpike;
rsynAMPA_R=zeros(1,N);rsynAMPA_ext=zeros(1,N);rsynGABA_R=zeros(1,N);x_NMDA_R=zeros(1,N);rsynNMDA_R=zeros(1,N);
validateattributes(options.gAMPA,{'double'},{'scalar','finite','nonnegative'});validateattributes(options.gNMDA,{'double'},{'scalar','finite','nonnegative'});gAMPA_R=options.gAMPA;gNMDA_R=options.gNMDA;gAMPA_ext=.3;gGABA_R=0;CmR=ones(1,N);gL_R=ones(1,N)*.025;
tao_AMPA=2;tao_GABA=10;tao_NMDA_rise=2;tao_NMDA_decay=100;Alpha=.5;tao_rp=ones(1,N)*2;v_thr=-50;v_reset=-65;
spike_R=zeros(1,N);poissonSpikeR=zeros(1,N);countHistory=zeros(1,Nt);
capacity=max(10000,ceil(N*options.totalMs*.25));spikeTime=zeros(1,capacity);spikeNeuron=zeros(1,capacity);eventCount=0;
externalBuffer=zeros(N,10000,'uint8');blockSha=strings(ceil(Nt/10000),1);blockSteps=zeros(ceil(Nt/10000),1);blockCount=0;
if options.captureVoltage,voltageHistory=nan(N,Nt);else,voltageHistory=[];end
flag_firing=0;stopDetected=false;break_time=0;refractoryEvents=0;holdViolations=0;
firstStepAMPA=NaN;secondStepAMPA=NaN;secondStepRise=NaN;secondStepGate=NaN;timer=tic;
for iii=1:Nt
    refractory=time(iii)-t_fring_R<=tao_rp;
    if strcmp(rule,'standard_refractory_first')
        vR(refractory)=v_reset;
        spike_R=double((vR>v_thr)&~refractory);
        fired=logical(spike_R);t_fring_R(fired)=time(iii);vR(fired)=v_reset;
        holdMask=refractory|fired;
    elseif strcmp(rule,'refractory_gated_events')
        spike_R=double((vR>v_thr)&~refractory);
    else
        spike_R(vR>v_thr)=1;spike_R(vR<=v_thr)=0;
    end
    refractoryEvents=refractoryEvents+sum(spike_R(refractory));
    Rand_poissonR=rand(1,N);
    P_poisson_R=1-exp(-options.baselineHz*step/1000);
    if iii>round(.5*1000/step)&&iii<round(1.0*1000/step),P_poisson_R=1-exp(-options.cueHz*step/1000);end
    poissonSpikeR(P_poisson_R>Rand_poissonR)=1;poissonSpikeR(P_poisson_R<=Rand_poissonR)=0;
    column=mod(iii-1,10000)+1;externalBuffer(:,column)=uint8(poissonSpikeR');
    if column==10000
        blockCount=blockCount+1;blockSha(blockCount)=hashBytes(externalBuffer(:));blockSteps(blockCount)=10000;
    end
    drsynAMPA_R=rsynAMPA_R+step*(-rsynAMPA_R/tao_AMPA+spike_R);
    drsynAMPA_ext=rsynAMPA_ext+step*(-rsynAMPA_ext/tao_AMPA+poissonSpikeR);
    drsynGABA_R=rsynGABA_R+step*(-rsynGABA_R/tao_GABA+spike_R);
    dx_NMDA_R=x_NMDA_R+step*(-x_NMDA_R/tao_NMDA_rise+spike_R);
    drsynNMDA_R=rsynNMDA_R+step*(-rsynNMDA_R/tao_NMDA_decay+Alpha*x_NMDA_R.*(1-rsynNMDA_R));
    sum_rsynAMPA_R=sum(matrixR.*rsynAMPA_R',1);
    sum_rsynNMDA_R=sum(matrixR.*rsynNMDA_R',1);
    % No inhibitory neurons in the archived all-excitatory configuration.
    sum_rsynGABA_R=sum(matrixR(N+1:N,:).*rsynGABA_R(N+1:N)',1);
    Irec_AMPA_R=gAMPA_R.*sum_rsynAMPA_R.*(0-vR);
    Irec_NMDA_R=(gNMDA_R.*sum_rsynNMDA_R.*(0-vR))./(1+exp(-.062*vR)/3.57);
    Irec_AMPA_ext=gAMPA_ext.*rsynAMPA_ext.*(0-vR);
    Irec_GABA_R=gGABA_R.*sum_rsynGABA_R.*(-70-vR);
    Isny_R=Irec_AMPA_R+Irec_NMDA_R+Irec_GABA_R+Irec_AMPA_ext;IextR=0;
    if ~strcmp(rule,'standard_refractory_first')
        vR(time(iii)-t_fring_R<=tao_rp)=v_reset;
        vR(vR>v_thr)=0;t_fring_R(vR>v_thr)=time(iii);
    end
    dvR=vR+step*(-gL_R.*(vR+70)+Isny_R+IextR)./CmR;
    if strcmp(rule,'standard_refractory_first')
        dvR(holdMask)=v_reset;
        holdViolations=holdViolations+nnz(dvR(holdMask)~=v_reset);
    end
    index_spike=find(spike_R==1);n=numel(index_spike);countHistory(iii)=n;
    if eventCount+n>numel(spikeTime),spikeTime=[spikeTime,zeros(1,capacity)];spikeNeuron=[spikeNeuron,zeros(1,capacity)];end
    if n>0,ids=eventCount+(1:n);spikeTime(ids)=time(iii);spikeNeuron(ids)=index_spike;eventCount=eventCount+n;end
    rsynAMPA_R=drsynAMPA_R;rsynAMPA_ext=drsynAMPA_ext;rsynGABA_R=drsynGABA_R;x_NMDA_R=dx_NMDA_R;rsynNMDA_R=drsynNMDA_R;vR=dvR;
    if iii==1,firstStepAMPA=mean(rsynAMPA_R);elseif iii==2,secondStepAMPA=mean(rsynAMPA_R);secondStepRise=mean(x_NMDA_R);secondStepGate=mean(rsynNMDA_R);end
    if options.captureVoltage,voltageHistory(:,iii)=vR';end
    if iii>1000/step
        flag_firing=flag_firing+countHistory(iii);
        if iii>1100/step
            flag_firing=flag_firing-countHistory(iii-round(100/step));
            if flag_firing==0 && ~stopDetected
                break_time=time(iii)-1100;stopDetected=true;
                if options.stopOnSilence,break;end
            end
        end
    end
    if iii==Nt && ~stopDetected,break_time=time(Nt)-1000;end
end
if column<10000
    blockCount=blockCount+1;blockSha(blockCount)=hashBytes(reshape(externalBuffer(:,1:column),[],1));blockSteps(blockCount)=column;
end
spikeTime=spikeTime(1:eventCount);spikeNeuron=spikeNeuron(1:eventCount);
minimumIsi=Inf;doubletCount=0;
for neuron=1:N
    intervals=diff(spikeTime(spikeNeuron==neuron));
    if ~isempty(intervals),minimumIsi=min(minimumIsi,min(intervals));doubletCount=doubletCount+sum(abs(intervals-step)<1e-9);end
end
strict=~stopDetected||break_time>4000;observed=break_time;if strict,observed=4000;end
state=struct('voltage',vR,'ampa',rsynAMPA_R,'ampa_external',rsynAMPA_ext,'nmda_rise',x_NMDA_R,'nmda_gate',rsynNMDA_R,'last_firing',t_fring_R);
assert(all(isfinite([vR rsynAMPA_R rsynAMPA_ext x_NMDA_R rsynNMDA_R])),'CP:NonFiniteState','Nonfinite trajectory state');
if ~strcmp(rule,'legacy'),assert(refractoryEvents==0 && doubletCount==0);end
out=struct('rule',rule,'spike_time',spikeTime,'spike_neuron',spikeNeuron,'observed_duration_ms',observed,'uncapped_duration_ms',break_time,'stop_detected',stopDetected,'strict_duration_gt_4000',strict,'ended_ms',time(iii),'steps',iii,'elapsed_seconds',toc(timer),'minimum_isi_ms',minimumIsi,'adjacent_step_doublet_count',doubletCount,'refractory_event_count',refractoryEvents,'standard_hold_violations',holdViolations,'external_block_sha256',blockSha(1:blockCount),'external_block_steps',blockSteps(1:blockCount),'final_state',state,'voltage_history',voltageHistory,'first_step_ampa',firstStepAMPA,'second_step_ampa',secondStepAMPA,'second_step_nmda_rise',secondStepRise,'second_step_nmda_gate',secondStepGate,'options',options);
end

function h=hashBytes(bytes)
md=java.security.MessageDigest.getInstance('SHA-256');md.update(uint8(bytes));
h=upper(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
end
