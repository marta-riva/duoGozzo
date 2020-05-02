function [u, tau, g, gamma] = calibFenglerSplineNodes(otm_option_table_)
% Function to calculate nodes of Fengler's smoothing spline
% In
%   otm_option_table_ [table] = OTM option table
% Out

% data
strike = otm_option_table_.strike_price;
forward = otm_option_table_.impl_forward;
maturity = otm_option_table_.ytm;
interest_rate = otm_option_table_.interest_rate;
impl_volatility = otm_option_table_.impl_volatility_mid;
% step 1: pre-smoother
fwd_moneyness = strike./forward;
% kappa = (floor(min(fwd_moneyness*10))/10):0.01:(ceil(max(fwd_moneyness*10))/10);
kappa = 0.4:0.01:1.4;
[pre_smooth_call_price, kappa, tau, forward_tau, interest_rate_tau] = ...
    calcFenglerPreSmoothedPrices(kappa', fwd_moneyness, maturity, ...
    impl_volatility, forward, interest_rate);
% step2: iterative smoothing of pricing surface
T = length(tau);
K = length(kappa);
g = zeros(K,T);
gamma = zeros(K,T);
u = zeros(K,T);
%
for t = T:-1:1
    u(:,t) = kappa*forward_tau(t);
    y = pre_smooth_call_price(:,t);
    n = length(u(:,t));
    h = diff(u(:,t));
    % inequality constraints A x <= b
    % -(g_2 - g_1)/h_1 + h_1/6 gamma(2) <= e^(-tau*r)
    %  (g_n - g_(n-1))/h_(n-1) + h_(n-1)/6 gamma(n-1) <= 0
    A = [1/h(1) -1/h(1) zeros(1,n-2) h(1)/6 zeros(1,n-3);
        zeros(1,n-2) -1/h(n-1) 1/h(n-1) zeros(1,n-3) h(n-1)/6];
    b = [exp(-tau(t)*interest_rate(t)); 0];
    % set-up lower bound
    lb = [max(exp(-interest_rate_tau(t)*tau(t))*(forward_tau(t)-u(:,t)'),0) zeros(1,n-2)];
    % set-up upper bound
    if t==T
        ub = [exp(-interest_rate_tau(t)*tau(t))*forward_tau(t) inf(1,2*n-3)];
    else
        ub = [exp(interest_rate_tau(t+1)*tau(t+1)-interest_rate_tau(t)*tau(t))*forward_tau(t)/forward_tau(t+1)*g(:,t+1)' inf(1,n-2)];
    end
    [g(:,t), gamma(:,t)] = solveFenglerQuadraticProgram(u(:,t), y, A, b, lb, ub);
end

end
