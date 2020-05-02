% Test script Zeliade Quasi-Explicit calibration
clc
clear
close all

%% Test Zeliade Quasi-Explicit Calibration
% mod = makeSviModelRaw(0.030,0.125,-0.8,0.074,0.050,1)
% mod = makeSviModelRaw(0.032,0.094,-0.99,0.093,0.041,1)
mod = makeSviModelRaw(0.028,0.105,-0.99,0.096,0.072,1)
% mod = makeSviModelRaw(0.04,0.1,-0.5,0,0.1,1)
% mod = makeSviModelRaw(0.1,0.06,-0.9,0.24,0.06,1)
%
k = (-1:0.01:1)';
tau = ones(size(k));
tot_ivar = calcSviTotIvarQs(mod, k, 'raw');
otm_option_table = array2table([tau, k, sqrt(tot_ivar./tau)]);
otm_option_table.Properties.VariableNames{1} = 'ytm';
otm_option_table.Properties.VariableNames{2} = 'k';
otm_option_table.Properties.VariableNames{3} = 'impl_volatility_mid';
%
mod_calib = calibSviModelRawZeliade(otm_option_table)
