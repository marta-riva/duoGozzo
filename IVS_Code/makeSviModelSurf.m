function [surf_svi_mod] = makeSviModelSurf(ts_, theta_ts_, rho_, phi_)
% Function to build SSVI parametrization
% In
%   ts_ [vector]: Vector of tenors
%   theta_ts_ [vector]: Theta parameters
%   rho_ [vector]: Rho parameter
%   phi_ [vector]: Phi function
% Out
%   surf_svi_mod [struct]: SSVI parametrization

surf_svi_mod = struct(...
    'ts', ts_, ...
    'theta_ts', theta_ts_, ...
    'rho', rho_, ...
    'phi', phi_);

end
