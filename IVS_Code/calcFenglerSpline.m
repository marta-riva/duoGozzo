function [smooth_prices] = calcFenglerSpline(v_, u_, g_, gamma_)
% Function to evaluate smoothing spline based on g and gamma
% In
%   v_ [vector]: Vector of strikes where to evaluate smoothing spline
%   u_ [vector]: Vector of strikes
%   g_ [vector]: Vector of prices
%   gamma_ [vector]: Vector of second derivatives
% Out
%   smooth_prices [vector]: Vector of interpolated prices
% Source
%   based on https://www.mathworks.com/matlabcentral/fileexchange/ ...
%   46253-arbitrage-free-smoothing-of-the-implied-volatility-surface

% make sure that input is sorted
[u, idx] = sort(u_);
g = g_(idx);
gamma_ = gamma_(idx);
% inputs
n = length(u);
m = length(v_);
smooth_prices = zeros(m,1);
%
for s=1:m
    for i=1:n-1
        h = u(i+1) - u(i);
        if (u(i) <= v_(s)) && (v_(s) <= u(i+1))
               smooth_prices(s) = ((v_(s)-u(i))*g(i+1) + (u(i+1)-v_(s))*g(i))/h ...
                    - 1/6*(v_(s)-u(i))*(u(i+1)-v_(s)) ...
                    * ((1+(v_(s)-u(i))/h)*gamma_(i+1) ...
                    + (1+(u(i+1)-v_(s))/h)*gamma_(i)) ;
        end
    end
    
    if v_(s) < min(u)
        dg = (g(2)-g(1))/(u(2)-u(1)) - 1/6*(u(2)-u(1))*gamma_(2);
        smooth_prices(s) = g(1) - (u(1) - v_(s))*dg;
    end
    
    if v_(s) > max(u)
        dg = (g(n)-g(n-1))/(u(n)-u(n-1)) + 1/6*(u(n)-u(n-1))*gamma_(n-1);
        smooth_prices(s) = g(n) + (v_(s) - u(n))*dg;
    end
end

end
