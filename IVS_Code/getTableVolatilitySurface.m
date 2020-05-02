function [vola_surf_table] = getTableVolatilitySurface(date_from_, ...
    date_to_, ticker_)
% Function to get the volatility surface table
% In
%   date_from_ [string] {yyyy-MM-dd}: Date from
%   date_to_ [string] {yyyy-MM-dd}: Date to
%   ticker_ [string]: Ticker name of underlying
% Out
%   vola_surf_table [table]: Voltility surface 

% FOR DEBUG PURPOSES
% date_ = '2017-12-01';

% load '.mat' file
load('_volatilitySurfaces.mat','volatilitySurfaces');
% if arguments less then to the set ticker to SPX
if (nargin < 2)
    ticker_ = 'SPX';
    date_to_ = date_from_;
elseif (nargin < 3)
    ticker_ = 'SPX';
end
% select underlying prices based on date and ticker
isDate = (volatilitySurfaces.date >= date_from_) & ...
    (volatilitySurfaces.date <= date_to_);
isTicker = (volatilitySurfaces.ticker == ticker_);
isRequested = (isDate & isTicker);
vola_surf_table = volatilitySurfaces(isRequested, :);

end
