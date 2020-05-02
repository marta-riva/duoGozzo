function [impl_vol] = calcIvBisection(p_mkt_, pricer_, eps_abs_, ...
    eps_step_, max_iter_)
% This function calculates the IV using a simple vectorized bisection
% method
% In
%   p_mkt_ [vector]: Vector of market prices
%   pricer_ [funciton handle]: Black-Scholes price formula
%   eps_abs_ [float]: Tolerance prices
%   eps_step_ [float]: Tolerance steps
%   max_iter_ [integer]: Maximum number of iterations
% Out
%   impl_vol [vector]: Vector with implied volatilities

if nargin < 3
    eps_abs_ = 1e-5;
    max_iter_ = 100;
    eps_step_ = 1e-5;
end
%
bs_mod_a = makeBsModel(repmat(0.001, size(p_mkt_)));
bs_mod_b = makeBsModel(repmat(5, size(p_mkt_)));
bs_mod_c = makeBsModel(nan(size(p_mkt_)));
fun = @(bs_mod, idxs) p_mkt_(idxs) - pricer_(bs_mod, idxs);
% preallocation
hasNegProduct = true(size(p_mkt_));
isErr = true(size(p_mkt_));
% iterate
iter = 1;
while any(isErr) || (iter <= max_iter_)
    bs_mod_c.sigma(isErr) = (bs_mod_a.sigma(isErr) + ...
        bs_mod_b.sigma(isErr))/2;
    hasNegProduct(isErr) = (fun(bs_mod_a, isErr).*fun(bs_mod_c, isErr)<0);
    bs_mod_b.sigma(hasNegProduct) = bs_mod_c.sigma(hasNegProduct);
    bs_mod_a.sigma(~hasNegProduct) = bs_mod_c.sigma(~hasNegProduct);
    %
    iter = iter + 1;
    isErr(isErr) = (bs_mod_b.sigma(isErr)-bs_mod_a.sigma(isErr) >= ...
        eps_step_ | (abs(fun(bs_mod_a, isErr)) >= eps_abs_ & ...
        abs(fun(bs_mod_b, isErr)) >= eps_abs_));
end
%
if (iter == max_iter_)
    error('The alogrithm did not converge after 100 iterations')
end
%
idxs = true(size(p_mkt_));
impl_vol = zeros(size(p_mkt_));
isA = (abs(fun(bs_mod_b, idxs)) < abs(fun(bs_mod_a, idxs))) ...
    & (abs(fun(bs_mod_a, idxs)) < eps_abs_);
impl_vol(isA) = bs_mod_a.sigma(isA);
impl_vol(~isA) = bs_mod_b.sigma(~isA);

end
