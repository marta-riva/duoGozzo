function [interest_rate_tbl] = getTableZeroCurve(date_)
% Function to get the zero curves table
% In
%   date_ [string] {yyyy-MM-dd}: Date
% Out
%   zero_curve_table [table]: Table with zero curve

% FOR DEBUG PURPOSES
% date_ = '2017-12-01';

% load '.mat' file
load('_zeroCurves.mat','zeroCurves');
% select curve based on the date
isDate = (zeroCurves.date == date_);
interest_rate_tbl = zeroCurves(isDate, :);
% divide rates by 100
interest_rate_tbl.rate = interest_rate_tbl.rate/100;
% make sure that rows are sorted by tenor
interest_rate_tbl = sortrows(interest_rate_tbl, 2);
interest_rate_tbl.tenor = interest_rate_tbl.tenor/365;

end
