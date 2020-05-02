function [] = makeAssertionsSviRaw(raw_svi_mod_)
% Function to make assertions for SVI raw parametrization
% In
%   nat_svi_model_ [struct]: SVI raw parametrization

a = raw_svi_mod_.a;
b = raw_svi_mod_.b;
rho = raw_svi_mod_.rho;
m = raw_svi_mod_.m;
sigma = raw_svi_mod_.sigma;
%
assert(all(isreal(a)))
assert(all(isreal(m)))
assert(all(b>=0))
assert(all(abs(rho)<1))
assert(all(sigma>0))
assert(all(a+b.*sigma.*sqrt(1-rho.^2)>=0))

end

