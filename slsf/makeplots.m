% load data;

line_width = 1;

% f = figure();
% 
% plot(Multime(:,1), Multime(:, 2), 'LineWidth', line_width);
% hold on;
% 
% plot(Multime(:,1), Multime(:, 3), 'LineWidth', line_width);
% hold on;
% 
% plot(Multime(:,1), Multime(:, 4), 'LineWidth', line_width);
% hold off;
% 
% set(gca,'fontsize',18);
% % set(gca, 'LineWidth', 2);
% 
% title('Large Number Multiplication');
% xlabel('Number of Bits');
% ylabel('Runtime (milisec)');
% legend('Grade School', 'Gauss', 'Karatsuba');

% 


% SF-
A = [
        98.8, 13.20, 2.3;
        197.45, 37.27, 2.75;
        303.15, 119.67, 4.0;
        396.6, 171.57, 5.25;
        502.35, 286.62, 7.29;
        597.8, 333.44 8.88;
        697.70, 373.56, 8.33;
        800.70, 590.14, 9.77;
        900.45, 901.37, 10.50;
    ];
% SF+
% B = [
%         98.80, 12.20, 1.10;
%         197.45, 33.45, 1.12;
%         303.15, 108.98, 1.25;
%         396.6, 150.80, 1.19;
%         502.35, 145.58, 1.24;
%         597.80, 286.05, 1.47;
%         697.7, 259.10, 1.27;
%         800.7, 442.81, 1.40;
%         900.05, 803.19, 1.36;
%     ];


sfplus = [
    0   2.5 97.5    37.91   96.65   1.08;
    0   12.5    87.5    91.06   295.77  1.2;
    2.5 12.5    85  139.59  498.75  1.12;
    2.5 22.5    75  341.36  700.88  1.47;
    2.5 25  72.5    260.11  602.12  1.52;
    2.5 32.5    65  400.83  801.23  1.27;
    0   15  85  104.18  399.05  1.18;
    0   7.5 92.5    47.54   197.9   1.14;
];

sfminus = [
    0   2.5 97.5    25.81   96.65   2.13;
    2.5 10  87.5    73.76   295.77  4.51;
    2.5 17.5    80  122.48  456.32  6.47;
    2.5 32.5    65  145.08  503.18  6.73;
    15  30  55  344.13  799.55  9.82;
    5   40  55  326.76  699.6   9.55;
    5   30  65  188.87  600.3   7.92;
];

%CF
C = [
        102.9, 66.77;
        202, 178.07;
        302.65, 275.39;
        397.70, 565.51 ;
        498.50, 808.9;
        600.85, 1062.08
    ];

legend_a = 'S+';
legend_b = 'S-';
legend_c = 'CF';

f2 = figure();

plot(B(:,1), B(:, 2), '-k', 'LineWidth', line_width);
hold on;
plot(A(:,1), A(:, 2), '--k', 'LineWidth', line_width);
hold on;
plot(C(:,1), C(:, 2), ':k', 'LineWidth', line_width);
% hold on;
% xlabel('Block Size');
ylabel('Sec.');
legend(legend_a, legend_b, legend_c);

f3 = figure();
plot(B(:,1), B(:, 3), '-k', 'LineWidth', line_width);
hold on;
plot(A(:,1), A(:, 3), '--k', 'LineWidth', line_width);
hold on;
% xlabel('Block Size');
ylabel('Num. Iter');
legend(legend_a, legend_b);

% plot(bnmTimer(:,1), bnmTimer(:, 2), 'LineWidth', line_width);
% hold on;
% 
% plot(bnmTimer(:,1), bnmTimer(:, 3), 'LineWidth', line_width);
% hold on;
% 
% plot(bnmTimer(:,1), bnmTimer(:, 4), 'LineWidth', line_width);
% hold on;
% 
% plot(bnmTimer(:,1), bnmTimer(:, 5), 'LineWidth', line_width);
% hold on;
% 
% plot(bnmTimer(:,1), bnmTimer(:, 6), 'LineWidth', line_width);
% hold on;
% 
% plot(bnmTimer(:,1), bnmTimer(:, 7), 'LineWidth', line_width);
% hold off;
% 
% set(gca,'fontsize',18);
% % set(gca, 'LineWidth', 2);
% 
% title('Large Matrix Multiplication with BigIntegers');
% xlabel('Matrix dimension');
% ylabel('Runtime (milisec)');
% 
% legend('Naive Matrix, Grade School', 'Naive Matrix, Gauss', 'Naive Matrix, Karatsuba',...
%     'Strassen, Grade School', 'Strassen, Gauss', 'Strassen, Karatsuba');



% 3rd

% f3 = figure();
% 
% plot(nimTimer(:,1), nimTimer(:, 2), 'LineWidth', line_width);
% hold on;
% 
% plot(nimTimer(:,1), nimTimer(:, 3), 'LineWidth', line_width);
% hold on;
% 
% 
% set(gca,'fontsize',18);
% % set(gca, 'LineWidth', 2);
% 
% title('Large Number Multiplication with Regular Integers');
% xlabel('Matrix dimension');
% ylabel('Runtime (milisec)');
% 
% legend('Naive Matrix', 'Strassen');