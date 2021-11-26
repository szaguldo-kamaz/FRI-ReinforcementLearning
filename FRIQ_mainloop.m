function FRIQ_mainloop()
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author:
%  David Vincze <david.vincze@uni-miskolc.hu>
% Author of the FIVE FRI method:
%  Szilveszter Kovacs <szkovacs@iit.uni-miskolc.hu>
% Additional reduction methods by: Tamas Tompa, Alex Toth
%
% Copyright (c) 2013-2021 by David Vincze
%

    %% for accessing user config values defined in the setup file
    global FRIQ_param_appname FRIQ_param_apptitle
    global FRIQ_param_FIVE_UD FRIQ_param_states FRIQ_param_statedivs FRIQ_param_states_steepness FRIQ_param_states_default
    global FRIQ_param_actions FRIQ_param_actiondiv
    global FRIQ_param_qdiff_pos_boundary FRIQ_param_qdiff_neg_boundary FRIQ_param_qdiff_final_tolerance FRIQ_param_reward_good_above
    global FRIQ_param_norandom FRIQ_param_drawsim FRIQ_param_maxsteps FRIQ_param_alpha FRIQ_param_gamma FRIQ_param_epsilon FRIQ_param_maxepisodes
    global FRIQ_param_doactionfunc FRIQ_param_rewardfunc FRIQ_param_drawfunc
    global FRIQ_param_construct_rb FRIQ_param_measure_constructed_rb_usage FRIQ_param_reduce_rb FRIQ_param_measure_reduced_rb_usage
    global FRIQ_param_reduction_strategy FRIQ_param_reduction_strategy_secondary
    global FRIQ_const_reduction_strategy__names FRIQ_const_reduction_secondary_strategies
    global FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY FRIQ_const_reduction_strategy__ALL

    %% Init

    global FRIQ_octave FRIQ_matlab
    if exist('OCTAVE_VERSION','builtin') > 0
        FRIQ_octave=true;
        FRIQ_matlab=false;
    else
        FRIQ_octave=false;
        FRIQ_matlab=true;
    end

    FIVEpath=strcat(pwd,'/FIVE');
    addpath(FIVEpath);

    global U VE R stopappnow numofrules reduction_state
    stopappnow = 0;
    reduction_state = 0;

    global numofstates numofactions Usize
    numofstates = size(FRIQ_param_states, 2);
    numofactions = length(FRIQ_param_actions);
    Usize = size(FRIQ_param_FIVE_UD, 2);

    if FRIQ_param_norandom == 1
        FRIQ_param_epsilon = 0;
    end

    % 'possiblestates' are used for define points where new rules can be possibly inserted
    global possiblestates possiblestates_epsilons
    global possibleaction possibleaction_epsilon

    possiblestates = FRIQ_param_states;
    possibleaction = FRIQ_param_actions;
    possiblestates_epsilons = FRIQ_param_statedivs;
    possibleaction_epsilon = FRIQ_param_actiondiv;

    % Generate initial data
    [U, VE, R] = FRIQ_gen_FIVE_FRI_params(FRIQ_param_FIVE_UD, FRIQ_param_states, FRIQ_param_states_steepness, FRIQ_param_actions); % for FRIQ-learning - generate initial rule base and FIVE FRI specific data
    [numofrules, ~] = size(R);

    xpoints = [];
    ypoints = [];

    if FRIQ_matlab
        set(gcf, 'BackingStore', 'off');
    end
    set(gco, 'Units', 'data');
    set(gcf, 'name', FRIQ_param_apptitle);
    set(gcf, 'Color', 'w');

    if ~exist('FRIQ_param_maxepisodes', 'var')
        FRIQ_param_maxepisodes = 2000;
    else

        if isempty(FRIQ_param_maxepisodes)
            FRIQ_param_maxepisodes = 2000;
        end

    end

    global filetimestamp
    timetemp=clock;
    filetimestamp=[num2str(timetemp(1)) '.' num2str(timetemp(2),'%0.2d') '.' num2str(timetemp(3),'%0.2d') '__' num2str(timetemp(4),'%0.2d') '_' num2str(timetemp(5),'%0.2d') '_' num2str(floor(timetemp(6)),'%0.2d')];

    % check logs/rulebases dir
    if ~isfolder('logs')
        mkdir('logs');
    end
    if ~isfolder('rulebases')
        mkdir('rulebases');
    end

    % open logfile
    global logfile
    logfile = fopen(['logs/FRIQ_' FRIQ_param_appname '_eplog__' filetimestamp '.txt'], 'w');

    if logfile == -1
        disp(['ERROR: Cannot open logs/FRIQ_' FRIQ_param_appname '_eplog__' filetimestamp '.txt !']);
        ERROR
    end

    total_reward_friq = nan;
    steps_friq = nan;
    num_of_rules = nan;

    %% FRIQ-learning main loop
    global debug_on
    debug_on = 0;
    global epno

    %% Simulation starts here

    if FRIQ_param_construct_rb == 1

        for epno = 1:FRIQ_param_maxepisodes

            prevR = R;
            prev_reward = total_reward_friq;
            prev_steps = steps_friq;
            prev_numru = num_of_rules;

            [total_reward_friq, steps_friq] = FRIQ_episode(FRIQ_param_maxsteps, FRIQ_param_alpha, FRIQ_param_gamma, FRIQ_param_epsilon);
            [num_of_rules, ~] = size(R);
            disp(            ['FRIQ_episode: ' int2str(epno) ' FRIQ_steps: ' int2str(steps_friq) ' FRIQ_reward: ' num2str(total_reward_friq) ' epsilon: ' num2str(FRIQ_param_epsilon) ' rules: ' num2str(num_of_rules)])
            fprintf(logfile, ['FRIQ_episode: ' int2str(epno) ' FRIQ_steps: ' int2str(steps_friq) ' FRIQ_reward: ' num2str(total_reward_friq) ' epsilon: ' num2str(FRIQ_param_epsilon) ' rules: ' num2str(num_of_rules) '\r\n']);

            if FRIQ_param_norandom == 0
                FRIQ_param_epsilon = FRIQ_param_epsilon * 0.99;
            else
                FRIQ_param_epsilon = 0;
            end

            xpoints(epno) = epno - 1; %#ok<AGROW>
            ypoints(epno) = steps_friq; %#ok<AGROW>

            % Redraw the learning curve
            subplot(2, 1, 1);
            plot(xpoints, ypoints);
            drawnow

            if prev_numru == num_of_rules && prev_steps == steps_friq && total_reward_friq > FRIQ_param_reward_good_above && prev_reward == total_reward_friq
                if max(abs(R(:, numofstates + 2) - prevR(:, numofstates + 2))) < FRIQ_param_qdiff_final_tolerance
                    dlmwrite(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB__' filetimestamp '.csv'], R);
                    dlmwrite(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB_steps__' filetimestamp '.txt'], steps_friq);
                    copyfile(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB__' filetimestamp '.csv'], ['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB.csv']);
                    copyfile(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB_steps__' filetimestamp '.txt'], ['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB_steps.txt']);
                    break
                end

            end

        end

    end

    %% Measure rule usage of the constructed rule-base

    if FRIQ_param_measure_constructed_rb_usage == 1
        disp(['Measuring rule usage with this rule-base: rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB' ]);
        fprintf(logfile, ['Measuring rule usage with this rule-base: rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB\r\n' ]);
        FRIQ_measure_RB_usage(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB']);
    end

    %% Reduction of a previously constructed rule-base

    if FRIQ_param_reduce_rb == 1
        if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ALL
            redstrats_to_use=1:size(FRIQ_const_reduction_strategy__names,2);
        else
            redstrats_to_use=FRIQ_param_reduction_strategy;
        end
        if FRIQ_param_reduction_strategy_secondary == FRIQ_const_reduction_strategy__ALL
            secondredstrats_to_use=[ 0 FRIQ_const_reduction_secondary_strategies ];
        else
            secondredstrats_to_use=FRIQ_param_reduction_strategy_secondary;
        end

        for redstrat = redstrats_to_use
            FRIQ_param_reduction_strategy=redstrat;
            if redstrat == FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY && ~isempty(secondredstrats_to_use)
                for secondredstrat = secondredstrats_to_use
                    if secondredstrat == 0
                        FRIQ_param_reduction_strategy_secondary=[];
                        disp('Using ANTECEDENT_REDUNDANCY without secondary strategy.');
                        fprintf(logfile, 'Using ANTECEDENT_REDUNDANCY without secondary strategy.\r\n');
                    else
                        FRIQ_param_reduction_strategy_secondary=secondredstrat;
                        disp([ 'Using ANTECEDENT_REDUNDANCY with ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} ]);
                        fprintf(logfile, [ 'Using ANTECEDENT_REDUNDANCY with ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} '\r\n' ]);
                    end
                    FRIQ_reduction();
                    % fallbacks can overwrite this in FRIQ_reduction(), so reset it every time before calling FRIQ_reduction()
                    FRIQ_param_reduction_strategy=FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY;
                    % Measure rule usage of the reduced rule-base
                    if FRIQ_param_measure_reduced_rb_usage == 1
                        if isempty(FRIQ_param_reduction_strategy_secondary)
                            reduced_rb_basefilename = [ 'rulebases/FRIQ_' FRIQ_param_appname '_reduced_RB_with_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} ];
                        else
                            reduced_rb_basefilename = [ 'rulebases/FRIQ_' FRIQ_param_appname '_reduced_RB_with_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} '_and_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} ];
                        end
                        disp(['Measuring rule usage with this rule-base: ' reduced_rb_basefilename ]);
                        fprintf(logfile, ['Measuring rule usage with this rule-base: ' reduced_rb_basefilename '\r\n' ]);
                        FRIQ_measure_RB_usage(reduced_rb_basefilename);
                    end
                end
            else
                FRIQ_param_reduction_strategy_secondary=[];
                disp([ 'Using ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} ]);
                fprintf(logfile, [ 'Using ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} '\r\n' ]);
                FRIQ_reduction();
                % fallbacks can overwrite this in FRIQ_reduction(), so reset it every time before calling FRIQ_reduction()
                FRIQ_param_reduction_strategy=redstrat;
                % Measure rule usage of the reduced rule-base
                if FRIQ_param_measure_reduced_rb_usage == 1
                    if isempty(FRIQ_param_reduction_strategy_secondary)
                        reduced_rb_basefilename = [ 'rulebases/FRIQ_' FRIQ_param_appname '_reduced_RB_with_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} ];
                    else
                        reduced_rb_basefilename = [ 'rulebases/FRIQ_' FRIQ_param_appname '_reduced_RB_with_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} '_and_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} ];
                    end
                    disp(['Measuring rule usage with this rule-base: ' reduced_rb_basefilename ]);
                    fprintf(logfile, ['Measuring rule usage with this rule-base: ' reduced_rb_basefilename '\r\n' ]);
                    FRIQ_measure_RB_usage(reduced_rb_basefilename);
                end
            end
        end
    end

    %% DeInit

    rmpath(FIVEpath);
    fclose(logfile);
