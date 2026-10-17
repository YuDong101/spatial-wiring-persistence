function figureDir = compute_fig1c(networkFile, workers, maxNewJobs)
%COMPUTE_FIG1C Simulate the 6000 scan networks and plot mean +/- sample SD.
%   compute_fig1c() is sequential; compute_fig1c([],16) uses 16 workers.
%   compute_fig1c([],16,100) runs at most 100 new cases and can be resumed.
here=fileparts(mfilename('fullpath'));
if nargin<1 || isempty(networkFile),networkFile=fullfile(here,'results','scan_networks.mat');end
assert(isfile(networkFile),'fig1:MissingNetwork','Run generate_scan_networks first');
if nargin<2 || isempty(workers),workers=1;end
if nargin<3 || isempty(maxNewJobs),maxNewJobs=Inf;end
S=load(networkFile,'network');net=S.network;
assert(strcmp(net.kind,'scan') && numel(net.alpha_list)==60 && numel(net.global_ids)==100);
[runDir,T]=simulate_representative_networks(networkFile,[],workers,maxNewJobs);
figureDir=''; if isempty(T),return,end
assert(height(T)==6000); duration=zeros(60,100);strict=zeros(60,1);
for k=1:60
    Q=sortrows(T(T.condition==net.condition_indices(k),:),'global_id');
    assert(height(Q)==100 && isequal(Q.global_id,(21:120)') && all(Q.alpha==net.alpha_list(k)));
    duration(k,:)=Q.duration_ms';strict(k)=sum(Q.strict_endpoint);
end
alpha=net.alpha_list(:); mu=mean(duration,2);sd=std(duration,0,2);
figureDir=fullfile(runDir,['figure_' char(java.util.UUID.randomUUID())]);mkdir(figureDir);
f=figure('Visible','off','Color','w','Units','centimeters','Position',[1 1 18 6]);cleanup=onCleanup(@()close(f));
ax=axes(f);hold(ax,'on');
patch(ax,[.65 .90 .90 .65],[0 0 4300 4300],[.93 .93 .93],'EdgeColor','none','HandleVisibility','off');
scatter(ax,repmat(alpha,100,1),duration(:),7,[.72 .8 .86],'filled','MarkerFaceAlpha',.3);
errorbar(ax,alpha,mu,sd,'-o','Color',[0 114 178]/255,'MarkerFaceColor','w','MarkerSize',4,'LineWidth',1,'CapSize',3);
yline(ax,4000,'--','Color',[.5 .5 .5],'HandleVisibility','off');
set(ax,'XScale','log','XLim',[.095 5.25],'YLim',[0 max(4200,max(mu+sd)+80)], ...
    'XTick',[.1 .2 .5 1 2 5],'XTickLabel',{'0.1','0.2','0.5','1','2','5'}, ...
    'YTick',0:1000:4000,'FontName','Arial','FontSize',9,'TickDir','out','Box','off');
xlabel(ax,'\alpha');ylabel(ax,'{\it T}_{\rm obs} (ms)');
legend(ax,{'Individual networks','Mean \pm SD'},'Location','northwest','Orientation','horizontal','Box','off');
exportgraphics(f,fullfile(figureDir,'Fig1c.pdf'),'ContentType','vector');
exportgraphics(f,fullfile(figureDir,'Fig1c.png'),'Resolution',300);
save(fullfile(figureDir,'Fig1c_data.mat'),'alpha','duration','mu','sd','strict');
fid=fopen(fullfile(figureDir,'Fig1c_summary.csv'),'w');assert(fid~=-1);fileCleanup=onCleanup(@()fclose(fid));
fprintf(fid,'alpha,mean_duration_ms,sample_sd_ms,strict_endpoint_count\n');
for k=1:60,fprintf(fid,'%.17g,%.17g,%.17g,%d\n',alpha(k),mu(k),sd(k),strict(k));end
clear fileCleanup
fprintf('FIG1C_COMPLETE conditions=60 networks=6000 output=%s\n',figureDir);
end
