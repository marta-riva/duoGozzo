function [forward] = calcBsForwardAnalytic(mkt_data_, tau_, idxs_)
% This function calculates the forward
% In
%   mkt_data_ [strcut]: Market data
%   tau_ [vector]: Time-to-maturity
%   idxs_ [vector]: Indexes of values to be calculated
% Out
%   forward [vector]: Forwards

if nargin < 3
    idxs_ = true(size(mkt_data_.S_t));
end
zr = mkt_data_.zr(idxs_);
S_t = mkt_data_.S_t(idxs_);
q = mkt_data_.q(idxs_);
tau = tau_(idxs_);
%
forward = S_t*exp((zr-q).*tau);

end
