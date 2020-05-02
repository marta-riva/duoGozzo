function [Ids, rate] = calcImpliedDivYield(underlying_table_, ...
    interp_Irs_, Ifs_, divyield_table_, plot_)
% This function calculates the implied dividend yields
% In
%   underlying_table_ [table]: Table with the underlying price
%   interp_Irs_ [strcut]: Interpolated zero-coupon rates
%   Ifs_ [strcut]: Impied forwards
%   divyield_table_ [table]: Table with the constant dividend yield
%   plot_ [char]: True for producing plot, false otherwise
% Out
%   Ids [strcut]: Impied dividends
%       ts [vector]: Tenors
%       qs [vector]: Quotes
%   rate [float]: Average implied dividends

if (nargin < 5)
    plot_ = false;
end
close = underlying_table_.close;
Ids.ts = Ifs_.ts;
Ids.qs = log(Ifs_.qs/close.*interp_Irs_.df_ts)./(-Ids.ts);
%
if nargout > 1
    isRequested = (Ids.ts >= 0.5);
    rate = mean(Ids.qs(isRequested));
    assert(rate>0,'Dividend Yield cannot be negative')
    if plot_
        % Plot for visual inspection --------------------------------------
        figure
        plot(Ids.ts,Ids.qs,'*-')
        xlabel('Tenors')
        ylabel('Implied dividend yield')
        title(['Calc Date: ', datestr(underlying_table_.date(1), ...
            'yyyy-mm-dd')])
        hold on
        plot(Ids.ts,rate*ones(size(Ids.ts)))
        plot(Ids.ts,divyield_table_.rate*ones(size(Ids.ts)))
        legend('Implied dividend yields','Framework dividend yield', ...
            'OM dividend yield')
        % -----------------------------------------------------------------
    end
end

end
