function surf_svi_mod = calibSviModelSurf(otm_option_table_, phi_fun_)
% Function that calibrates the SSVI surface
% In
%   otm_option_table_ [table]: OTM option table
%   phi_fun_ [char]: 'heston_like', 'power_law' or 'square_root'
% Out
%   surf_svi_mod [struct]: Calibrated SSVI model

vega = otm_option_table_.vega;
volume = otm_option_table_.volume;
tau = otm_option_table_.ytm;
impl_vol = otm_option_table_.impl_volatility_mid;
tot_impl_var = impl_vol.^2.*tau;
try
    k = otm_option_table_.k;
catch
    k = log(otm_option_table_.strike_price./otm_option_table_.impl_forward);
end
% use linear interpolation for ATM total implied variance
taus = sort(unique(tau));
theta = zeros(size(taus));
for i=1:length(taus)
    isRequested = (tau == taus(i));
    theta(i) = interp1(k(isRequested), tot_impl_var(isRequested), ...
        0, 'linear', 'extrap');
end
assert(all(theta>0))
%define bounds
lb = [-0.999,0];
ub = [0.999,inf];
nonlcon = @(params) makeCons(params, phi_fun_);
% define minimization problem
options = optimset('fmincon');
options = optimset(options, 'algorithm', 'interior-point');
options = optimset(options, 'Display', 'off');
surf_svi_mod = makeSviModelSurf(unique(tau), theta, NaN, NaN);
phi_fun = @(params) makeSviParametrization(params, phi_fun_);
fun = @(params) objFun(params, k, tau, surf_svi_mod, phi_fun, impl_vol, ...
    tot_impl_var, vega);
% perform optimization N times with random start values
N = 20;
res = zeros(length(lb),N);
fval = zeros(N,1);
for n = 1:N
    % define initial guess
    x0 = generateRandomX0(lb, ub);
    % using a try statement since the parameters could not pass the
    % assetions in `makeAssertionsSviRaw.m` or `makeAssertionsSviNat.m`
    try
        [res(:,n), fval(n)] = fmincon(fun, x0, [], [], [], [], lb, ub, ...
            nonlcon, options);
    catch ME
        if ~strcmp(ME.identifier,'MATLAB:assertion:failed')
            rethrow(ME)
        else
            fval(n) = 1e5;
        end
    end
end
[~, idx] = min(fval);
res = res(:,idx);
surf_svi_mod.rho = res(1);
surf_svi_mod.phi = phi_fun([res(2);1/2]);

end

function obj = objFun(params_, k_, tau_, surf_svi_mod_, phi_fun_, ...
    impl_vol_, tot_impl_var_, vega_)

% tau_cutoff = min(0.1,max(tau_));
% isReq = (tau_>=tau_cutoff);
surf_svi_mod_.rho = params_(1);
surf_svi_mod_.phi = phi_fun_([params_(2); 1/2]);
[mod_tot_impl_var, mod_impl_vol] = calcSviSurf(surf_svi_mod_, k_, tau_, 'surf');
obj = sum(vega_.*(impl_vol_-mod_impl_vol).^2);
obj = obj*10000;

end

function [c, ceq] = makeCons(params_, phi_fun_)

switch phi_fun_
    case 'heston_like'
        %by construction, rho is the first parameter, lamda the second  
        c = 1 + abs(params_(1)) - 4*params_(2);
    case 'power_law'
        %by construction, rho is the first parameter, eta the second
        c = params_(2) * (1 + abs(params_(1))) - 2;
    case 'square_root'
        %by construction, rho is the first parameter, eta the second
        c = params_(2) * (1 + abs(params_(1))) - 2;        
    otherwise
        error('Incorrect function for phi');
end
ceq = 0;

end

function x0 = generateRandomX0(lb_, ub_)

lb_(~isfinite(lb_)) = -10;
ub_(~isfinite(ub_)) = 10;
x0 = lb_ + rand(size(lb_)).*(ub_-lb_);

end
