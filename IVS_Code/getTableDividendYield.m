function [dividend_yield_tbl] = getTableDividendYield(date_, ticker_)
% Function to get the dividend yield table
% In
%   date_ [char] {yyyy-MM-dd}: Date
% Out
%   dividend_yield_tbl [table]: Table with dividen yield

% FOR DEBUG PURPOSES
% date_ = '2017-12-01';

% load '.mat' file
load('_dividendYields.mat','dividendYields');
% if arguments less then to the set ticker to SPX
if nargin<2
    ticker_ = 'SPX';
end
% select curve based on the date
isDate = (dividendYields.date == date_);
isTicker = (dividendYields.ticker == ticker_);
isRequested = (isDate & isTicker);
dividend_yield_tbl = dividendYields(isRequested, :);
% divide rates by 100
dividend_yield_tbl.rate = dividend_yield_tbl.rate/100;

end
