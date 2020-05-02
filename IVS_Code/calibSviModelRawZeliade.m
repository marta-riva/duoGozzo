function [raw_svi_mod] = calibSviModelRawZeliade(otm_option_table_)
% Function that calibrates single SVI slices using Zeliade Quasi-Explicit
% calibration
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
    bid_iv = otm_option_table_.impl_volatility_bid;
    ask_iv = otm_option_table_.impl_volatility_ask;
%     mid_iv = otm_option_table_.impl_volatility_mid;
%     mid_iv = (bid_iv+ask_iv)/2;
    mid_tot_ivar = (bid_iv.^2+ask_iv.^2)/2.*tau;
%     mid_tot_ivar = mid_iv.^2.*tau;
catch
    mid_iv = otm_option_table_.impl_volatility_mid;
    mid_tot_ivar = mid_iv.^2.*tau;
end
% fit each slice idependently
a = zeros(n_slices,1);
b = zeros(n_slices,1);
rho = zeros(n_slices,1);
m = zeros(n_slices,1);
sigma = zeros(n_slices,1);
for i=1:n_slices
    isRequested = (tau == taus(i));
    k_t = k(isRequested);
    tot_ivar_t = mid_tot_ivar(isRequested);
    % define bounds
    lb = [2*min(k_t), 0.001];
    ub = [2*max(k_t), 1];
    % define optimization problem
%     options = optimset('fmincon');
%     options = optimset(options, 'algorithm', 'sqp');
%     options = optimset(options, 'Display', 'off');
    options_ = optimset('fminsearch');
    options_ = optimset(options_, 'Display', 'off');
    fun = @(params) solveGrad(params(2), params(1), k_t, tot_ivar_t, taus(i));
    % perform optimization N times with random start values
    N = 20;
    res = zeros(length(lb),N);
    fval = zeros(N,1);
    for n = 1:N
        % define initial guess
        x0 = generateRandomX0(lb, ub);
%         [res(:,n), fval(n)] = fmincon(fun, x0, [], [], [], [], lb, ub, [], options);
        [res(:,n), fval(n)] = fminsearch(fun, x0, options_);
    end
    [~, idx] = min(fval);
    res = res(:,idx);
    % get parameters
    [~, a_tilde, d, c] = solveGrad(res(2), res(1), k_t, tot_ivar_t, taus(i));
    % transform parameters
    a(i) = a_tilde;
    b(i) = c/res(2);
    sigma(i) = res(2);
    rho(i) = d/(b(i)*sigma(i));
    m(i) = res(1);
end
% define model
raw_svi_mod = makeSviModelRaw(a', b', rho', m', sigma', taus');

end

function obj = objFun(ys_, a_tilde_, d_, c_, tot_ivar_t_, sigma_, tau_)

% a = a_tilde_;
% b = c_/sigma_;
% rho = d_/(b*sigma_);
% minVar = a+b*sigma_*sqrt(abs(1-rho^2));
% negVarPenalty = min(100,exp(-1/minVar));
% absRhoPenalty = 100*(abs(rho)>0.999);
obj = sum((a_tilde_+d_.*ys_+c_.*sqrt(ys_.^2+1)-tot_ivar_t_).^2);
% loss = sum((sqrt(a_tilde_+d_.*ys_+c_.*sqrt(ys_.^2+1))-sqrt(tot_ivar_t_)).^2);
% loss = sqrt(sum(((a_tilde_+d_.*ys_+c_.*sqrt(ys_.^2+1))/tau_-tot_ivar_t_/tau_).^2));
% loss = loss+negVarPenalty;
% loss = loss+absRhoPenalty;
% loss = loss*10000;

end

function flag = isInteriorD(sigma_, a_tilde, d_, c_, tot_ivar_t_)

isValid_c = (0 <= c_) && (c_ <= 4*sigma_);
isValid_d = (abs(d_) <= c_) && (abs(d_) <= (4*sigma_-c_));
isValid_a_tilde = (0 <= a_tilde) && (a_tilde <= max(tot_ivar_t_));
flag = isValid_c && isValid_d && isValid_a_tilde;

end

function [loss, a_tilde, d, c] = solveGrad(sigma_, m_, k_, tot_ivar_, tau_)
% In
% Out

ys = (k_-m_)/sigma_;
% number of options on slice
n = length(ys);
y = sum(ys);
y2 = sum(ys.^2);
y2one = sum(ys.^2+1);
ysqrt = sum(sqrt(ys.^2+1));
y2sqrt = sum(ys.*sqrt(ys.^2 + 1));
v = sum(tot_ivar_);
vy = sum(tot_ivar_.*ys);
vsqrt = sum(tot_ivar_.*sqrt(ys.^2+1));
%
matrix = [n, y, ysqrt; y, y2, y2sqrt; ysqrt, y2sqrt, y2one];
vector = [v; vy; vsqrt];
x = matrix\vector;
%
a_tilde_temp = x(1);
d_temp = x(2);
c_temp = x(3);
if isInteriorD(sigma_, a_tilde_temp, d_temp, c_temp, tot_ivar_)
    a_tilde = a_tilde_temp;
    d = d_temp;
    c = c_temp;
    loss = objFun(ys, a_tilde, d, c, tot_ivar_, sigma_, tau_);
else
    loss = NaN;
    % a = 0
    matrices = [n, 0, 0; y, y2, y2sqrt; ysqrt, y2sqrt, y2one];
    vectors = [0; vy; vsqrt];
    clamp_params = false;
    % a = max(tot_ivar)
    matrices(:,:,2) = [1, 0, 0; y, y2, y2sqrt; ysqrt, y2sqrt, y2one];
    vectors(:,2) = [max(tot_ivar_); vy; vsqrt];
    clamp_params(2) = false;
    % d = c
    matrices(:,:,3) = [1, y, ysqrt; 0, -1, 1; ysqrt, y2sqrt, y2one];
    vectors(:,3) = [v; 0; vsqrt];
    clamp_params(3) = false;
    % d = -c
    matrices(:,:,4) = [n, y, ysqrt; 0, 1, 1; ysqrt, y2sqrt, y2one];
    vectors(:,4) = [v; 0; vsqrt];
    clamp_params(4) = false;
    % d <= 4*s-c
    matrices(:,:,5) = [n, y, ysqrt; 0, 1, 1; ysqrt, y2sqrt, y2one];
    vectors(:,5) = [v; 4*sigma_; vsqrt];
    clamp_params(5) = false;
    % -d <= 4*s-c
    matrices(:,:,6) = [n, y, ysqrt; 0, -1, 1; ysqrt, y2sqrt, y2one];
    vectors(:,6) = [v; 4*sigma_; vsqrt];
    clamp_params(6) = false;
    % c = 0
    matrices(:,:,7) = [n, y, ysqrt; y, y2, y2sqrt; 0, 0, 1];
    vectors(:,7) = [v; vy; 0];
    clamp_params(7) = false;
    % c = 4*S
    matrices(:,:,8) = [n, y, ysqrt; y, y2, y2sqrt; 0, 0, 1];
    vectors(:,8) = [v; vy; 4*sigma_];
    clamp_params(8) = false;
    % c = 0, implies d = 0, find optimal a
    matrices(:,:,9) = [n, y, ysqrt; 0, 1, 0; 0, 0, 1];
    vectors(:,9) = [v; 0; 0];
    clamp_params(9) = true;
    % c = 4s, implied d = 0, find optimal a
    matrices(:,:,10) = [n, y, ysqrt; 0, 1, 0; 0, 0, 1];
    vectors(:,10) = [v; 0; 4*sigma_];
    clamp_params(10) = true;
    % a = 0, d = c, find optimal c
    matrices(:,:,11) = [1, 0, 0; 0, -1, 1; ysqrt, y2sqrt, y2one];
    vectors(:,11) = [0; 0; vsqrt];
    clamp_params(11) = true;
    % a = 0, d = -c, find optimal c
    matrices(:,:,12) = [1, 0, 0; 0, 1, 1; ysqrt, y2sqrt, y2one];
    vectors(:,12) = [0; 0; vsqrt];
    clamp_params(12) = true;
    % a = 0, d = 4s-c, find optimal c
    matrices(:,:,13) = [1, 0, 0; 0, 1, 1; ysqrt, y2sqrt, y2one];
    vectors(:,13) = [0; 4*sigma_; vsqrt];
    clamp_params(13) = true;
    % a = 0, d = c-4s, find optimal c
    matrices(:,:,14) = [1, 0, 0; 0, -1, 1; ysqrt, y2sqrt, y2one];
    vectors(:,14) = [0; 4*sigma_; vsqrt];
    clamp_params(14) = true;
    %
    for i=1:14
        x = matrices(:,:,i)\vectors(:,i);
        a_tilde_temp = x(1);
        d_temp = x(2);
        c_temp = x(3);
        if clamp_params(i)
            dmax = min(c_temp, 4*sigma_-c_temp);
            a_tilde_temp = min(max(a_tilde_temp, 0), max(tot_ivar_));
            d_temp = min(max(d_temp, -dmax), dmax);
            c_temp = min(max(c_temp, 0), 4*sigma_);
        end
        loss_temp = objFun(ys, a_tilde_temp, d_temp, c_temp, tot_ivar_, sigma_, tau_);
        if isInteriorD(sigma_, a_tilde_temp, d_temp, c_temp, tot_ivar_) && ...
            (isnan(loss) || loss_temp < loss)
            a_tilde = a_tilde_temp;
            d = d_temp;
            c = c_temp;
            loss = loss_temp;
        end
    end
end

end

function x0 = generateRandomX0(lb_, ub_)
% In
% Out

x0 = lb_ + rand(size(lb_)).*(ub_-lb_);

end
