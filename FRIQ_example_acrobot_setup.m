function FRIQ_example_acrobot_setup()
% Acrobot Problem example
% with FRI-based Reinforcement Learning
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2021 by David Vincze
%
%
    %% USER DEFINED problem parameters for FRIQ
    global FRIQ_param_appname FRIQ_param_apptitle
    global FRIQ_param_FIVE_UD FRIQ_param_states FRIQ_param_states_default FRIQ_param_statedivs FRIQ_param_states_steepness
    global FRIQ_param_actions FRIQ_param_actiondiv
    global FRIQ_param_qdiff_pos_boundary FRIQ_param_qdiff_neg_boundary FRIQ_param_qdiff_final_tolerance FRIQ_param_reward_good_above FRIQ_param_reduction_reward_tolerance FRIQ_param_reduction_rule_distance
    global FRIQ_param_norandom FRIQ_param_drawsim FRIQ_param_maxsteps FRIQ_param_alpha FRIQ_param_gamma FRIQ_param_epsilon
    global FRIQ_param_construct_rb FRIQ_param_reduce_rb 
    global FRIQ_param_reduction_strategy FRIQ_param_reduction_strategy_secondary FRIQ_param_remove_unnecessary_membership_functions
    global FRIQ_param_doactionfunc FRIQ_param_rewardfunc FRIQ_param_drawfunc FRIQ_param_quantize_observationsfunc

    % constants
    global FRIQ_const_reduction_strategy__MIN_Q
    global FRIQ_const_reduction_strategy__MAX_Q
    global FRIQ_const_reduction_strategy__HALF_GROUP_REMOVAL
    global FRIQ_const_reduction_strategy__BUILD_MINANDMAXQ
    global FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY 
    global FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST
    global FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MINQ
    global FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MAXQ
    global FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MERGE_MEAN
    global FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST
    global FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MINQ
    global FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MAXQ
    global FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MERGE_MEAN
    global FRIQ_const_reduction_strategy__CLUSTER__HIERARCHICAL
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_ONE
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_MANY
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_ONE
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_MANY
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_CENTROID
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINANDMAXQ
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MAXABSQ
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINABSQ

    FRIQ_param_appname = 'example_acrobot';
    FRIQ_param_apptitle = 'FRIQ-learning example: Acrobot';

    % state descriptors
    x1 = linspace(-pi / 2, pi / 2, 5);
    x2 = linspace(-pi / 2, pi / 2, 5);
    x3 = linspace(-pi / 4, pi / 4, 3);
    x4 = linspace(-pi / 4, pi / 4, 3);
    % state descriptor step size
    x1div = pi / 4;
    x2div = pi / 4;
    x3div = pi / 4;
    x4div = pi / 4;

    % define actions
    FRIQ_param_actions = [-1, 0, 1];
    FRIQ_param_actiondiv = 1;

    % Universe sizes for FIVE FRI (states + action)
    Us1 = -2:0.1:2;
    Us2 = -2:0.1:2;
    Us3 = -1:0.05:1;
    Us4 = -1:0.05:1;
    Ua  = -2:.1:2;
    FRIQ_param_FIVE_UD = [Us1; Us2; Us3; Us4; Ua];

    FRIQ_param_states    = {x1 x2 x3 x4};
    FRIQ_param_statedivs = {x1div x2div x3div x4div};
    % steepness of the triangles defining the membership functions for the states
    FRIQ_param_states_steepness = [1, 1, 1, 1];
    FRIQ_param_states_default   = [0 0 0 0];

    % config
    FRIQ_param_norandom           = 1;
    FRIQ_param_construct_rb       = 0;
    FRIQ_param_reduce_rb          = 1;
    FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY;
    FRIQ_param_reduction_strategy_secondary = FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST;
    FRIQ_param_remove_unnecessary_membership_functions = 0;
%     FRIQ_param_drawsim            = false; % indicates whether to display the graphical interface or not
    FRIQ_param_drawsim            = true; % indicates whether to display the graphical interface or not
    FRIQ_param_maxsteps           = 1000; % maximum number of steps per episode

    FRIQ_param_qdiff_pos_boundary           =   +1.0;
    FRIQ_param_qdiff_neg_boundary           = -200.0;
    FRIQ_param_qdiff_final_tolerance        =   50.0;
    FRIQ_param_reward_good_above            =    0.0;
    FRIQ_param_reduction_reward_tolerance   =  200.0;
    FRIQ_param_reduction_rule_distance      =    0.1;   % for defining 'similar' rules

    % learning parameters
    FRIQ_param_alpha    = 0.5;   % learning rate
    FRIQ_param_gamma    = 1.0;   % discount factor
    FRIQ_param_epsilon  = 0.001; % probability of a random action selection (overriden by FRIQ_norandom if necessary)

    % external functions
    FRIQ_param_drawfunc     = @FRIQ_example_acrobot_draw;       % function to call for the visualization of a resulting step
    FRIQ_param_rewardfunc   = @FRIQ_example_acrobot_getreward;  % function to call for reward calculation
    FRIQ_param_doactionfunc = @FRIQ_example_acrobot_doaction;   % function to call for calculating the next state bases on the selected action
    FRIQ_param_quantize_observationsfunc = @FRIQ_quantize_observations; % function to call for quantizing observations (can be "built-in")
    
