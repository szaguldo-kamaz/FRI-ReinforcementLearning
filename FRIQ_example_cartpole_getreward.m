function [reward, isfinalstate] = FRIQ_example_cartpole_getreward(state)
% Cart-Pole Reward function
%
% Based on the original discrete SARSA version by:
%  Jose Antonio Martin H. <jamartinh@fdi.ucm.es>
%  https://jamh-web.appspot.com/download.htm
% See Sutton & Barto book: Reinforcement Learning p.214
%
    x         = state(1);
    %x_dot     = s(2);
    theta     = state(3);
    theta_dot = state(4);

    %r = 50 - 25*abs(10*theta)^2 - 10*abs(x) - 20*theta_dot;
    reward = 10 - 10 * abs(10 * theta)^2 - 5 * abs(x) - 10 * theta_dot; % max: -104.7884
    %r = 5 - 2.5*abs(theta)^2 - 2.5*abs(x) - 2.5*theta_dot; % max: -28.3446
    isfinalstate = 0;

    twelve_degrees     = deg2rad(12); % 12
    fourtyfive_degrees = deg2rad(45); % 45
    %if (x < -4.0 | x > 4.0  | theta < -twelve_degrees | theta > twelve_degrees)
    if (x <- 4.0 | x > 4.0 | theta <- fourtyfive_degrees | theta > fourtyfive_degrees)
        %    r = -5000 - 50*abs(x) - 100*abs(theta);
        reward = -10000 - 50 * abs(x) - 100 * abs(theta); % max: -10000 -500 -20.9440 = -10521
        %    r = -2000 - 25*abs(x) - 50*abs(theta); % max -2260.5
        isfinalstate = 1;
    end
