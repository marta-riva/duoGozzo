function [underlying_price_table] = getTableUnderlyingPrice(date_from_, ...
    date_to_, ticker_)
% Function to get the underlying price table
% In
%   date_ [string] {yyyy-MM-dd}: Date
%   ticker_ [string]: Ticker name of underlying
% Out
%   underlying_price_table [table]: Underlying price table

% FOR DEBUG PURPOSES
% date_ = '2017-12-01';

% load '.mat' file
load('_underlyingPrices.mat','underlyingPrices');
% compute log returns based on close price
unique_secid = unique(underlyingPrices.secid);
underlyingPrices.log_return = zeros(size(underlyingPrices,1),1);
for i=1:length(unique_secid)
    isSecid = (underlyingPrices.secid == unique_secid(i));
    close = underlyingPrices.close(isSecid);
    underlyingPrices.log_return(isSecid) = [NaN; log(close(2:end)./...
        close(1:end-1))];
end
% if arguments less then to the set ticker to SPX
if nargin<2
    ticker_ = 'SPX';
    date_to_ = date_from_;
end
% select underlying prices based on date and ticker
isDate = (underlyingPrices.date >= date_from_) & ...
    (underlyingPrices.date <= date_to_);
if strcmp(ticker_, 'all')
    isTicker = true(length(isDate),1);
else
    isTicker = (underlyingPrices.ticker == ticker_);
end
isRequested = (isDate & isTicker);
underlying_price_table = underlyingPrices(isRequested, :);

end
