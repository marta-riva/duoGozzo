function [phi] = makeSviParametrization(params_, phi_fun_)
% Function to return the function handle for the phi function
% In
%   params_ [vector]: Vector of parameters
%   phi_fun_ [char]: 'heston_like', 'power_law' or 'square_root'
% Out
%   phi [function handle]: Phi function handle

switch phi_fun_
    case 'heston_like'
        lambda = params_(1);
        phi = @(theta) 1./(lambda*theta).*(1-(1-exp(-lambda*theta))./(lambda*theta));
    case 'power_law'
        eta = params_(1);
        gamma = params_(2);
        %
        phi = @(theta) eta./(theta.^(gamma).*(1+theta).^(1-gamma));
    case 'square_root'
        eta = params_(1);
        %
        phi = @(theta) eta./sqrt(theta);
    otherwise
        error('Incorrect function for phi');
end

end

