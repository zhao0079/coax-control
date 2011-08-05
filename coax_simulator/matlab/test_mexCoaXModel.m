[a, p] = system('rospack find coax_simulator');
addpath(strcat(p, '/bin'));

clear
clc

run parameter

p.mass = m;
p.inertia = [Ixx, Iyy, Izz];
p.offset = [d_up, d_lo];
p.linkage_factor = [l_up, l_lo];
p.spring_constant = [k_springup, k_springlo];
p.thrust_factor = [k_Tup, k_Tlo];
p.moment_factor = [k_Mup, k_Mlo];
p.following_time = [Tf_up, Tf_motup, Tf_motlo];
p.speed_conversion = [rs_mup, rs_bup, rs_mlo, rs_blo];
p.phase_lag = [zeta_mup, zeta_bup, zeta_mlo, zeta_blo];
p.max_swashplate_angle = max_SPangle;

% Reset the model
mexCoaXModel('reset');

% Set the parameters
mexCoaXModel('set_params', p);

% Set the initial state
s.position = [0, 0, 0.5];
s.linear_velocity = [0, 0, 0];
s.rotation = [0, 0, 0];
s.angular_velocity = [0, 0, 0];
s.rotor_speed = [0, 0];
s.bar_direction = [0, 0, 1];

mexCoaXModel('set_state', s);

tnow = 0;
dt = 0.01;

for i = 1:50
    % Set the command
    cmd = [0, 0, 0, 0];
    mexCoaXModel('set_cmd', cmd);

    % Update until the time provided
    mexCoaXModel('update', tnow);

    % Get the state after the update
    mexCoaXModel('get_state')

    tnow = tnow + dt;
end

% Remember, always reset the model if you plan to start the
% simulation over
