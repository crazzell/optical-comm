%% Plot final curves
clear, clc, close all

Lspan = 0:10;
Prec_dqpsk_theory = [-30.1284261077549,-30.1284261077549,-30.1284261077549,-30.1284261077549,-30.1284261077549,-30.1284261077549,-30.1284261077549,-30.1284261077549,-30.1284261077549,-30.1284261077549,-30.1284261077549];
Prec_dqpsk_enob4 = [-26.5425867550074,-26.3366940184331,-26.5332663219999,-26.3054542230310,-26.2285078752495,-25.7813502523169,-25.6861388160907,-25.2559785980040,-24.6597576820493,-23.9896945043901,-23.1834648497271];
Prec_dqpsk_enobInf = [-27.9779902099372,-27.9294281911093,-27.8616600209428,-27.7979720197385,-27.5358341748796,-27.3494848593896,-27.2403129958443,-26.9616325417719,-26.5963556913557,-26.2374018073473,-25.5475599973890];

% QPSK assumes DPLL
Prec_qpsk_theory = [-32.5250233495152,-32.5250233495152,-32.5250233495152,-32.5250233495152,-32.5250233495152,-32.5250233495152,-32.5250233495152,-32.5250233495152,-32.5250233495152,-32.5250233495152,-32.5250233495152];
Prec_qpsk_enob4 = [-30.1989069947056,-29.9715426479822,-29.8597173545040,-29.8309520745951,-29.7199885241380,-29.7497531030089,-29.5640683285256,-29.3588734714837,-29.2081431193596,-28.9815007252740,-28.6234301858235];
Prec_qpsk_enobInf = [-30.7682600779459,-30.7218092989141,-30.7407887997361,-30.8704203890362,-30.5703691999887,-30.5085963805337,-30.4316297227746,-30.2897166291723,-30.1044925743504,-29.9141396575355,-29.6825721021575];

Color = {[51, 105, 232]/255, [255,127,0]/255};

figure, hold on, box on
plot(Lspan, Prec_qpsk_enob4, '-o', 'Color', Color{1}, 'LineWidth', 2)
plot(Lspan, Prec_dqpsk_enob4, '-o', 'Color', Color{2}, 'LineWidth', 2)
plot(Lspan, Prec_qpsk_theory, ':', 'Color',  Color{1}, 'LineWidth', 2)
plot(Lspan, Prec_qpsk_enobInf, '--o', 'Color', Color{1}, 'LineWidth', 2)
plot(Lspan, Prec_dqpsk_enobInf, '--o', 'Color', Color{2}, 'LineWidth', 2)
plot(Lspan, Prec_dqpsk_theory, ':', 'Color', Color{2}, 'LineWidth', 2)
legend('QPSK', 'DQPSK')
xlabel('Fiber length (km)', 'FontSize', 12)
ylabel('Receiver sensitivity (dBm)', 'FontSize', 12)
set(gca, 'FontSize', 12)