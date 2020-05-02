function [option_table] = getTableOptionMultipleDays(date_from_,date_to_,ticker_,source_)
% Function to get the option prices table for multiple days
% In
%   date_from_ [char] {yyyy-MM-dd}: Date from
%   date_to_ [char] {yyyy-MM-dd}: Date to
%   ticker [char]: Ticker name of underlying
%   source_ [char]: 'filesys', 'db' or 'mat'
% Out
%   option_table [table]: Table with option prices

% FOR DEBUG PURPOSES
% date_from_ = '2017-12-01';
% date_to_ = '2017-12-29';

if nargin<3
    ticker_ = 'SPX';
    source_ = 'filesys';
elseif nargin<3
    source_ = 'filesys';
end
%
load('_dates.mat','dates')
dates_target = dates(dates<=date_to_ & dates>=date_from_);
if strcmp(source_,'db')
    option_table = getTableOptionFromDB(dates_target(1),ticker_);
    for i=2:length(dates_target)
        option_table = vertcat(option_table,...
            getTableOptionFromDB(dates_target(i),ticker_));
    end
elseif strcmp(source_,'mat')
    load('_optionPrices.mat', 'optionPrices')
    option_table = getTableOptionFromMat(dates_target(1),optionPrices,ticker_);
    for i=2:length(dates_target)
        option_table = vertcat(option_table,...
            getTableOptionFromMat(dates_target(i),optionPrices,ticker_));
    end
elseif strcmp(source_,'filesys')
    option_table = getTableOptionFromFileSys(dates_target(1),ticker_);
    for i=2:length(dates_target)
        option_table = vertcat(option_table,...
            getTableOptionFromFileSys(dates_target(i),ticker_));
    end
else
    error('Invalid source')
end

end

