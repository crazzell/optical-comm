function [Eopt, Sopt, num, approx] = capacity_vs_pump_power_qsub(edf_type, pumpWavelengthnm, pumpPowermW, Nspans, spanLengthKm)
%% Compute maximum capacity for given pump power
% Power loading and EDF length are optimized
% Inputs:
% - edf_type: % which fiber to use. 
    % Fibers available:  
    % > {'giles_ge:silicate' (default), 'giles_al:ge:silicate'}
    % > {'principles_type1', 'principles_type2', 'principles_type3'}.
% - pumpWavelengthnm: pump wavelength in nm
% - pumpPowermW: pump power in mW
% - Nspans: number of spans
% - spanLengthKm: span length in km
% - PmaxdBm: maximum power for each signal channel in dBm
% Outputs:
% - Eopt: instance of EDF class with optimized length
% - Sopt: instance of class Channels for the signals with optimized power
% - num: numerical solution
% - approx: approximated solutions

addpath data/
addpath f/
addpath ../f/

verbose = false;

% Filename
filename = sprintf('results/capacity_vs_pump_power_EDF=%s_pump=%smW_%snm_L=%s_x_%skm.mat',...
        edf_type, pumpPowermW, pumpWavelengthnm, Nspans, spanLengthKm);
filename = check_filename(filename); % verify if already exists and rename it if it does
disp(filename) 

% convert inputs to double (on cluster inputs are passed as strings)
if ~all(isnumeric([pumpPowermW, Nspans, spanLengthKm]))
    pumpPower = 1e-3*str2double(pumpPowermW);
    pumpWavelength = 1e-9*str2double(pumpWavelengthnm);
    Nspans = round(str2double(Nspans));
    spanLength = 1e3*str2double(spanLengthKm);
end

% EDF fiber
E = EDF(10, edf_type);

% Pump & Signal
df = 50e9;
dlamb = df2dlamb(df);
lamb = 1522e-9:dlamb:1582e-9;
Signal = Channels(lamb, 0, 'forward');
Pump = Channels(pumpWavelength, pumpPower, 'forward');

% SMF fiber
SMF = fiber(spanLength, @(lamb) 0.18, @(lamb) 0);
[~, spanAttdB] = SMF.link_attenuation(Signal.wavelength);

% Problem variables
problem.spanAttdB = spanAttdB;
problem.Namp = Nspans;
problem.df = df;
problem.excess_noise = 1.5; 
problem.SwarmSize = min(500, 20*(Signal.N+1));
problem.step_approx = @(x) 0.5*(tanh(2*x) + 1); % Smoothing factor = 2

% Select range of maximum signal power based on pump power
PonVec = 1/70*(Pump.wavelength/1550e-9)*(Pump.P/(10^(mean(spanAttdB)/10)-1)); % initial power cap
prev_maxP = Inf;
for k = 1:5 % at most 5 iterations
    problem.Pon = PonVec(k);
    Signal.P(1:end) = PonVec(k);
    
    % Optimize power load and EDF length
    try
        fprintf('Power cap = %.5f mW (%.3f dBm)\n', 1e3*problem.Pon, Watt2dBm(problem.Pon));
        [Eopt{k}, Sopt{k}, exitflag{k}, num{k}, approx{k}] =...
            optimize_power_load_and_edf_length('particle swarm', E, Pump, Signal, problem, verbose);
        
        SE(k) =  sum(num{k}.SE);
        
        maxP = max(Sopt{k}.P);
        if maxP > 0.99*problem.Pon % clip
            disp('Optimal power loading was clipped')
            PonVec(k+1) = 2*problem.Pon; % double power cap if clipped            
        elseif abs(Watt2dBm(maxP) - Watt2dBm(prev_maxP)) >= 0.5 
            disp('Optimal power loading was different from previous iteration')
            PonVec(k+1) = 1.5*maxP; % change power cap to maxP + ~2 dB
        else
            break
        end
        
        prev_maxP = maxP;
        
    catch e
        warning(e.message)
        Eopt{k} = NaN; Sopt{k} = NaN; exitflag{k} = NaN; num{k} = NaN; approx{k} = NaN;
        SE(k) = NaN;
        break
    end
end

[~, kopt] = max(SE);

% Save to file
save(filename)