function [bsm_mod] = makeBsModel(sigma_)
% Function to build Black-Scholes model
% In
%   sigma_ [vector]: Sigmas
% Out
%   bsm_mod [struct]: Black-Scholes model

bsm_mod = struct(...
    'sigma', sigma_);

end
