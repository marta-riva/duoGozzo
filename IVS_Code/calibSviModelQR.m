function [svi_mod_calib] = calibSviModelQR(otm_option_table_, phi_fun_, ...
    mod_)
% Function that calibrates an entire SVI surface free of stati arbitrage
% In
%   otm_option_table_ [table]: OTM option table
%   phi_fun_ [char]: 'heston_like', 'power_law' or 'square_root'
%   mod_ [char]: 'raw','jw', 'nat' or 'surf'
% Out
%   svi_mod_calib [struct]: Calibrated SVI model

if nargin < 3
    mod_ = 'raw';
end
vega = otm_option_table_.vega;
tau = otm_option_table_.ytm;
taus = unique(tau);
impl_vol = otm_option_table_.impl_volatility_mid;
tot_impl_var = impl_vol.^2.*tau;
try
    k = otm_option_table_.k;
catch
    k = log(otm_option_table_.strike_price./otm_option_table_.impl_forward);
end
% fit SVI surface by estimating parameters subject to parameter bounds:
% -1 < rho < 1, 0 < lambda
% and constraints: in heston_like: (1 + |rho|) <= 4 lambda
% in power-law: eta(1+|rho|) <= 2
surf_svi_mod = calibSviModelSurf(otm_option_table_, phi_fun_);
% transform SSVI parameters to raw SVI parameters
raw_svi_mod = makeSviModelConversion(surf_svi_mod, 'surf', 'raw');
% iterate through each maturity and fit raw SVI
raw_svi_mod_calib = raw_svi_mod;
for t = length(taus):-1:1
    isRequested = (tau==taus(t));
    k_t = k(isRequested);
    tot_impl_var_t = tot_impl_var(isRequested);
    impl_vol_t = impl_vol(isRequested);
    if (t == length(taus))
        raw_svi_mod_before = makeSviModelReduce(raw_svi_mod, taus(t-1));
        raw_svi_mod_after = [];
    elseif (t == 1)
        raw_svi_mod_before = [];
        raw_svi_mod_after = makeSviModelReduce(raw_svi_mod_calib, taus(t+1));
    else
        raw_svi_mod_before = makeSviModelReduce(raw_svi_mod, taus(t-1));
        raw_svi_mod_after = makeSviModelReduce(raw_svi_mod_calib, taus(t+1));
    end
    raw_svi_mod_t = makeSviModelReduce(raw_svi_mod, taus(t));
    raw_svi_mod_calib.ts(t) = taus(t);
    [raw_svi_mod_calib.a(t), raw_svi_mod_calib.b(t), ...
        raw_svi_mod_calib.rho(t), raw_svi_mod_calib.m(t), ...
        raw_svi_mod_calib.sigma(t)] = recalibSviModelRaw(raw_svi_mod_t, ...
        raw_svi_mod_before, raw_svi_mod_after, k_t, tot_impl_var_t, ...
        impl_vol_t, vega(isRequested));
end
svi_mod_calib = makeSviModelConversion(raw_svi_mod_calib, 'raw', mod_);

end

function [a, b, rho, m, sigma] = recalibSviModelRaw(raw_svi_mod_t_, ...
    raw_svi_before_, raw_svi_after_, k_t_, tot_impl_var_t_, ...
    impl_vol_t_, vega_t_)

tau = raw_svi_mod_t_.ts;
a = raw_svi_mod_t_.a;
b = raw_svi_mod_t_.b;
rho = raw_svi_mod_t_.rho;
m = raw_svi_mod_t_.m;
sigma = raw_svi_mod_t_.sigma;
% define initial guess
x0 = [a, b, rho, m, sigma];
% variable bounds
lb = [-10,0,-0.999,2*min(k_t_),0.001];
ub = [10,0.5/tau,0.999,2*max(k_t_),1];
% define optimization problem
options = optimset('fmincon');
options = optimset(options, 'algorithm', 'sqp');
options = optimset(options, 'Display', 'off');
% define constraints
nonlcon = @(params) makeCons(params, tau);
fun = @(params) objFun(params, x0, k_t_, tau, tot_impl_var_t_, ...
    impl_vol_t_, vega_t_, raw_svi_before_, raw_svi_after_);
[res, fval] = fmincon(fun, x0, [], [], [], [], lb, ub, nonlcon, options);
% use ga to find solution if optimizer gets stuck
% optionsGa = gaoptimset(@ga);
% optionsGa = gaoptimset(optionsGa, 'Display', 'off');
% optionsGa = gaoptimset(optionsGa, 'MutationFcn', @mutationadaptfeasible);
% if fval==1e6
%     optionsGa = gaoptimset(optionsGa, 'InitialPopulation', x0);
% else
%     optionsGa = gaoptimset(optionsGa, 'InitialPopulation', [x0; res]);
% end
% optionsGa = gaoptimset(optionsGa, 'HybridFcn', {@fmincon, options});
% [res, ~] = ga(fun, length(x0), [], [], [], [], lb, ub, nonlcon, optionsGa);
a = res(1);
b = res(2);
rho = res(3);
m = res(4);
sigma = res(5);

end

function obj = objFun(params_, params_0_, k_t_, tau_, tot_impl_var_t_, ...
    impl_vol_t_, vega_t_, raw_svi_before_, raw_svi_after_)

mod_tot_impl_var_t = params_(1)+params_(2).*(params_(3).*(k_t_- ...
    params_(4))+sqrt((k_t_-params_(4)).^2+params_(5).^2));
mod_i_vol_t = sqrt(mod_tot_impl_var_t/tau_);
sqDist_t = sum(vega_t_.*(mod_i_vol_t-impl_vol_t_).^2);
mod_tot_impl_var_t_0 = params_0_(1)+params_0_(2).*(params_0_(3).*(k_t_- ...
    params_0_(4))+sqrt((k_t_-params_0_(4)).^2+params_0_(5).^2));
mod_i_vol_t_0 = sqrt(mod_tot_impl_var_t_0/tau_);
sqDist_t_0 = sum(vega_t_.*(mod_i_vol_t_0-impl_vol_t_).^2);
obj = sqDist_t/sqDist_t_0 + calcPenalty(params_, raw_svi_before_, ...
    raw_svi_after_);

end

function [cross_penalty] = calcPenalty(params_, raw_svi_before_, ...
    raw_svi_after_)

raw_svi_t_.ts = NaN;
raw_svi_t_.a = params_(1);
raw_svi_t_.b = params_(2);
raw_svi_t_.rho = params_(3);
raw_svi_t_.m = params_(4);
raw_svi_t_.sigma = params_(5);
if (~isempty(raw_svi_before_))
    [~, crossedness] = calcSviRoots(raw_svi_before_, raw_svi_t_);
    cross_penalty = crossedness;
else
    minVar = params_(1)+params_(2)*params_(5)*sqrt(abs(1-params_(3)^2));
    negVarPenalty = min(100,exp(-1/minVar));
    cross_penalty = negVarPenalty;
end
if (~isempty(raw_svi_after_))
    [~, crossedness] = calcSviRoots(raw_svi_after_, raw_svi_t_);
    cross_penalty = cross_penalty + crossedness;
end
cross_penalty = cross_penalty*10000;

end

function [c, ceq] = makeCons(params_, tau_)

c = -(params_(1)*tau_+params_(2)*tau_.*params_(5).*sqrt(1-params_(3).^2));
ceq = 0;

end
