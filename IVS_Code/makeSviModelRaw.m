function [raw_svi_mod] = makeSviModelRaw(a_, b_, rho_, m_, sigma_, ts_, ...
    assert_)
% Function to build SVI JW parametrization
% In
%   a_ [vector]: A parameter
%   b_ [vector]: B parameter
%   rho_ [vector]: Rho parameter
%   m_ [vector]: M parameter
%   sigma_ [vector]: Sigma parameter
%   ts_ [vector]: Vector of tenors
%   assert_ [vector]: 'true' or 'false'
% Out
%   nat_svi_mod [struct]: SVI Natural parametrization

if (nargin < 7)
    assert_ = true;
end
raw_svi_mod = struct(...
    'ts', ts_, ...
    'a', a_, ...
    'b', b_, ...
    'rho', rho_, ...
    'm', m_, ...
    'sigma', sigma_);
%
if assert_
    makeAssertionsSviRaw(raw_svi_mod)
end

end
