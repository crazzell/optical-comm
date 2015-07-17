%% Calculate BER of amplified IM-DD system. 
% BER is calculated via montecarlo simulation and through saddlepoint approximation
% to calculate tail probabilities given the moment generating funcion.

function [ber, mpam] = soa_ber(mpam, tx, fiber, soa, rx, sim)

dBm2Watt = @(x) 1e-3*10.^(x/10);

% Auxiliary variables
link_gain = soa.Gain*fiber.link_attenuation(tx.lamb)*rx.R; % Overall link gain
Deltaf = rx.elefilt.noisebw(sim.fs)/2; % electric filter one-sided noise bandwidth
Deltafopt = rx.optfilt.noisebw(sim.fs)/2; % optical filter baseband equivalent one-sided noise bandwidth
% function to calculate noise std
varTherm = rx.N0*Deltaf; % variance of thermal noise

% Variance of signal dependent noise
if sim.shot
    varShot = @(Plevel) 2*1.60217657e-19*(rx.R*Plevel + rx.Id)*Deltaf;
else
    varShot = @(Plevel) 0;
end

if sim.RIN
    varRIN =  @(Plevel) 10^(tx.RIN/10)*Plevel.^2*Deltaf;
else
    varRIN = @(Plevel) 0;
end

% Variance of shot and RIN
varSigDependent = @(Plevel) varShot(Plevel) + varRIN(Plevel);

% Noise std for the level Plevel
noise_std = @(Plevel) sqrt(varTherm + varSigDependent(Plevel)...
    + 2*rx.R^2*Plevel*soa.N0*Deltaf + rx.R^2*soa.N0^2*Deltafopt*Deltaf*(1-1/(2*Deltafopt/Deltaf)));
% Note: Plevel corresponds to the level after SOA amplification.
% Therefore, the soa.Gain doesn't appear in the second term because
% it's already included in the value of Plevel.
% Note: second term corresponds to sig-sp beat noise, and third term
% corresponds to sp-sp beat noise with noise in one polarization.
% Multiply last term by 2 in order to include noise in other polarization

% Level Spacing Optimization
if strcmp(mpam.level_spacing, 'optimized')
    % is sim.stats is set to Gaussian, then use Gaussian approximation,
    % otherwise uses accurate statistics
    if isfield(sim, 'stats') && strcmp(sim.stats, 'gaussian')        
        % Optimize levels using Gaussian approximation
        mpam.optimize_level_spacing_gauss_approx(sim.BERtarget, tx.rexdB, noise_std, sim.verbose);     
    else
        % Optimize levels using accurate noise statisitics
        [a, b] = level_spacing_optm(mpam, tx, soa, rx, sim);
        mpam.set_levels(a, b);
    end
end   
    
% Transmitted power
Ptx = dBm2Watt(tx.PtxdBm);

ber.count = zeros(size(Ptx));
ber.est = zeros(size(Ptx));
ber.gauss = zeros(size(Ptx));
ber.awgn = zeros(size(Ptx));
for k = 1:length(Ptx)
    tx.Ptx = Ptx(k);
         
    % Montecarlo simulation
    ber.count(k) = ber_soa_montecarlo(mpam, tx, fiber, soa, rx, sim);
    
    % Estimated BER using KLSE Fourier and saddlepoint approximation of
    % tail probabilities
    [ber.est(k), ber.gauss(k)] = ber_soa_klse_fourier(mpam, tx, fiber, soa, rx, sim);
    
    % AWGN  
    mpam.adjust_levels(tx.Ptx*link_gain, tx.rexdB);

    ber.awgn(k) = mpam.ber_awgn(noise_std);
end

if sim.verbose   
    figure, hold on
    plot(tx.PtxdBm, log10(ber.count), '-o')
    plot(tx.PtxdBm, log10(ber.est))
    plot(tx.PtxdBm, log10(ber.gauss))
    plot(tx.PtxdBm, log10(ber.awgn))
    % plot(tx.PtxdBm, log10(ber.est_pdf))
    legend('Counted', 'KLSE Fourier & Saddlepoint Approx', 'Gaussian Approximation', 'AWGN',...
        'Location', 'SouthWest')
    axis([tx.PtxdBm(1) tx.PtxdBm(end) -10 0])
end
    