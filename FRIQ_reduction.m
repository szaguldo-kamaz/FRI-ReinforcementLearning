function FRIQ_reduction()
%
% FRIQ-learning framework v0.70
% https://github.com/szaguldo-kamaz/
%
% Author:
%  David Vincze <david.vincze@uni-miskolc.hu>
% Author of the FIVE FRI method:
%  Szilveszter Kovacs <szkovacs@iit.uni-miskolc.hu>
% Additional reduction methods by: Tamas Tompa, Alex Toth
%
% Copyright (c) 2013-2022 by David Vincze
%

    %% for accessing user config values defined in the setup file
    global FRIQ_param_appname FRIQ_param_apptitle
    global FRIQ_param_FIVE_UD FRIQ_param_states FRIQ_param_statedivs FRIQ_param_states_steepness FRIQ_param_states_default
    global FRIQ_param_actions FRIQ_param_actiondiv
    global FRIQ_param_qdiff_pos_boundary FRIQ_param_qdiff_neg_boundary FRIQ_param_qdiff_final_tolerance FRIQ_param_reward_good_above FRIQ_param_reduction_reward_tolerance FRIQ_param_reduction_rule_distance FRIQ_param_reduction_allow_better_reward_above_tolerance
    global FRIQ_param_norandom FRIQ_param_drawsim FRIQ_param_maxsteps FRIQ_param_alpha FRIQ_param_gamma FRIQ_param_epsilon FRIQ_param_maxepisodes
    global FRIQ_param_doactionfunc FRIQ_param_rewardfunc FRIQ_param_drawfunc
    global FRIQ_param_reduction_strategy FRIQ_param_reduction_strategy_secondary FRIQ_param_remove_unnecessary_membership_functions
    global FRIQ_param_reduction_kmeans_rng FRIQ_param_reduction_kmeans_distancemetric
    global FRIQ_param_test_previous_rb
    global FRIQ_param_maxreductionepisodes

    %% Define constants - for the names of the strategies
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
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_ONE
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_MANY
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_ONE
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_MANY
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_CENTROID
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINANDMAXQ
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MAXABSQ
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINABSQ
    global FRIQ_const_reduction_strategy__CLUSTER__HIERARCHICAL
    global FRIQ_const_reduction_strategy__names

    %% Init
    global U VE R stopappnow numofrules reduction_state
    reduction_state = 0;

    global numofstates numofactions Usize
    global possiblestates possiblestates_epsilons
    global possibleaction possibleaction_epsilon
    global logfile filetimestamp
    global debug_on

%% Reduction of a previously constructed rule-base

    global R_tocalc R_tmp R_tocalc_prev

        toreduceRB_filename=['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB.csv'];
        toreduceRB_steps_filename=['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB_steps.txt'];
%         toreduceRB_filename=['rulebases/FRIQ_example_cartpole_reduced_RB_with_ANTECEDENT_REDUNDANCY_and_ELIMINATE_DUPLICATED__MERGE_MEAN.csv'];
%         toreduceRB_steps_filename=['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB_steps.txt'];

        reduction_strategy_rb_filename_base = [ 'rulebases/FRIQ_' FRIQ_param_appname '_reduced_RB_with_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} ];
        if ~isempty(FRIQ_param_reduction_kmeans_distancemetric)
            reduction_strategy_rb_filename_base = [ reduction_strategy_rb_filename_base '_distmetric_' num2str(FRIQ_param_reduction_kmeans_distancemetric) ];
        end
        if ~isempty(FRIQ_param_reduction_kmeans_rng)
            reduction_strategy_rb_filename_base = [ reduction_strategy_rb_filename_base '_withrng_' num2str(FRIQ_param_reduction_kmeans_rng) ];
        end
        if ~isempty(FRIQ_param_reduction_strategy_secondary)
            reduction_strategy_rb_filename_base = [ reduction_strategy_rb_filename_base '_and_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} ];
        end

        % initialization for HALF_GROUP_REMOVAL
        div_limitq = 2;
        really_eliminate_rules = 0;

        % load the rule-base + steps
        if ~exist(toreduceRB_filename, 'file') || ~exist(toreduceRB_steps_filename, 'file')
            disp('The supplied rule-base files were not found, please run the construction process first (set FRIQ_param_construct_rb = 1).');
            return;
        end
        R = dlmread(toreduceRB_filename);
        steps_friq_incremental = dlmread(toreduceRB_steps_filename);
        numofrules = size(R, 1);

        if isempty(FRIQ_param_reduction_strategy_secondary)
            disp(['Using reduction strategy: ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} ]);
            fprintf(logfile, ['Using reduction strategy: ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} '\r\n' ]);
        else
            disp(['Using reduction strategy: ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} ' with ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} ]);
            fprintf(logfile, ['Using reduction strategy: ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} ' with ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} '\r\n' ]);
        end

        R_tmp = R;
        R_tocalc = R;
        R_tocalc_prev = R;
        reduction_state = 1;

        % initialization for ANTECEDENT_REDUNDANCY
        tested_rule = 1;
        tested_antecedent = 1;
        U_states = U(1:numofstates, :);
        VE_states = VE(1:numofstates, :);
        [nu, mu] = size(U_states);

        % initialization for CLUSTER__KMEANS_REMOVE_ONE & CLUSTER__KMEANS_REMOVE_MANY
        k_value = 2;
        tested_cluster = 1;
        removed_clusters = 0;

        % initialization for BUILD_MINANDMAXQ
        found_smallest_rb = 0;

        if ~isempty(FRIQ_param_maxreductionepisodes)
            FRIQ_param_maxreductionepisodes = 50000;
        end

        if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__MIN_Q || FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__MAX_Q
            iterations = (numofrules + 1);
        else
            iterations = FRIQ_param_maxreductionepisodes;
        end

        % measure cpu usage
        cputime_reduction_start = cputime;

        %% Reduction mainloop
        for epno = 1:iterations

            if ~isempty(FRIQ_param_reduction_kmeans_rng)
                rng(FRIQ_param_reduction_kmeans_rng);
            end

            % Two-step reduction strategies (need to do it here, because of possible fallbacks)
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MAXQ || ...
               FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MINQ || ...
               FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MAXQ || ...
               FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MINQ

                switch FRIQ_param_reduction_strategy
                    % Two-step reduction strategies switch - DUPLICATED_MAXQ -> DUPLICATED_FIRST
                    case FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MAXQ
                        % sort by Q value descending
                        [~, idx] = sortrows(abs(R), -(numofstates + 2));
                        R = R(idx, :);
                        % switch to ELIMINATE_DUPLICATED (6) as the remaining steps are the same
                        FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST;

                    % Two-step reduction strategies switch - DUPLICATED_MINQ -> DUPLICATED_FIRST
                    case FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MINQ
                        % sort by Q value ascending
                        [~, idx] = sortrows(abs(R), (numofstates + 2));
                        R = R(idx, :);
                        % switch to ELIMINATE_DUPLICATED (6) as the remaining steps are the same
                        FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST;

                    % Two-step reduction strategies switch - SIMILAR_MAXQ -> SIMILAR_FIRST
                    case FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MAXQ
                        % sort by Q value descending
                        [~, idx] = sortrows(abs(R), -(numofstates + 2));
                        R = R(idx, :);
                        % switch to strategy ELIMINATE_SIMILAR__FIRST (5) as the remaining steps are the same
                        FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST;

                    % Two-step reduction strategies switch - SIMILAR_MINQ -> SIMILAR_FIRST
                    case FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MINQ
                        % sort by Q value ascending
                        [~, idx] = sortrows(abs(R), (numofstates + 2));
                        R = R(idx, :);
                        % switch to strategy ELIMINATE_SIMILAR__FIRST (5) as the remaining steps are the same
                        FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST;
                end
                R_tmp = R;
                R_tocalc = R;
                R_tocalc_prev = R;
            end

            % empty check necessary because kmeans sometimes creates empty clusters
            if isempty(R)
                total_reward_friq = FRIQ_param_reward_good_above - 1; % TODO CHECK
            else
                [total_reward_friq, steps_friq] = FRIQ_episode(FRIQ_param_maxsteps, FRIQ_param_alpha, FRIQ_param_gamma, FRIQ_param_epsilon);
            end

            num_of_rules = size(R, 1);
            disp(            ['FRIQ_reduction_episode: ' int2str(epno) ' FRIQ_steps: ' int2str(steps_friq) ' FRIQ_reward: ' num2str(total_reward_friq) ' epsilon: ' num2str(FRIQ_param_epsilon) ' rules: ' num2str(num_of_rules)])
            fprintf(logfile, ['FRIQ_reduction_episode: ' int2str(epno) ' FRIQ_steps: ' int2str(steps_friq) ' FRIQ_reward: ' num2str(total_reward_friq) ' epsilon: ' num2str(FRIQ_param_epsilon) ' rules: ' num2str(num_of_rules) '\r\n']);

            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__MIN_Q || FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__MAX_Q

                if epno > 1
                    diff_rewardf = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) && (steps_friq <= steps_friq_incremental) && (abs(diff_rewardf) <= FRIQ_param_reduction_reward_tolerance)
                        % omission of this rule could be a good idea, keep this rb
                        diff_rewardf = prev_total_reward_friq - total_reward_friq;
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Eliminated rule: no. ', int2str(mindex), ' - ', num2str(R_tocalc_prev(mindex, :)), ' Reward diff was: ', num2str(diff_rewardf)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Eliminated rule: no. ', int2str(mindex), ' - ', num2str(R_tocalc_prev(mindex, :)), ' Reward diff was: ', num2str(diff_rewardf) '\r\n']);
                        prev_total_reward_friq = total_reward_friq;
                    else
                        % omission of the rule was a bad idea -> restore rule base
                        R_tmp = R_tmp_prev;
                        R_tmp(mindex, numofstates + 2) = NaN; % mark as "restored"
                        R_tocalc = R_tocalc_prev;
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Rule stays: no. ', int2str(mindex), ' - ', num2str(R_tocalc(mindex, :))]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Rule stays: no. ', int2str(mindex), ' - ', num2str(R_tocalc(mindex, :)), '\r\n']);
                    end

                else
                    prev_total_reward_friq = total_reward_friq;
                end

            end

            %% 1. min q
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__MIN_Q
                % take out next candidate rule
                [mvalue, mindex] = min(abs(R_tmp(:, numofstates + 2)));

                if isnan(mvalue)
                    disp('Smallest rule-base found. Stop.');
                    fprintf(logfile, 'Smallest rule-base found. Stop.\r\n');
                    R = R_tocalc;
                    stopappnow = 1;
                else
                    R_tmp_prev = R_tmp;
                    R_tmp(mindex, :) = [];
                    R_tocalc_prev = R_tocalc;
                    R_tocalc(mindex, :) = [];
                    R = R_tocalc;
                end

            end

            %% 2. max q
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__MAX_Q
                % take out next candidate rule
                [mvalue, mindex] = max(abs(R_tmp(:, numofstates + 2)));

                if isnan(mvalue)
                    disp('Smallest rule-base found. Stop.');
                    fprintf(logfile, 'Smallest rule-base found. Stop.\r\n');
                    R = R_tocalc;
                    stopappnow = 1;
                else
                    R_tmp_prev = R_tmp;
                    R_tmp(mindex, :) = [];
                    R_tocalc_prev = R_tocalc;
                    R_tocalc(mindex, :) = [];
                    R = R_tocalc;
                end

            end

            %% 3. rule groups - current +- average q value
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__HALF_GROUP_REMOVAL
                % first check the result of the previous iteration (if this is not the first iteration)
                if epno > 1
                    [~, numofelimrules] = size(eliminated_rules);
                    diff_rewardf = prev_total_reward_friq - total_reward_friq;
                    if (total_reward_friq > FRIQ_param_reward_good_above) && (steps_friq <= steps_friq_incremental) && (abs(diff_rewardf) <= FRIQ_param_reduction_reward_tolerance)
                        % omission of this rule group could be a good idea
                        diff_rewardf = prev_total_reward_friq - total_reward_friq;

                        for currule = 1:numofelimrules
                            fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Eliminated rule: no. ', int2str(eliminated_rules(currule)), ' - ', num2str(R_to_display_prev(eliminated_rules(currule), :)), ' Reward diff was: ', num2str(diff_rewardf) '\r\n']);
                        end

                        prev_stepsf = steps_friq;
                        prev_total_reward_friq = total_reward_friq;
                        div_limitq = 2;
                        really_eliminate_rules = 0;
                        R_lastgood = R_tocalc;
                    else
                        % omission of the previous rule group was a bad idea
                        % restore rule base
                        % and increase the divider for 'qlimit' variable
                        R_tmp = R_tmp_prev;
                        R_tocalc = R_tocalc_prev;

                        for currule = 1:numofelimrules
                            fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Rule stays: no. ', int2str(eliminated_rules(currule)), ' - ', num2str(R_to_display_prev(eliminated_rules(currule), :)), '\r\n']);

                            if really_eliminate_rules == 1
                                disp(['FRIQ_reduction_episode: ', int2str(epno), ' Marked rule: no. ', int2str(eliminated_rules(currule)), ' - ', num2str(R_tmp(eliminated_rules(currule), :))]);
                                fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Marked rule: no. ', int2str(eliminated_rules(currule)), ' - ', num2str(R_tmp(eliminated_rules(currule), :)), '\r\n']);
                                R_tmp(eliminated_rules(currule), numofstates + 2) = NaN; % "mark as restored"
                            end

                        end

                        div_limitq = div_limitq * 2;
                    end

                else
                    prev_total_reward_friq = total_reward_friq;
                end

                R_to_display_prev = R_tocalc;
                R_tocalc_prev = R_tocalc;

                % look for rule groups to remove
                eliminated_rules = [];
                [mvalue, mindex] = min(abs(R_tmp(:, numofstates + 2)));
                % every rule has been checked and marked for permanent?
                if isnan(mvalue)
                    if (total_reward_friq > FRIQ_param_reward_good_above) && (steps_friq <= steps_friq_incremental) && (abs(diff_rewardf) <= FRIQ_param_reduction_reward_tolerance)
                        disp('Smallest rule-base found. Stop.');
                        fprintf(logfile, 'Smallest rule-base found. Stop.\r\n');
                        R = R_tocalc;
                        stopappnow = 1;
                    else
                        R_tmp = R_lastgood;
                        R_tmp_prev = R_lastgood;
                        R_tocalc = R_lastgood;
                        R_tocalc_prev = R_lastgood;
                        [numpassedrules, ~] = size(R_tocalc);
                        fprintf(2, ['Switching to strategy 1 (MIN_Q) with last good RB! Number of rules: ', int2str(numpassedrules) '\r\n '])
%                         disp(['Switching to strategy 1 (MIN_Q) with last good RB! Number of rules: ', int2str(numpassedrules)]);
                        FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__MIN_Q;
                    end

                else % there are still some more rules to check
                    [numofrules, ~] = size(R_tmp);
%-                     qlimit=nansum(abs(R_tmp(:,numofstates+2)))/numofrules/div_limitq;
                    absqs = abs(R_tmp(:, numofstates + 2));
%                     [minabsqs,minabsqsindex]=min(absqs);
                    [minabsqs, ~] = min(absqs);
                    qlimit = (max(absqs) - minabsqs) / div_limitq + minabsqs;
                    absqs_tmp = absqs;
%-                    absqs_tmp(minabsqsindex,:)=[];
%-                    secondminabsqs=min(absqs_tmp);

                    % search for the second minimal absq
                    for secsearchi = numofrules:-1:1

                        if absqs_tmp(secsearchi) == minabsqs
                            absqs_tmp(secsearchi, :) = [];
                        end

                    end

                    secondminabsqs = min(absqs_tmp);

                    if (numofrules - 1) ~= size(absqs_tmp, 1)
                        disp(            ['FRIQ_reduction_episode_RED3x: ' int2str(epno) ' minabsqs: ' num2str(minabsqs, 16) ' secondminabsqs: ' num2str(secondminabsqs, 16) ' size(absqs_tmp,1): ' int2str(size(absqs_tmp, 1))]);
                        fprintf(logfile, ['FRIQ_reduction_episode_RED3x: ' int2str(epno) ' minabsqs: ' num2str(minabsqs, 16) ' secondminabsqs: ' num2str(secondminabsqs, 16) ' size(absqs_tmp,1): ' int2str(size(absqs_tmp, 1)) '\r\n']);
                    end

                    if (qlimit < secondminabsqs) || isnan(secondminabsqs)
                        qlimit = minabsqs;
                        really_eliminate_rules = 1;
                    end

                    if (numofrules == 1)
                        really_eliminate_rules = 1;
                    end

                    R_tmp_prev = R_tmp;
                    %[mvalue,mindex]=min(abs(R_tmp(:,numofstates+2)));

                    disp(            ['FRIQ_reduction_episode_RED3: ', int2str(epno), ' qlimit: ', num2str(qlimit, 16), ' secondminabsqs: ', num2str(secondminabsqs, 16), ' div: ', int2str(div_limitq) ' norules: ' int2str(numofrules) ' maxq: ' num2str(max(absqs), 16) ' minq: ' num2str(min(absqs), 16)]);
                    fprintf(logfile, ['FRIQ_reduction_episode_RED3: ', int2str(epno), ' qlimit: ', num2str(qlimit, 16), ' secondminabsqs: ', num2str(secondminabsqs, 16), ' div: ', int2str(div_limitq) ' norules: ' int2str(numofrules) ' maxq: ' num2str(max(absqs), 16) ' minq: ' num2str(min(absqs), 16) '\r\n']);

                    for currule = numofrules:-1:1

                        if isnan(R_tmp(currule, numofstates + 2))
                            continue
                        end

                        if (abs(R_tmp(currule, numofstates + 2)) <= qlimit)%|| (qlimitdiff <= 0 && qlimitdiff > -0.001)% some extra tolerance
                            R_tmp(currule, :) = [];
                            R_tocalc(currule, :) = [];
                            eliminated_rules = [eliminated_rules currule]; %#ok<AGROW>
                        end

                    end

%                     R_tocalc_prev=R_tocalc;
                    R = R_tocalc;

                end

            end

            %% 15. rules with min and max q value remain - BUILD_MINANDMAXQ
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__BUILD_MINANDMAXQ

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                    R = [];
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Keeping rules: ', int2str(find(ismember(R_tmp(:, 1:numofstates + 1), R(:, 1:numofstates + 1), 'rows')).'), '.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Keeping rules: ', int2str(find(ismember(R_tmp(:, 1:numofstates + 1), R(:, 1:numofstates + 1), 'rows')).'), '.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;
                        found_smallest_rb = 1;
                    end

                end

                [maxvalue, maxindex] = max(R_tmp(:, numofstates + 2));
                [minvalue, minindex] = min(R_tmp(:, numofstates + 2));

                if found_smallest_rb == 1 || isnan(maxvalue) || isnan(minvalue) || maxvalue == minvalue
                    % every rule has been tested
                    disp('Found smallest rule-base. Stop.');
                    fprintf(logfile, 'Found smallest rule-base. Stop.\r\n');
                    stopappnow = 1;
                else
                    R = [R; R_tmp(maxindex, :)]; %#ok<AGROW>
                    R_tmp(maxindex, numofstates + 2) = nan;
                    R = [R; R_tmp(minindex, :)]; %#ok<AGROW>
                    R_tmp(minindex, numofstates + 2) = nan;
                end

            end

            %% 4. remove unnecessary antecedents ANTECEDENT_REDUNDANCY
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the antecedent from the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of antecedent: no. ', int2str(tested_antecedent), ' from rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of antecedent: no. ', int2str(tested_antecedent), ' from rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;
                    else
                        % omission of the antecedent from the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of antecedent: no. ', int2str(tested_antecedent), ' from rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of antecedent: no. ', int2str(tested_antecedent), ' from rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                    end

                    % test the next antecedent
                    tested_antecedent = tested_antecedent + 1;

                    % every antecedent have been tested, move on to the next rule
                    if tested_antecedent > numofstates
                        tested_rule = tested_rule + 1;
                        tested_antecedent = 1;
                    end

                end

                if (tested_rule > num_of_rules)
                    % every rule and antecedent have been tested -> switch to secondary strategy if configured

                    R = R_tmp;

                    if isempty(FRIQ_param_reduction_strategy_secondary)
                        disp(            'Every rule and antecedent have been tested. No secondary strategy was configured, so stopping now.');
                        fprintf(logfile, 'Every rule and antecedent have been tested. No secondary strategy was configured, so stopping now.\r\n');
                        stopappnow = 1;
                    else
                        disp(            [ 'Every rule and antecedent have been tested. Switching to ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} ' as a secondary strategy to possibly further reduce RB.' ]);
                        fprintf(logfile, [ 'Every rule and antecedent have been tested. Switching to ' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} ' as a secondary strategy to possibly further reduce RB.\r\n' ]);
                        FRIQ_param_reduction_strategy = FRIQ_param_reduction_strategy_secondary;
                        tested_rule = 1;
                    end

                else
                    % there are rules and antecedents that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    if isnan(R_tmp(tested_rule, tested_antecedent))
                        % this antecedent of the rule has already been tested
                        continue
                    end

                    % collect rules similar to the one being tested
                    rule_group = zeros(1, num_of_rules);
                    rule_group(tested_rule) = tested_rule;

                    for rule_index = 1:num_of_rules

                        if (rule_index == tested_rule) || isnan(R_tmp(rule_index, tested_antecedent))
                            continue
                        end

                        distances = FIVEVagDist_fixres(U_states, nu, mu, VE_states, R_tmp(tested_rule, 1:numofstates), R_tmp(rule_index, 1:numofstates));

                        if (min(distances) < 0)
                            distance = -norm(distances(distances < 0), 2);
                        else
                            distance = norm(distances, 2);
                        end

                        if distance < FRIQ_param_reduction_rule_distance
                            rule_group(rule_index) = rule_index;
                        end

                    end

                    % remove the antecedent being tested from the collected rules
                    rule_group = rule_group(rule_group > 0);
                    R_tmp(rule_group, tested_antecedent) = nan;

                    R = R_tmp;
                end

            end

            %% 5. remove similar rules ELIMINATE_SIMILAR__FIRST
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        tested_rule = tested_rule - size(rule_group(rule_group <= tested_rule), 2);
                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                    end

                    % test the next rule
                    tested_rule = tested_rule + 1;

                end

                if tested_rule > size(R_tmp, 1)
                    % every rule have been tested
                    disp('Every rule have been tested. Stop.');
                    fprintf(logfile, 'Every rule have been tested. Stop.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    % collect rules similar to the one being tested
                    rule_group = zeros(1, num_of_rules);

                    for rule_index = 1:num_of_rules

                        if rule_index == tested_rule
                            continue
                        end

                        distances = FIVEVagDist_fixres(U_states, nu, mu, VE_states, R_tmp(tested_rule, 1:numofstates), R_tmp(rule_index, 1:numofstates));

                        if (min(distances) < 0)
                            distance = -norm(distances(distances < 0), 2);
                        else
                            distance = norm(distances, 2);
                        end

                        if distance < FRIQ_param_reduction_rule_distance
                            rule_group(rule_index) = rule_index;
                        end

                    end

                    % remove the collected rules from the rule base
                    rule_group = rule_group(rule_group > 0);
                    R_tmp(rule_group, :) = [];

                    R = R_tmp;

                end

            end

            %% 6. remove duplicated rules (use this strategy after ANTECEDENT_REDUNDANCY (4) was applied) + MAXQ and MINQ (7+8) also falls back to this
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        if size(rule_group, 2) == 1
                            tested_rule = tested_rule - 1;
                        else
                            tested_rule = tested_rule - size(rule_group(rule_group < tested_rule), 2);
                        end

                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                    end

                    % test the next rule
                    tested_rule = tested_rule + 1;

                end

                if tested_rule > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Stop.');
                    fprintf(logfile, 'Every rule has been tested. Stop.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    % collect rules that are only different from the tested one in the q value
                    R_tmp(isnan(R_tmp)) = inf; % functions usually can't work with nan, replace them with inf

                    rule_group = find(ismember(R_tmp(:, 1:(numofstates + 1)), R_tmp(tested_rule, 1:(numofstates + 1)), 'rows'));
                    rule_group = rule_group.'; % create a row vector from the column

                    if size(rule_group, 2) > 1
                        % mindex = find(ismember(R_tmp, max(R_tmp(rule_group, :)), 'rows'), 1); % find rule with highest q value in the group
                        mindex = tested_rule;

                        rule_group(rule_group == mindex) = []; % remove rule with highest q value from the group
                    end

                    R_tmp(rule_group, :) = []; % remove collected rules from the rule-base

                    R_tmp(isinf(R_tmp)) = nan;

                    R = R_tmp;

                end

            end

            %% 9. merge duplicated rules using mean (use this strategy after ANTECEDENT_REDUNDANCY (4) was applied) - ELIMINATE_DUPLICATED__MERGE_MEAN
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MERGE_MEAN

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        tested_rule = tested_rule - size(rule_group(rule_group < tested_rule), 2) - 1;
                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                    end

                    % test the next rule
                    tested_rule = tested_rule + 1;

                end

                if tested_rule > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Stop.');
                    fprintf(logfile, 'Every rule has been tested. Stop.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    % collect rules that are only different from the tested one in the q value
                    R_tmp(isnan(R_tmp)) = inf; % functions usually can't work with nan, replace them with inf  %% TODO CHECK THIS - restored later?

                    rule_group = find(ismember(R_tmp(:, 1:(numofstates + 1)), R_tmp(tested_rule, 1:(numofstates + 1)), 'rows'));
                    rule_group = rule_group.'; % create a row vector from the column

                    % construct new rule using mean of the collected ones
                    new_rule = mean(R_tmp(rule_group, :));

                    R_tmp(rule_group, :) = []; % remove collected rules from the rule-base

                    % if we removed more than one rule, add the new one to the rule-base
                    if size(rule_group, 2) > 1
                        R_tmp = [R_tmp; new_rule]; %#ok<AGROW>
                    end

                    R_tmp(isinf(R_tmp)) = nan;

                    R = R_tmp;

                end

            end

            %% 12. it's like ELIMINATE_DUPLICATED__MERGE_MEAN but the distance can be more than zero - ELIMINATE_SIMILAR__MERGE_MEAN
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MERGE_MEAN

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        tested_rule = tested_rule - size(rule_group(rule_group <= tested_rule), 2);
                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' Omission of rules: ', int2str(rule_group), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                    end

                    % test the next rule
                    tested_rule = tested_rule + 1;

                end

                if tested_rule > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Stop.');
                    fprintf(logfile, 'Every rule has been tested. Stop.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    % collect rules similar to the one being tested
                    rule_group = zeros(1, num_of_rules);

                    for rule_index = 1:num_of_rules

                        distances = FIVEVagDist_fixres(U_states, nu, mu, VE_states, R_tmp(tested_rule, 1:numofstates), R_tmp(rule_index, 1:numofstates));

                        if (min(distances) < 0)
                            distance = -norm(distances(distances < 0), 2);
                        else
                            distance = norm(distances, 2);
                        end

                        if distance < FRIQ_param_reduction_rule_distance
                            rule_group(rule_index) = rule_index;
                        end

                    end

                    rule_group = rule_group(rule_group > 0);

                    % construct new rule using mean of the collected ones
                    new_rule = mean(R_tmp(rule_group, :));

                    % remove the collected rules from the rule base
                    R_tmp(rule_group, :) = [];

                    % if we removed more than one rule, add the new one to the rule-base
                    if size(rule_group, 2) > 1
                        R_tmp = [R_tmp; new_rule]; %#ok<AGROW>
                    end

                    R = R_tmp;

                end

            end

            %% 13. kmeans v1 CLUSTER__KMEANS_REMOVE_ONE
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_ONE

                if epno == 1
                    kmeans_create_new_clusters = true;
                    prev_total_reward_friq = total_reward_friq;
                else
                    kmeans_create_new_clusters = false;
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        tested_cluster = 0;
                        k_value = 2;
                        kmeans_create_new_clusters = true;

                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                        idx = prev_idx;
                    end

                    % test the next rule
                    % workaround - matlab kmeans() sometimes generates empty clusters -> skip them
                    while kmeans_create_new_clusters == false  % no need for this step when creating new clusters
                        tested_cluster = tested_cluster + 1;
                        if tested_cluster > k_value || ~isempty(idx(idx == tested_cluster))
                            break
                        end
                    end

                    if tested_cluster > k_value
                        kmeans_create_new_clusters = true;
                        k_value = k_value + 1;
                    end

                end

                if k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Stop. You can try "traditional" methods for further reduction.');
                    fprintf(logfile, 'Every rule has been tested. Stop. You can try "traditional" methods for further reduction.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet

                    if kmeans_create_new_clusters == true
                        [idx, C] = kmeans(R_tmp, k_value, 'Distance', FRIQ_param_reduction_kmeans_distancemetric, 'EmptyAction', 'drop');
                        tested_cluster = 1;
                        % workaround - matlab kmeans() sometimes generates empty clusters -> skip them - when the first cluster is empty
                        while true
                            if ~isnan(C(tested_cluster,:))
                                break
                            end
                            disp([ 'kmeans() created an empty cluster. Skipping cluster: ' num2str(tested_cluster) ]);
                            fprintf(logfile, [ 'kmeans() created an empty cluster. Skipping cluster: ' num2str(tested_cluster) '\r\n' ]);
                            tested_cluster = tested_cluster + 1;
                        end
                    end

                    % something went wrong with kmeans() ? (can happen, also gives a warning, this way we can detect it)
                    if max(idx) ~= size(C,1)

                        % in that case, just skip this cluster (go to the next k-value, see above)
                        tested_cluster = k_value;
                        disp('kmeans() did not produce a valid result. Skipping.');
                        fprintf(logfile, 'kmeans() did not produce a valid result. Skipping.\r\n');

                    else  % kmeans() was seemingly ok

                        R_tmp_prev = R_tmp;
                        prev_idx = idx;

                        % remove a cluster from the rule-base
                        R_tmp(idx == tested_cluster, :) = [];
                        idx(idx == tested_cluster) = [];

                        R = R_tmp;

                    end

                end

            end

            %% 14. kmeans v2 - CLUSTER__KMEANS_REMOVE_MANY
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_MANY

                if epno == 1
                    kmeans_create_new_clusters = true;
                    prev_total_reward_friq = total_reward_friq;
                else
                    kmeans_create_new_clusters = false;
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        removed_clusters = 1;
                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                        idx = prev_idx;
                    end

                    % test the next rule
                    % workaround - matlab kmeans() sometimes generates empty clusters -> skip them
                    while kmeans_create_new_clusters == false  % no need for this step when creating new clusters
                        tested_cluster = tested_cluster + 1;
                        if tested_cluster > k_value || ~isempty(idx(idx == tested_cluster))
                            break
                        end
                    end

                    if tested_cluster > k_value

                        kmeans_create_new_clusters = true;

                        if removed_clusters == 1
                            k_value = 2;
                        else
                            k_value = k_value + 1;
                        end

                        removed_clusters = 0;
                    end

                end

                if k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Stop. You can try "traditional" methods for further reduction.');
                    fprintf(logfile, 'Every rule has been tested. Stop. You can try "traditional" methods for further reduction.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet

                    if kmeans_create_new_clusters == true
                        % returns the indexes of clusters where each of the rules belong one-by-one
                        [idx, C] = kmeans(R_tmp, k_value, 'Distance', FRIQ_param_reduction_kmeans_distancemetric, 'EmptyAction', 'drop');
                        tested_cluster = 1;
                        % workaround - matlab kmeans() sometimes generates empty clusters -> skip them - when the first cluster is empty
                        while true
                            if ~isnan(C(tested_cluster,:))
                                break
                            end
                            disp([ 'kmeans() created an empty cluster. Skipping cluster: ' num2str(tested_cluster) ]);
                            fprintf(logfile, [ 'kmeans() created an empty cluster. Skipping cluster: ' num2str(tested_cluster) '\r\n' ]);
                            tested_cluster = tested_cluster + 1;
                        end
                    end

                    % something went wrong with kmeans() ? (can happen, also gives a warning, this way we can detect it)
                    if max(idx) ~= size(C,1)

                        % in that case, just skip this cluster (go to the next k-value, see above)
                        tested_cluster = k_value;
                        disp('kmeans() did not produce a valid result. Skipping.');
                        fprintf(logfile, 'kmeans() did not produce a valid result. Skipping.\r\n');

                    else  % kmeans() was seemingly ok

                        R_tmp_prev = R_tmp;
                        prev_idx = idx;

                        % remove a cluster from the rule-base
                        R_tmp(idx == tested_cluster, :) = [];
                        idx(idx == tested_cluster) = [];

                        R = R_tmp;

                    end

                end

            end

            %% 16. kmeans v3 - CLUSTER__KMEANS_REPLACE_ONE
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_ONE

                if epno == 1
                    kmeans_create_new_clusters = true;
                    prev_total_reward_friq = total_reward_friq;
                else
                    kmeans_create_new_clusters = false;
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        kmeans_create_new_clusters = true;
                        tested_cluster = 0;
                        k_value = 2;
                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                        idx = prev_idx;
                    end

                    % test the next rule
                    % workaround - matlab kmeans() sometimes generates empty clusters -> skip them
                    while kmeans_create_new_clusters == false  % no need for this step when creating new clusters
                        tested_cluster = tested_cluster + 1;
                        if tested_cluster > k_value || ~isempty(idx(idx == tested_cluster))
                            break
                        end
                    end

                    if tested_cluster > k_value
                        kmeans_create_new_clusters = true;
                        k_value = k_value + 1;
                    end

                end

                if k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Stop. You can try "traditional" methods for further reduction.');
                    fprintf(logfile, 'Every rule has been tested. Stop. You can try "traditional" methods for further reduction.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet

                    if kmeans_create_new_clusters == true
                        [idx, C] = kmeans(R_tmp, k_value, 'Distance', FRIQ_param_reduction_kmeans_distancemetric, 'EmptyAction', 'drop');
                        tested_cluster = 1;
                        % workaround - matlab kmeans() sometimes generates empty clusters -> skip them - when the first cluster is empty
                        while true
                            if ~isnan(C(tested_cluster,:))
                                break
                            end
                            disp([ 'kmeans() created an empty cluster. Skipping cluster: ' num2str(tested_cluster) ]);
                            fprintf(logfile, [ 'kmeans() created an empty cluster. Skipping cluster: ' num2str(tested_cluster) '\r\n' ]);
                            tested_cluster = tested_cluster + 1;
                        end
                    end

                    % something went wrong with kmeans() ? (can happen, also gives a warning, this way we can detect it)
                    if max(idx) ~= size(C,1)
                        % in that case, just skip this cluster (go to the next k-value, see above)
                        tested_cluster = k_value;
                        disp('kmeans() did not produce a valid result. Skipping.');
                        fprintf(logfile, 'kmeans() did not produce a valid result. Skipping.\r\n');

                    else  % kmeans() was seemingly ok

                        R_tmp_prev = R_tmp;
                        prev_idx = idx;

                        % if there is more than one element in the cluster
                        if size(R_tmp(idx == tested_cluster), 1) > 1
                            % check wether centroid is inside the Universe (e.g. mountaincar + 'correlation' distance metrics)
                            for centroid_dim = 1:(numofstates + 1)
                                if C(tested_cluster, centroid_dim) < U(centroid_dim, 1)
                                    disp([ 'Centroid outside the Universe, overwriting with minimum value: ' num2str(C(tested_cluster, centroid_dim)) '->' num2str(U(centroid_dim, 1)) '.']);
                                    fprintf(logfile, [ 'Centroid outside the Universe, overwriting with minimum value: ' num2str(C(tested_cluster, centroid_dim)) '->' num2str(U(centroid_dim, 1)) '.\r\n']);
                                    C(tested_cluster, centroid_dim) = U(centroid_dim, 1);
                                elseif C(tested_cluster, centroid_dim) > U(centroid_dim, mu)
                                    disp([ 'Centroid outside the Universe, overwriting with maximum value: ' num2str(C(tested_cluster, centroid_dim)) '->' num2str(U(centroid_dim, mu)) '.']);
                                    fprintf(logfile, [ 'Centroid outside the Universe, overwriting with maximum value: ' num2str(C(tested_cluster, centroid_dim)) '->' num2str(U(centroid_dim, mu)) '.\r\n']);
                                    C(tested_cluster, centroid_dim) = U(centroid_dim, mu);
                                end
                            end
                            % add centroid element as a rule
                            if max(ismember(R_tmp, C(tested_cluster, :), 'rows'))
                                % can easily happen, beacuse the points are aligned in case they are out of the Universe (see above)
                                disp('Centroid rule already in rule-base. Skipping.');
                                fprintf(logfile, 'Centroid rule already in rule-base. Skipping.\r\n');
                            else
                                R_tmp(size(R_tmp, 1) + 1, :) = C(tested_cluster, :);
                                idx(size(idx, 1) + 1) = 0;  % mark the newly inserted centroid rule in idx also
                            end
                        end

                        % remove a cluster from the rule-base
                        R_tmp(idx == tested_cluster, :) = [];
                        idx(idx == tested_cluster) = [];

                        R = R_tmp;

                    end

                end

            end

            %% 17. kmeans v4 - CLUSTER__KMEANS_REPLACE_MANY
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_MANY

                if epno == 1
                    kmeans_create_new_clusters = true;
                    prev_total_reward_friq = total_reward_friq;
                else
                    kmeans_create_new_clusters = false;
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        removed_clusters = 1;
                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                        idx = prev_idx;
                    end

                    % test the next rule
                    % workaround - matlab kmeans() sometimes generates empty clusters -> skip them
                    while kmeans_create_new_clusters == false  % no need for this step when creating new clusters
                        tested_cluster = tested_cluster + 1;
                        if tested_cluster > k_value || ~isempty(idx(idx == tested_cluster))
                            break
                        end
                    end

                    if tested_cluster > k_value
                        kmeans_create_new_clusters = true;

                        if removed_clusters == 1
                            k_value = 2;
                        else
                            k_value = k_value + 1;
                        end

                        removed_clusters = 0;
                    end

                end

                if k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Stop. You can try "traditional" methods for further reduction.');
                    fprintf(logfile, 'Every rule has been tested. Stop. You can try "traditional" methods for further reduction.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet

                    if kmeans_create_new_clusters == true
                        [idx, C] = kmeans(R_tmp, k_value, 'Distance', FRIQ_param_reduction_kmeans_distancemetric, 'EmptyAction', 'drop');
                        tested_cluster = 1;
                        % workaround - matlab kmeans() sometimes generates empty clusters -> skip them - when the first cluster is empty
                        while true
                            if ~isnan(C(tested_cluster,:))
                                break
                            end
                            disp([ 'kmeans() created an empty cluster. Skipping cluster: ' num2str(tested_cluster) ]);
                            fprintf(logfile, [ 'kmeans() created an empty cluster. Skipping cluster: ' num2str(tested_cluster) '\r\n' ]);
                            tested_cluster = tested_cluster + 1;
                        end
                    end

                    % something went wrong with kmeans() ? (can happen, also gives a warning, this way we can detect it)
                    if max(idx) ~= size(C,1)

                        % in that case, just skip this cluster (go to the next k-value, see above)
                        tested_cluster = k_value;
                        disp('kmeans() did not produce a valid result. Skipping.');
                        fprintf(logfile, 'kmeans() did not produce a valid result. Skipping.\r\n');

                    else  % kmeans() was seemingly ok

                        R_tmp_prev = R_tmp;
                        prev_idx = idx;

                        % if there is more than one element in the cluster
                        if size(R_tmp(idx == tested_cluster), 1) > 1
                            % check wether centroid is inside the Universe (e.g. mountaincar + 'correlation' distance metrics)
                            for centroid_dim = 1:(numofstates + 1)
                                if C(tested_cluster, centroid_dim) < U(centroid_dim, 1)
                                    disp([ 'Centroid outside the Universe, overwriting with minimum value: ' num2str(C(tested_cluster, centroid_dim)) '->' num2str(U(centroid_dim, 1)) '.']);
                                    fprintf(logfile, [ 'Centroid outside the Universe, overwriting with minimum value: ' num2str(C(tested_cluster, centroid_dim)) '->' num2str(U(centroid_dim, 1)) '.\r\n']);
                                    C(tested_cluster, centroid_dim) = U(centroid_dim, 1);
                                elseif C(tested_cluster, centroid_dim) > U(centroid_dim, mu)
                                    disp([ 'Centroid outside the Universe, overwriting with maximum value: ' num2str(C(tested_cluster, centroid_dim)) '->' num2str(U(centroid_dim, mu)) '.']);
                                    fprintf(logfile, [ 'Centroid outside the Universe, overwriting with maximum value: ' num2str(C(tested_cluster, centroid_dim)) '->' num2str(U(centroid_dim, mu)) '.\r\n']);
                                    C(tested_cluster, centroid_dim) = U(centroid_dim, mu);
                                end
                            end
                            % add centroid element as a rule
                            if max(ismember(R_tmp, C(tested_cluster, :), 'rows'))
                                % can easily happen, beacuse the points are aligned in case they are out of the Universe (see above)
                                disp('Centroid rule already in rule-base. Skipping.');
                                fprintf(logfile, 'Centroid rule already in rule-base. Skipping.\r\n');
                            else
                                R_tmp(size(R_tmp, 1) + 1, :) = C(tested_cluster, :);
                                idx(size(idx, 1) + 1) = 0;  % mark the newly inserted centroid rule in idx also                            end
                            end
                        end

                        % remove a cluster from the rule-base
                        R_tmp(idx == tested_cluster, :) = [];
                        idx(idx == tested_cluster) = [];

                        R = R_tmp;
                    end
                end

            end

            %% 18. kmeans v5, COSINE + CORRELATION DISTANCE METRICS produces suboptimal results - CLUSTER__KMEANS_BUILD_CENTROID
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_CENTROID

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % possible solution found
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be good enough.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be good enough.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);

                        prev_total_reward_friq = total_reward_friq;

                        found_smallest_rb = 1;
                    else
                        % Too few (or "misleading") rules, add more
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be low, increasing it.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be low, increasing it.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        k_value = k_value + 1;
                    end

                end

                if found_smallest_rb == 1 || k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Solution found, or every rule has been tested. Stop.');
                    fprintf(logfile, 'Solution found, or every rule has been tested. Stop.\r\n');
                    stopappnow = 1;
                else

                    [idx, C] = kmeans(R_tmp, k_value, 'Distance', FRIQ_param_reduction_kmeans_distancemetric, 'EmptyAction', 'drop');

                    % something went wrong with kmeans() ? (can happen, also gives a warning, this way we can detect it)
                    if max(idx) ~= size(C,1)

                        % in that case, just skip this cluster (go to the next k-value, see above - using the same RB, it will "fail" againa, so k_value will be incremented)
                        disp('kmeans() did not produce a valid result. Skipping.');
                        fprintf(logfile, 'kmeans() did not produce a valid result. Skipping.\r\n');

                    else  % kmeans() was seemingly ok

                        R = [];

                        for centroidrule_index = 1:size(C, 1)
                            for centroid_dim = 1:(numofstates + 1)
                                if C(centroidrule_index, centroid_dim) < U(centroid_dim, 1)
                                    disp([ 'Centroid outside the Universe, overwriting with minimum value: ' num2str(C(centroidrule_index, centroid_dim)) '->' num2str(U(centroid_dim, 1)) '.']);
                                    fprintf(logfile, [ 'Centroid outside the Universe, overwriting with minimum value: ' num2str(C(centroidrule_index, centroid_dim)) '->' num2str(U(centroid_dim, 1)) '.\r\n']);
                                    C(centroidrule_index, centroid_dim) = U(centroid_dim, 1);
                                elseif C(centroidrule_index, centroid_dim) > U(centroid_dim, mu)
                                    disp([ 'Centroid outside the Universe, overwriting with maximum value: ' num2str(C(centroidrule_index, centroid_dim)) '->' num2str(U(centroid_dim, mu)) '.']);
                                    fprintf(logfile, [ 'Centroid outside the Universe, overwriting with maximum value: ' num2str(C(centroidrule_index, centroid_dim)) '->' num2str(U(centroid_dim, mu)) '.\r\n']);
                                    C(centroidrule_index, centroid_dim) = U(centroid_dim, mu);
                                end
                            end
                            % add centroid element as a rule
                            if ~isempty(R) && max(ismember(R, C(centroidrule_index, :), 'rows'))
                                % can easily happen, beacuse the points are aligned in case they are out of the Universe (see above)
                                disp('Centroid rule already in rule-base. Skipping.');
                                fprintf(logfile, 'Centroid rule already in rule-base. Skipping.\r\n');
                            else
                                R = [R; C(centroidrule_index, :)]; %#ok<AGROW>
                            end
                        end

                    end

                end

            end

            %% 19. kmeans v6: min and max q value rule of every cluster - CLUSTER__KMEANS_BUILD_MINANDMAXQ
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINANDMAXQ

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))

                        % possible solution found
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be good enough.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be good enough.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);

                        prev_total_reward_friq = total_reward_friq;

                        found_smallest_rb = 1;
                    else
                        % Too few (or "misleading") rules, add more
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be low, increasing it.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be low, increasing it.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        k_value = k_value + 1;
                    end

                end

                if found_smallest_rb == 1 || k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Solution found, or every rule has been tested. Stop.');
                    fprintf(logfile, 'Solution found, or every rule has been tested. Stop.\r\n');
                    stopappnow = 1;
                else
                    [idx, C] = kmeans(R_tmp, k_value, 'Distance', FRIQ_param_reduction_kmeans_distancemetric, 'EmptyAction', 'drop');

                    % something went wrong with kmeans() ? (can happen, also gives a warning, this way we can detect it)
                    if max(idx) ~= size(C,1)

                        % in that case, just skip this cluster (go to the next k-value, see above - using the same RB, it will "fail" againa, so k_value will be incremented)
                        disp('kmeans() did not produce a valid result. Skipping.');
                        fprintf(logfile, 'kmeans() did not produce a valid result. Skipping.\r\n');

                    else  % kmeans() was seemingly ok

                        R = [];

                        for clusterno = 1:k_value

                            if size(R_tmp(idx == clusterno, :), 1) < 3
                                R = [R; R_tmp(idx == clusterno, :)]; %#ok<AGROW>
                                continue
                            end

                            rulecluster = R_tmp(idx == clusterno, :);
                            [~, maxindex] = max(rulecluster(:, numofstates + 2));
                            [~, minindex] = min(rulecluster(:, numofstates + 2));
                            R = [R; rulecluster(maxindex, :)]; %#ok<AGROW>
                            R = [R; rulecluster(minindex, :)]; %#ok<AGROW>

                        end

                    end

                end

            end

            %% 20. kmeans v7: max absolute q value rule of every cluster - CLUSTER__KMEANS_BUILD_MAXABSQ
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MAXABSQ

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))

                        % possible solution found
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be good enough.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be good enough.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);

                        prev_total_reward_friq = total_reward_friq;

                        found_smallest_rb = 1;
                    else
                        % Too few (or "misleading") rules, add more
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be low, increasing it.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be low, increasing it.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        k_value = k_value + 1;
                    end

                end

                if found_smallest_rb == 1 || k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Solution found, or every rule has been tested. Stop.');
                    fprintf(logfile, 'Solution found, or every rule has been tested. Stop.\r\n');
                    stopappnow = 1;
                else

                    [idx, C] = kmeans(R_tmp, k_value, 'Distance', FRIQ_param_reduction_kmeans_distancemetric, 'EmptyAction', 'drop');

                    % something went wrong with kmeans() ? (can happen, also gives a warning, this way we can detect it)
                    if max(idx) ~= size(C,1)

                        % in that case, just skip this cluster (go to the next k-value, see above - using the same RB, it will "fail" againa, so k_value will be incremented)
                        disp('kmeans() did not produce a valid result. Skipping.');
                        fprintf(logfile, 'kmeans() did not produce a valid result. Skipping.\r\n');

                    else  % kmeans() was seemingly ok

                        R = [];

                        for clusterno = 1:k_value

                            if size(R_tmp(idx == clusterno, :), 1) < 2
                                R = [R; R_tmp(idx == clusterno, :)]; %#ok<AGROW>
                                continue
                            end

                            rulecluster = R_tmp(idx == clusterno, :);
                            [~, maxindex] = max(abs(rulecluster(:, numofstates + 2)));
                            R = [R; rulecluster(maxindex, :)]; %#ok<AGROW>

                        end

                    end

                end

            end

            %% 21. kmeans v8: min absolute q value rule of every cluster - CLUSTER__KMEANS_BUILD_MINABSQ
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINABSQ

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ( (FRIQ_param_reduction_allow_better_reward_above_tolerance && (prev_total_reward_friq <= total_reward_friq)) ...
                                 || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance) )
%                             && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))

                        % possible solution found
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be good enough.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be good enough.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);

                        prev_total_reward_friq = total_reward_friq;

                        found_smallest_rb = 1;
                    else
                        % Too few (or "misleading") rules, add more
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be low, increasing it.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' seems to be low, increasing it.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        k_value = k_value + 1;
                    end

                end

                if found_smallest_rb == 1 || k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Solution found, or every rule has been tested. Stop.');
                    fprintf(logfile, 'Solution found, or every rule has been tested. Stop.\r\n');
                    stopappnow = 1;
                else

                    [idx, C] = kmeans(R_tmp, k_value, 'Distance', FRIQ_param_reduction_kmeans_distancemetric, 'EmptyAction', 'drop');

                    % something went wrong with kmeans() ? (can happen, also gives a warning, this way we can detect it)
                    if max(idx) ~= size(C,1)

                        % in that case, just skip this cluster (go to the next k-value, see above - using the same RB, it will "fail" againa, so k_value will be incremented)
                        disp('kmeans() did not produce a valid result. Skipping.');
                        fprintf(logfile, 'kmeans() did not produce a valid result. Skipping.\r\n');

                    else  % kmeans() was seemingly ok

                        R = [];

                        for clusterno = 1:k_value

                            if size(R_tmp(idx == clusterno, :), 1) < 2
                                R = [R; R_tmp(idx == clusterno, :)]; %#ok<AGROW>
                                continue
                            end

                            rulecluster = R_tmp(idx == clusterno, :);
                            [~, minindex] = min(abs(rulecluster(:, numofstates + 2)));
                            R = [R; rulecluster(minindex, :)]; %#ok<AGROW>

                        end

                    end

                end

            end

            %% 22. Hierarchical clustering: min and max Q-value rules of every (sub)cluster
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__HIERARCHICAL 

                global finalReducedR
                finalReducedR = [];
                FRIQ_reduction_strategy_cluster_hierarchical(R_tmp);
                found_smallest_rb = 1;
                stopappnow = 1;
                R = finalReducedR;
            end
            
            %% end of loop
            if stopappnow == 1

                cputime_reduction_end = cputime;

                dlmwrite([ reduction_strategy_rb_filename_base '_' filetimestamp '.csv' ], R);
                copyfile([ reduction_strategy_rb_filename_base '_' filetimestamp '.csv' ], [ reduction_strategy_rb_filename_base '.csv' ]);

                FRIQ_param_test_previous_rb = 1;
                reduction_state = 0;
                stopappnow = 0;
                [total_reward_friq, steps_friq] = FRIQ_episode(FRIQ_param_maxsteps, FRIQ_param_alpha, FRIQ_param_gamma, FRIQ_param_epsilon);

                dlmwrite([ reduction_strategy_rb_filename_base '_steps_' filetimestamp '.txt' ], steps_friq);
                copyfile([ reduction_strategy_rb_filename_base '_steps_' filetimestamp '.txt' ], [ reduction_strategy_rb_filename_base '_steps.txt' ]);
                dlmwrite([ reduction_strategy_rb_filename_base '_reward_' filetimestamp '.txt' ], total_reward_friq);
                copyfile([ reduction_strategy_rb_filename_base '_reward_' filetimestamp '.txt' ], [ reduction_strategy_rb_filename_base '_reward.txt' ]);
                dlmwrite([ reduction_strategy_rb_filename_base '_cputime_' filetimestamp '.txt' ], cputime_reduction_end - cputime_reduction_start);
                copyfile([ reduction_strategy_rb_filename_base '_cputime_' filetimestamp '.txt' ], [ reduction_strategy_rb_filename_base '_cputime.txt' ]);
                dlmwrite([ reduction_strategy_rb_filename_base '_reductioneps_' filetimestamp '.txt' ], epno);
                copyfile([ reduction_strategy_rb_filename_base '_reductioneps_' filetimestamp '.txt' ], [ reduction_strategy_rb_filename_base '_reductioneps.txt' ]);

                break
            end

        end

    %% remove membership functions where every rules' antecedent is nan (whole column)
    if FRIQ_param_remove_unnecessary_membership_functions == 1
        FRIQ_reduction_remove_unnecessary_MFs([ reduction_strategy_rb_filename_base '_' filetimestamp '.csv' ]);
    end
