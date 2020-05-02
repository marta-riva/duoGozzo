function [dual_gamma] = calcBsDualGammaAnalytic(bs_mod_, option_, mkt_data_, ....
    method_, idxs_)
% This function calculates the Black-Scholes dual gamma
% In
%   bs_mod_ [strcut]: Sigmas
%   option_ [strcut]: Options
%   mkt_data_ [strcut]: Market data
%   method_ [char]: Method
%   idxs_ [vector]: Indexes of values to be calculated
% Out
%   dual_gamma [vector]: Dual Gammas

if nargin < 5
    idxs_ = true(size(option_.K));
end
sigma = bs_mod_.sigma(idxs_,:);
K = option_.K(idxs_);
tau = option_.tau(idxs_);
zr = mkt_data_.zr(idxs_);
%
if strcmp(method_, 'forward')
    F_t = mkt_data_.F_t(idxs_);
    %
    d_1 = (log(F_t./K)+sigma.^2/2.*tau)./(sigma.*sqrt(tau));
    d_2 = d_1 - sigma.*sqrt(tau);
    dual_gamma = exp(-zr.*tau)./(K.*sigma.*sqrt(tau)).*normpdf(d_2);
elseif strcmp(method_, 'spot')
    S_t = mkt_data_.S_t(idxs_);
    q = mkt_data_.q(idxs_);
    %
    d_1 = (log(S_t./K)+(zr-q+sigma.^2/2).*tau)./(sigma.*sqrt(tau));
    d_2 = d_1 - sigma.*sqrt(tau);
    dual_gamma = exp(-zr.*tau)./(K.*sigma.*sqrt(tau)).*normpdf(d_2);
else
    error('Invalid method')
end

end
