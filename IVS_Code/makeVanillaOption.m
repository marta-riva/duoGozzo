function [option] = makeVanillaOption(K_, tau_, cp_flag_)
% Function to build option structure
% In
%   K_ [vector]: Strike prices vector
%   tau_ [vector]: Time-to-maturity vector
%   cp_flag_ [vector]: Flags (1 for call -1 for put) vector
% Out
%   option [struct]: Options

option = struct(...
    'K', K_,...
    'tau', tau_,...
    'cp_flag', cp_flag_);

end
