function [svi_mod_out] = makeSviModelConversion(svi_mod_in_, from_, to_)
% Function which converts SVI parameters
% In
%   svi_mod_in_ [struct]: SVI parametrization to be converted
%   from_ [char]: 'raw','jw', 'nat' or 'surf'
%   to_ [char]: 'raw','jw', 'nat' or 'surf'
% Out
%   svi_mod_out [struct]: SVI parametrization to be converted

if strcmp(from_,'raw')
    %
    ts = svi_mod_in_.ts;
    a = svi_mod_in_.a;
    b = svi_mod_in_.b;
    rho = svi_mod_in_.rho;
    m = svi_mod_in_.m;
    sigma = svi_mod_in_.sigma;
    if strcmp(to_,'raw')
        %
        svi_mod_out = svi_mod_in_;
    elseif strcmp(to_,'nat')
        mu = m+rho.*sigma./sqrt(1-rho.^2);
        omega = 2*b.*sigma./sqrt(1-rho.^2);
        zeta = sqrt(1-rho.^2)./sigma;
        delta = a-omega/2.*(1-rho.^2);
        %
        svi_mod_out = makeSviModelNat(delta, mu, rho, omega, zeta, ts);
    elseif strcmp(to_,'jw')
        v_ts = (a+b.*(-rho.*m+sqrt(m.^2+sigma.^2)))./ts;
        w_ts = v_ts.*ts;
        psi_ts = 1./sqrt(w_ts).*b/2.*(-m./sqrt(m.^2+sigma.^2)+rho);
        p_ts = 1./sqrt(w_ts).*b.*(1-rho);
        c_ts = 1./sqrt(w_ts).*b.*(1+rho);
        v_tilde_ts = 1./ts.*(a+b.*sigma.*sqrt(1-rho.^2));
        %
        svi_mod_out = makeSviModelJW(ts, v_ts, psi_ts, p_ts, c_ts, v_tilde_ts);
    else
        error('Invalid "out" model selection')
    end
elseif strcmp(from_,'nat')
    %
    ts = svi_mod_in_.ts;
    delta = svi_mod_in_.delta;
    mu = svi_mod_in_.mu;
    rho = svi_mod_in_.rho;
    omega = svi_mod_in_.omega;
    zeta = svi_mod_in_.zeta;
    if strcmp(to_,'raw')
        a = delta + omega/2.*(1-rho.^2);
        b = omega.*zeta/2;
        m = mu-rho./zeta;
        sigma = sqrt(1-rho.^2)./zeta;
        %
        svi_mod_out = makeSviModelRaw(a,b,rho,m,sigma,ts);
    elseif strcmp(to_,'nat')
        %
        svi_mod_out = svi_mod_in_;
    elseif strcmp(to_,'jw')
        raw_svi_mod = makeSviModelConversion(svi_mod_in_,'nat','raw');
        %
        svi_mod_out = makeSviModelConversion(raw_svi_mod,'raw','jw');
    else
        error('Invalid "out" model selection')
    end
elseif strcmp(from_,'jw')
    %
    ts = svi_mod_in_.ts;
    v_ts = svi_mod_in_.v_ts;
    w_ts = v_ts.*ts;
    psi_ts = svi_mod_in_.psi_ts;
    p_ts = svi_mod_in_.p_ts;
    c_ts = svi_mod_in_.c_ts;
    v_tilde_ts = svi_mod_in_.v_tilde_ts;
    if strcmp(to_,'raw')
        b = sqrt(w_ts)/2.*(c_ts+p_ts);
        rho = 1-p_ts.*sqrt(w_ts)./b;
        beta = rho-2*psi_ts.*sqrt(w_ts)./b;
        assert(all(abs(beta)<=1))
        alpha = sign(beta).*sqrt(1./beta.^2-1);
        m = (v_ts-v_tilde_ts).*ts./b./(-rho+sign(alpha).*sqrt(1+alpha.^2)-alpha.*sqrt(1-rho.^2));
        sigma = alpha.*m;
        a = v_tilde_ts.*ts-b.*sigma.*sqrt(1-rho.^2);
        %
        svi_mod_out = makeSviModelRaw(a,b,rho,m,sigma,ts);
    elseif strcmp(to_,'nat')
        raw_svi_mod = makeSviModelConversion(svi_mod_in_,'jw','raw');
        %
        svi_mod_out = makeSviModelConversion(raw_svi_mod,'raw','nat');
    elseif strcmp(to_,'jw')
        svi_mod_out = svi_mod_in_;
    else
        error('Invalid "out" model selection')
    end
elseif strcmp(from_,'surf')
    ts = svi_mod_in_.ts;
    theta_ts = svi_mod_in_.theta_ts;
    rho = svi_mod_in_.rho;
    phi = svi_mod_in_.phi;
    if strcmp(to_,'raw')
        jw_svi_mod = makeSviModelConversion(svi_mod_in_,'surf','jw');
        %
        svi_mod_out = makeSviModelConversion(jw_svi_mod,'jw','raw');
    elseif strcmp(to_,'nat')
        jw_svi_mod = makeSviModelConversion(svi_mod_in_,'surf','jw');
        %
        svi_mod_out = makeSviModelConversion(jw_svi_mod,'jw','nat');
    elseif strcmp(to_,'jw')
        v_ts = theta_ts./ts;
        psi_ts = 1/2.*rho.*sqrt(theta_ts).*phi(theta_ts);
        p_ts = 1/2.*sqrt(theta_ts).*phi(theta_ts).*(1-rho);
        c_ts = 1/2.*sqrt(theta_ts).*phi(theta_ts).*(1+rho);
        v_tilde_ts = theta_ts./ts.*(1-rho.^2);
        %
        svi_mod_out = makeSviModelJW(ts, v_ts, psi_ts, p_ts, c_ts, v_tilde_ts);
    else
        error('Invalid "out" model selection')
    end 
else
    error('Invalid "in" model selection')
end

end

