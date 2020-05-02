function [tot_impl_var, impl_vola] = calcSviSurf(svi_mod_, k_, tau_, ...
    mod_, plot_)
% This function calculates an entire SVI volatility surfaces
% In
%   svi_mod_ [struct]: SVI parametrization
%   k_ [vector]: Log moneyness vector
%   tau_ [float]: Time-to-maturity
%   mod_ [char]: Parametrization ('raw', 'surf', 'nat' or 'jw')
%   plot_ [char]: True for producing plot, false otherwise
% Out
%   tot_impl_var [vector]: Vector of total implied variances
%   impl_vola [vector]: Vector of implied volatilities

if nargin<5
    plot_ = false;
end
taus = unique(tau_);
tot_impl_var = zeros(size(k_));
for i=1:length(taus)
    reduced_svi_mod = makeSviModelReduce(svi_mod_, taus(i));
    isRequested = (tau_ == taus(i));
    tot_impl_var(isRequested) = calcSviTotIvarQs(reduced_svi_mod, ...
        k_(isRequested), mod_);
end
if nargout > 1
    impl_vola = sqrt(tot_impl_var./tau_);    
end
%
if plot_
    % Plot for inspection -------------------------------------------------
    figure
    for i=1:length(taus)
        isRequested = (taus(i) == tau_);
        plot(k_(isRequested),tot_impl_var(isRequested),'LineWidth',1.5)
        hold on
    end
    xlabel('$\log(K/F_{t,T})$ - Log Moneyness')
    ylabel('$w$ - Implied Total Variance')
    legend(join([repmat('$\tau=$ ',size(taus)) string(taus)]))
    xlim([-0.8 0.3])
    % ---------------------------------------------------------------------
end

end
