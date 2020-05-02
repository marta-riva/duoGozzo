function [xTrain, yTrain] = makeTableVolaSurf(date_, lookback_, maturity_)
% Function to build the dataset for training the ANNs with OptionMetrics
% volatility surfaces
% In
%   date [string] {yyyy-MM-dd}: Date
%   lookback_ [integer]: Lookbak period
%   maturity_ [integer]: Tenor
% Out
%   xTrain [table]: Calls option table
%   yTrain [table]: Puts option table

if nargin < 3
    maturity_ = 30;
end
%
load('_dates.mat','dates');
idx_date_to = find(date_ == dates);
idx_date_from = idx_date_to-lookback_;
date_to = dates(idx_date_to);
date_from = dates(idx_date_from);
%
vola_surf_table = getTableVolatilitySurface(date_from,date_to,'SPX');
vola_surf_table.ytm = vola_surf_table.days/365;
spx_price_table = getTableUnderlyingPrice(date_from,date_to,'SPX');
vix_price_table = getTableUnderlyingPrice(date_from,date_to,'VIX');
%
isOtmCall = vola_surf_table.delta <= 55;
isOtmPut = vola_surf_table.delta >= -55;
if strcmp(maturity_,'all')
    isMaturity = true(size(vola_surf_table,1),1);
else
    isMaturity = (vola_surf_table.days == maturity_);
end
isRequested = (isOtmCall & isOtmPut & isMaturity);
%
xTrain = vola_surf_table(isRequested,[2 4 5 12]);
% averaging
isP555045 = ismember(xTrain.delta,[-55 -50 -45]);
isC555045 = ismember(xTrain.delta,[55 50 45]);
p555045 = xTrain(isP555045,:);
c555045 = xTrain(isC555045,:);
imp_vol_average = (p555045.impl_volatility + c555045.impl_volatility)/2;
% redifine impl vola
xTrain.impl_volatility(isP555045) = imp_vol_average;
xTrain.impl_volatility(isC555045) = imp_vol_average;
% further filtering
isOtmCall = xTrain.delta < 50;
isOtmPut = xTrain.delta >= -50;
xTrain = xTrain(isOtmCall & isOtmPut,:);
% rescaling of delta
xTrain.delta = -1/100*xTrain.delta+1/2*(xTrain.delta>0)-1/2*(xTrain.delta<0);
% sorting
xTrain = sortrows(xTrain,2);
xTrain = sortrows(xTrain,4);
xTrain = sortrows(xTrain,1);
% add vix and spx info
[~,idxs_vix] = ismember(xTrain.date,vix_price_table.date);
[~,idxs_spx] = ismember(xTrain.date,spx_price_table.date);
xTrain.vix_level = vix_price_table.close(idxs_vix);
xTrain.spx_return = spx_price_table.log_return(idxs_spx);
%
isRequested = (xTrain.date > date_from);
yTrain = xTrain.impl_volatility(isRequested);
isRequested = (xTrain.date < date_to);
xTrain = xTrain(isRequested,:);

end

