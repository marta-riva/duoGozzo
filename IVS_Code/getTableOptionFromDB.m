function [option_table] = getTableOptionFromDB(date_, ticker_)
% Function to get the option prices table
% In
%   date [string] {yyyy-MM-dd}: Date
%   conn [connection]: Connection to PostgreSQL database
%   ticker [char]: Ticker name of underlying
% Out
%   option_table [table]: Table with option prices

conn = makeDBConnection('optionMetrics');
%
if nargin<3
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
% define query
columns = ['secid,date,symbol,exdate,last_date,cp_flag,' ...
    'strike_price,best_bid,best_offer,volume,open_interest,' ...
    'impl_volatility,delta,gamma,vega,theta,optionid,ticker,' ...
    'index_flag,div_convention,exercise_style,am_set_flag'];
schema = [char(34), 'optionPricesData', char(34)];
table = [char(34), date_str, char(34)];
ticker = [char(39), ticker_, char(39)];
selectquery = ['SELECT ', columns, ' FROM ', schema, '.', table, ...
    ' WHERE ticker = ', ticker, ';'];
% execute query
option_table = select(conn,selectquery);
% conversion
option_table.date = datetime(option_table.date,'InputFormat','yyyy-MM-dd');
option_table.exdate = datetime(option_table.exdate,'InputFormat','yyyy-MM-dd');
option_table.last_date = datetime(option_table.last_date,'InputFormat','yyyy-MM-dd');
option_table.cp_flag = categorical(option_table.cp_flag);
option_table.ticker = categorical(option_table.ticker);
option_table.div_convention = categorical(option_table.div_convention);
option_table.exercise_style = categorical(option_table.exercise_style);
option_table.symbol = string(option_table.symbol);
option_table.strike_price = double(option_table.strike_price);
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
%
close(conn)

end
