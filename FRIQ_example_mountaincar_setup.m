function FRIQ_example_mountaincar_setup()
% MountainCar Problem example
% with FRI-based Q-learning (using SARSA)
%
% http://users.iit.uni-miskolc.hu/~vinczed/friq/
%
% FIVE-based FRIQ-learning extension and framework by:
%  David Vincze <david.vincze@iit.uni-miskolc.hu>
% FIVE FRI method developed by:
%  Szilveszter Kovacs <szkovacs@iit.uni-miskolc.hu>
%
% Original discrete version programmed in MATLAB by:
%  Jose Antonio Martin H. <jamartinh@fdi.ucm.es>
% See Sutton & Barto book: Reinforcement Learning p.214
%
    %% USER DEFINED problem parameters for FRIQ
    global FRIQ_param_appname FRIQ_param_apptitle
    global FRIQ_param_FIVE_UD FRIQ_param_states FRIQ_param_states_default FRIQ_param_statedivs FRIQ_param_states_steepness
    global FRIQ_param_actions FRIQ_param_actiondiv
    global FRIQ_param_qdiff_pos_boundary FRIQ_param_qdiff_neg_boundary FRIQ_param_qdiff_final_tolerance FRIQ_param_reward_good_above FRIQ_param_reduction_reward_tolerance FRIQ_param_reduction_rule_distance
    global FRIQ_param_norandom FRIQ_param_drawsim FRIQ_param_maxsteps FRIQ_param_alpha FRIQ_param_gamma FRIQ_param_epsilon
    global FRIQ_param_construct_rb FRIQ_param_measure_constructed_rb_usage FRIQ_param_reduce_rb FRIQ_param_measure_reduced_rb_usage
    global FRIQ_param_reduction_strategy FRIQ_param_reduction_strategy_secondary FRIQ_param_maxepisodes FRIQ_param_remove_unnecessary_membership_functions
    global FRIQ_param_doactionfunc FRIQ_param_rewardfunc FRIQ_param_drawfunc FRIQ_param_quantize_observationsfunc
    global FRIQ_param_antecedent_terms FRIQ_param_antecedent_names

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
    global FRIQ_const_reduction_strategy__ALL

    FRIQ_param_appname = 'example_mountaincar';
    FRIQ_param_apptitle = 'FRIQ-learning example: MountainCar';

    % state descriptor step size
    x1div = (0.55 - (-1.5)) / 10.0;
    x2div = (0.07 - (-0.07)) / 5.0;

    % state descriptors
    x1 = -1.5:x1div:0.5;
    x2 = -0.07:x2div:0.07;

    % define actions
    FRIQ_param_actions = [-1.0, 0.0, 1.0];
    FRIQ_param_actiondiv = 1;

    % Universe sizes for FIVE FRI (states + action)
    Us1 = -2:0.1:2;
    Us2 = -0.1:0.005:0.1;
    Ua  = -2:.1:2;
    FRIQ_param_FIVE_UD = [Us1; Us2; Ua];

    FRIQ_param_states    = {x1 x2};
    FRIQ_param_statedivs = {x1div x2div};
    % steepness of the triangles defining the membership functions for the states
    FRIQ_param_states_steepness = [1, 1];
    FRIQ_param_states_default   = [-0.5, 0.0];

    FRIQ_param_antecedent_terms = {
        {'LEFT8', 'LEFT7', 'LEFT6', 'LEFT5', 'LEFT4', 'LEFT3', 'LEFT2', 'LEFT1', 'RIGHT1', 'RIGHT2'}
        {'LEFT3', 'LEFT2', 'LEFT1', 'RIGHT1', 'RIGHT2', 'RIGHT3'}
        {'LEFT', 'STOPPED', 'RIGHT'}
    };

    FRIQ_param_antecedent_names = {
        'CAR POSITION'
        'CAR VELOCITY'
        'FORCE TO APPLY'
    };

    % configuration
    FRIQ_param_norandom                     = 1;
    FRIQ_param_construct_rb                 = 1;
    FRIQ_param_measure_constructed_rb_usage = 1;
    FRIQ_param_reduce_rb                    = 0;
    FRIQ_param_measure_reduced_rb_usage     = 0;
    FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ALL;
    FRIQ_param_reduction_strategy_secondary = FRIQ_const_reduction_strategy__ALL;
%     FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY;
%     FRIQ_param_reduction_strategy_secondary = FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST;
    FRIQ_param_remove_unnecessary_membership_functions = 0;
%    FRIQ_param_drawsim            = false; % indicates whether to display the graphical interface or not
    FRIQ_param_drawsim            = true; % indicates whether to display the graphical interface or not
    FRIQ_param_maxsteps           = 1000; % maximum number of steps per episode
%    FRIQ_param_maxsteps           = 500; % maximum number of steps per episode
    FRIQ_param_maxepisodes        = 1000;

    FRIQ_param_qdiff_pos_boundary           =    +1.0;
    FRIQ_param_qdiff_neg_boundary           =    -4.0;
    FRIQ_param_qdiff_final_tolerance        =   500.0;
    FRIQ_param_reward_good_above            = -5000.0;
    FRIQ_param_reduction_reward_tolerance   =  1500.0;
    FRIQ_param_reduction_rule_distance      =     0.1;

    % learning parameters
    FRIQ_param_alpha        = 0.5;  % learning rate
    FRIQ_param_gamma        = 1.0;  % discount factor
    FRIQ_param_epsilon      = 0.01; % probability of a random action selection (overriden by FRIQ_norandom if necessary)

    % external functions
    FRIQ_param_drawfunc     = @FRIQ_example_mountaincar_draw;       % function to call for the visualization of a resulting step
    FRIQ_param_rewardfunc   = @FRIQ_example_mountaincar_getreward;  % function to call for reward calculation
    FRIQ_param_doactionfunc = @FRIQ_example_mountaincar_doaction;   % function to call for calculating the next state bases on the selected action
    FRIQ_param_quantize_observationsfunc = @FRIQ_quantize_observations; % function to call for quantizing observations (can be "built-in")
