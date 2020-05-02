% Test script IV smiles
clc
clear
close all
set(groot, 'defaultAxesFontSize', 10);
set(groot, 'defaultTextInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');

%% Date
date = '2017-12-20';

%% Get market options data from DB
% raw_option_table = getTableOptionFromDB(date);

%% Get market options data from .mat
% load('_optionPrices.mat', 'optionPrices')
% raw_option_table = getTableOptionFromMat(date, optionPrices);

%% Get market options data from files
raw_option_table = getTableOptionFromFileSys(date);

%% Get underlying and zero curves market data
underlying_table = getTableUnderlyingPrice(date);
zerocurve_table = getTableZeroCurve(date);
divyield_table = getTableDividendYield(date);

%% Filter options data
filtered_option_table = makeTableOptionFiltered(raw_option_table);

%% Make interest rates structure and interpolation
raw_Irs = makeIrsFromZeroCurve(zerocurve_table.rate, zerocurve_table.tenor);
taus = unique(filtered_option_table.ytm);
interp_Irs = interpZrFromIrs(raw_Irs, taus, 'linear');

%% Calculate implied forwards and implied dividend yields
Ifs = calcImpliedForwards(filtered_option_table, interp_Irs, ...
    underlying_table, divyield_table);
[Ids, rate_fe] = calcImpliedDivYield(underlying_table, interp_Irs, Ifs, ...
    divyield_table);

%% Populate table with further columns
[~, idxs] = ismember(filtered_option_table.ytm, taus);
filtered_option_table.interest_rate = interp_Irs.zr_ts(idxs);
filtered_option_table.impl_forward = Ifs.qs(idxs);
filtered_option_table.impl_divyield = Ids.qs(idxs);

%% Further filter options data - remove ITM options
otm_option_table = makeTableOptionOtm(filtered_option_table);

%% Calculate implied volatilites
% define instrument
option = makeVanillaOption(otm_option_table.strike_price, ...
    otm_option_table.ytm, otm_option_table.cp_flag);
% define market data
mkt_data = makeMarketData(repmat(underlying_table.close, ...
    size(otm_option_table,1),1), otm_option_table.impl_forward, ...
    otm_option_table.interest_rate, repmat(divyield_table.rate, ...
    size(otm_option_table,1),1));
%
otm_option_table.impl_volatility_mid = calcIvJaeckel(otm_option_table.mid, ...
    option, mkt_data, 'forward');
otm_option_table.impl_volatility_bid = calcIvJaeckel(otm_option_table.best_bid, ...
    option, mkt_data, 'forward');
otm_option_table.impl_volatility_ask = calcIvJaeckel(otm_option_table.best_offer, ...
    option, mkt_data, 'forward');

%% Newton-Raphson method
% define pricer
% pricer = @(bs_mod, idxs) calcBsPriceAnalytic(bs_mod, option, mkt_data, ...
%     'forward', idxs);
% define vega
% vega = @(bs_mod, idxs) calcBsVegaAnalytic(bs_mod, option, mkt_data, ...
%     'forward', idxs);
% otm_option_table.impl_volatility_mid = calcIvNewtonRaphson(otm_option_table.mid, ...
%     pricer, vega);

%% Bisection method
% define pricer
% pricer = @(bs_mod, idxs) calcBsPriceAnalytic(bs_mod, option, mkt_data, ...
%     'forward', idxs);
% otm_option_table.impl_volatility_mid = calcIvBisection(otm_option_table.mid, ...
%     pricer);

%% Grid search
% define pricer
% pricer = @(bs_mod, idxs) calcBsPriceAnalytic(bs_mod, option, mkt_data, ...
%     'forward', idxs);
% otm_option_table.impl_volatility_mid = calcIvGridSearch(otm_option_table.mid, ...
%     pricer);

%% OM comparison test 
% otm_option_table.impl_volatility_mid = calcIvJaeckel(otm_option_table.mid, ...
%     option, mkt_data, 'spot');

%% Plot
makePlotSmiles(otm_option_table, underlying_table)
