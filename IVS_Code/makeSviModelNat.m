function [nat_svi_mod] = makeSviModelNat(delta_, mu_, rho_, omega_, ...
    zeta_, ts_, assert_)
% Function to build SVI natural parametrization
% In
%   delta_ [vector]: Delta parameter
%   mu_ [vector]: Mu parameter
%   rho_ [vector]: Rho parameter
%   omega_ [vector]: Omega parameter
%   zeta_ [vector]: Zeta parameter
%   ts_ [vector]: Vector of tenors
%   assert_ [vector]: 'true' or 'false'
% Out
%   nat_svi_mod [struct]: SVI Natural parametrization

if (nargin < 7)
    assert_ = true;
end
nat_svi_mod = struct(...
    'ts', ts_, ...
    'delta', delta_, ...
    'mu', mu_, ...
    'rho', rho_, ...
    'omega', omega_, ...
    'zeta', zeta_);
%
if assert_
    makeAssertionsSviNat(nat_svi_mod)
end

end
