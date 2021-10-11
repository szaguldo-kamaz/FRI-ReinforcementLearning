function [reward, isfinalstate] = FRIQ_example_acrobot_getreward(x)
% GetReward returns the reward at the current state
% x: a vector of acrobot state
% r: the returned reward.
% f: true if the acrobot reached the goal, otherwise f is false
%
% Based on the original discrete SARSA version by:
%  Jose Antonio Martin H. <jamartinh@fdi.ucm.es>
%  https://jamh-web.appspot.com/download.htm
% See Sutton & Barto book: Reinforcement Learning
%
    theta1 = x(1);
    theta2 = x(2);
    y_acrobot(1) = 0;
    y_acrobot(2) = y_acrobot(1) - cos(theta1);
    y_acrobot(3) = y_acrobot(2) - cos(theta2);

    % goal
    goal = y_acrobot(1) + 1.0;

    reward = -10; % y_acrobot(3);
    isfinalstate = 0;

    if (y_acrobot(3) >= goal)
        reward = 1000; % 10*y_acrobot(3);
        isfinalstate = 1;
    end
