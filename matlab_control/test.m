COAX56 = 0;
if (COAX56)
    %pid = nav_msgs_Odometry('connect','subscriber','odom56','odom56');
    iid = geometry_msgs_Quaternion('connect','subscriber','coax_info56','coax_info56');
    tid = geometry_msgs_Quaternion('connect','publisher','trim56','trim56');
    mid = std_msgs_Bool('connect','publisher','nav_mode56','nav_mode56');
    cid = geometry_msgs_Quaternion('connect','publisher','raw_control56','raw_control56');
    cmid = geometry_msgs_Quaternion('connect','subscriber','control_mode56','control_mode56');
else
    %pid = nav_msgs_Odometry('connect','subscriber','odom57','odom57');
    iid = geometry_msgs_Quaternion('connect','subscriber','coax_info57','coax_info57');
    tid = geometry_msgs_Quaternion('connect','publisher','trim57','trim57');
    mid = std_msgs_Bool('connect','publisher','nav_mode57','nav_mode57');
    cid = geometry_msgs_Quaternion('connect','publisher','raw_control57','raw_control57');
    cmid = geometry_msgs_Quaternion('connect','subscriber','control_mode57','control_mode57');
end

nav_mode = std_msgs_Bool('empty');
nav_mode.data = 1;
std_msgs_Bool('send',mid,nav_mode); % switch to NAV_RAW_MODE

raw_control = geometry_msgs_Quaternion('empty');
volt_compUp = 0;
volt_compLo = 0;

omega = pi/2;
t0 = clock;
i = 0;
tic
while i<500
    
    dt = etime(clock, t0);
    if (dt < 2)
        motor_up = 0.35;
        motor_lo = 0.35;
    else
        motor_up = 0.35;
        motor_lo = 0.35;
    end
    
    
    % Voltage compensation
    info = geometry_msgs_Quaternion('read',iid,1);
    if (~isempty(info))
        v_bat = round(100*info.y)/100;
        volt_compUp = (12.22 - v_bat)*0.0279;
        volt_compLo = (12.22 - v_bat)*0.0287;
    end
    motor_up = motor_up + volt_compUp;
    motor_lo = motor_lo + volt_compLo;
    
    
    raw_control.x = motor_up;
    raw_control.y = motor_lo;
    raw_control.z = 0.0285;
    raw_control.w = 0.0921;
    
    
    geometry_msgs_Quaternion('send',cid,raw_control);
    
%     if (~isempty(info))
%         if (info.y < 10.6)
%             time = toc
%             break;
%         end
%     end
    i = i+1;
    pause(0.009);
end

raw_control.x = 0;
raw_control.y = 0;
raw_control.z = 0;
raw_control.w = 0;
geometry_msgs_Quaternion('send',cid,raw_control);

%nav_msgs_Odometry('disconnect',pid);
geometry_msgs_Quaternion('disconnect',iid);
geometry_msgs_Quaternion('disconnect',tid);
std_msgs_Bool('disconnect',mid);
geometry_msgs_Quaternion('disconnect',cid);
geometry_msgs_Quaternion('disconnect',cmid);
clear
clc