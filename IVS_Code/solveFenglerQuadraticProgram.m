function [g, gamma] = solveFenglerQuadraticProgram(u, y, A, b, lb, ub, lambda)
% Function to solve the quadratic program of Fenlger's implied volatility
% surface smoothing algorithm
% In
%   u [vector]: Moneyness of nodes
%   y [vector]: Call prices at nodes
%   A [matrix]: Matrix for linear inequality (Ax <= b)
%   b [vector]: Vector of inequality values
%   lb [vector]: Lower bound
%   ub [vector]: Upper bound
%   lambda [float]: Smoothing parameter
% Out
%   g [vector]: Vector of smoothed call option prices
%   gamma [vector]: Vector of second derivatives at nodes
% Source
%   based on https://www.mathworks.com/matlabcentral/fileexchange/ ...
%   46253-arbitrage-free-smoothing-of-the-implied-volatility-surface

n = length(u);

if nargin == 6
    lambda = 1e-2;
end

% ensure column vectors
u = u(:);
y = y(:);

% check that input is consistent
if length(y) ~= length(u)
    error('length of y is incorrect');
end

if any(ub-lb<0)
    pos_neg = ub-lb<0;
    lb(pos_neg) = ub(pos_neg);
end

% set up estimation and restriction matrices
h = diff(u,1);

Q = zeros(n,n-2);
for j = 2:(n-1)
    Q(j-1,j-1) = h(j-1)^(-1);
    Q(j,  j-1) = -h(j-1)^(-1) - h(j)^(-1);
    Q(j+1,j-1) = h(j)^(-1);
end

R = zeros(n-2,n-2);
for i = 2:(n-1)
    R(i-1,i-1) = 1/3*(h(i-1)+h(i));
    if i < n-1
        R(i-1,i+1-1) = 1/6*h(i);
        R(i+1-1,i-1) = 1/6*h(i);
    end
end

% set-up problem min_x -y'x + 0.5 x'Bx

% linear term
y = [y;zeros(n-2,1)];

%quadratic term
B = [diag(ones(n,1)) zeros(n,size(R,2)); zeros(size(R,1),n) lambda*R]; 

% initial guess
x0 = y; 
x0(n+1:end) = 1e-3;

% equality constraint Aeq x = beq
Aeq = [Q; -R']';
beq = zeros(size(Aeq,1),1);

% estimate the quadratic program
options = optimoptions('quadprog');
options = optimoptions(options, 'Algorithm', 'interior-point-convex', ...
    'Display', 'off');
x = quadprog(B, -y, A, b, Aeq, beq, lb, ub, x0, options);

% First n values of x are the points g_i
g = x(1:n);

% Remaining values of x are the second derivatives
gamma = [0; x(n+1:2*n-2); 0];
    
end
