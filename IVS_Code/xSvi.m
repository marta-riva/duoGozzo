% Test script SVI
clc
clear
close all
set(groot, 'defaultAxesFontSize', 10);
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');

%% Date
date = '2017-12-20';

%% Getting otm_option_table
% Get market options data from files
raw_option_table = getTableOptionFromFileSys(date);
% Get underlying and zero curves market data
underlying_table = getTableUnderlyingPrice(date);
zerocurve_table = getTableZeroCurve(date);
divyield_table = getTableDividendYield(date);
% Filter options data
filtered_option_table = makeTableOptionFiltered(raw_option_table);
% Make interest rates structure and interpolation
raw_Irs = makeIrsFromZeroCurve(zerocurve_table.rate, zerocurve_table.tenor);
taus = unique(filtered_option_table.ytm);
interp_Irs = interpZrFromIrs(raw_Irs, taus, 'linear');
% Calculate implied forwards and implied dividend yields
Ifs = calcImpliedForwards(filtered_option_table, interp_Irs, ...
    underlying_table, divyield_table);
% Populate table with further columns
[~, idxs] = ismember(filtered_option_table.ytm, taus);
filtered_option_table.interest_rate = interp_Irs.zr_ts(idxs);
filtered_option_table.impl_forward = Ifs.qs(idxs);
% Further filter options data - remove ITM options
otm_option_table = makeTableOptionOtm(filtered_option_table);
% Calculate implied volatilites
% define instrument
option = makeVanillaOption(otm_option_table.strike_price, ...
    otm_option_table.ytm, otm_option_table.cp_flag);
% define market data
mkt_data = makeMarketData(repmat(underlying_table.close, ...
    size(otm_option_table,1),1), otm_option_table.impl_forward, ...
    otm_option_table.interest_rate, repmat(divyield_table.rate, ...
    size(otm_option_table,1),1));
%
otm_option_table.impl_volatility_mid = calcIvJaeckel(otm_option_table.mid, ...
    option, mkt_data, 'forward');
otm_option_table.impl_volatility_bid = calcIvJaeckel(otm_option_table.best_bid, ...
    option, mkt_data, 'forward');
otm_option_table.impl_volatility_ask = calcIvJaeckel(otm_option_table.best_offer, ...
    option, mkt_data, 'forward');
% recalculate vega
bs_mod = makeBsModel(otm_option_table.impl_volatility_mid);
otm_option_table.vega = calcBsVegaAnalytic(bs_mod, option, mkt_data,...
    'forward');

%% SVI single slices
raw_svi_calib = calibSviModelRaw(otm_option_table);
k = (-1:0.001:1)';
tau = otm_option_table.ytm;
taus = unique(tau);
k_ = repmat(k,length(taus),1);
t_ = reshape(repmat(taus',length(k),1),length(k_),1);
[tot_ivar, ivol] = calcSviSurf(raw_svi_calib, k_, t_, 'raw', true);
isValid = ~isnan(otm_option_table.impl_volatility_mid);
k_vol = log(otm_option_table.strike_price./otm_option_table.impl_forward);
figure
for i=1:length(taus)
    isRequested = (tau == taus(i)) & isValid;
    bid_t = otm_option_table.impl_volatility_bid(isRequested);
    ask_t = otm_option_table.impl_volatility_ask(isRequested);
    mid_t = otm_option_table.impl_volatility_mid(isRequested);
    k_vol_t = k_vol(isRequested);
    k_t = k_(t_ == taus(i));
    t_t = t_(t_ == taus(i));
    subplot(ceil(length(taus)/2),2,i)
    plot(k_vol_t,mid_t,'ok','MarkerSize',4)
    hold on
    plot(k_vol_t,ask_t,'ob','MarkerSize',4)
    plot(k_vol_t,bid_t,'or','MarkerSize',4)
    plot(k_t,ivol(t_ == taus(i)),'color',[0.91 0.41 0.17],'LineWidth',2)
    axis([min(k_vol_t)-0.01 max(k_vol_t)+0.01 min(mid_t)-0.04 max(mid_t)+0.04])
    xlabel('$\log(K/F_{t,T})$')
    ylabel('$\hat{\sigma}$')
    ylim([0.05,0.45])
    title(['\boldmath$\tau=$\textbf{',num2str(taus(i)),'}'])
    legend('Mid IV','Ask IV','Bid IV','SVI fit')
end
calcSviArbBfly(raw_svi_calib,'raw')

%% SSVI
surf_svi_calib = calibSviModelSurf(otm_option_table, 'power_law');
[tot_ivar_surf, ivol_surf] = calcSviSurf(surf_svi_calib, k_, t_, 'surf', true);
figure
for i=1:length(taus)
    isRequested = (tau == taus(i)) & isValid;
    bid_t = otm_option_table.impl_volatility_bid(isRequested);
    ask_t = otm_option_table.impl_volatility_ask(isRequested);
    mid_t = otm_option_table.impl_volatility_mid(isRequested);
    k_vol_t = k_vol(isRequested);
    k_t = k_(t_ == taus(i));
    t_t = t_(t_ == taus(i));
    subplot(ceil(length(taus)/2),2,i)
    plot(k_vol_t,mid_t,'ok','MarkerSize',4)
    hold on
    plot(k_vol_t,ask_t,'ob','MarkerSize',4)
    plot(k_vol_t,bid_t,'or','MarkerSize',4)
    plot(k_t,ivol_surf(t_ == taus(i)),'color',[0.91 0.41 0.17],'LineWidth',2)
    axis([min(k_vol_t)-0.01 max(k_vol_t)+0.01 min(mid_t)-0.04 max(mid_t)+0.04])
    xlabel('$\log(K/F_{t,T})$')
    ylabel('$\hat{\sigma}$')
    ylim([0.05,0.45])
    title(['\boldmath$\tau=$\textbf{',num2str(taus(i)),'}'])
    legend('Mid IV','Ask IV','Bid IV','SSVI fit')
end

%% SVI surface
raw_svi_surf_calib = calibSviModelQR(otm_option_table, 'power_law');
calcSviArbBfly(raw_svi_surf_calib,'raw')
k_ = (floor(min(k_vol)*10)/10:0.01:ceil(max(k_vol)*10)/10)';
taus = unique(tau);
k__ = repmat(k_,length(taus),1);
ts_ = reshape(repmat(taus',length(k_),1),length(k__),1);
[~, plot_impl_vola] = calcSviSurf(raw_svi_surf_calib, k__, ts_, 'raw', true);
% Surface
X = unique(exp(k__));
Y = unique(ts_);
Z = reshape(plot_impl_vola,length(X),length(Y));
figure
surf(X,Y,Z','FaceColor','none','EdgeColor','interp')
hold on
plot3(exp(k_vol),tau,otm_option_table.impl_volatility_mid,'ro')
zlabel('$\hat{\sigma}$ - Implied Volatility')
ylabel('$\tau$ - Tenor')
xlabel('$K/F_{t,T}$ - Forward Moneyness')
view(45,15)
box on
% PDF
figure
for i=1:length(taus)
    reduced_raw = makeSviModelReduce(raw_svi_surf_calib, taus(i));
    density = calcSviDensity(reduced_raw, (-0.8:0.000001:0.3), 'raw');
    plot((-0.8:0.000001:0.3),density,'LineWidth',1.5)
    hold on
end
xlabel('$\log(K/F_{t,T})$ - Log Moneyness')
xlim([-0.8 0.3])
legend(join([repmat('$\tau=$ ',size(taus)) string(taus)]),'Location','NorthWest')
title('\textbf{Calculation Date: 2017-12-20}')
