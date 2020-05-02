function [next_trad_date] = getNextTradingDate(date_, trad_dates_)
% Function to get the following trading date
% In
%   date_ [datetime]: Current date
%   trad_dates_ [vector]: Vector of dates
% Out
%   next_trad_date [datetime]: Following date

% FOR DEBUG PURPOSES
% date_ = '2017-12-01';
% load('_dates.mat')
% trad_dates_ = dates

isRequested = circshift(trad_dates_==date_, 1);
next_trad_date = datestr(trad_dates_(isRequested),'yyyy-mm-dd');

end
