function [irs] = makeIrs(ts_, zr_ts_, fr_ts_, df_ts_)
% Function to build interest rate structure
% In
%   ts_ [vector]: Tenors in years
%   zr_ts_ [vector]: Zero rates
%   fr_ts_ [vector]: Forward rates
%   df_ts_ [vector]: Disount factors
% Out
%   irs [struct]: Interest rate structure

irs = struct( ...
    'ts', ts_, ...
    'zr_ts', zr_ts_, ...
    'fr_ts', fr_ts_, ...
    'df_ts', df_ts_);

end
