function [Ifs] = calcImpliedForwards(filtered_option_table_, interp_Irs_, ...
    underlying_table_, divyield_table_, plot_)
% This function calculates the implied forwards
% In
%   filtered_option_table_ [table]: Table with the option prices
%   interp_Irs_ [strcut]: Interpolated zero-coupon rates
%   underlying_table_ [table]: Table with the underlying price
%   divyield_table_ [table]: Table with the constant dividend yield
%   plot_ [char]: True for producing plot, false otherwise
% Out
%   Ifs [strcut]: Impied forwards
%       ts [vector]: Tenors
%       qs [vector]: Quotes

if nargin<5
    plot_ = false;
end
taus = unique(filtered_option_table_.ytm);
Ifs.ts = taus;
Ifs.qs = zeros(size(taus));
for i=1:length(taus)
    tau = taus(i);
    [calls, puts] = makeTableOptionStraddle(filtered_option_table_, ...
        tau);
    strike_prices = calls.strike_price;
    zr = interp_Irs_.zr_ts(i);
    impl_forwards = (calls.mid-puts.mid)*exp(zr*tau)+strike_prices;
    kappa = strike_prices./impl_forwards;
    isCloseATM = (kappa >= 0.95) & (kappa <= 1.05);
    if plot_
        % Plot for visual inspection --------------------------------------
        figure
        plot(strike_prices, impl_forwards, '*-')
        xlabel('Strike Prices')
        ylabel('Implied Forwards')
        ylim([min(impl_forwards)-5, max(impl_forwards)+5])
        title(['Calc Date: ', datestr(calls.date(1)), ' Exp Date: ', ...
            datestr(ex_date)])
        % -----------------------------------------------------------------
    end
    [~, idx_min] = min(abs(calls.mid(isCloseATM)-puts.mid(isCloseATM)));
    % fall back
    if isempty(idx_min)
        % calculate forward using OM data if no straddle
        mkt_data = makeMarketData(underlying_table_.close, NaN, zr, ...
            divyield_table_.rate);
        Ifs.qs(i) = calcBsForwardAnalytic(mkt_data, tau);
    else
        Ifs.qs(i) = impl_forwards(idx_min);
        % alternatively use the median or mean
        % Ifs.qs(i) = median(impl_forwards);
        % Ifs.qs(i) = mean(impl_forwards);
    end
end

end
