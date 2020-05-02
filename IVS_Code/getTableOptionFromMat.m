function [option_table] = getTableOptionFromMat(date_, optionPrices_, ticker_)
% Function to get the option prices table
% In
%   date [char] {yyyy-MM-dd}: Date
%   optionPrices [table]: Containing all the option prices
%   ticker [char]: ticker Name of underlying
% Out
%   option_table [table]: Table with option prices

% FOR DEBUG PURPOSES
% date_ = '2017-12-01';
% load('optionPrices.mat', 'optionPrices')

% select option prices based on date and ticker
if nargin<3
    ticker_ = 'SPX';
end
isDate = (optionPrices_.date == date_);
isTicker = (optionPrices_.ticker == ticker_);
isRequested = (isDate & isTicker);
option_table = optionPrices_(isRequested, :);
% divide strike by 1000
option_table.strike_price = option_table.strike_price/1000;
% redefine flag
option_table.cp_flag = (option_table.cp_flag == 'C') - ...
    (option_table.cp_flag == 'P');
% calculate time to maturity in days and years
dtms = datenum(option_table.exdate) - datenum(option_table.date);
option_table.dtm = dtms;
% if am flag set to true then subtract one day
option_table.ytm = dtms/365 - double(option_table.am_set_flag)/365;
option_table.ytm(option_table.ytm < 0) = 0;
% calculate mid price
option_table.mid = (option_table.best_offer + option_table.best_bid)/2;
% sorting by strike
option_table = sortrows(option_table, 7);
% sorting by flag
option_table = sortrows(option_table, 6);
% sorting by days to maturity
option_table = sortrows(option_table, 23);

end
