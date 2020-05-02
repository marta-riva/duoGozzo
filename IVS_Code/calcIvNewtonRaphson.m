function [impl_vol] = calcIvNewtonRaphson(p_mkt_, pricer_, vega_, ...
    eps_abs_, max_iter_)
% This function calculates the IV using a simple vectorized Newthod-Raphson
% algorithm
% In
%   p_mkt_ [vector]: Vector of market prices
%   pricer_ [funciton handle]: Black-Scholes price formula
%   vega_ [funciton handle]: Black-Scholes vega formula
%   eps_abs_ [float]: Tolerance prices
%   max_iter_ [integer]: Maximum number of iterations
% Out
%   impl_vol [vector]: Vector with implied volatilities

if nargin < 4
    eps_abs_ = 1e-5;
    max_iter_ = 100;
end
% define function handle
fun = @(bs_mod, idxs) pricer_(bs_mod, idxs) - p_mkt_(idxs);
% initialize model
bs_mod = makeBsModel(nan(size(p_mkt_)));
[~, init_guess] = vega_(bs_mod, true(size(p_mkt_)));
bs_mod.sigma = init_guess;
% iterate
iter = 1;
isErr = true(size(init_guess));
while any(isErr) || (iter <= max_iter_)
    vega = vega_(bs_mod, isErr);
    p_diff = fun(bs_mod, isErr);
    bs_mod.sigma(isErr) = bs_mod.sigma(isErr) - p_diff./vega;
    assert(~any(bs_mod.sigma<0),'Implied volatility must be larger than 0')
    %
    iter = iter + 1;
    isErr(isErr) = (abs(fun(bs_mod, isErr)) >= eps_abs_);
end
%
if (iter == max_iter_)
    error('The alogrithm did not converge after 100 iterations')
end
% define iv value
impl_vol = bs_mod.sigma;
assert(~any(impl_vol<0), 'Implied volatility must be strictly larger than 0')
assert(~any(impl_vol==Inf), 'Implied volatility should be smaller than Inf')

end
