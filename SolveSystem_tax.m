%Program to solve pollution/RBC model with AIM
%New specification of damages to output, not utility
%Decentralized model with tax policy
%12/1/2010

% ===========   M O D I F I C A D O      R I C A R D O   ===============

clear;

%First define the parameter values
global beta delta rho alpha eta theta1 theta2 gamma phic d2 d1 d0;

%{
beta = 0.98267; %discount rate
delta = 0.025; %capital depreciation
rho = .95; %persistence of TFP shock
sd = 0.007; %standard deviation of shock
alpha = 0.36; %curvature of production function

eta = 0.9979; %pollution depreciation 
theta1 = .05607; %abatement cost equation parameters, from Nordhaus
theta2 = 2.8;
gamma = 1-.696; %1 - elasticity of emissions with respect to output
phic = 2; %CRRA for consumption
d2 = 1.4647*10^(-8); %damage function parameters, from Nordhaus
d1 = -6.6722*10^(-6);
d0 = 1.395*10^(-3);
erowcoef  = 4;  
damage_scale = 5.3024; %To scale the pollution levels and get the damage function correct
d2 = d2/damage_scale^2;
d1 = d1/damage_scale;
%}


%
% calibra��o brasil 
 
beta   = 0.98;      % - 
delta  = 0.025;     % - 
rho    = 0.95;      % - 
sd     = 0.0095;    % - 
alpha  = 0.40;      % - 

eta    = 0.9979;       % de Reilly (1992) e Heutel - pollution depreciation    
theta1 = 0.04183;      % - Nordhaus - abatement cost equation parameters, from Nordhaus = 0.04183 AmLat
                       % ...arquivo 'RICE_042510'; planilha 'LatAm'; c�lula 'C31'
theta2 = 2.8;          % este... da planilha 'Parameters'; c�lula 'C63' (manteve) - 2.8
gamma  = 1 - 1.07;     % via primeira diferen�a das s�ries - 1.07
phic   = 2 ;           % - 2
d2     = ( 9.2619*10^(-9));   % - %damage function parameters, from Nordhaus
d1     = (-2.1647*10^(-6));   % - 
d0     = (-2.9736*10^(-3));   % - 
erowcoef  = 80;          % - pelo CDIAC (2010) - coefficient relating how rest-of-world emissions compare to domestic emissions (era 4)
                         % CDIAC: em 2010 total mundo = 9.167.000; Brasil = 114.468; US = 1.481.608 (thousand metric tons of carbon)
                         % resultado para Brazil � erowcoef  = 80, mas explode antes
dmg_scl  = 5.3024;       % damage scale - To scale the pollution levels and get the damage function correct (manteve)
dmg_scl  = 5.3024*(1-0.9979)/(1-eta); % new values of eta mean this needs to be rescaled
d2       = d2/dmg_scl^2; 
d1       = d1/dmg_scl;   

%}

% arquivo? sim: 1 
se_arqu1 = 0 ;     %   1 choque
se_arqu2 = 0 ;     % 100 choques

% Nome arquivo a ser salvo
planilha = strcat('brasil_2x1-', num2str(50)) ;
arquivo1 = strcat('dano', '.xlsx');
arquivo2 = strcat('elasticidade-x', '.xlsx');


imprespsize = .01;

%Solve for steady state solution based on first order condition
a_ss = 1;

%guess at the steady state values
%Guess values are from the old model's solution   - basecase: 36 e 4
k_g = 36;
e_g =  4;

guess = [k_g,e_g]; %guess for vector of steady state values
options=optimset('Display','iter','MaxFunEvals',5000,'TolFun',1*10^(-10));  %N�o tinha "[,'TolFun',1*10^(-10)]" - padr�o � -6
ss_sol = fsolve(@steadystate_tax,guess,options);                            %Usar -9 se der erro no aim_eig, olhar e voltar -10
clear options guess k_g e_g;

k_ss = ss_sol(1);
e_ss = ss_sol(2);

i_ss = delta*k_ss;
x_ss = 4*e_ss/(1-eta);
y_ss = (1-d2*(x_ss)^2-d1*(x_ss)-d0)*k_ss^alpha;
mu_ss = 1-e_ss/y_ss^(1-gamma);
z_ss = theta1*mu_ss^theta2*y_ss;
c_ss = y_ss - i_ss - z_ss;
tau_ss = theta1*theta2*mu_ss^(theta2-1)*y_ss^gamma;
r_ss = y_ss*alpha*k_ss^(-1)*(1-tau_ss*(1-mu_ss)*(1-gamma)*y_ss^(-gamma)-theta1*mu_ss^theta2);

%derivatives of firm demand equations
zy = (theta2*(1-gamma)-1)/(theta2-1)*(z_ss/y_ss);
ztau = theta2/(theta2-1)*(z_ss/tau_ss);
etau = -1/(theta2-1)*y_ss^(1-gamma)*mu_ss/tau_ss;
ey = (1-gamma)*y_ss^(-gamma) + (gamma/(theta2-1)+gamma-1)*mu_ss*y_ss^(-gamma);
rtau = -alpha*(1-gamma)*y_ss^(1-gamma)/k_ss...
    + alpha*(1-gamma)*(1+1/(theta2-1))*mu_ss*y_ss^(1-gamma)/k_ss...
    - alpha*theta1*theta2/(theta2-1)*y_ss/k_ss*mu_ss^theta2/tau_ss;
ry = alpha/k_ss - alpha*(1-gamma)^2*tau_ss*y_ss^(-gamma)/k_ss...
    + alpha*(1-gamma)*(1-gamma-gamma/(theta2-1))*tau_ss*mu_ss*y_ss^(-gamma)/k_ss...
    - alpha*theta1*(1-theta2*gamma/(theta2-1))*mu_ss^theta2/k_ss;
rk = -alpha*y_ss/k_ss^2 + alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)/k_ss^2 ...
    - alpha*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)/k_ss^2 ...
    + alpha*theta1*y_ss/k_ss^2*mu_ss^theta2;

lambda_ss = (-ztau/etau*(ey+(1-eta*beta)/(k_ss^alpha*(2*d2*x_ss+d1)))-(1-zy))...
    *(phic/c_ss*(1-zy)*(1-1/beta)+ry-(phic/c_ss*ztau*(1/beta-1)+rtau)/etau...
    *(ey+(1-eta*beta)/(k_ss^alpha*(2*d2*x_ss+d1))))^(-1);
zeta_ss = c_ss^(-phic)*(-ztau + lambda_ss*(phic*c_ss^(-1)*ztau*(1/beta-1)+rtau))/etau; 
omega_ss = -zeta_ss*(1-eta*beta)/k_ss^alpha/(2*d2*x_ss+d1);


%Write out the structural coefficient matrix h
%The order of the parameters is [c,e,k,x,mu,y,z,i,tau,r,lambda,zeta,omega,a]
neq = 14;
nlag = 1;
nlead = 1;
h = zeros(neq,neq*(nlag+1+nlead));
%Columns 1-14 are variables at t-1
%Columns 15-28 are variables at t
%Columns 28-42 are variables at t+1

%Eqn 1: evolution of shock a
h(1,14) = -rho;
h(1,28) = 1;

%Eqn 2: Budget constraint
h(2,15) = c_ss;
h(2,22) = i_ss;
h(2,21) = z_ss;
h(2,20) = -y_ss;

%Eqn 3: Capital accumulation
h(3,17) = k_ss;
h(3,3) = -k_ss*(1-delta);
h(3,22) = -i_ss;

%Eqn 4: pollution stock
h(4,4) = -eta;
h(4,16) = -(1-eta);
h(4,18) = 1;

%Eqn 5: Emissions
h(5,16) = e_ss;
h(5,20) = y_ss^(1-gamma)*(1-gamma)*(mu_ss-1);
h(5,19) = mu_ss*y_ss^(1-gamma);

%Eqn 6: Abatement
h(6,21) = 1;
h(6,19) = -theta2;
h(6,20) = -1;

%Eqn 7: Production function
h(7,20) = y_ss;
h(7,28) = -(1-d2*x_ss^2-d1*x_ss-d0)*k_ss^alpha;
h(7,3) = -(1-d2*x_ss^2-d1*x_ss-d0)*k_ss^alpha*alpha;
h(7,18) = k_ss^alpha*(2*d2*x_ss^2+d1*x_ss);

%Eqn 8: Consumer's FOC
h(8,15) = phic;
h(8,29) = beta*(r_ss+1-delta)*(-phic);
h(8,38) = beta*r_ss;

%Eqn 9: Firm's FOC wrt k
h(9,20) = alpha*y_ss/k_ss - alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)/k_ss*(1-gamma)...
    + alpha*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)/k_ss*(1-gamma)...
    - alpha*theta1*y_ss/k_ss*mu_ss^theta2;
h(9,3) = alpha*y_ss/k_ss*(-1) - alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)/k_ss*(-1)...
    + alpha*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)/k_ss*(-1)...
    - alpha*theta1*y_ss/k_ss*mu_ss^theta2*(-1);
h(9,23) = -alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)/k_ss...
    + alpha*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)/k_ss;
h(9,19) = alpha*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)/k_ss...
    - alpha*theta1*y_ss/k_ss*mu_ss^theta2*theta2;
h(9,24) = -r_ss;

%Eqn 10: Firm's FOC wrt mu
h(10,23) = 1;
h(10,20) = -gamma;
h(10,19) = -(theta2-1);


%Eqn 11: Planner's FOC wrt tau
h(11,15) = theta2/(theta2-1)*(-c_ss^(-phic))*z_ss/tau_ss*(-phic)...
    - phic*theta2/(theta2-1)*lambda_ss*c_ss^(-phic-1)*z_ss/tau_ss*(-phic-1)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-theta2)/(theta2-1)*z_ss/tau_ss*(r_ss+1-delta)*(-phic-1)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)*y_ss^(1-gamma)/k_ss*(-phic)...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1+1/(theta2-1))*mu_ss*y_ss^(1-gamma)/k_ss*(-phic)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*theta2/(theta2-1)*y_ss/k_ss*mu_ss^theta2/tau_ss*(-phic);
h(11,21) = theta2/(theta2-1)*(-c_ss^(-phic))*z_ss/tau_ss...
    - phic*theta2/(theta2-1)*lambda_ss*c_ss^(-phic-1)*z_ss/tau_ss...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-theta2)/(theta2-1)*z_ss/tau_ss*(r_ss+1-delta);
h(11,23) = theta2/(theta2-1)*(-c_ss^(-phic))*z_ss/tau_ss*(-1)...
    - phic*theta2/(theta2-1)*lambda_ss*c_ss^(-phic-1)*z_ss/tau_ss*(-1)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-theta2)/(theta2-1)*z_ss/tau_ss*(r_ss+1-delta)*(-1)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*theta2/(theta2-1)*y_ss/k_ss*mu_ss^theta2/tau_ss*(-1)...
    + zeta_ss/(theta2-1)*mu_ss*y_ss^(1-gamma)/tau_ss*(-1);
h(11,25) = -phic*theta2/(theta2-1)*lambda_ss*c_ss^(-phic-1)*z_ss/tau_ss;
h(11,11) = lambda_ss*(-phic)*c_ss^(-phic-1)*(-theta2)/(theta2-1)*z_ss/tau_ss*(r_ss+1-delta)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)*y_ss^(1-gamma)/k_ss...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1+1/(theta2-1))*mu_ss*y_ss^(1-gamma)/k_ss...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*theta2/(theta2-1)*y_ss/k_ss*mu_ss^theta2/tau_ss;
h(11,24) = lambda_ss*(-phic)*c_ss^(-phic-1)*(-theta2)/(theta2-1)*z_ss/tau_ss*r_ss;
h(11,20) = lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)*y_ss^(1-gamma)/k_ss*(1-gamma)...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1+1/(theta2-1))*mu_ss*y_ss^(1-gamma)/k_ss*(1-gamma)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*theta2/(theta2-1)*y_ss/k_ss*mu_ss^theta2/tau_ss...
    + zeta_ss/(theta2-1)*mu_ss*y_ss^(1-gamma)/tau_ss*(1-gamma);
h(11,3) = lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)*y_ss^(1-gamma)/k_ss*(-1)...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1+1/(theta2-1))*mu_ss*y_ss^(1-gamma)/k_ss*(-1)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*theta2/(theta2-1)*y_ss/k_ss*mu_ss^theta2/tau_ss*(-1);
h(11,19) = lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1+1/(theta2-1))*mu_ss*y_ss^(1-gamma)/k_ss...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*theta2/(theta2-1)*y_ss/k_ss*mu_ss^theta2/tau_ss*theta2...
    + zeta_ss/(theta2-1)*mu_ss*y_ss^(1-gamma)/tau_ss;
h(11,26) = zeta_ss/(theta2-1)*mu_ss*y_ss^(1-gamma)/tau_ss;


%Eqn 12: Planner's FOC wrt x
h(12,26) = zeta_ss;
h(12,40) = -beta*eta*zeta_ss;
h(12,27) = omega_ss*k_ss^alpha*(2*d2*x_ss+d1);
h(12,28) = omega_ss*k_ss^alpha*(2*d2*x_ss+d1);
h(12,3) = omega_ss*k_ss^alpha*(2*d2*x_ss+d1)*alpha;
h(12,18) = omega_ss*k_ss^alpha*2*d2*x_ss;

%Eqn 13: Planner's FOC wrt y
h(13,15) = c_ss^(-phic)*(-phic)...
    - ((1-gamma)*theta2-1)/(theta2-1)*c_ss^(-phic)*z_ss/y_ss*(-phic)...
    + lambda_ss*phic*c_ss^(-phic-1)*(-phic-1)...
    - lambda_ss*phic*c_ss^(-phic-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*(-phic-1)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*r_ss*(-phic-1)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*r_ss*(-phic-1)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(1-delta)*(-phic-1)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*(1-delta)*(-phic-1)...
    + lambda_ss*c_ss^(-phic)*alpha/k_ss*(-phic)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)^2*tau_ss*y_ss^(-gamma)/k_ss*(-phic)...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1-gamma-gamma/(theta2-1))*tau_ss*mu_ss*y_ss^(-gamma)/k_ss*(-phic)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*(1-theta2*gamma/(theta2-1))/k_ss*mu_ss^theta2*(-phic);
h(13,21) = -((1-gamma)*theta2-1)/(theta2-1)*c_ss^(-phic)*z_ss/y_ss...
    - lambda_ss*phic*c_ss^(-phic-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*r_ss...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*(1-delta);
h(13,20) = -((1-gamma)*theta2-1)/(theta2-1)*c_ss^(-phic)*z_ss/y_ss*(-1)...
    - lambda_ss*phic*c_ss^(-phic-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*(-1)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*r_ss*(-1)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*(1-delta)*(-1)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)^2*tau_ss*y_ss^(-gamma)/k_ss*(-gamma)...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1-gamma-gamma/(theta2-1))*tau_ss*mu_ss*y_ss^(-gamma)/k_ss*(-gamma)...
    - zeta_ss*(1-gamma)*y_ss^(-gamma)*(-gamma)...
    - zeta_ss*(gamma/(theta2-1)+gamma-1)*mu_ss*y_ss^(-gamma)*(-gamma);
h(13,25) = lambda_ss*phic*c_ss^(-phic-1)...
    - lambda_ss*phic*c_ss^(-phic-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss;
h(13,11) = lambda_ss*(-phic)*c_ss^(-phic-1)*r_ss...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*r_ss...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(1-delta)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*(1-delta)...
    + lambda_ss*c_ss^(-phic)*alpha/k_ss...
    + lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)^2*tau_ss*y_ss^(-gamma)/k_ss...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1-gamma-gamma/(theta2-1))*tau_ss*mu_ss*y_ss^(-gamma)/k_ss...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*(1-theta2*gamma/(theta2-1))/k_ss*mu_ss^theta2;
h(13,24) = lambda_ss*(-phic)*c_ss^(-phic-1)*r_ss...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-1)*((1-gamma)*theta2-1)/(theta2-1)*z_ss/y_ss*r_ss;
h(13,3) = lambda_ss*c_ss^(-phic)*alpha/k_ss*(-1)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)^2*tau_ss*y_ss^(-gamma)/k_ss*(-1)...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1-gamma-gamma/(theta2-1))*tau_ss*mu_ss*y_ss^(-gamma)/k_ss*(-1)...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*(1-theta2*gamma/(theta2-1))/k_ss*mu_ss^theta2*(-1);
h(13,23) = lambda_ss*c_ss^(-phic)*(-alpha)*(1-gamma)^2*tau_ss*y_ss^(-gamma)/k_ss...
    + lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1-gamma-gamma/(theta2-1))*tau_ss*mu_ss*y_ss^(-gamma)/k_ss;
h(13,19) = lambda_ss*c_ss^(-phic)*alpha*(1-gamma)*(1-gamma-gamma/(theta2-1))*tau_ss*mu_ss*y_ss^(-gamma)/k_ss...
    + lambda_ss*c_ss^(-phic)*(-alpha)*theta1*(1-theta2*gamma/(theta2-1))/k_ss*mu_ss^theta2*theta2...
    - zeta_ss*(gamma/(theta2-1)+gamma-1)*mu_ss*y_ss^(-gamma);
h(13,26) = -zeta_ss*(1-gamma)*y_ss^(-gamma)...
    - zeta_ss*(gamma/(theta2-1)+gamma-1)*mu_ss*y_ss^(-gamma);
h(13,27) = omega_ss;

%Eqn 14: Planner's FOC wrt k
h(14,15) = -c_ss^(-phic)*(-phic)...
    + lambda_ss*(-phic)*c_ss^(-phic-1)*(-phic-1)...
    + lambda_ss*phic*c_ss^(-phic-1)*r_ss*(-phic-1)...
    + lambda_ss*phic*c_ss^(-phic-1)*(1-delta)*(-phic-1);
h(14,29) = beta*(1-delta)*c_ss^(-phic)*(-phic)...
    + lambda_ss*phic*c_ss^(-phic-1)*(1-delta)*beta*(-phic-1)...
    + lambda_ss*beta*(-phic)*c_ss^(-phic-1)*(1-delta)*r_ss*(-phic-1)...
    + lambda_ss*beta*(-phic)*c_ss^(-phic-1)*(1-delta)^2*(-phic-1)...
    + lambda_ss*beta*c_ss^(-phic)*(-alpha)*y_ss*k_ss^(-2)*(-phic)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)*k_ss^(-2)*(-phic)...
    + lambda_ss*beta*c_ss^(-phic)*(-alpha)*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)*k_ss^(-2)*(-phic)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*theta1*y_ss*k_ss^(-2)*mu_ss^theta2*(-phic);
h(14,39) = lambda_ss*phic*c_ss^(-phic-1)*(1-delta)*beta;
h(14,25) = lambda_ss*(-phic)*c_ss^(-phic-1)...
    + lambda_ss*beta*(-phic)*c_ss^(-phic-1)*(1-delta)*r_ss...
    + lambda_ss*beta*(-phic)*c_ss^(-phic-1)*(1-delta)^2 ...
    + lambda_ss*beta*c_ss^(-phic)*(-alpha)*y_ss*k_ss^(-2)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)*k_ss^(-2)...
    + lambda_ss*beta*c_ss^(-phic)*(-alpha)*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)*k_ss^(-2)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*theta1*y_ss*k_ss^(-2)*mu_ss^theta2;
h(14,38) = lambda_ss*beta*(-phic)*c_ss^(-phic-1)*(1-delta)*r_ss;
h(14,20) = lambda_ss*beta*c_ss^(-phic)*(-alpha)*y_ss*k_ss^(-2)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)*k_ss^(-2)*(1-gamma)...
    + lambda_ss*beta*c_ss^(-phic)*(-alpha)*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)*k_ss^(-2)*(1-gamma)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*theta1*y_ss*k_ss^(-2)*mu_ss^theta2;
h(14,3) = lambda_ss*beta*c_ss^(-phic)*(-alpha)*y_ss*k_ss^(-2)*(-2)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)*k_ss^(-2)*(-2)...
    + lambda_ss*beta*c_ss^(-phic)*(-alpha)*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)*k_ss^(-2)*(-2)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*theta1*y_ss*k_ss^(-2)*mu_ss^theta2*(-2);
h(14,23) = lambda_ss*beta*c_ss^(-phic)*alpha*(1-gamma)*tau_ss*y_ss^(1-gamma)*k_ss^(-2)...
    + lambda_ss*beta*c_ss^(-phic)*(-alpha)*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)*k_ss^(-2);
h(14,19) = lambda_ss*beta*c_ss^(-phic)*(-alpha)*(1-gamma)*tau_ss*mu_ss*y_ss^(1-gamma)*k_ss^(-2)...
    + lambda_ss*beta*c_ss^(-phic)*alpha*theta1*y_ss*k_ss^(-2)*mu_ss^theta2*theta2;
h(14,11) = lambda_ss*phic*c_ss^(-phic-1)*r_ss...
    + lambda_ss*phic*c_ss^(-phic-1)*(1-delta);
h(14,24) = lambda_ss*phic*c_ss^(-phic-1)*r_ss;
h(14,41) = omega_ss*(-beta)*(1-d0)*alpha*k_ss^(alpha-1)...
    + omega_ss*(-beta)*(-d2*x_ss^2)*alpha*k_ss^(alpha-1)...
    + omega_ss*(-beta)*(-d1*x_ss)*alpha*k_ss^(alpha-1);
h(14,42) = omega_ss*(-beta)*(1-d0)*alpha*k_ss^(alpha-1)...
    + omega_ss*(-beta)*(-d2*x_ss^2)*alpha*k_ss^(alpha-1)...
    + omega_ss*(-beta)*(-d1*x_ss)*alpha*k_ss^(alpha-1);
h(14,17) = omega_ss*(-beta)*(1-d0)*alpha*k_ss^(alpha-1)*(alpha-1)...
    + omega_ss*(-beta)*(-d2*x_ss^2)*alpha*k_ss^(alpha-1)*(alpha-1)...
    + omega_ss*(-beta)*(-d1*x_ss)*alpha*k_ss^(alpha-1)*(alpha-1);
h(14,32) = omega_ss*(-beta)*(-d2*x_ss^2)*alpha*k_ss^(alpha-1)*2 ...
    + omega_ss*(-beta)*(-d1*x_ss)*alpha*k_ss^(alpha-1);
%{
%Check numerically that these equations are correctly linearized
var_vector = [c_ss,e_ss,k_ss,x_ss,mu_ss,y_ss,z_ss,i_ss,tau_ss,r_ss,lambda_ss,zeta_ss,omega_ss,a_ss];
%Non-linearized versions of each equation
f1 = @(var) log(var(28)) - rho*log(var(14));
f2 = @(var) var(15) + var(22) + var(21) - var(20);
f3 = @(var) var(17) - (1-delta)*var(3) - var(22);
f4 = @(var) var(18) - eta*var(4) - 4*var(16);
f5 = @(var) var(16) - (1-var(19))*(var(20))^(1-gamma);
f6 = @(var) var(21) - theta1*(var(19))^theta2*var(20);
f7 = @(var) var(20) - (1-d2*(var(18))^2-d1*var(18)-d0)*var(28)*(var(3))^alpha;
f8 = @(var) -(var(15))^(-phic) + beta*(var(29))^(-phic)*(var(38)+1-delta);
%}

%These are parameters for the AIM solution method
condn = .0000001;
uprbnd = 1;

[b,rts,ia,nexact,nnumeric,lgroots,mcode,q] = aim_eig(h,neq,nlag,nlead,condn,uprbnd);

%Get the observable structure

scof = obstruct(h,b,neq,nlag,nlead);

%Use this to get the reduced form of the structural model

S_minus1 = scof(:,1:neq); %This is for nlag = 1
S_zero = scof(:,neq+1:2*neq);

B_minus1 = -inv(S_zero)*S_minus1;
B_zero = inv(S_zero);

%%%%%%%%%%%%%%%%%%%%%%%%%
%Generate impulse response functions

T = 100; %periods for response
state = zeros(neq,T);
eps = zeros(neq,T);

eps(:,1) = [imprespsize;0;0;0;0;0;0;0;0;0;0;0;0;0]; %shock to a 

state(:,1) = B_minus1*[0;0;0;0;0;0;0;0;0;0;0;0;0;0] + B_zero*eps(:,1);
for t = 2:T
    state(:,t) = B_minus1*state(:,t-1) + B_zero*eps(:,t); 
end;

%Examine how this affects emissions in each period, capital, abatement, and
%production

c = state(1,:);
e = state(2,:);
k = state(3,:);
x = state(4,:);
mu = state(5,:);
y = state(6,:);
z = state(7,:);
i = state(8,:);
tau = state(9,:);
r = state(10,:);
lambda = state(11,:);
zeta = state(12,:);
omega = state(13,:);
a = state(14,:);


%gerar arquivo com as vari�veis
%xlswrite ('Impulso-Resposta.xlsx',[a',y',c',r',i',k',e',x',z',mu',tau',lambda',zeta',omega'], 'Valores1')

if se_arqu1 == 1; 
  xlswrite (arquivo1, [a',y',c',r',i',k',e',x',z',mu',tau',lambda',zeta',omega'], planilha)
end;

%Create matrices to input in the functions to create figures
IRFAmatrix = [a',y',k',c',r',mu',tau'];
plot(IRFAmatrix);
%createfigure_IRF_A(IRFAmatrix);

IRFBmatrix = [a',mu',z',y',tau',e'];
plot(IRFBmatrix);
%createfigure_IRF_B(IRFBmatrix);

IRFCmatrix = [lambda',zeta',omega'];
plot(IRFCmatrix);
%createfigure_IRF_C(IRFCmatrix);

IRFDmatrix = [k',e',tau',mu',z'];
plot(IRFDmatrix);
%createfigure_IRF_D(IRFDmatrix);

%%%%%%%%%%%%%%%%%%%%%%%%%%
%Generate business cycle simulations

T = 100; %periods for response
state2 = zeros(neq,T);
eps2 = zeros(neq,T);

load commonshocks; %This contains the matrix commonshocks, which has a series
                    %of shocks, that are common for comparison of
                    %different policies

for t = 1:T
    eps2(1,t) = sd*commonshocks(t); 
end;

state2(:,1) = B_minus1*[0;0;0;0;0;0;0;0;0;0;0;0;0;0] + B_zero*eps2(:,1);
for t = 2:T
    state2(:,t) = B_minus1*state2(:,t-1) + B_zero*eps2(:,t);
end;

%Examine how this affects emissions in each period, capital, abatement, and
%production

c_2 = state2(1,:);
e_2 = state2(2,:);
k_2 = state2(3,:);
x_2 = state2(4,:);
mu_2 = state2(5,:);
y_2 = state2(6,:);
z_2 = state2(7,:);
i_2 = state2(8,:);
tau_2 = state2(9,:);
r_2 = state2(10,:);
lambda_2 = state2(11,:);
zeta_2 = state2(12,:);
omega_2 = state2(13,:);
a_2 = state2(14,:);

%gerar arquivo com as vari�veis
%xlswrite ('Impulso-Resposta.xlsx',[a_2',y_2',c_2',r_2',i_2',k_2',e_2',x_2',...
%    z_2',mu_2',tau_2',lambda_2',zeta_2',omega_2'], 'ValoresX')

if se_arqu2 == 1; 
  xlswrite (arquivo2, [a_2',y_2',c_2',r_2',i_2',k_2',e_2',x_2',...
            z_2',mu_2',tau_2',lambda_2',zeta_2',omega_2'], planilha)
end;

%Create matrices to input in the functions to create figures

grafico_paper = [y_2',e_2',tau_2'];
plot(grafico_paper);

Cyclematrix = [y_2',e_2',k_2',x_2'];
plot(Cyclematrix);
%createfigure_Cycle(Cyclematrix);


%Find moments of simulation
std(y_2); %standard deviation of detrended output
std(e_2);
corrcoef(y_2,e_2); %correlations between output and emissions

desv_pad = cell(14, 2);
desv_pad{1,1}  = 'c';      desv_pad{1,2}  = std(c_2);
desv_pad{2,1}  = 'e';      desv_pad{2,2}  = std(e_2);
desv_pad{3,1}  = 'k';      desv_pad{3,2}  = std(k_2);
desv_pad{4,1}  = 'x';      desv_pad{4,2}  = std(x_2);
desv_pad{5,1}  = 'r';      desv_pad{5,2}  = std(r_2);
desv_pad{6,1}  = 'y';      desv_pad{6,2}  = std(y_2);
desv_pad{7,1}  = 'z';      desv_pad{7,2}  = std(z_2);
desv_pad{8,1}  = 'i';      desv_pad{8,2}  = std(i_2);
desv_pad{9,1}  = 'a';      desv_pad{9,2}  = std(a_2);
desv_pad{10,1} = 'mu';     desv_pad{10,2} = std(mu_2);
desv_pad{11,1} = 'tau';    desv_pad{11,2} = std(tau_2);
desv_pad{12,1} = 'zeta';   desv_pad{12,2} = std(zeta_2);
desv_pad{13,1} = 'omega';  desv_pad{13,2} = std(omega_2);
desv_pad{14,1} = 'lambda'; desv_pad{14,2} = std(lambda_2);

desv_pad;

cv = cell(14, 2);
cv{1,1}  = 'c';      cv{1,2}  = std(c_2)/mean(c_2);
cv{2,1}  = 'e';      cv{2,2}  = std(e_2)/mean(e_2);
cv{3,1}  = 'k';      cv{3,2}  = std(k_2)/mean(k_2);
cv{4,1}  = 'x';      cv{4,2}  = std(x_2)/mean(x_2);
cv{5,1}  = 'r';      cv{5,2}  = std(r_2)/mean(r_2);
cv{6,1}  = 'y';      cv{6,2}  = std(y_2)/mean(y_2);
cv{7,1}  = 'z';      cv{7,2}  = std(z_2)/mean(z_2);
cv{8,1}  = 'i';      cv{8,2}  = std(i_2)/mean(i_2);
cv{9,1}  = 'a';      cv{9,2}  = std(a_2)/mean(a_2);
cv{10,1} = 'mu';     cv{10,2} = std(mu_2)/mean(mu_2);
cv{11,1} = 'tau';    cv{11,2} = std(tau_2)/mean(tau_2);
cv{12,1} = 'zeta';   cv{12,2} = std(zeta_2/mean(zeta_2));
cv{13,1} = 'omega';  cv{13,2} = std(omega_2)/mean(omega_2);
cv{14,1} = 'lambda'; cv{14,2} = std(lambda_2)/mean(lambda_2);

cv;










