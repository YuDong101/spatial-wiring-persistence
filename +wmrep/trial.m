function [time,outputR,LFP_R,break_time,time_fir_c,n_fir_c,rate_fir] = trial(gPoisson,NR_node,gAMPA_R,gAMPA_ext,gNMDA_R,gGABA_R,matrixR)
%TRIAL Original Euler LIF simulation with recurrent AMPA and NMDA.
% Computational statements are preserved from the manuscript simulator.
% Duration is measured from cue offset to the start of a confirmed
% 100-ms silent window. A 4000-ms value is the simulation endpoint code.
% Random driving input uses rng(1, 'twister') for each condition.
rng(1,'twister');
T_tot=5000; step=0.01;
Nt=round(T_tot/step);
tao_AMPA=2; tao_GABA=10;  tao_NMDA_rise=2;  tao_NMDA_decay=100; Alpha=0.5;
r_poissonR1=800; r_poissonR2=1600; poissonSpikeR(1:NR_node)=0.0;
raitoEI=1;
flag_firing=0.0; break_time=0.0;
vR(1:NR_node)=-70;
spike_R(1:NR_node)=0;
rsynAMPA_R(1:NR_node)=0.0; rsynAMPA_ext(1:NR_node)=0.0; rsynGABA_R(1:NR_node)=0.0;
x_NMDA_R(1:NR_node) = 0.0; rsynNMDA_R(1:NR_node) = 0.0;
output_spike_R(1:NR_node,1:Nt)=0.0;
outputR=0.0; output_sny=0.0;
LFP_R(1:Nt)=0.0;
n_fir=[];time_fir=[]; ss=1;
time=step:step:T_tot;
CmR(1:round(raitoEI*NR_node))=1; CmR(round(raitoEI*NR_node+1):NR_node)=0.5;
gL_R(1:round(raitoEI*NR_node)) = 0.025; gL_R(round(raitoEI*NR_node+1):NR_node) = 0.020;
v_thr=-50; v_reset=-65; tao_rp(1:round(raitoEI*NR_node))=2; tao_rp(round(raitoEI*NR_node+1):NR_node)=1;
t_fring_R(NR_node)=0;
for iii  = 1:Nt
    spike_R(vR>v_thr)=1;    spike_R(vR<=v_thr)=0;
    Rand_poissonR=rand (1,NR_node);
    P_poisson_R=1-exp(-r_poissonR1*step/1000);
    if iii>round(0.5*1000/step) && iii< round(1.0*1000/step), P_poisson_R=1-exp(-r_poissonR2*step/1000); end
    poissonSpikeR(P_poisson_R>Rand_poissonR)=1; poissonSpikeR(P_poisson_R<=Rand_poissonR)=0;
    drsynAMPA_R = rsynAMPA_R + step*(-rsynAMPA_R/tao_AMPA+spike_R);
    drsynAMPA_ext = rsynAMPA_ext + step*(-rsynAMPA_ext/tao_AMPA+gPoisson.*poissonSpikeR);
    drsynGABA_R = rsynGABA_R + step*(-rsynGABA_R/tao_GABA+spike_R);
    dx_NMDA_R   = x_NMDA_R + step*(-x_NMDA_R/tao_NMDA_rise+spike_R);
    drsynNMDA_R = rsynNMDA_R + step*(-rsynNMDA_R/tao_NMDA_decay+Alpha*x_NMDA_R.*(1-rsynNMDA_R));
    sum_rsynAMPA_R=sum(matrixR(1:round(raitoEI*NR_node),:).*rsynAMPA_R(1:round(raitoEI*NR_node))',1);
    sum_rsynNMDA_R=sum(matrixR(1:round(raitoEI*NR_node),:).*rsynNMDA_R(1:round(raitoEI*NR_node))',1);
    sum_rsynGABA_R=sum(matrixR(round(raitoEI*NR_node+1):NR_node,:).*rsynGABA_R(round(raitoEI*NR_node+1):NR_node)',1);
    Irec_AMPA_R=gAMPA_R.*sum_rsynAMPA_R.*(0-vR); Irec_NMDA_R=(gNMDA_R.*sum_rsynNMDA_R.*(0-vR))./(1+exp(-0.062*vR)/3.57);
    Irec_AMPA_ext=gAMPA_ext.*rsynAMPA_ext.*(0-vR); Irec_AMPA_ext(round(raitoEI*NR_node+1):NR_node)=0.0*Irec_AMPA_ext(round(raitoEI*NR_node+1):NR_node);
    Irec_GABA_R=gGABA_R.*sum_rsynGABA_R.*(-70-vR);
    Isny_R = Irec_AMPA_R + Irec_NMDA_R + Irec_GABA_R + Irec_AMPA_ext;
    IextR=0;
    vR(time(iii)-t_fring_R<=tao_rp)=v_reset;
    vR(vR>v_thr)=0; t_fring_R(vR>v_thr)=time(iii);
    dvR = vR + step*(-gL_R.*(vR+70)+Isny_R+IextR)./CmR;
    output_spike_R(:,iii)=spike_R;
    index_spike=find(spike_R==1);
    if isempty(index_spike)==0
        for jjj=1:length(index_spike)
            time_fir(ss)=time(iii);
            n_fir(ss)=index_spike(jjj);
            ss=ss+1;
        end
    end
    LFP_R(iii)=sum(vR(1:round(raitoEI*NR_node)))/(raitoEI*NR_node);
    rsynAMPA_R    = drsynAMPA_R; rsynAMPA_ext = drsynAMPA_ext;
    rsynGABA_R    = drsynGABA_R;
    x_NMDA_R      = dx_NMDA_R;
    rsynNMDA_R    = drsynNMDA_R;
    vR = dvR;
    if iii>1000/step
        flag_firing=flag_firing+sum(output_spike_R(:,iii),'all');
        flag_Spontaneous = 1;
        if iii>1100/step
            flag_firing=flag_firing-sum(output_spike_R(:,iii-round(100/step)),'all');
            if(flag_firing==0), break_time=time(iii)-1100; break; end
        end
        if iii==Nt, break_time=time(Nt)-1000; flag_persitent = 1; end
    end
end
T0=1000;
for ii=1:NR_node
    firIndex=find(n_fir==ii);
    nspike(ii)=length(find(time_fir(firIndex)>T0));
end
rate_fir=nspike/((T_tot-T0)*0.001);
time_fir_c = {time_fir};
n_fir_c = {n_fir};
