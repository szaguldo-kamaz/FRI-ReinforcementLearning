function [ action ] = FRIQ_epsilon_greedy_selection(state, epsilon, actionset)
% FRIQ_epsilon_greedy_selection: epsilon-greedy strategy action selection
%
% FRIQ-learning framework v0.70
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2022 by David Vincze
%

    global numofactions

    if (epsilon == 0) % if random actions are disabled - choose the best
        action = FRIQ_get_best_action(state, actionset);
    else
        if (rand() > epsilon)
            action = FRIQ_get_best_action(state, actionset);
        else
            % random action
            action = floor(rand()*(numofactions))+1;
            if (action > numofactions)
                action = numofactions;
            end
        end
    end
