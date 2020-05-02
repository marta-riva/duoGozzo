% Test script Gatheral's anlysis
clc
clear
close all
set(groot, 'defaultAxesFontSize', 10);
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');

%% Define models
vogtRawSvi = makeSviModelRaw(-0.0410,0.1331,0.3060,0.3586,0.4153,1);
vogtNatSvi = makeSviModelConversion(vogtRawSvi,'raw','nat');
vogtJWSvi = makeSviModelConversion(vogtRawSvi,'raw','jw');

%% Test converters
% vogtParamsRawSvi = makeSviModelRaw(-0.0410,0.1331,0.3060,0.3586,0.4153,1);
% vogtParamsJWSvi = makeSviModelJW(1,0.01742625,-0.1752111,0.6997381, ...
%   1.316798,0.0116249);
% vogtParamsNatSvi = makeSviModelNat(-0.093624903235478,0.492084867241300, ...
%   0.3060,0.116123109998804,2.292394683562490,1);
% vogtParamsRawSvi_ = makeSviModelConversion(vogtParamsJWSvi,'jw','raw');
% vogtParamsRawSvi__ = makeSviModelConversion(vogtParamsNatSvi,'nat','raw');
% vogtParamsJWSvi_ = makeSviModelConversion(vogtParamsRawSvi,'raw','jw');
% vogtParamsJWSvi__ = makeSviModelConversion(vogtParamsNatSvi,'nat','jw');
% vogtParamsNatSvi_ = makeSviModelConversion(vogtParamsRawSvi,'raw','nat');
% vogtParamsNatSvi__ = makeSviModelConversion(vogtParamsJWSvi,'jw','nat');

% Plot total implied variance
k = (-1.5:0.05:1.5)';
% Total variance
w_nat = calcSviTotIvarQs(vogtNatSvi,k,'nat');
w_raw = calcSviTotIvarQs(vogtRawSvi,k,'raw');
w_jw = calcSviTotIvarQs(vogtJWSvi,k,'jw');
figure
plot(k,w_nat,'*')
hold on
plot(k,w_raw,'o')
plot(k,w_jw,'-')
% Plot density
g_nat = calcSviDensity(vogtNatSvi, k, 'nat');
g_raw = calcSviDensity(vogtRawSvi, k, 'raw');
g_jw = calcSviDensity(vogtJWSvi,k,'jw');
figure
plot(k,g_nat,'*')
hold on
plot(k,g_raw,'o')
plot(k,g_jw,'-')

%% Eliminate Bfly Arbitrage
vogtJWSviNoArb = calcSviModelNoBflyArb(vogtJWSvi,'jw','jw',true);

%% Arbitrage-free Surface SVI
k = (-1.5:0.01:1.5)';
k_ = (-1.5:0.1:1.5)';
theta_ts = (0.1:0.1:1)';
ts = (0.1:0.1:1)';
rho = 0.3;
lambda = (1+abs(rho))/4 + 1;
phi = makeSviParametrization(lambda,'heston_like');
surfSvi_mod = makeSviModelSurf(ts, theta_ts, rho, phi);
natSvi_mod = makeSviModelConversion(surfSvi_mod,'surf','nat');
TotIvarSurf = zeros(length(k),length(theta_ts));
TotIvarNat = zeros(length(k_),length(theta_ts));
for i=1:length(ts)
    smallSurfSvi_mod = makeSviModelReduce(surfSvi_mod, ts(i));
    smallNatSvi_mod = makeSviModelReduce(natSvi_mod, ts(i));
    TotIvarSurf(:,i) = calcSviTotIvarQs(smallSurfSvi_mod, k, 'surf');
    TotIvarNat(:,i) = calcSviTotIvarQs(smallNatSvi_mod, k_, 'nat');
end
%
k__ = repmat(k,length(theta_ts),1);
ts_ = reshape(repmat(theta_ts',length(k),1),length(k__),1);
TotIvarSurf_ = calcSviSurf(surfSvi_mod, k__, ts_, 'surf', true);
% plot total variance
figure
plot(k,TotIvarSurf)
hold on
plot(k_,TotIvarNat,'ko')
xlabel('$\log(K/F_t)$ - Log Strike')
ylabel('$w$ - Implied Total Variance')

%% Test Data
load('_testData/_sviTest.mat')
% !!!! objective function needs to be adjusted (vega is set to NaN)
surf_svi_mod = calibSviModelSurf(otm_option_table, 'power_law');
raw_svi_mod_calib = calibSviModelQR(otm_option_table, 'power_law');

%% Plot
tau = otm_option_table.ytm;
taus = unique(tau);
impl_vol = otm_option_table.impl_volatility_mid;
tot_impl_var = impl_vol.^2.*tau;
k = otm_option_table.k;
calcSviSurf(surf_svi_mod, k, tau, 'surf', true);
k_ = (-1:0.01:1)';
k__ = repmat(k_,length(taus),1);
ts_ = reshape(repmat(taus',length(k_),1),length(k__),1);
calcSviSurf(surf_svi_mod, k__, ts_, 'surf', true);

[mod_tot_impl_var, mod_impl_vola] = calcSviSurf(raw_svi_mod_calib, k, tau, 'raw', true);
k_ = (floor(min(k)*10)/10:0.025:ceil(max(k)*10)/10)';
taus = unique(tau);
k__ = repmat(k_,length(taus),1);
ts_ = reshape(repmat(taus',length(k_),1),length(k__),1);
[~, plot_impl_vola] = calcSviSurf(surf_svi_mod, k__, ts_, 'surf', true);

X = unique(exp(k__));
Y = unique(ts_);
Z = reshape(plot_impl_vola,length(X),length(Y));
figure
surf(X,Y,Z','FaceColor','none','EdgeColor','interp')
hold on
plot3(exp(k),tau,impl_vol,'r*')
view(45,15)

%% Test Gatheral Data
load('_testData/_gatheral050915.mat')
% !!!! objective function needs to be adjusted (vega is set to NaN)
mod_calib = calibSviModelRaw(otm_option_table);
k = (-1:0.001:1)';
tau = otm_option_table.ytm;
taus = unique(tau);
k_ = repmat(k,length(taus),1);
t_ = reshape(repmat(taus',length(k),1),length(k_),1);
[~, ivol] = calcSviSurf(mod_calib, k_, t_, 'raw', true);
isValid = ~isnan(otm_option_table.impl_volatility_bid);
k_vol = log(otm_option_table.strike_price./otm_option_table.impl_forward);
for i=1:length(taus)
    isRequested = (tau == taus(i)) & isValid;
    bid_t = otm_option_table.impl_volatility_bid(isRequested);
    ask_t = otm_option_table.impl_volatility_ask(isRequested);
    mid_t = (bid_t+ask_t)/2;
    k_vol_t = k_vol(isRequested);
    k_t = k_(t_ == taus(i));
    t_t = t_(t_ == taus(i));
    figure
    plot(k_vol_t,mid_t,'*k')
    hold on
    plot(k_vol_t,ask_t,'*b')
    plot(k_vol_t,bid_t,'*r')
    plot(k_t,ivol(t_ == taus(i)),'color',[0.9100 0.4100 0.1700])
    axis([min(k_vol_t)-0.01 max(k_vol_t)+0.01 min(bid_t)-0.04 max(ask_t)+0.04])
end
