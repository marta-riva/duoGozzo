function [smooth_call_price, smooth_impl_vol] = calcFenglerSmoothIvQs(u_, ...
    tau_, g_, gamma_, option_, mkt_data_, method_)
% Function to calculate smooth call prices and smooth implied volatilities
% In
%   u_ [matrix]: Matrix of strikes
%   tau_ [vector]: Maturities vector
%   g_ [matrix]: Matrix of prices
%   gamma_ [matrix]: Matrix of second derivatives
%   option_ [struct]: Options
%   mkt_data_ [struct]: Market data
%   method_ [char]: Method ('forward' or 'spot')
% Out
%   smooth_call_price [vector]: Vector of smooth call prices
%   smooth_impl_vol [vector]: Vector of smooth implied volatilities
% Source
%   based on https://www.mathworks.com/matlabcentral/fileexchange/ ...
%   46253-arbitrage-free-smoothing-of-the-implied-volatility-surface

T = length(tau_);
smooth_call_price = zeros(size(option_.tau));
for t = 1:T
    isRequested = (option_.tau == tau_(t));
    smooth_call_price(isRequested) = calcFenglerSpline(option_.K(isRequested), ...
        u_(:,t), g_(:,t), gamma_(:,t));
end
%
smooth_impl_vol = calcIvJaeckel(smooth_call_price, option_, ...
    mkt_data_, method_);

end
