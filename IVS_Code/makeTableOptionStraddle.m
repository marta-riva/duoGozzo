function [calls, puts] = makeTableOptionStraddle(filtered_option_table_, ...
    ytm_)
% Function to build straddles
% In
%   filtered_option_table_ [table]: Filtered option table
% Out
%   calls [table]: Calls option table
%   puts [table]: Puts option table

isCall = (filtered_option_table_.cp_flag == 1);
isPut = (filtered_option_table_.cp_flag == -1);
isRequested = (filtered_option_table_.ytm == ytm_);
calls = filtered_option_table_(isCall & isRequested, :);
puts = filtered_option_table_(isPut & isRequested, :);
[~,idx_c,idx_p] = intersect(calls.strike_price,puts.strike_price);
calls = calls(idx_c,:);
puts = puts(idx_p,:);

end
