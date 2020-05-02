% Test script Fenlger smoothing approach
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
% Calculate implied forwards
Ifs = calcImpliedForwards(filtered_option_table, interp_Irs, ...
    underlying_table, divyield_table);
[Ids, rate_fe] = calcImpliedDivYield(underlying_table, interp_Irs, Ifs, ...
    divyield_table);
% Populate table with further columns
[~, idxs] = ismember(filtered_option_table.ytm, taus);
filtered_option_table.interest_rate = interp_Irs.zr_ts(idxs);
filtered_option_table.impl_forward = Ifs.qs(idxs);
filtered_option_table.impl_divyield = Ids.qs(idxs);
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
% Compute call prices
bs_mod = makeBsModel(otm_option_table.impl_volatility_mid);
option.cp_flag = ones(size(bs_mod.sigma));
otm_option_table.call_price = calcBsPriceAnalytic(bs_mod, option, mkt_data,...
    'forward');

%% Fengler
[u, tau, g, gamma] = calibFenglerSplineNodes(otm_option_table);
if any(gamma<0,'all')
    error('Gamma has to be greater equal zero')
elseif any(g<0,'all')
    error('Spline values have to be greater equal zero')
end
% Plot smiles
kappa = (0.4:0.01:1.4)';
kappa_grid = repmat(kappa,length(tau),1);
tau_grid = reshape(repmat(tau,1,length(kappa))', length(kappa_grid), 1);
[~, idxs] = ismember(tau_grid,Ifs.ts);
mkt_data_grid = makeMarketData(nan(size(idxs)), Ifs.qs(idxs), ...
    interp_Irs.zr_ts(idxs), nan(size(idxs)));
option_grid = makeVanillaOption(kappa_grid.*Ifs.qs(idxs), tau_grid, ...
    ones(size(idxs)));
[~, smooth_iv] = calcFenglerSmoothIvQs(u, tau, g, gamma, option_grid, ...
    mkt_data_grid, 'forward');
tau_ = otm_option_table.ytm;
k_ = otm_option_table.strike_price./otm_option_table.impl_forward;
for i=1:length(taus)
    isRequested = (tau_ == taus(i));
    bid_t = otm_option_table.impl_volatility_bid(isRequested);
    ask_t = otm_option_table.impl_volatility_ask(isRequested);
    mid_t = otm_option_table.impl_volatility_mid(isRequested);
    k_vol_t = k_(isRequested);
    k_t = kappa_grid(tau_grid == taus(i));
    subplot(ceil(length(taus)/2),2,i)
    plot(k_vol_t,mid_t,'ok','MarkerSize',4)
    hold on
    plot(k_vol_t,ask_t,'ob','MarkerSize',4)
    plot(k_vol_t,bid_t,'or','MarkerSize',4)
    plot(k_t,smooth_iv(tau_grid == taus(i)),'color',[0.91 0.41 0.17],'LineWidth',2)
    axis([min(k_vol_t)-0.01 max(k_vol_t)+0.01 min(mid_t)-0.04 max(mid_t)+0.04])
    xlabel('$\log(K/F_{t,T})$')
    ylabel('$\hat{\sigma}$')
    ylim([0.05,0.45])
    title(['\boldmath$\tau=$\textbf{',num2str(taus(i)),'}'])
    legend('Mid IV','Ask IV','Bid IV','Smoothed IV')
end
% Plot total variance smiles
figure
for i=1:length(taus)
    k_t = kappa_grid(tau_grid == taus(i));
    plot(kappa,smooth_iv(tau_grid == taus(i)).^2*taus(i),'LineWidth',1.5)
    hold on
end
legend(string(taus(i)))
xlabel('$K/F_{t,T}$ - Foward Moneyness')
xlim([0.6 1.4])
ylabel('$\hat{\sigma}^2\tau$ - Total Implied Variance')
title('\textbf{Calculation Date: 2017-12-20}')
legend(join([repmat('$\tau=$ ',size(taus)) string(taus)]))

%% Arbitrage free surface
kappa = (0.4:0.01:1.4)';
kappa_grid = repmat(kappa,length(tau),1);
tau_grid = reshape(repmat(tau,1,length(kappa))', length(kappa_grid), 1);
[~, idxs] = ismember(tau_grid,Ifs.ts);
mkt_data_grid = makeMarketData(nan(size(idxs)), Ifs.qs(idxs), ...
    interp_Irs.zr_ts(idxs), nan(size(idxs)));
option_grid = makeVanillaOption(kappa_grid.*Ifs.qs(idxs), tau_grid, ...
    ones(size(idxs)));
[~, smooth_iv] = calcFenglerSmoothIvQs(u, tau, g, gamma, option_grid, ...
    mkt_data_grid, 'forward');
figure
surf(kappa,tau,reshape(smooth_iv,length(kappa),length(tau))','FaceColor','none','EdgeColor',...
    'interp')
hold on
plot3(k_,tau_,otm_option_table.impl_volatility_mid,'ro')
xlim([0.4 1.4])
zlim([0 0.7])
zlabel('$\hat{\sigma}$ - Implied Volatility')
ylabel('$\tau$ - Tenor')
xlabel('$K/F_{t,T}$ - Forward Moneyness')
view(45,15)

%% Delta tenor interpolation
[~, idxs] = unique(option.tau);
mkt_data_unique = makeMarketData(mkt_data.S_t(idxs), mkt_data.F_t(idxs), ...
    mkt_data.zr(idxs), mkt_data.q(idxs));
delta_target = [(-0.05:-0.05:-0.45)';(0.5:-0.05:0.05)'];
tau_ = (365/12:365/12:1*365)'/365;
interp_Irs_ = interpZrFromIrs(raw_Irs, tau_, 'linear');
interp_Ifs_ = interp1(Ifs.ts, Ifs.qs, tau_, 'linear', 'extrap');
impl_volatility = zeros(length(delta_target), length(tau_));
for t = 1:length(tau_)
    tau_loop = tau_(t);
    interp_Irs_loop = interp_Irs_.zr_ts(t);
    interp_Ifs_loop = interp_Ifs_(t);
    for k = 1:length(delta_target)
        impl_volatility(k,t) = interpIvFromDeltaTau(delta_target(k), ...
            tau_loop, mkt_data_unique, interp_Irs_loop, interp_Ifs_loop, ...
            'forward', u, tau, g, gamma);
    end
end
% Plot
xcoords=-delta_target+sign(delta_target)*0.5;
figure
surf(xcoords,tau_,impl_volatility','FaceColor','none','EdgeColor',...
    'interp')
hold on
isRequested = (otm_option_table.ytm<=1 & otm_option_table.ytm>=30/365);
isRequested = isRequested & (option.K./mkt_data.F_t >= 0.6 & ...
    option.K./mkt_data.F_t <= 1.25);
xcoords_=-otm_option_table.delta+sign(otm_option_table.delta)*0.5;
xtickangle(90)
plot3(xcoords_(isRequested), option.tau(isRequested),...
    otm_option_table.impl_volatility_mid(isRequested),'ro');
view(45,15)
xlabel('$\delta^{BS}$ - Black-Scholes Delta')
xticks((-0.45:0.05:0.45))
xlim([-0.5 0.5])
xticklabels({'5P','10P','15P','20P','25P','30P','35P','40P','45P','ATM',...
    '45C','40C','35C','30C','25C','20C','15C','10C','5C'})
ylabel('$\tau$ - Tenor')
zlabel('$\hat{\sigma}$ - Implied Volatility')
