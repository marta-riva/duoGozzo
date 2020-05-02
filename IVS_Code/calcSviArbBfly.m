function [slice_arb] = calcSviArbBfly(svi_mod_, mod_)
% This function calculates the arbitrage butterfly for multiple slices
% In
%   svi_mod_ [struct]: SVI parametrization
%   mod_ [char]: Parametrization ('raw', 'surf', 'nat' or 'jw')
% Out
%   slice_arb [table]: Table with bfly arbitrage values

taus = svi_mod_.ts;
raw_svi_mod = makeSviModelConversion(svi_mod_, mod_, 'raw');
slice_arb = zeros(length(taus),3);
for i = 1:length(taus)
    raw_svi_mod_slice = makeSviModelReduce(raw_svi_mod, taus(i));
    fun = @(k) calcSviDensity(raw_svi_mod_slice, k, 'raw');
    [res, fval] = fminbnd(fun,0,5);
    kArb = res;
    gArb = min(fval,0);
    slice_arb(i,:) = [taus(i) kArb gArb];
 end
%
slice_arb = array2table(slice_arb);
slice_arb.Properties.VariableNames = {'tau' 'kArb' 'gArb'};

end

