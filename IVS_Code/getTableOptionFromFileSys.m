function [option_table] = getTableOptionFromFileSys(date_, ticker_)
% Function to get the option prices table
% In
%   date [char] {yyyy-MM-dd}: Date
%   ticker [char]: Ticker name of underlying
% Out
%   option_table [table]: Table with option prices

% FOR DEBUG PURPOSES
% date_ = '2017-12-01';

if nargin<2
    ticker_ = 'SPX';
end
% convert date to string if necessary
if isdatetime(date_)
    date_str = datestr(date_,'yyyymmdd');
elseif ischar(date_)
    date_str = char(join(strsplit(date_,'-'),''));
elseif isstring(date_)
    date_str = char(join(strsplit(date_,'-'),''));
else
    error('Unkown date type')
end
% read table
file_name = ['_optionPricesData/' date_str '.csv'];
opts = detectImportOptions(file_name);
opts.VariableNames = {'secid','date','symbol','exdate','last_date','cp_flag', ...
    'strike_price','best_bid','best_offer','volume','open_interest', ...
    'impl_volatility','delta','gamma','vega','theta','optionid', ...
    'ticker','index_flag','div_convention','exercise_style','am_set_flag'};
opts.VariableTypes = {'double','datetime','char','datetime','datetime',...
    'char','double','double','double','double','double','double',...
    'double','double','double','double','double','char','double',...
    'char','char','double'};
opts.VariableOptions(:,12).TreatAsMissing = 'NA';
opts.VariableOptions(:,13).TreatAsMissing = 'NA';
opts.VariableOptions(:,14).TreatAsMissing = 'NA';
opts.VariableOptions(:,15).TreatAsMissing = 'NA';
opts.VariableOptions(:,16).TreatAsMissing = 'NA';
optionPrices_ = readtable(file_name,opts);
% conversion
optionPrices_.cp_flag = categorical(optionPrices_.cp_flag);
optionPrices_.ticker = categorical(optionPrices_.ticker);
optionPrices_.div_convention = categorical(optionPrices_.div_convention);
optionPrices_.exercise_style = categorical(optionPrices_.exercise_style);
optionPrices_.symbol = string(optionPrices_.symbol);
%
isRequested = (optionPrices_.ticker == ticker_);
option_table = optionPrices_(isRequested,:);
% divide strike by 1000
option_table.strike_price = option_table.strike_price/1000;
% redefine flag
option_table.cp_flag = (option_table.cp_flag == 'C') - ...
    (option_table.cp_flag == 'P');
% calculate time to maturity in years
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
