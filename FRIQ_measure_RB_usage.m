function FRIQ_measure_RB_usage(RBbasefilename)
%
% FRIQ-learning framework v0.70
% https://github.com/szaguldo-kamaz/
%
% Author:
%  David Vincze <david.vincze@uni-miskolc.hu>
% Author of the FIVE FRI method:
%  Szilveszter Kovacs <szkovacs@iit.uni-miskolc.hu>
%
% Copyright (c) 2013-2022 by David Vincze
%

    %% for accessing user config values defined in the setup file
    global FRIQ_param_maxsteps FRIQ_param_alpha FRIQ_param_gamma FRIQ_param_epsilon

    %% Init
    global R logfile debug_on
    global measure_rb_usage_state Rusage

    %% Measure usage of the constructed rule-base
    
    % load rule-base
    if ~exist([ RBbasefilename '.csv'], 'file')
        
        disp(['measure_rb_usage: rule-base file not found: ' RBbasefilename '.csv ! Please run the construction process first (set FRIQ_param_construct_rb = 1).']);
        return;
    end
    R = dlmread([ RBbasefilename '.csv']);
    numofrules = size(R, 1);
    
    Rusage=zeros(size(R,1),1);
    measure_rb_usage_state=1; %#ok<NASGU>
    [total_reward_friq, steps_friq] = FRIQ_episode(FRIQ_param_maxsteps, FRIQ_param_alpha, FRIQ_param_gamma, 0);
    measure_rb_usage_state=0;
    disp(            ['FRIQ_usage_measurement_episode: FRIQ_steps: ' int2str(steps_friq) ' FRIQ_reward: ' num2str(total_reward_friq) ' epsilon: 0 rules: ' num2str(numofrules)])
    fprintf(logfile, ['FRIQ_usage_measurement_episode: FRIQ_steps: ' int2str(steps_friq) ' FRIQ_reward: ' num2str(total_reward_friq) ' epsilon: 0 rules: ' num2str(numofrules) '\r\n']);
    dlmwrite([RBbasefilename '_with_usage.csv'], [ R Rusage Rusage/sum(Rusage) ]);
