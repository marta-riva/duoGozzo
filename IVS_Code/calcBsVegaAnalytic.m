function [vega, max_vega_sigma] = calcBsVegaAnalytic(bs_mod_, ...
    option_, mkt_data_, method_, idxs_)
% This function calculates the Black-Scholes vega
% In
%   bs_mod_ [strcut]: Sigmas
%   option_ [strcut]: Options
%   mkt_data_ [strcut]: Market data
%   method_ [char]: Method
%   idxs_ [vector]: Indexes of values to be calculated
% Out
%   vega [vector]: Vegas
%   max_vega_sigma [vector]: Sigmas corresponding to the maximum vega value

if nargin < 5
    idxs_ = true(size(option_.K));
end
sigma = bs_mod_.sigma(idxs_,:);
K = option_.K(idxs_);
tau = option_.tau(idxs_);
zr = mkt_data_.zr(idxs_);
%
if strcmp(method_,'forward')
    F_t = mkt_data_.F_t(idxs_);
    %
    d_1 = (log(F_t./K)+sigma.^2/2.*tau)./(sigma.*sqrt(tau));
    d_2 = d_1 - sigma.*sqrt(tau);
    if (nargout > 1)
        max_vega_sigma = sqrt(2./tau.*abs(log(F_t./K)));
    end
elseif strcmp(method_, 'spot')
    S_t = mkt_data_.S_t(idxs_);
    q = mkt_data_.q(idxs_);
    %
    d_1 = (log(S_t./K)+(zr-q+sigma.^2./2).*tau)./(sigma.*sqrt(tau));
    d_2 = d_1 - sigma.*sqrt(tau);
    if (nargout > 1)
        max_vega_sigma = sqrt(2./tau.*abs(log(S_t./K)+(zr+q).*tau));
    end
else
    error('Invalid method')
end

vega = K.*exp(-zr.*tau).*normpdf(d_2).*sqrt(tau);

end
