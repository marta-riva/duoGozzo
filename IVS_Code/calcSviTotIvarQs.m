function [tot_impl_var] = calcSviTotIvarQs(svi_mod_, k_, mod_)
% This function calculates implied total variances
% In
%   svi_mod_ [struct]: SVI parametrization
%   k_ [vector]: Log moneyness vector
%   mod_ [char]: Parametrization ('raw', 'surf', 'nat' or 'jw')
% Out
%   tot_impl_var [vector]: Vector of total implied variances

if strcmp(mod_,'jw')
    raw_svi_mod = makeSviModelConversion(svi_mod_,'jw','raw');
elseif strcmp(mod_,'nat')
    raw_svi_mod = makeSviModelConversion(svi_mod_,'nat','raw');
    %
%     makeAssertionsSviNat(svi_mod_)
%     delta = svi_mod_.delta;
%     mu = svi_mod_.mu;
%     rho = svi_mod_.rho;
%     omega = svi_mod_.omega;
%     zeta = svi_mod_.zeta;
%     tot_impl_var = delta+omega/2.*(1+zeta.*rho.*(k_-mu)+sqrt((zeta.*(k_-mu)+rho).^2+(1-rho.^2)));
elseif strcmp(mod_,'raw')
    raw_svi_mod = svi_mod_;
elseif strcmp(mod_,'surf')
    raw_svi_mod = makeSviModelConversion(svi_mod_,'surf','raw');
else
    error('Invalid model')
end
%
a = raw_svi_mod.a;
b = raw_svi_mod.b;
rho = raw_svi_mod.rho;
m = raw_svi_mod.m;
sigma = raw_svi_mod.sigma;
%
tot_impl_var = a+b.*(rho.*(k_-m)+sqrt((k_-m).^2+sigma.^2));

end

