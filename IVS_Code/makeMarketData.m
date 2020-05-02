function [mkt_data] = makeMarketData(S_t_, F_t_, zr_, q_)
% Function to build market data structure
% In
%   S_t_ [vector]: Underliyng spot price vector
%   F_t_ [vector]: Forward price vector
%   zr_ [vector]: Zero-coupons vector
%   q_ [vector]: Dividend yield vector
% Out
%   mkt_data [struct]: Market data

mkt_data = struct( ...
    'S_t', S_t_,...
    'F_t', F_t_,...
    'zr', zr_,...
    'q', q_);

end
