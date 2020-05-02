% Main script to interpolate volatility surfaces on a regular delta-tenor
% grid
clc
clear
close all

% dates
load('_dates.mat')
dates = dates(3777:end);
impl_vol = zeros(19*12*length(dates),4);
for i=1:length(dates)
    date = dates(i);
    from = (i-1)*19*12+1;
    to = i*19*12;
    try
        % Get market options data from files
        raw_option_table = getTableOptionFromFileSys(date);
        % Get underlying and zero curves market data
        underlying_table = getTableUnderlyingPrice(date);
        zerocurve_table = getTableZeroCurve(date);
        divyield_table = getTableDividendYield(date);
        % Filter options data
        filtered_option_table = makeTableOptionFiltered(raw_option_table);
        % Make interest rates structure and interpolation
        raw_Irs = makeIrsFromZeroCurve(zerocurve_table.rate, zerocurve_table.tenor);
        taus = unique(filtered_option_table.ytm);
        interp_Irs = interpZrFromIrs(raw_Irs, taus, 'linear');
        % Calculate implied forwards and implied dividend yields
        Ifs = calcImpliedForwards(filtered_option_table, interp_Irs, ...
            underlying_table, divyield_table);
        % Populate table with further columns
        [~, idxs] = ismember(filtered_option_table.ytm, taus);
        filtered_option_table.interest_rate = interp_Irs.zr_ts(idxs);
        filtered_option_table.impl_forward = Ifs.qs(idxs);
        % Further filter options data - remove ITM options
        otm_option_table = makeTableOptionOtm(filtered_option_table);
        % Calculate implied volatilites
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
        % Compute call prices and log strike
        bs_mod = makeBsModel(otm_option_table.impl_volatility_mid);
        option.cp_flag = ones(size(bs_mod.sigma));
        otm_option_table.call_price = calcBsPriceAnalytic(bs_mod, option, mkt_data,...
            'forward');
        otm_option_table.k = log(otm_option_table.strike_price./...
            otm_option_table.impl_forward);
        % Fengler smoothing
        [u, tau, g, gamma] = calibFenglerSplineNodes(otm_option_table);
        if any(gamma<0,'all')
            error('Gamma has to be greater equal zero')
        elseif any(g<0,'all')
            error('Spline values have to be greater equal zero')
        end
        % Delta moneyness interpolation
        [~, idxs] = unique(option.tau);
        mkt_data_unique = makeMarketData(mkt_data.S_t(idxs), ...
            mkt_data.F_t(idxs), mkt_data.zr(idxs), mkt_data.q(idxs));
        delta_target = [(-0.05:-0.05:-0.45)';(0.5:-0.05:0.05)'];
        tau_target = (365/12:365/12:1*365)'/365;
        interp_Irs_target = interpZrFromIrs(raw_Irs, tau_target, 'linear');
        interp_Ifs_target = interp1(Ifs.ts, Ifs.qs, tau_target, 'linear', ...
            'extrap');
        impl_volatility = zeros(length(delta_target), length(tau_target));
        for t = 1:length(tau_target)
            tau_loop = tau_target(t);
            interp_Irs_loop = interp_Irs_target.zr_ts(t);
            interp_Ifs_loop = interp_Ifs_target(t);
            for k = 1:length(delta_target)
                impl_volatility(k,t) = interpIvFromDeltaTau(delta_target(k), ...
                    tau_loop, mkt_data_unique, interp_Irs_loop, ...
                    interp_Ifs_loop, 'forward', u, tau, g, gamma);
            end
        end
        % 
        temp = [repmat(datenum(date),length(tau_target)*length(delta_target),1), ...
            reshape(repmat(tau_target,1,length(delta_target))',length(tau_target)*length(delta_target),1), ...
            repmat(delta_target,length(tau_target),1), ...
            reshape(impl_volatility,length(tau_target)*length(delta_target),1)];
        impl_vol(from:to,:) = temp;
        disp('Calculation done for')
        disp(date)
    catch ME
        disp(ME)
        disp('!!!!!!! Error for !!!!!!!')
        disp(date)
        temp = [repmat(datenum(date),19*12,1),zeros(19*12,1),zeros(19*12,1),zeros(19*12,1)];
        impl_vol(from:to,:) = temp;
    end
end
