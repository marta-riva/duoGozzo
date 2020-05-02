function [filtered_option_table] = makeTableOptionFiltered(raw_option_table_)
% Function to filter the raw option data
% In
%   raw_option_table_ [table]: Raw option table
% Out
%   filtered_option_table [table]: Filtered option table

isValidBid = (raw_option_table_.best_bid > 0.1);
isValidAsk = (raw_option_table_.best_offer > 0.1);
hasValidExpiration = (raw_option_table_.dtm > 7) & ...
    (raw_option_table_.dtm < 1.5*365.25);
hasValidTrading = (datenum(raw_option_table_.date)-...
    datenum(raw_option_table_.last_date) <= 3);
% hasValidOpenInterest = (raw_option_table_.open_interest > 0);
% hasValidVolume = (raw_option_table_.volume > 0);
% define isValid
isValid = isValidBid & ...
            isValidAsk & ...
            hasValidTrading & ...
            hasValidExpiration;% & ...
%             hasValidOpenInterest; & ...
%             hasValidVolume;
% hasValidIv = ~(isnan(raw_option_table_.impl_volatility));
% isValid = hasValidIv;
% define filtered option table    
filtered_option_table = raw_option_table_(isValid,:);
% getting rid of weekly options
symbol_split = split(filtered_option_table.symbol,' ');
hasSpxSymbol = (symbol_split(:,1) == 'SPX');
if any(symbol_split(:,1) == 'SPX') && any(symbol_split(:,1) == 'SPXW')
    isValid = hasSpxSymbol;
    filtered_option_table = filtered_option_table(isValid, :);
end

end
