%% UNCONDITIONAL SECOND MOMENTS UNDER COUNTERFACTUAL POLICY RULE

% Tomas Caravello, Alisdair McKay, Christian Wolf

% this version: June 7, 2024

%% HOUSEKEEPING

clc
clear all
close all

warning('off','MATLAB:dispatcher:nameConflict')

path = '/Users/tomyc/Dropbox (MIT)/EACBN_2024/code';
session = '/2_mp_modelcnfctls';
experiment = '/applications/second_moments';

save_fig = 0;

addpath([path session '/suff_stats/ratex']);
addpath([path session '/suff_stats/behavioral_fixed']);
addpath([path session '/_auxiliary_functions'])
addpath([path session '/var_inputs/_results']);
cd([path session experiment]);

%% IMPORTS & SETTINGS

%----------------------------------------------------------------
% Experiment
%----------------------------------------------------------------

indic_1shock = 1; %if you want to use only the matched empirical shock to implement approximate counterfactual.

%----------------------------------------------------------------
% Policy Shock Sufficient Statistics
%----------------------------------------------------------------

% model selection for draws

indic_RE    = 0; %1 if you want to use Ratex only.
indic_behav = 0; %1 if you want to use behavioral only.
indic_joint = 1; %1 if you want to use the joint distribution between ratex and behavioral.

% import

if indic_1shock == 0

    import_suffstats

elseif indic_1shock == 1

    import_suffstats_1shock
end

% sizes

T       = size(Pi_m_draws,1);
n_draws = size(Pi_m_draws,3);

%----------------------------------------------------------------
% Wold IRFs
%----------------------------------------------------------------

load wold_results

wold_base = IS_wold.Theta_OLS([9 2 10],:,1:T); % variables: (pi, y, i)

series_names = series_names([9 2 10]);

n_y      = size(wold_base,1);
n_shocks = size(wold_base,2);

clear IS_wold

%----------------------------------------------------------------
% Specify Counterfactual Rule
%----------------------------------------------------------------

cnfctl_0y       = 0; % output gap targeting
cnfctl_0pi      = 0; % inflation targeting
cnfctl_0ib      = 0; % nominal rate peg
cnfctl_tylr     = 0; % Taylor rule
cnfctl_ngdp     = 0; % NGDP targeting
cnfctl_ibtarget = 0; % rate target
cnfctl_optpol   = 1; % optimal dual mandate

set_cnfctl_rule

%----------------------------------------------------------------
% Shock Space
%----------------------------------------------------------------

if indic_1shock == 0
    shock_max = T; % set = T for all shocks
elseif indic_1shock == 1
    shock_max = 1;
end

if shock_max < T
    disp('Note: I am not using all shocks.')
end

%% CONSTRUCT COUNTERFACTUAL WOLD IRFs

%----------------------------------------------------------------
% Counterfactual Posterior Draws
%----------------------------------------------------------------

wold_cnfctl = NaN(n_y,n_shocks,T,n_draws);

for i_draw = 1:n_draws
    
% get policy shock IRFs

Pi_m = Pi_m_draws(:,1:shock_max,i_draw);
Y_m  = Y_m_draws(:,1:shock_max,i_draw);
I_m  = I_m_draws(:,1:shock_max,i_draw);

for i_shock = 1:n_shocks

% get the corresponding base sequences

pi_z = squeeze(wold_base(1,i_shock,:));
y_z  = squeeze(wold_base(2,i_shock,:));
i_z  = squeeze(wold_base(3,i_shock,:));

% find best fit to counterfactual rule

if cnfctl_optpol == 0

[pi_z_cnfctl,y_z_cnfctl,i_z_cnfctl] = cnfctl_fn(A_pi,A_y,A_i,wedge,...
    Pi_m,Y_m,I_m,pi_z,y_z,i_z);

elseif cnfctl_optpol == 1

[pi_z_cnfctl,y_z_cnfctl,i_z_cnfctl] = optpol_fn(W_pi,W_y,W_i,...
    Pi_m,Y_m,I_m,pi_z,y_z,i_z);

end

wold_cnfctl(1,i_shock,:,i_draw) = pi_z_cnfctl;
wold_cnfctl(2,i_shock,:,i_draw) = y_z_cnfctl;
wold_cnfctl(3,i_shock,:,i_draw) = i_z_cnfctl;

end

end

%----------------------------------------------------------------
% Construct Percentiles
%----------------------------------------------------------------

wold_cnfctl_lb  = quantile(wold_cnfctl,0.16,4);
wold_cnfctl_med = quantile(wold_cnfctl,0.5,4);
wold_cnfctl_ub  = quantile(wold_cnfctl,0.84,4);

%----------------------------------------------------------------
% Individual Models
%----------------------------------------------------------------

n_models     = 2;

if indic_behav == 1
    model_names = {'B-RANK','B-HANK'};
else
    model_names = {'RANK','HANK'};
end
wold_cnfctl_models = NaN(n_y,n_shocks,T,n_models,n_draws);

for i_model = 1:n_models
    
for i_draw = 1:n_draws
    
% get policy shock IRFs

if i_model == 1

    Pi_m = Pi_m_rank_draws(:,1:shock_max,i_draw);
    Y_m  = Y_m_rank_draws(:,1:shock_max,i_draw);
    I_m  = I_m_rank_draws(:,1:shock_max,i_draw);

elseif i_model == 2

    Pi_m = Pi_m_hank_draws(:,1:shock_max,i_draw);
    Y_m  = Y_m_hank_draws(:,1:shock_max,i_draw);
    I_m  = I_m_hank_draws(:,1:shock_max,i_draw);
end

for i_shock = 1:n_shocks

% get the corresponding base sequences

pi_z = squeeze(wold_base(1,i_shock,:));
y_z  = squeeze(wold_base(2,i_shock,:));
i_z  = squeeze(wold_base(3,i_shock,:));

% find best fit to counterfactual rule

if cnfctl_optpol == 0

[pi_z_cnfctl,y_z_cnfctl,i_z_cnfctl] = cnfctl_fn(A_pi,A_y,A_i,wedge,...
    Pi_m,Y_m,I_m,pi_z,y_z,i_z);

elseif cnfctl_optpol == 1

[pi_z_cnfctl,y_z_cnfctl,i_z_cnfctl] = optpol_fn(W_pi,W_y,W_i,...
    Pi_m,Y_m,I_m,pi_z,y_z,i_z);

end

wold_cnfctl_models(1,i_shock,:,i_model,i_draw) = pi_z_cnfctl;
wold_cnfctl_models(2,i_shock,:,i_model,i_draw) = y_z_cnfctl;
wold_cnfctl_models(3,i_shock,:,i_model,i_draw) = i_z_cnfctl;

end

end

end

%% GET COUNTERFACTUAL BUSINESS-CYCLE STATISTICS

%----------------------------------------------------------------
% Baseline
%----------------------------------------------------------------

% VMA-implied variance-covariance matrix

base.cov = zeros(n_y,n_y);
for i_hor = 1:T
    base.cov = base.cov + wold_base(:,:,i_hor) * wold_base(:,:,i_hor)';
end

% correlations

base.corr = zeros(n_y,n_y);
for i_y = 1:n_y
    for ii_y = 1:n_y
        base.corr(i_y,ii_y) = base.cov(i_y,ii_y)/sqrt(base.cov(i_y,i_y) * base.cov(ii_y,ii_y));
    end
end

% frequency bands

omega_1 = (2*pi)/32;
omega_2 = (2*pi)/6;

base.freq_cov = diag(freq_var_fn(wold_base,omega_1,omega_2));

%----------------------------------------------------------------
% Counterfactual (draws)
%----------------------------------------------------------------

% VMA-implied variance-covariance matrix

cnfctl.cov = zeros(n_y,n_y,n_draws);
for i_draw = 1:n_draws
    for i_hor = 1:T
        cnfctl.cov(:,:,i_draw) = cnfctl.cov(:,:,i_draw) + wold_cnfctl(:,:,i_hor,i_draw) * wold_cnfctl(:,:,i_hor,i_draw)';
    end
end

cnfctl.cov_lb  = quantile(cnfctl.cov,0.16,3);
cnfctl.cov_med = quantile(cnfctl.cov,0.5,3);
cnfctl.cov_ub  = quantile(cnfctl.cov,0.84,3);

% correlations

cnfctl.corr = zeros(n_y,n_y,n_draws);
for i_draw = 1:n_draws
    for i_y = 1:n_y
        for ii_y = 1:n_y
            cnfctl.corr(i_y,ii_y,i_draw) = cnfctl.cov(i_y,ii_y,i_draw)/sqrt(cnfctl.cov(i_y,i_y,i_draw) * cnfctl.cov(ii_y,ii_y,i_draw));
        end
    end
end

cnfctl.corr_lb  = quantile(cnfctl.corr,0.16,3);
cnfctl.corr_med = quantile(cnfctl.corr,0.5,3);
cnfctl.corr_ub  = quantile(cnfctl.corr,0.84,3);

% frequency bands

cnfctl.freq_cov = zeros(n_y,n_draws);

for i_draw = 1:n_draws
    cnfctl.freq_cov(:,i_draw) = diag(freq_var_fn(wold_cnfctl(:,:,:,i_draw),omega_1,omega_2));
end

cnfctl.freq_cov_lb  = quantile(cnfctl.freq_cov,0.16,2);
cnfctl.freq_cov_med = quantile(cnfctl.freq_cov,0.5,2);
cnfctl.freq_cov_ub  = quantile(cnfctl.freq_cov,0.84,2);

%----------------------------------------------------------------
% Counterfactual (models)
%----------------------------------------------------------------

% VMA-implied variance-covariance matrix

cnfctl_models.cov = zeros(n_y,n_y,n_models,n_draws);
for i_model = 1:n_models
    for i_draw = 1:n_draws
        for i_hor = 1:T
            cnfctl_models.cov(:,:,i_model,i_draw) = cnfctl_models.cov(:,:,i_model,i_draw) ...
                + wold_cnfctl_models(:,:,i_hor,i_model,i_draw) * wold_cnfctl_models(:,:,i_hor,i_model,i_draw)';
        end
    end
end

cnfctl_models.cov = quantile(cnfctl_models.cov,0.5,4);

%% PLOT COUNTERFACTUALS

%----------------------------------------------------------------
% General Settings
%----------------------------------------------------------------

% show Wold rotations?

plot_wold = 0;

% plot horizon

IRF_hor_plot = 30;

% color settings

settings.colors.black  = [0 0 0];
settings.colors.dgrey  = [130/255 130/255 130/255];
settings.colors.blue   = [116/255 158/255 178/255];
settings.colors.lblue  = 0.25 * settings.colors.blue + 0.75 * [1 1 1];
settings.colors.models = [196/255 174/255 120/255; ... % beige
                            204/255 0/255 0/255; ... % red
                            102/255 178/255 255/255; % blue
                            32/255, 119/255, 34/255]; %orange 

% plot size

plotwidth = 0.27;
gapsize = 0.05;
gapsize_edges = (1-3*plotwidth-2*gapsize)/2;
left_pos = [gapsize_edges, gapsize_edges + gapsize + plotwidth, gapsize_edges + 2 * gapsize + 2 * plotwidth];

%----------------------------------------------------------------
% Posterior Standard Deviations
%----------------------------------------------------------------

if indic_RE == 1
    cd([path session experiment '/_results/RE']);
elseif indic_behav == 1
    cd([path session experiment '/_results/behav']);
elseif indic_joint == 1
    cd([path session experiment '/_results/joint']);
end

n_kernel = 1001;
n_gap    = 20;

figure(1)

for i_y = 1:n_y

grid_lb       = 0;
grid_ub       = 2 * max(sqrt(cnfctl.cov_ub(i_y,i_y)),sqrt(base.cov(i_y,i_y)));
grid_plot     = linspace(grid_lb,grid_ub,n_kernel)';
dist_plot     = kernel(grid_plot,winsorize(squeeze(sqrt(cnfctl.cov(i_y,i_y,:))),95),0.4);
dist_plot     = dist_plot ./ sum(dist_plot);

plot_lb_indx = find(dist_plot ~= 0, 1 );
plot_ub_indx = find(dist_plot ~= 0, 1, 'last' );

[~,base_pos] = min(abs(grid_plot - sqrt(base.cov(i_y,i_y))));

plot_lb_indx = max(min(plot_lb_indx - n_gap, base_pos - n_gap), 1);
plot_ub_indx = min(max(plot_ub_indx + n_gap, base_pos + n_gap), n_kernel);

subplot(1,3,i_y)
pos = get(gca, 'Position');
set(gca,'FontSize',16)
set(gca,'TickLabelInterpreter','latex')
pos(1) = left_pos(i_y);
pos(3) = plotwidth;
set(gca,'Position', pos)
hold on
plot(0,0,':','Color',settings.colors.black,'LineWidth',4)
hold on
plot(0,0,'Color',settings.colors.blue,'LineWidth',4)
hold on
for i_model = 1:n_models
    plot(0,0,'-','Color',settings.colors.models(i_model,:),'LineWidth',4)
    hold on
end
hold on
plot(grid_plot,dist_plot,'Color',settings.colors.blue,'LineWidth',4)
hold on
jbfill(grid_plot,0*dist_plot,dist_plot,...
    settings.colors.lblue,settings.colors.lblue,0,0.5);
hold on
plot([sqrt(base.cov(i_y,i_y)) sqrt(base.cov(i_y,i_y))],[0 1],':','Color',settings.colors.black,'LineWidth',4)
hold on
for i_model = 1:n_models
    plot([sqrt(cnfctl_models.cov(i_y,i_y,i_model)) sqrt(cnfctl_models.cov(i_y,i_y,i_model))],[0 1],'-','Color',settings.colors.models(i_model,:),'LineWidth',4)
    hold on
end
xlim([grid_plot(plot_lb_indx) grid_plot(plot_ub_indx)])
ylim([0 1.2 * max(dist_plot)])
% yticks([])
xlabel('St. Dev.','interpreter','latex','FontSize',20)
set(gcf,'color','w')
title(series_names(i_y),'interpreter','latex','fontsize',24)
grid on
if i_y == 1
    legend(cat(2,{'Data','Counterfct''l'},model_names),'Location','Southeast','fontsize',18,'interpreter','latex','NumColumns',2)
end
hold off

end

pos = get(gcf, 'Position');
set(gcf, 'Position', [pos(1) pos(2) 2.25*pos(3) 1.25*pos(4)]);
set(gcf, 'PaperPositionMode', 'auto');

if save_fig ==1
    if indic_1shock == 0
        if cnfctl_optpol == 1
            print('cnfctl_histograms_optpol','-dpng');
        elseif cnfctl_tylr == 1
            print('cnfctl_histograms_tylr','-dpng');
        end
    elseif indic_1shock == 1
        if cnfctl_optpol == 1
            print('cnfctl_histograms_optpol_1shock','-dpng');
        end
    end
end
    
cd([path session experiment]);

%----------------------------------------------------------------
% Wold Shocks
%----------------------------------------------------------------

if plot_wold == 1

for i_shock = 1:n_shocks

figure(1+i_shock)

for i_y = 1:n_y

subplot(1,3,i_y)
pos = get(gca, 'Position');
set(gca,'FontSize',16)
set(gca,'TickLabelInterpreter','latex')
pos(1) = left_pos(i_y);
pos(3) = plotwidth;
set(gca,'Position', pos)
hold on
jbfill(0:1:IRF_hor_plot,(squeeze(wold_cnfctl_lb(i_y,i_shock,1:IRF_hor_plot+1)))',(squeeze(wold_cnfctl_ub(i_y,i_shock,1:IRF_hor_plot+1)))',...
    settings.colors.lblue,settings.colors.lblue,0,1);
hold on
plot(0:1:IRF_hor_plot,(squeeze(wold_base(i_y,i_shock,1:IRF_hor_plot+1)))',':','Color',settings.colors.dgrey,'LineWidth',4)
hold on
plot(0:1:IRF_hor_plot,(squeeze(wold_cnfctl_med(i_y,i_shock,1:IRF_hor_plot+1)))','Color',settings.colors.blue,'LineWidth',4)
hold on
% xlim([1 IRF_hor_plot])
% ylim([-2 2])
% yticks([-2 -1 0 1 2])
set(gcf,'color','w')
title(series_names(i_y),'interpreter','latex','fontsize',24)
xlabel('Horizon','interpreter','latex','FontSize',20)
if i_y == 1
    ylabel('\% Deviation','interpreter','latex','FontSize',20)
end
grid on
hold off

end

pos = get(gcf, 'Position');
set(gcf, 'Position', [pos(1) pos(2) 2.25*pos(3) 1.25*pos(4)]);
set(gcf, 'PaperPositionMode', 'auto');

end

end