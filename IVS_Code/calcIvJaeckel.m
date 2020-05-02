function [impl_vol] = calcIvJaeckel(p_mkt_, option_, mkt_data_, method_)
% This function calculates the IV using the method proposed by Jaekel
% In
%   p_mkt_ [vector]: Vector of market prices
%   option_ [struct]: Options
%   mkt_data_ [struct]: Market data
%   method_ [char]: Method ('forward' or 'spot')
% Out
%   impl_vol [vector]: Vector with implied volatilities
% References
%   Jaekel, 2016, "Let's be rational", https://doi.org/10.1002/wilm.10395

K = option_.K;
tau = option_.tau;
cp_flag = option_.cp_flag;
zr = mkt_data_.zr;
F_t = mkt_data_.F_t;
S_t = mkt_data_.S_t;
q = mkt_data_.q;
%
class = false(size(K));
isCall = (cp_flag == 1);
class(isCall) = true;
if strcmp(method_,'spot')
    impl_vol = blsimpv(S_t, K, zr, tau, p_mkt_, 'Class', class, ...
        'Yield', q, 'Method', 'jackel2016');
elseif strcmp(method_,'forward')
    impl_vol = blkimpv(F_t, K, zr, tau, p_mkt_, 'Class', class, ...
        'Method', 'jackel2016');
else
    error('Invalid method')
end

end
