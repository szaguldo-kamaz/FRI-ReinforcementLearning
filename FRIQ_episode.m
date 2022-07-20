function [total_reward_friq, steps_friq] = FRIQ_episode(maxsteps, alpha, gamma, epsilon)
% FRIQ_episode: FRIQ-learning framework: Evaluate an episode
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2021 by David Vincze
%

    global FRIQ_param_drawfunc FRIQ_param_doactionfunc FRIQ_param_rewardfunc FRIQ_param_quantize_observationsfunc
    global FRIQ_param_states FRIQ_param_statedivs FRIQ_param_states_default FRIQ_param_actions
    global FRIQ_param_test_previous_rb
    global FRIQ_param_drawsim
    global stopappnow stepno reduction_state measure_rb_usage_state
    global debug_on

    state             = FRIQ_param_states_default; 
    steps_friq        = 0;
    total_reward_friq = 0;

    if measure_rb_usage_state == 1
        noRBupdate=1;
    else
        if FRIQ_param_test_previous_rb == 1
            noRBupdate=1;
        else
            if reduction_state == 1
                noRBupdate=1;
            else
                noRBupdate=0;
            end
        end
    end

    % set initial state
    state_quantized = state;
    % choose an action using the epsilon-greedy selection strategy for the initial state
    action_index = FRIQ_epsilon_greedy_selection(state_quantized, epsilon, FRIQ_param_actions);

    for stepno = 1:maxsteps
        % convert the index of the action to an action value
        action_value = FRIQ_param_actions(action_index);

        % perform action, which takes the system to a new state
        state_p = FRIQ_param_doactionfunc(action_value, state);

        % calculate the reward for the state change
        [reward, isfinalstate] = FRIQ_param_rewardfunc(state_p);
        total_reward_friq = total_reward_friq + reward;

        %state_p_quantized=state_p;
        state_p_quantized = FRIQ_param_quantize_observationsfunc(state_p, FRIQ_param_states, FRIQ_param_statedivs);

        if debug_on == 1
            format long
            ['step: ' int2str(stepno) ' rew: ' num2str(reward, '%.16f')]
            state_p
            state_p_quantized
        end

        % choose an action for the currently observed situation
        action_p = FRIQ_epsilon_greedy_selection(state_p_quantized, epsilon, FRIQ_param_actions);
        % convert the index of the action to an action value
        action_p_value = FRIQ_param_actions(action_p);

        % update the rule-base conclusions (Q vals) (when in incremental construction phase)
        if noRBupdate == 0
            FRIQ_update_RB(state_quantized, action_value, reward, state_p_quantized, action_p_value, alpha, gamma);
        end

        state_quantized = state_p_quantized;
        action_index = action_p;
        state = state_p;

        steps_friq = steps_friq + 1;

        % visualization
        if FRIQ_param_drawsim == 1
            FRIQ_param_drawfunc(state, action_value, steps_friq);
        end

        if (isfinalstate == 1) || (stopappnow == 1)
            break
        end

    end

    if FRIQ_param_drawsim == 1
        FRIQ_param_drawfunc(state, action_value, steps_friq);
    end
