function FRIQ_example_cartpole_setup()
% CartPole Problem example
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
    global FRIQ_param_norandom FRIQ_param_drawsim FRIQ_param_maxsteps FRIQ_param_alpha FRIQ_param_gamma FRIQ_param_epsilon FRIQ_param_maxepisodes
    global FRIQ_param_construct_rb FRIQ_param_measure_constructed_rb_usage FRIQ_param_reduce_rb FRIQ_param_measure_reduced_rb_usage
    global FRIQ_param_reduction_strategy FRIQ_param_reduction_strategy_secondary FRIQ_param_remove_unnecessary_membership_functions
    global FRIQ_param_reduction_kmeans_rng FRIQ_param_reduction_kmeans_distancemetric
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
    global FRIQ_const_reduction_strategy__ALL_CLUSTER_KMEANS

    FRIQ_param_appname = 'example_cartpole';
    FRIQ_param_apptitle = 'FRIQ-learning example: CartPole';

    % state descriptor step size
    %x1div = (2-(-2)) / 3.0;
    x1div = 2;
    %x2div = (0.1-(-0.1)) / 2.0;
    x2div = 1;
    %x3div = (deg2rad(12)-(deg2rad(-12)))/8.0;
    x3div = 0.0524;
    %x4div = (deg2rad(10)-(deg2rad(-10)))/2.0;
    x4div = 2;

    % state descriptors
    %x1  = -2:x1div:2;
    x1 = [-1  1];
    %x2  = -0.5:x2div:0.5;
    x2 = [-1 0 1];
    %x3  = deg2rad(-12):x3div:deg2rad(12);
    x3 = [-0.2094 -0.1571 -0.1047 -0.0524 0 0.0524 0.1047 0.1571 0.2094];
    %x4  = deg2rad(-10):x4div:deg2rad(10);
    x4 = [-1  1];

    % define actions
    FRIQ_param_actions = -1.0:0.1:1.0;
    %FRIQ_param_actions = [ -1.0 -0.9 0.8 0.7 0.6 0.5 0.4 0.3 0.2 0.1 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0];
    FRIQ_param_actiondiv = 0.1;

    % % Universe sizes for FIVE FRI (states + action)
    % Us1 = [-2:0.1:2];
    % Us2 = [-2:0.1:2];
    % %Us3 = [deg2rad(-20):deg2rad(20)/20:deg2rad(20)];
    % Us3 = [deg2rad(-15):deg2rad(15)/20:deg2rad(15)];
    % Us4 = [-2:0.1:2];
    % Ua  = [-1:.05:1];

    Us1 = -8:.016:8;    % Universe (input)  - state x1 - x
    Us2 = -16:.032:16;  % Universe (input)  - state x2 - x dot
    %Us3 = deg2rad(-90):deg2rad(90)/500:deg2rad(90);         % Universe (input)  - state x3 - theta
    Us3 = -1.5707963267948966:0.0031415926535897933:1.5707963267948966; % Universe (input)  - state x3 - theta
    Us4 = -8:.016:8;    % Universe (input)  - state x4 - theta dot
    Ua = -4:.008:4;     % Universe (input)  - action number

    % dlmwrite('us1.txt',Us1,'precision','%.20f','delimiter','\n');
    % dlmwrite('us2.txt',Us2,'precision','%.18f','delimiter','\n');
    % dlmwrite('us3.txt',Us3,'precision','%.18f','delimiter','\n');
    % dlmwrite('us4.txt',Us4,'precision','%.18f','delimiter','\n');
    % dlmwrite('ua.txt',Ua,'precision','%.18f','delimiter','\n');

    FRIQ_param_FIVE_UD = [Us1; Us2; Us3; Us4; Ua];

    FRIQ_param_states = {x1 x2 x3 x4};
    FRIQ_param_statedivs = {x1div x2div x3div x4div};
    % steepness of the triangles defining the membership functions for the states
    %FRIQ_param_states_steepness=[1, 1, 1/(deg2rad(12)/4.5), 1];
    FRIQ_param_states_steepness = [1, 1, 21.485917317405871, 1];
    FRIQ_param_states_default = [1 0 0 0];
    %FRIQ_param_states_default=[0 0 0 0.01];

    FRIQ_param_antecedent_terms = {
        {'LEFT','RIGHT'}
        {'LEFT','STOPPED','RIGHT'}
        {'MAX LEFT','LEFT','LITTLE LEFT','BIT LEFT','STANDING','BIT RIGHT','LITTLE RIGHT','RIGHT','MAX RIGHT'}
        {'LEFT','RIGHT'}
        {'LEFT10','LEFT9','LEFT8','LEFT7','LEFT6','LEFT5','LEFT4','LEFT3','LEFT2','LEFT1','STOP','RIGHT1','RIGHT2','RIGHT3','RIGHT4','RIGHT5','RIGHT6','RIGHT7','RIGHT8','RIGHT9','RIGHT10'}
    };

    FRIQ_param_antecedent_names = {
        'CART POSITION'
        'CART ACCELERATION'
        'POLE POSITION'
        'POLE FALLING'
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
    FRIQ_param_reduction_kmeans_rng = 3;
    FRIQ_param_reduction_kmeans_distancemetric = 'sqeuclidean';  % 'sqeuclidean' | 'cityblock' | 'cosine' | 'correlation'
%     FRIQ_param_reduction_strategy_secondary = [];
%     FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY;
%     FRIQ_param_reduction_strategy_secondary = FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MERGE_MEAN;
    FRIQ_param_remove_unnecessary_membership_functions = 0;
%     FRIQ_param_drawsim            = false; % indicates whether to display the graphical interface or not
    FRIQ_param_drawsim            = true; % indicates whether to display the graphical interface or not
    FRIQ_param_maxsteps           = 1000; % maximum number of steps per episode

    FRIQ_param_qdiff_pos_boundary         =   +1.0;
    FRIQ_param_qdiff_neg_boundary         = -200.0;
    FRIQ_param_qdiff_final_tolerance      =  250.0;
    FRIQ_param_reward_good_above          =    0.0;
    % FRIQ_param_reduction_reward_tolerance   =     0.0; % set to 0.0 for zero tolerance
    FRIQ_param_reduction_reward_tolerance =    inf; % set to 0.0 for zero tolerance
    FRIQ_param_reduction_rule_distance    =    0.1;   % for defining 'similar' rules

    % learning parameters
    FRIQ_param_alpha        = 0.3;      % learning rate
    FRIQ_param_gamma        = 1.0;      % discount factor
    FRIQ_param_epsilon      = 0.001;    % probability of a random action selection (overriden by FRIQ_norandom if necessary)

    % external functions
    FRIQ_param_drawfunc     = @FRIQ_example_cartpole_draw;      % function to call for the visualization of a resulting step
    FRIQ_param_rewardfunc   = @FRIQ_example_cartpole_getreward; % function to call for reward calculation
    FRIQ_param_doactionfunc = @FRIQ_example_cartpole_doaction;  % function to call for calculating the next state bases on the selected action
    FRIQ_param_quantize_observationsfunc = @FRIQ_example_cartpole_quantize_observations; % function to call for quantizing observations (can be "built-in")
