function [impl_vol] = calcSviIvQs(svi_mod_, k_, mod_)
% This function returns IV quotes depending on the SVI parametrization
% In
%   svi_mod_ [struct]: SVI parametrization
%   k_ [vector]: Log moneyness vector
%   mod_ [char]: Parametrization ('raw', 'surf', 'nat' or 'jw')
% Out
%   impl_vol [vector]: Probabilities density values

ts = svi_mod_.ts;
tot_impl_var = calcSviTotIvarQs(svi_mod_, k_, mod_);
impl_vol = sqrt(tot_impl_var/ts);

end

