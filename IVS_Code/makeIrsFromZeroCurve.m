function [irs] = makeIrsFromZeroCurve(zr_ts_, ts_)
% This function builds a strcutre with zero-copun rates, forward rates,
% discount factors and their tenors
% In
%   zr_ts_ [vector]: Zero rates
%   ts_ [vector]: Tenors in years
% Out
%   irs [struct]: Interest rate structure
%       ts [vector]: Tenors in years
%       zr_ts [vector]: Zero rates
%       fr_ts [vector]: Forward rates
%       df_ts [vector]: Disount factors

% compute forward rates
fr_ts = (zr_ts_(2:end) .* ts_(2:end,1) - ...
    zr_ts_(1:end-1,1) .* ts_(1:end-1,1)) ./ ...
        (ts_(2:end,1) - ts_(1:end-1,1));
fr_ts = [zr_ts_(1,1); fr_ts];
% compute discount factors
df_ts = exp(-zr_ts_ .* ts_);
% create structure
irs = makeIrs(ts_, zr_ts_, fr_ts, df_ts);

end
