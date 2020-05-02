function [] = makeAssertionsSviNat(nat_svi_model_)
% Function to make assertions for SVI natural parametrization
% In
%   nat_svi_model_ [struct]: SVI natural parametrization

delta = nat_svi_model_.delta;
mu = nat_svi_model_.mu;
rho = nat_svi_model_.rho;
omega = nat_svi_model_.omega;
zeta = nat_svi_model_.zeta;
%
assert(all(isreal(delta)))
assert(all(isreal(mu)))
assert(all(omega>=0))
assert(all(abs(rho)<1))
assert(all(zeta>0))

end

