function [pre_smooth_call_price, kappa, tau, forward, interest_rate] = ...
    calcFenglerPreSmoothedPrices(kappa_, fwd_moneyness_, tau_, ...
    impl_volatility_, impl_forward_, interest_rate_, plot_)
% This function calculates the pre-smoothed call option prices
% In
%   kappa_ [vector]: Equally spaced forward moneyness vector
%   fwd_moneyness_ [vector]: Actual forward moneyness vector
%   tau_ [vector]: Time-to-maturities vector
%   impl_volatility_ [vector]: Implied volatilities vector
%   impl_forward_ [vector]: Implied forwards vector
%   interest_rate_ [vector]: Interest rates vector
% Out
%   pre_smooth_call_price [vector]: Pre-smoothed call prices vector
%   kappa [vector]: Forward moneyness vector
%   tau [vector]: Time-to-maturities vector
%   forward [vector]: Implied forwards vector
%   interest_rate [vector]: Interest rates vector
% Source
%   based on https://www.mathworks.com/matlabcentral/fileexchange/ ...
%   46253-arbitrage-free-smoothing-of-the-implied-volatility-surface

if (nargin < 7)
    plot_ = false;
end
kappa = kappa_;
% thin-plate spline
x = [fwd_moneyness_'; tau_'];
% y = (impl_volatility_.^2 .* maturity_)';
y = impl_volatility_';
warning('off');
[thin_plate_spline] = tpaps(x, y, 1);
warning('on');

% get maturity points and resort data so that it corresponds to tau
[tau, idx] = unique(tau_);
forward = impl_forward_(idx);
interest_rate = interest_rate_(idx);

% sort tau
[tau, idx]   = sort(tau);
forward = forward(idx);
interest_rate = interest_rate(idx);

[X,Y] = meshgrid(kappa,tau);
X = reshape(X,1,numel(X));
Y = reshape(Y,1,numel(Y));
XY = [X; Y];
% total_variance_interpolated = fnval(thin_plate_spline, XY);
impl_volatility_interpolated = fnval(thin_plate_spline, XY)';
if plot_
    % Plot for visual inspection ------------------------------------------
    Z = reshape(impl_volatility_interpolated, length(tau), length(kappa))';
%     Z = reshape(total_variance_interpolated, length(tau), length(kappa))';
    figure
    surf(kappa,tau,Z','FaceColor','none')
    xlabel('$K/F$')
    ylabel('$\tau$')
    zlabel('Total Implied Variance')
    view(45,15)
    hold on
    plot3(fwd_moneyness_,tau_,y','r*');
    % ---------------------------------------------------------------------
end

% remove all kappas where total variance is non-positive
if any(impl_volatility_interpolated<=0)
% if any(total_variance_interpolated<=0)
    pos_neg = impl_volatility_interpolated<=0;
%     pos_neg = total_variance_interpolated<=0;
    kappas_neg = unique(X(pos_neg));
    pos_delete = ismember(X,kappas_neg);
    impl_volatility_interpolated = impl_volatility_interpolated(~pos_delete);
%     total_variance_interpolated = total_variance_interpolated(~pos_delete);
    X = X(~pos_delete);
    Y = Y(~pos_delete);
    kappa = kappa(~ismember(kappa, kappas_neg));
end

% impl_volatility_interpolated = sqrt(total_variance_interpolated./Y)';

% calculation of call prices
[~, idx] = ismember(Y,tau);
option = makeVanillaOption(forward(idx).*X', Y', ones(size(idx))');
bs_model = makeBsModel(impl_volatility_interpolated);
mkt_data = makeMarketData(NaN, forward(idx), interest_rate(idx), NaN);
pre_smooth_call_price = calcBsPriceAnalytic(bs_model, option, mkt_data, ...
    'forward');

% ensure that output dimensions are correct, each column is one smile
pre_smooth_call_price = reshape(pre_smooth_call_price, length(tau), ...
    length(kappa))'; 
tau = tau(:);
kappa = kappa(:);

end
