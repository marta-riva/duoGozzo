function [impl_vol_approx] = calcIvApproxLiRationalFunc(p_mkt_, option_, ...
    mkt_data_)
% This function calculates the IV approximation due to Li
% In
%   p_mkt_ [vector]: Vector of market prices
%   option_ [strcut]: Options
%   mkt_data_ [strcut]: Market data
% Out
%   impl_vol_approx [vector]: Impied volatility approximations
% Reference
%   Li, 2006, "You Don't Have to Bother Newton for Implied Volatility",
%   http://papers.ssrn.com/sol3/papers.cfm?abstract_id=952727

K = option_.K;
tau = option_.tau;
cp_flag = option_.cp_flag;
zr = mkt_data_.zr;
F_t = mkt_data_.F_t;
len_p_mkt = length(p_mkt_);
% p
p = [-0.969271876255; 0.097428338274; 1.750081126685];
% m
m = ones(1,1,14);
m(:) = [...
    6.268456292246;
    -6.284840445036;
    30.068281276567;
    -11.780036995036;
    -2.310966989723;
    -11.473184324152;
    -230.101682610568;
    86.127219899668;
    3.730181294225;
    -13.954993561151;
    261.950288864225;
    20.090690444187;
    -50.117067019539;
    13.723711519422];
m = m(ones(len_p_mkt,1),1,:);
% n
n = ones(1,1,14);
n(:) = [...
    -0.068098378725;
    0.440639436211;
    -0.263473754689;
    -5.792537721792;
    -5.267481008429;
    4.714393825758;
    3.529944137559;
    -23.636495876611;
    -9.020361771283;
    14.749084301452;
    -32.570660102526;
    76.398155779133;
    41.855161781749;
    -12.150611865704];
n = n(ones(len_p_mkt,1),1,:);
% i
i = ones(1,1,14);
i(:) = [0,1,0,1,2,0,1,2,3,0,1,2,3,4];
i = i(ones(len_p_mkt,1),1,:);
% j
j = ones(1,1,14);
j(:) = [1,0,2,1,0,3,2,1,0,4,3,2,1,0];
j = j(ones(len_p_mkt,1),1,:);

% Calculate Normalized Moneyness Measure
x = log(F_t./K);
% Convert Put to Call by Parity Relation
isPut = (cp_flag == -1);
p_mkt_call = p_mkt_ + isPut.*(F_t - K).*exp(-zr.*tau);
% Normalized Call Price
norm_p_mkt_call = p_mkt_call./(F_t.*exp(-zr.*(tau)));

% Repmat to 3d size 14
x = x(:,:,ones(1,14));
% Repmat to 3d size 14
norm_p_mkt_call = norm_p_mkt_call(:,:,ones(1,14));

% Rational Function -  Eqn(19) of Li 2006
fcnv = @(p,m,n,i,j,x,c)(p(1).*x(:,:,1) + p(2).*sqrt(c(:,:,1)) + p(3).*c(:,:,1) + (sum(n.*((x.^i).*(sqrt(c).^j)),3))./(1 + sum(m.*((x.^i).*(sqrt(c).^j)),3)));
% D- Domain (x<=-1)
v1 = fcnv(p,m,n,i,j,x,norm_p_mkt_call);
% Reflection for D+ Domain (x>1)
v2 = fcnv(p,m,n,i,j,-x,exp(x).*norm_p_mkt_call + 1 -exp(x)); 
v = zeros(size(p_mkt_)); v(x(:,:,1)<=0)=v1(x(:,:,1)<=0); v(x(:,:,1)>0)=v2(x(:,:,1)>0);
% Domain-of-Approximation is x={-0.5,+0.5},v={0,1},x/v={-2,2}
domainFilter = x(:,:,1)>=-0.5 & x(:,:,1)<=0.5 & v > 0 & v <1 & (x(:,:,1)./v)<=2 & (x(:,:,1)./v)>=-2;
% v = sigma.*(sqrt(tau));
impl_vol_approx = v./sqrt(tau);
% use 0.8 arbtrarily as best vol-guess for out-of-domain points
impl_vol_approx(~domainFilter) = 0.8;

end
