function [raw_svi_mod] = calibSviModelRaw(otm_option_table_)
% Function that calibrates single SVI slices
% In
%   otm_option_table_ [table]: OTM option table
% Out
%   raw_svi_mod [struct]: Calibrated SVI model

tau = otm_option_table_.ytm;
taus = unique(tau);
n_slices = length(taus);
try
    k = otm_option_table_.k;
catch
    k = log(otm_option_table_.strike_price./otm_option_table_.impl_forward);
end
%
try
%     bid_iv = otm_option_table_.impl_volatility_bid;
%     ask_iv = otm_option_table_.impl_volatility_ask;
    % TODO: Why not first calculate mid IV
%     mid_ivar = (bid_iv.^2+ask_iv.^2)/2;
%     mid_iv = (bid_iv+ask_iv)/2;
    mid_iv = otm_option_table_.impl_volatility_mid;
    mid_ivar = mid_iv.^2;%.*tau;
catch
    mid_iv = otm_option_table_.impl_volatility_mid;
    mid_ivar = mid_iv.^2;%.*tau;
end
% fit each slice idependently
a = zeros(n_slices,1);
b = zeros(n_slices,1);
rho = zeros(n_slices,1);
m = zeros(n_slices,1);
sigma = zeros(n_slices,1);
for i=1:n_slices
    isValid = ~isnan(mid_ivar);
    isRequested = (tau == taus(i)) & isValid;
    k_t = k(isRequested);
    impl_var_t = mid_ivar(isRequested);
    impl_vol_t = mid_iv(isRequested);
    vega = otm_option_table_.vega(isRequested);
    volume = otm_option_table_.volume(isRequested);
    % define bounds
    lb = [-10,0,-0.999,2*min(k_t),0.001];
    ub = [10,0.5/taus(i),0.999,2*max(k_t),1];
    % define optimization problem
    options = optimset('fmincon');
    options = optimset(options, 'algorithm', 'sqp');
    options = optimset(options, 'Display', 'off');
    nonlcon = @(params) makeCons(params, taus(i));
    fun = @(params) objFun(params, k_t, impl_vol_t, impl_var_t, vega, taus(i));
    % perform optimization N times with random start values
    N = 20;
    res = zeros(length(lb),N);
    fval = zeros(N,1);
    for n = 1:N
        % define initial guess
        x0 = generateRandomX0(lb, ub);
        x0(1) = min(impl_var_t);
        [res(:,n), fval(n)] = fmincon(fun, x0, [], [], [], [], lb, ub, ...
            nonlcon, options);
    end
    [~, idx] = min(fval);
    res = res(:,idx);
    % for Gatheral's approach
%     raw_svi_temp = makeSviModelRaw(res(1)*taus(i), res(2)*taus(i), ...
%         res(3), res(4), res(5), taus(i));
    raw_svi_temp = makeSviModelRaw(res(1), res(2), ...
        res(3), res(4), res(5), taus(i));
    % TODO ensure no slice arbitrage
%     raw_svi_temp_no_arb = calcSviModelNoBflyArb(raw_svi_temp, 'raw', 'raw');
    raw_svi_temp_no_arb = raw_svi_temp;
    a(i) = raw_svi_temp_no_arb.a;
    b(i) = raw_svi_temp_no_arb.b;
    rho(i) = raw_svi_temp_no_arb.rho;
    m(i) = raw_svi_temp_no_arb.m;
    sigma(i) = raw_svi_temp_no_arb.sigma;
end
raw_svi_mod = makeSviModelRaw(a', b', rho', m', sigma', taus');

end

function obj = objFun(params_, k_t_, impl_vol_t, impl_var_t_, vega_, tau_)

mod_tot_impl_var_t = params_(1)+params_(2).*(params_(3).*(k_t_- ...
    params_(4))+sqrt((k_t_-params_(4)).^2+params_(5).^2));
mod_i_vol_t = sqrt(mod_tot_impl_var_t/tau_);
minVar = params_(1)+params_(2)*params_(5)*sqrt(abs(1-params_(3)^2));
negVarPenalty = min(100,exp(-1/minVar));
obj = sum(vega_.*(impl_vol_t-mod_i_vol_t).^2)+negVarPenalty;
obj = obj*10000;

end

function [c, ceq] = makeCons(params_, tau_)

c = -(params_(1)*tau_+params_(2)*tau_.*params_(5).*sqrt(1-params_(3).^2));
ceq = 0;

end

function x0 = generateRandomX0(lb_, ub_)

x0 = lb_ + rand(size(lb_)).*(ub_-lb_);

end
