function [g] = calcSviDensity(svi_mod_, k_, mod_)
% This function evaluates SVI probabilities density
% In
%   svi_mod_ [struct]: SVI parametrization
%   k_ [vector]: Log moneyness vector
%   mod_ [char]: Parametrization ('raw', 'surf', 'nat' or 'jw')
% Out
%   g [vector]: Probabilities density values

% convert parametrization if necessary
if strcmp(mod_,'jw')
    raw_svi_mod = makeSviModelConversion(svi_mod_,'jw','raw');
elseif strcmp(mod_,'nat')
    raw_svi_mod = makeSviModelConversion(svi_mod_,'nat','raw');
elseif strcmp(mod_,'raw')
    makeAssertionsSviRaw(svi_mod_)
    raw_svi_mod = svi_mod_;
else
    error('Invalid model')
end
% define variables
a = raw_svi_mod.a;
b = raw_svi_mod.b;
rho = raw_svi_mod.rho;
m = raw_svi_mod.m;
sigma = raw_svi_mod.sigma;
% calculate terms separately
discr = sqrt((k_-m).^2+sigma.^2);
w = a+b.*(rho.*(k_-m)+discr);
dw = b.*rho + b.*(k_-m)./discr;
d2w = b.*sigma.^2./discr.^3;
% calculate density
g = (1-k_.*dw./(2*w)).^2-dw.^2./4.*(1./w+1/4)+d2w/2;
% Gatheral's mistake (https://www.imperial.ac.uk/media/imperial-college/
% research-centres-and-groups/cfm-imperial-institute-of-quantitative-
% finance/events/distinguished-lectures/Gatheral-2nd-Lecture.pdf)
% g = 1-k_.*dw./w+dw.*dw/4.*(-1./w+k_.*k_./(w.*w)-4)+d2w/2;

end

