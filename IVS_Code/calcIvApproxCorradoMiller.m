function [impl_vol_approx] = calcIvApproxCorradoMiller(p_mkt_, option_, ...
    mkt_data_, method_)
% This function calculates the IV approximation due to Corrado & Miller
% In
%   p_mkt_ [vector]: Vector of market prices
%   option_ [strcut]: Options
%   mkt_data_ [strcut]: Market data
% Out
%   impl_vol_approx [vector]: Impied volatility approximations
% Reference
%   Li, 2006, "You Don't Have to Bother Newton for Implied Volatility",
%   http://papers.ssrn.com/sol3/papers.cfm?abstract_id=952727

K = option_.K;
tau = option_.tau;
cp_flag = option_.cp_flag;
zr = mkt_data_.zr;
%
if strcmp(method_, 'forward')
    F_t = mkt_data_.F_t;
elseif strcmp(method_, 'spot')
    S_t = mkt_data_.S_t;
    q = mkt_data_.q;
    %
    F_t = S_t.*exp((zr-q).*tau);
else
    error('Invalid method')
end
% convert to call prices
isPut = (cp_flag == -1);
p_mkt_call = p_mkt_+isPut.*(F_t-K).*exp(-zr.*tau);
%
v = (sqrt(2*pi))./(F_t+K).*(p_mkt_call.*exp(zr.*tau)-(F_t-K)/2+ ...
    sqrt((p_mkt_call.*exp(zr.*tau)-(F_t-K)/2).^2-(F_t-K).^2/pi))./sqrt(tau);
impl_vol_approx = v./sqrt(tau);

end

