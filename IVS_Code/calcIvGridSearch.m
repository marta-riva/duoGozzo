function [impl_vol] = calcIvGridSearch(p_mkt_, pricer_, grid_size_)
% This function calculates the IV using a simple vectorized grid search
% apporach
% In
%   p_mkt_ [vector]: Vector of market prices
%   pricer_ [funciton handle]: Black-Scholes formula
%   grid_size_ [float]: Grid step
% Out
%   impl_vol [vector]: Vector with implied volatilities

if nargin < 3
    grid_size_ = 0.0001;
end
%
grid = repmat(0.01:grid_size_:5.00,size(p_mkt_));
bs_mod = makeBsModel(grid);
p_bs = pricer_(bs_mod, true(size(p_mkt_)));
[~, idx_min] = min(abs(p_bs - p_mkt_),[],2);
impl_vol = zeros(size(idx_min));
for i=1:length(impl_vol)
    impl_vol(i) = grid(1, idx_min(i));
end

end
