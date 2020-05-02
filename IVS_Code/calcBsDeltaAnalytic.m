function [delta] = calcBsDeltaAnalytic(bs_mod_, option_, mkt_data_, ...
    method_, idxs_)
% This function calculates the Black-Scholes delta
% In
%   bs_mod_ [strcut]: Sigmas
%   option_ [strcut]: Options
%   mkt_data_ [strcut]: Market data
%   method_ [char]: Method
%   idxs_ [vector]: Indexes of values to be calculated
% Out
%   delta [vector]: Deltas

if nargin < 5
    idxs_ = true(size(option_.K));
end
sigma = bs_mod_.sigma(idxs_,:);
K = option_.K(idxs_);
tau = option_.tau(idxs_);
cp_flag = option_.cp_flag(idxs_);
zr = mkt_data_.zr(idxs_);
F_t = mkt_data_.F_t(idxs_);
S_t = mkt_data_.S_t(idxs_);
%
if strcmp(method_, 'forward')
    q = log(F_t./S_t.*exp(-zr.*tau))./(-tau);
    d_1 = (log(F_t./K)+sigma.^2/2.*tau)./(sigma.*sqrt(tau));
    delta = cp_flag.*exp(-q.*tau).*normcdf(cp_flag.*d_1);
elseif strcmp(method_, 'spot')
    q = mkt_data_.q(idxs_);
    %
    d_1 = (log(S_t./K)+(zr-q+sigma.^2/2).*tau)./(sigma.*sqrt(tau));
    delta = cp_flag.*exp(-q.*tau).*normcdf(cp_flag.*d_1);
else
    error('Invalid formula type')
end

end

