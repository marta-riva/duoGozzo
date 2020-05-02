function [svi_mod_new] = calcSviModelNoBflyArb(svi_mod_, from_, to_, plot_)
% This function returns an SVI parametrization free of butterfly arbitrage
% In
%   svi_mod_ [struct]: SVI parametrization
%   from_ [char]: Parametrization ('raw', 'surf', 'nat' or 'jw')
%   to_ [char]: Parametrization ('raw', 'surf', 'nat' or 'jw')
%   plot_ [char]: True for producing plot, false otherwise
% Out
%   svi_mod_new [struct]: SVI parametrization

if (nargin < 4)
    plot_ = false;
end
tau = svi_mod_.ts;
jw_svi_mod = makeSviModelConversion(svi_mod_, from_, 'jw');
% fixing the model temporarly
v_ts = jw_svi_mod.v_ts;
psi_ts = jw_svi_mod.psi_ts;
p_ts = jw_svi_mod.p_ts;
% Gatheral, 2014, p. 68 
c_prime_ts = p_ts+2.*psi_ts;
v_tilde_prime_ts = v_ts.*4.*p_ts.*c_prime_ts./(p_ts+c_prime_ts).^2;
% define fixed model
jw_svi_mod_fix = jw_svi_mod;
jw_svi_mod_fix.c_ts = c_prime_ts;
jw_svi_mod_fix.v_tilde_ts  = v_tilde_prime_ts;
% define strike grid
k = (-0.8:0.001:0.3)';
bs_mod = makeBsModel(sqrt(calcSviTotIvarQs(jw_svi_mod, k, 'jw')));
option = makeVanillaOption(exp(k), ones(size(k)), ones(size(k)));
mkt_data = makeMarketData(NaN, ones(size(k)), zeros(size(k)), NaN);
% calculate option prices to match
target_call_prices = calcBsPriceAnalytic(bs_mod, option, mkt_data,'forward');
% calculate IV to match
target_impl_vol = sqrt(calcSviTotIvarQs(jw_svi_mod, k, 'jw')/tau);
% define ojective function
fun = @(params) objFun(params, jw_svi_mod, target_call_prices, ...
    target_impl_vol, k);
% define bounds
upper_c_ts = max(jw_svi_mod.c_ts,jw_svi_mod_fix.c_ts);
lower_c_ts = min(jw_svi_mod.c_ts,jw_svi_mod_fix.c_ts);
upper_upper_v_tilde_ts = max(jw_svi_mod.v_tilde_ts,...
    jw_svi_mod_fix.v_tilde_ts);
lower_upper_v_tilde_ts = min(jw_svi_mod.v_tilde_ts,...
    jw_svi_mod_fix.v_tilde_ts);
lb = [lower_c_ts lower_upper_v_tilde_ts];
ub = [upper_c_ts upper_upper_v_tilde_ts];
% define initial guess
x0 = [jw_svi_mod.c_ts, jw_svi_mod.v_tilde_ts];
% define options
options = optimset('fmincon');
options = optimset(options, 'algorithm', 'sqp');
options = optimset(options, 'Display', 'off');
% optimize
[res, ~] = fmincon(fun, x0, [], [], [], [], lb, ub, [], options);
% define new model
jw_svi_mod_new = jw_svi_mod;
jw_svi_mod_new.c_ts = res(1);
jw_svi_mod_new.v_tilde_ts = res(2);
%
svi_mod_new = makeSviModelConversion(jw_svi_mod_new,'jw',to_);
if plot_
    % plot for inspection -------------------------------------------------
    k = (-1.5:0.05:1.5)';
    g_fix = calcSviDensity(jw_svi_mod_fix, k, 'jw');
    w_fix = calcSviTotIvarQs(jw_svi_mod_fix, k, 'jw');
    g_raw = calcSviDensity(jw_svi_mod, k, 'jw');
    w_raw = calcSviTotIvarQs(jw_svi_mod, k, 'jw');
    w_new = calcSviTotIvarQs(jw_svi_mod_new, k, 'jw');
    g_new = calcSviDensity(jw_svi_mod_new, k, 'jw');
    % total variance
    figure
    plot(k,w_fix,'o')
    hold on
    plot(k,w_raw,'o')
    plot(k,w_new,'-')
    yline(0,'k--');
    % density
    figure
    plot(k,g_fix,'o')
    hold on
    plot(k,g_raw,'o')
    plot(k,g_new,'-')
    yline(0,'k--');
    % ---------------------------------------------------------------------
end

end

function obj = objFun(params_, jw_svi_mod_, target_call_prices_, ...
    target_impl_vol, k_)
% Objective function
% In
%   params_ [vector]: SVI parameters
%   jw_svi_mod_ [struct]: JW-paramterization
%   target_call_prices_ [vector]: Vector of call prices
%   target_impl_vol [vector]: Vector of implied volatilities
%   k_ [vector]: Vector of log moneyness

tau = jw_svi_mod_.ts;
jw_svi_mod_.c_ts = params_(1);
jw_svi_mod_.v_tilde_ts = params_(2);
%
bs_mod_fun = makeBsModel(sqrt(calcSviTotIvarQs(jw_svi_mod_, k_, 'jw')));
mod_impl_vol = sqrt(calcSviTotIvarQs(jw_svi_mod_, k_, 'jw')/tau);
option_fun = makeVanillaOption(exp(k_), ones(size(k_)), ones(size(k_)));
mkt_data_fun = makeMarketData(NaN, ones(size(k_)), zeros(size(k_)), NaN);
newCallPrices = calcBsPriceAnalytic(bs_mod_fun, option_fun, mkt_data_fun, 'forward');
%
arbVal = calcSviArbBfly(jw_svi_mod_,'jw');
%
obj = sum((newCallPrices-target_call_prices_).^2)+100*arbVal.gArb.^2;
% obj = sum((mod_impl_vol-target_impl_vol).^2)+100*arbVal.gArb.^2;

end
