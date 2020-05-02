function [otm_option_table] = makeTableOptionOtm(filtered_option_table_)
% Function to filter ITM option data
% In
%   filtered_option_table_ [table]: Filtered option table
% Out
%   otm_option_table [table]: OTM option table

isCall = (filtered_option_table_.cp_flag == 1);
isPut = (filtered_option_table_.cp_flag == -1);
isItmCall = (filtered_option_table_.strike_price < ...
    filtered_option_table_.impl_forward);
isItmPut = (filtered_option_table_.strike_price > ...
    filtered_option_table_.impl_forward);
isNotRequested = (isItmCall & isCall) | (isItmPut & isPut);
otm_option_table = filtered_option_table_(~isNotRequested,:);

end
