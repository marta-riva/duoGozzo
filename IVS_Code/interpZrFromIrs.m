function [irs] = interpZrFromIrs(irs_, tqs_, method_)
% Function to interpolate zero-coupon rates
% In
%   irs_ [struct]: Raw interest rate structure
%   tqs_ [vector]: Tenors to interpolate at
%   method_ [char]: 'linear','spline' or 'pchip'
% Out
%   irs [struct]: Raw interest rate structure

if nargin<3
    method_='linear';
end
% interpolate
supported_methods = ['linear','spline','pchip'];
if ismember(method_,supported_methods)
    zr_tqs = interp1(irs_.ts, irs_.zr_ts, tqs_, method_, 'extrap');
else
    error('The interpolation method is not supported')
end
% create structure
irs = makeIrsFromZeroCurve(zr_tqs, tqs_);

end
