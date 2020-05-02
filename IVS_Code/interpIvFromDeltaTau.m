function [impl_volatility, fwd_moneyness] = ...
    interpIvFromDeltaTau(delta_target_, tau_target_, ...
    mkt_data_, interp_zr_, interp_F_t_, method_, u_, tau_, g_, gamma_)
% Function to interpolate zero-coupon rates
% In
%   irs_ [struct]: Raw interest rate structure
%   tqs_ [vector]: Tenors to interpolate at
%   method_ [char]: 'linear','spline' or 'pchip'
% Out
%   impl_volatility [float]: Implied volatility
%   fwd_moneyness [float]: Forward moneyness

cp_flag_target = 1*(delta_target_>0)-1*(delta_target_<0);
synth_option = makeVanillaOption(NaN, tau_target_, cp_flag_target);
fun = @(fwd_moneyness) calcDelta(fwd_moneyness, synth_option, ...
    mkt_data_, interp_zr_, interp_F_t_, method_, u_, tau_, g_, ...
    gamma_) - delta_target_;
%
lb = 0.4*(cp_flag_target == -1) + 0.9*(cp_flag_target == 1);
ub = 1.1*(cp_flag_target == -1) + 1.4*(cp_flag_target == 1);
fwd_moneyness = fzero(fun, [lb, ub]);
[~, impl_volatility] = calcDelta(fwd_moneyness, synth_option, mkt_data_, ...
    interp_zr_, interp_F_t_, method_, u_, tau_, g_, gamma_);

end

function [delta, impl_volatility] = calcDelta(fwd_moneyness_, ...
    synth_option_, mkt_data_, interp_zr_, interp_F_t_, method_, u_, tau_, ...
    g_, gamma_)
% In
% Out

[isTrue, idx] = ismember(synth_option_.tau, tau_);
if isTrue
    option = makeVanillaOption(fwd_moneyness_.*mkt_data_.F_t(idx), ...
        tau_(idx), ones(size(idx)));
    synth_mkt_data = makeMarketData(mkt_data_.S_t(idx), mkt_data_.F_t(idx), ...
        mkt_data_.zr(idx), mkt_data_.q(idx));
    [~, impl_vol] = calcFenglerSmoothIvQs(u_, tau_, g_, gamma_, ...
        option, synth_mkt_data, method_);
    bs_mod = makeBsModel(impl_vol);
    synth_option_.K = fwd_moneyness_.*mkt_data_.F_t(idx);
else
    option = makeVanillaOption(fwd_moneyness_.*mkt_data_.F_t, tau_, ...
        ones(size(tau_)));
    [~, impl_vol] = calcFenglerSmoothIvQs(u_, tau_, g_, gamma_, option, ...
        mkt_data_, method_);
    impl_tot_var = impl_vol.^2.*tau_;
    interp_tot_var = interp1(tau_, impl_tot_var, synth_option_.tau, ...
        'linear', 'extrap');
    interp_impl_vol = sqrt(interp_tot_var/synth_option_.tau);
    synth_mkt_data = makeMarketData(mkt_data_.S_t(1), interp_F_t_, ...
        interp_zr_, mkt_data_.q(1));
    bs_mod = makeBsModel(interp_impl_vol);
    synth_option_.K = fwd_moneyness_*interp_F_t_;
end
%
if (nargout == 1)
    delta = calcBsDeltaAnalytic(bs_mod, synth_option_, synth_mkt_data, ...
        method_);
elseif (nargout > 1)
    delta = NaN;
    impl_volatility = bs_mod.sigma;
end

end
