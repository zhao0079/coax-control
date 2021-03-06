function [xdot] = coax_eom(t,state,control,param)

% States
x        = state(1);      % x position
y        = state(2);      % y position
z        = state(3);      % z position
u        = state(4);      % u velocity
v        = state(5);      % v velocity
w        = state(6);      % w velocity
roll     = state(7);      % roll angle
pitch    = state(8);      % pitch angle
yaw      = state(9);      % yaw angle
p        = state(10);     % body roll rate
q        = state(11);     % body pitch rate
r        = state(12);     % body yaw rate 
Omega_up = state(13);     % upper rotor speed
Omega_lo = state(14);     % lower rotor speed
a_up     = state(15);     % stabilizer bar z-axis x-component
b_up     = state(16);     % stabilizer bar z-axis y-component

% Controls
u_motup = control(1);
u_motlo = control(2);
u_serv1 = control(3);
u_serv2 = control(4);

% Parameter
m = param.m;
g = param.g;
Ixx = param.Ixx;
Iyy = param.Iyy;
Izz = param.Izz;
d_up = param.d_up;
d_lo = param.d_lo;
k_springup = param.k_springup;
k_springlo = param.k_springlo;
l_up = param.l_up;
l_lo = param.l_lo;
k_Tup = param.k_Tup;
k_Tlo = param.k_Tlo;
k_Mup = param.k_Mup;
k_Mlo = param.k_Mlo;
Tf_motup = param.Tf_motup;
Tf_motlo = param.Tf_motlo;
Tf_up = param.Tf_up;
rs_mup = param.rs_mup;
rs_bup = param.rs_bup;
rs_mlo = param.rs_mlo;
rs_blo = param.rs_blo;
zeta_mup = param.zeta_mup;
zeta_bup = param.zeta_bup;
zeta_mlo = param.zeta_mlo;
zeta_blo = param.zeta_blo;
max_SPangle = param.max_SPangle;
Omega_max = param.Omega_max;

% Thrust vector directions
a_lo = l_lo*u_serv1*max_SPangle;
b_lo = l_lo*u_serv2*max_SPangle;
z_Tup = [cos(a_up)*sin(b_up) -sin(a_up) cos(a_up)*cos(b_up)]'; % rot around body-x then body-y
z_Tlo = [cos(a_lo)*sin(b_lo) -sin(a_lo) cos(a_lo)*cos(b_lo)]';

% Coordinate transformation body to world coordinates
c_r = cos(roll);
s_r = sin(roll);
c_p = cos(pitch);
s_p = sin(pitch);
c_y = cos(yaw);
s_y = sin(yaw);

Rb2w = [c_p*c_y (s_r*s_p*c_y-c_r*s_y) (c_r*s_p*c_y+s_r*s_y); ...
        c_p*s_y (s_r*s_p*s_y+c_r*c_y) (c_r*s_p*s_y-s_r*c_y); ...
        -s_p s_r*c_p c_r*c_p];

% Flapping Moments
cp = [-z_Tup(2) z_Tup(1) 0]'; % z_b x z_Tup
norm_cp = sqrt(cp(1)*cp(1) + cp(2)*cp(2) + cp(3)*cp(3));
if (norm_cp ~= 0)
    M_flapup  = 2*k_springup*cp/norm_cp*acos(z_Tup(3));
else
    M_flapup  = [0 0 0]';
end

cp   = [-z_Tlo(2) z_Tlo(1) 0]'; % z_b x z_Tlo
norm_cp = sqrt(cp(1)*cp(1) + cp(2)*cp(2) + cp(3)*cp(3));
if (norm_cp ~= 0)
    M_flaplo  = 2*k_springlo*cp/norm_cp*acos(z_Tlo(3));
else
    M_flaplo  = [0 0 0]';
end

% Thrust magnitudes
T_up = k_Tup*Omega_up*Omega_up;
T_lo = k_Tlo*Omega_lo*Omega_lo;

% Summarized Forces
F_thrust = T_up*z_Tup + T_lo*z_Tlo;
Fx = Rb2w(1,:)*F_thrust;
Fy = Rb2w(2,:)*F_thrust;
Fz = -m*g + Rb2w(3,:)*F_thrust;

% Summarized Moments
Mx = q*r*(Iyy-Izz) - T_up*z_Tup(2)*d_up - T_lo*z_Tlo(2)*d_lo + M_flapup(1) + M_flaplo(1);
My = p*r*(Izz-Ixx) + T_up*z_Tup(1)*d_up + T_lo*z_Tlo(1)*d_lo + M_flapup(2) + M_flaplo(2);
Mz = p*q*(Ixx-Iyy) - k_Mup*Omega_up*Omega_up + k_Mlo*Omega_lo*Omega_lo;
%[Mx My Mz]
% State derivatives
xddot = 1/m*Fx;
yddot = 1/m*Fy;
zddot = 1/m*Fz;

rolldot = p + q*s_r*s_p/c_p + r*c_r*s_p/c_p;
pitchdot = q*c_r - r*s_r;
yawdot = q*s_r/c_p + r*c_r/c_p;

pdot = 1/Ixx*Mx;
qdot = 1/Iyy*My;
rdot = 1/Izz*Mz;

Omega_up_des = rs_mup*u_motup + rs_bup;
Omega_lo_des = rs_mlo*u_motlo + rs_blo;
Omega_updot = 1/Tf_motup*(Omega_up_des - Omega_up);
Omega_lodot = 1/Tf_motlo*(Omega_lo_des - Omega_lo);

a_updot = -1/Tf_up*a_up - l_up*p;
b_updot = -1/Tf_up*b_up - l_up*q;

% Function outputs
xdot = zeros(16,1);

xdot(1)  = state(4);
xdot(2)  = state(5);
xdot(3)  = state(6);
xdot(4)  = xddot;
xdot(5)  = yddot;
xdot(6)  = zddot;
xdot(7)  = rolldot;
xdot(8)  = pitchdot;
xdot(9)  = yawdot;
xdot(10) = pdot;
xdot(11) = qdot;
xdot(12) = rdot;
xdot(13) = Omega_updot;
xdot(14) = Omega_lodot;
xdot(15) = a_updot;
xdot(16) = b_updot;

end

