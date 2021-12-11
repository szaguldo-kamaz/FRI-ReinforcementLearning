function [ total_reward, steps ] = FRIQ_rulebase_load(maxsteps, epsilon, RB)
% FRIQ_rulebase_load: reload the reduced RB rule-base and trying that

% By David Vincze
% e-mail: vincze.david@iit.uni-miskolc.hu
%   Copyright (c) 2013-2014 by David Vincze
%   Last modified: 31.05.16 by Tamas Tompa
%
% Portions based on original discrete version Q-learning demos programmed in MATLAB by:
%  Jose Antonio Martin H. <jamartinh@fdi.ucm.es>
%

global FRIQ_param_drawfunc FRIQ_param_doactionfunc FRIQ_param_rewardfunc FRIQ_param_quantize_observationsfunc
global FRIQ_param_states FRIQ_param_statedivs FRIQ_param_states_default FRIQ_param_actions
global FRIQ_param_drawsim
global stopappnow stepno R

x                 = FRIQ_param_states_default;
steps_friq        = 0;
total_reward_friq = 0;
s = x;

if(isempty(RB) == 1) % first iteration
    total_reward = -Inf;
    steps = -1;
    
    disp(['FRIQ_steps: ',int2str(steps_friq),' FRIQ_reward: ',num2str(total_reward_friq),' rules: ' num2str(length(RB))]);
    disp('The rule-base did not solve the problem!');
    disp(' ');
    return;
else
    % load the rulebase
    R = RB;
    
    % select an action using the epsilon greedy selection strategy
    a = FRIQ_epsilon_greedy_selection(s, epsilon, FRIQ_param_actions);
    
    for stepno=1:maxsteps
        % convert the index of the action into an action value
        action = FRIQ_param_actions(a);
        
        % do the selected action and get the next state
        xp = FRIQ_param_doactionfunc(action, x);
        
        % observe the reward at state xp and the final state flag
        [r,f_friq] = FRIQ_param_rewardfunc(xp);
        total_reward_friq = total_reward_friq + r;
        
        sp  = FRIQ_param_quantize_observationsfunc(xp, FRIQ_param_states, FRIQ_param_statedivs);
        
        % propose an action for the current situation
        ap = FRIQ_epsilon_greedy_selection(sp, epsilon, FRIQ_param_actions);
        
        %update the current variables
        a = ap;
        x = xp;
        
        %increment the step counter.
        steps_friq = steps_friq+1;
        
        % Plot of the cart-pole problem
        if FRIQ_param_drawsim == true
            FRIQ_param_drawfunc(x,action,steps_friq);
        end
        
        % if goal is reached then break the episode
        if (f_friq==true) || (stopappnow == 1)
            break
        end
    end
    
    if FRIQ_param_drawsim == true
        FRIQ_param_drawfunc(x,action,steps_friq);
    end
    
    % update the variables
    total_reward = total_reward_friq;
    steps = steps_friq;
end