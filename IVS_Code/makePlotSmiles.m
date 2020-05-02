function [] = makePlotSmiles(otm_option_table_, underlying_table_, ...
    space_, dimension_, view_)
% Function to produce IV smiles plot
% In
%   otm_option_table_ [table]: OTM option volatility table
%   underlying_table_ [table]: Underlying price table
%   space_ [char]: Space dimension
%   dimension_ [char]: Time dimensions
%   view_ [char]: 'single' for unique figure, 'multiple' for more figures

if nargin<3
    space_ = 'forward moneyness';
    dimension_ = 'implied volatility';
    view_ = 'single';
end
% sorting by strike flag and days to maturity
otm_option_table_ = sortrows(otm_option_table_, 7);
otm_option_table_ = sortrows(otm_option_table_, 6);
otm_option_table_ = sortrows(otm_option_table_, 24);
% looping over different expirations
ytms = unique(otm_option_table_.ytm);
for i=1:length(ytms)
    isRequested = otm_option_table_.ytm == ytms(i);
    option_table = otm_option_table_(isRequested,:);
    % view
    if strcmp(view_,'single')
        figure
    end
    % space
    if strcmp(space_,'strike')
        x_label = '$K$ - Strike';
        x_coords = option_table.strike_price;
    elseif strcmp(space_,'moneyness')
        x_label = '$K/S_t$ - Moneyness';
        close = underlying_table_.close;
        x_coords = option_table.strike_price/close;
    elseif strcmp(space_,'log moneyness')
        x_label = '$\log(K/S_t)$ - Log Moneyness';
        close = underlying_table_.close;
        x_coords = log(option_table.strike_price/close);
    elseif strcmp(space_,'forward moneyness')
        x_label = '$K/F_t$ - Forward Moneyness';
        x_coords = option_table.strike_price./option_table.impl_forward;
    elseif strcmp(space_,'log forward  moneyness')
        x_label = '$\log(K/F_t)$ - Log Forward Moneyness';
        x_coords = log(option_table.strike_price./option_table.impl_forward);
    elseif strcmp(space_,'delta')
        x_label = '$\Delta$ - Delta';
        x_coords = -option_table.delta+option_table.cp_flag*0.5;
    else
        error('Unknown space variable')
    end
    % dimension
    if strcmp(dimension_,'implied volatility')
        y_label = '$\sigma_{imp}$ - Implied Volatility';
        y_coords_OM = option_table.impl_volatility;
        y_coords_FE = option_table.impl_volatility_mid;
    elseif strcmp(dimension_,'implied variance')
        y_label = '$\sigma_{imp}^2$ - Implied Variance';
        y_coords_OM = option_table.impl_volatility.^2;
        y_coords_FE = option_table.impl_volatility_mid.^2;
    elseif strcmp(dimension_, 'total implied variance')
        y_label = '$\sigma_{imp}^2\tau$ - Total Implied Variance';
        y_coords_OM = (option_table.impl_volatility.^2).*option_table.ytm;
        y_coords_FE = (option_table.impl_volatility_mid.^2).*option_table.ytm;
    else
        error('Unknown space variable')
    end
    % plot
    plot(x_coords,y_coords_OM,'+-')
    hold on
    plot(x_coords,y_coords_FE,'+-')
    legend('OM quotes','FE quotes')
    title([string(option_table.ticker(1)),' - Calc Date: ', ...
        datestr(option_table.date(1),'yyyy-mm-dd'), ' - Exp Date: ', ...
        datestr(option_table.exdate(1),'yyyy-mm-dd'), ...
        ' - Days to Maturity: ', num2str(ytms(i))])
    xlabel(x_label)
    ylabel(y_label)
    title(['Calc Date: ', datestr(option_table.date(1)), ' Exp Date: ', ...
        datestr(option_table.exdate(1)), ' Years to Maturity: ', ...
        num2str(ytms(i))])
    if strcmp(space_,'delta')
        xlim([-0.495 0.495])
    end
    % view
    if strcmp(view_,'multiple')
        hold on
    end
end

end
