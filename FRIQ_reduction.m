function FRIQ_reduction()
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
    global FRIQ_param_qdiff_pos_boundary FRIQ_param_qdiff_neg_boundary FRIQ_param_qdiff_final_tolerance FRIQ_param_reward_good_above FRIQ_param_reduction_reward_tolerance FRIQ_param_reduction_rule_distance
    global FRIQ_param_norandom FRIQ_param_drawsim FRIQ_param_maxsteps FRIQ_param_alpha FRIQ_param_gamma FRIQ_param_epsilon FRIQ_param_maxepisodes
    global FRIQ_param_doactionfunc FRIQ_param_rewardfunc FRIQ_param_drawfunc
    global FRIQ_param_reduction_strategy FRIQ_param_reduction_strategy_secondary FRIQ_param_remove_unnecessary_membership_functions

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
    global FRIQ_const_reduction_strategy__CLUSTER__HIERARCHICAL
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_ONE
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_MANY
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_ONE
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_MANY
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_CENTROID
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINANDMAXQ
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MAXABSQ
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINABSQ
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

        if isempty(FRIQ_param_reduction_strategy_secondary)
            reduction_strategy_rb_filename = [ 'rulebases/FRIQ_' FRIQ_param_appname '_reduced_RB_with_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} '_' filetimestamp '.txt' ];
        else
            reduction_strategy_rb_filename = [ 'rulebases/FRIQ_' FRIQ_param_appname '_reduced_RB_with_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy} '_and_' FRIQ_const_reduction_strategy__names{FRIQ_param_reduction_strategy_secondary} '_' filetimestamp '.txt' ];
        end

        % initialization for HALF_GROUP_REMOVAL
        div_limitq = 2;
        really_eliminate_rules = 0;

        % load the previously incrementally constructed rule-base
        if ~exist(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB.txt'], 'file') || ...
           ~exist(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB_steps.txt'], 'file')

            disp('Incrementally constructed rule-base files not found, please run the construction process first (set FRIQ_param_construct_rb = 1).');
            return;
        end
        R = dlmread(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB.txt']);
        steps_friq_incremental = dlmread(['rulebases/FRIQ_' FRIQ_param_appname '_incrementally_constructed_RB_steps.txt']);
        numofrules = size(R, 1);

        %% 7. two-step reduction strategies switch - maxq
        if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MAXQ
            % sort by Q value descending
            [~, idx] = sortrows(abs(R), -(numofstates + 2));
            R = R(idx, :);

            % switch to ELIMINATE_DUPLICATED (6) as the remaining steps are the same
            FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST;

        %% 8. two-step reduction strategies switch - minq
        elseif FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MINQ
            % sort by Q value ascending
            [~, idx] = sortrows(abs(R), (numofstates + 2));
            R = R(idx, :);

            % switch to ELIMINATE_DUPLICATED (6) as the remaining steps are the same
            FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST;

        end

        %% 10. two-step reduction strategies switch - maxq
        if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MAXQ
            % sort by Q value descending
            [~, idx] = sortrows(abs(R), -(numofstates + 2));
            R = R(idx, :);

            % switch to strategy ELIMINATE_SIMILAR__FIRST (5) as the remaining steps are the same
            FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST;

        %% 11. two-step reduction strategies switch - minq
        elseif FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MINQ
            % sort by Q value ascending
            [~, idx] = sortrows(abs(R), (numofstates + 2));
            R = R(idx, :);

            % switch to strategy ELIMINATE_SIMILAR__FIRST (5) as the remaining steps are the same
            FRIQ_param_reduction_strategy = FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST;
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

        if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__MIN_Q || FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__MAX_Q
            iterations = (numofrules + 1);
        else
            iterations = 10000;
        end

        %% Reduction mainloop
        for epno = 1:iterations

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
                    disp('Smallest rule-base found. Exiting.');
                    fprintf(logfile, 'Smallest rule-base found. Exiting.\r\n');
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
                    disp('Smallest rule-base found. Exiting.');
                    fprintf(logfile, 'Smallest rule-base found. Exiting.\r\n');
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
                        disp('Smallest rule-base found. Exiting.');
                        fprintf(logfile, 'Smallest rule-base found. Exiting.\r\n');
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                    disp('Found smallest rule-base. Exiting.');
                    fprintf(logfile, 'Found smallest rule-base. Exiting.\r\n');
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                    disp('Every rule have been tested. Exiting.');
                    fprintf(logfile, 'Every rule have been tested. Exiting.\r\n');
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                    disp('Every rule has been tested. Exiting.');
                    fprintf(logfile, 'Every rule has been tested. Exiting.\r\n');
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                    disp('Every rule has been tested. Exiting.');
                    fprintf(logfile, 'Every rule has been tested. Exiting.\r\n');
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                    disp('Every rule has been tested. Exiting.');
                    fprintf(logfile, 'Every rule has been tested. Exiting.\r\n');
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
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        tested_cluster = 0;
                        k_value = 2;
                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                    end

                    % test the next rule
                    tested_cluster = tested_cluster + 1;

                    if tested_cluster > k_value
                        tested_cluster = 1;
                        k_value = k_value + 1;
                    end

                end

                if k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Exiting.');
                    fprintf(logfile, 'Every rule has been tested. Exiting.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    if tested_cluster == 1
                        idx = kmeans(R_tmp, k_value, 'Distance', 'sqeuclidean', 'EmptyAction', 'drop');
                    end

                    % remove a cluster from the rule-base
                    R_tmp(idx == tested_cluster, :) = [];
                    prev_idx=idx;
                    idx(idx == tested_cluster) = [];

                    R = R_tmp;
                end

            end

            %% 14. kmeans v2 - CLUSTER__KMEANS_REMOVE_MANY
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_MANY

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                    end

                    % test the next rule
                    tested_cluster = tested_cluster + 1;

                    if tested_cluster > k_value
                        tested_cluster = 1;

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
                    disp('Every rule has been tested. Exiting.');
                    fprintf(logfile, 'Every rule has been tested. Exiting.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    if tested_cluster == 1
                        % returns the indexes of clusters where each of the rules belong one-by-one
                        idx = kmeans(R_tmp, k_value, 'Distance', 'sqeuclidean', 'EmptyAction', 'drop');
                    end

                    % remove a cluster from the rule-base
                    R_tmp(idx == tested_cluster, :) = [];
                    prev_idx=idx;
                    idx(idx == tested_cluster) = [];

                    R = R_tmp;
                end

            end

            %% 16. kmeans v3 - CLUSTER__KMEANS_REPLACE_ONE
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_ONE

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
                        % omission of the rule group could be a good idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' could be a good idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        prev_total_reward_friq = total_reward_friq;

                        tested_cluster = 0;
                        k_value = 2;
                    else
                        % omission of the rule group was a bad idea
                        disp(            ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq)]);
                        fprintf(logfile, ['FRIQ_reduction_episode: ', int2str(epno), ' K-value: ', int2str(k_value), ' Tested cluster: ', int2str(tested_cluster), ' Omission of rules: ', int2str(find(ismember(R_tmp_prev, R_tmp_prev(prev_idx == tested_cluster, :), 'rows')).'), ' was a bad idea.', ' Reward diff was: ', num2str(diff_reward_friq), '\r\n']);
                        R_tmp = R_tmp_prev;
                    end

                    % test the next rule
                    tested_cluster = tested_cluster + 1;

                    if tested_cluster > k_value
                        tested_cluster = 1;
                        k_value = k_value + 1;
                    end

                end

                if k_value > size(R_tmp, 1)
                    % every rule has been tested
                    disp('Every rule has been tested. Exiting.');
                    fprintf(logfile, 'Every rule has been tested. Exiting.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    if tested_cluster == 1
                        [idx, C] = kmeans(R_tmp, k_value, 'Distance', 'sqeuclidean', 'EmptyAction', 'drop');
                    end

                    if size(R_tmp(idx == tested_cluster), 1) > 1
                        % add centroid element as a rule
                        R_tmp(size(R_tmp, 1) + 1, :) = C(tested_cluster, :);
                    end

                    % remove a cluster from the rule-base
                    R_tmp(idx == tested_cluster, :) = [];
                    prev_idx=idx;
                    idx(idx == tested_cluster) = [];

                    R = R_tmp;
                end

            end

            %% 17. kmeans v4 - CLUSTER__KMEANS_REPLACE_MANY
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_MANY

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                    end

                    % test the next rule
                    tested_cluster = tested_cluster + 1;

                    if tested_cluster > k_value
                        tested_cluster = 1;

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
                    disp('Every rule has been tested. Exiting.');
                    fprintf(logfile, 'Every rule has been tested. Exiting.\r\n');
                    R = R_tmp;
                    stopappnow = 1;
                else
                    % there are rules that haven't been tested yet
                    R_tmp_prev = R_tmp;

                    if tested_cluster == 1
                        [idx, C] = kmeans(R_tmp, k_value, 'Distance', 'sqeuclidean', 'EmptyAction', 'drop');
                    end

                    if size(R_tmp(idx == tested_cluster), 1) > 1
                        % add centroid element as a rule
                        R_tmp(size(R_tmp, 1) + 1, :) = C(tested_cluster, :);
                    end

                    % remove a cluster from the rule-base
                    R_tmp(idx == tested_cluster, :) = [];
                    prev_idx=idx;
                    idx(idx == tested_cluster) = [];

                    R = R_tmp;
                end

            end

            %% 18. kmeans v5, DO NOT USE THIS STRATEGY WITH COSINE DISTANCE METRICS! - CLUSTER__KMEANS_BUILD_CENTROID
            if FRIQ_param_reduction_strategy == FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_CENTROID

                if epno == 1
                    prev_total_reward_friq = total_reward_friq;
                else
                    diff_reward_friq = prev_total_reward_friq - total_reward_friq;

                    if (total_reward_friq > FRIQ_param_reward_good_above) ...
                            && (steps_friq <= steps_friq_incremental) ...
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))
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
                    disp('Solution found, or every rule has been tested. Exiting.');
                    fprintf(logfile, 'Solution found, or every rule has been tested. Exiting.\r\n');
                    stopappnow = 1;
                else
                    R = [];

                    [~, C] = kmeans(R_tmp, k_value, 'Distance', 'sqeuclidean', 'EmptyAction', 'drop');

                    for centroid_index = 1:size(C, 1)
                        R = [R; C(centroid_index, :)]; %#ok<AGROW>
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))

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
                    disp('Solution found, or every rule has been tested. Exiting.');
                    fprintf(logfile, 'Solution found, or every rule has been tested. Exiting.\r\n');
                    stopappnow = 1;
                else
                    R = [];

                    idx = kmeans(R_tmp, k_value, 'Distance', 'sqeuclidean', 'EmptyAction', 'drop');

                    for cluster = 1:k_value

                        if size(R_tmp(idx == cluster, :), 1) < 3
                            R = [R; R_tmp(idx == cluster, :)]; %#ok<AGROW>
                            continue
                        end

                        C = R_tmp(idx == cluster, :);
                        [~, maxindex] = max(C(:, numofstates + 2));
                        [~, minindex] = min(C(:, numofstates + 2));
                        R = [R; C(maxindex, :)]; %#ok<AGROW>
                        R = [R; C(minindex, :)]; %#ok<AGROW>
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))

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
                    disp('Solution found, or every rule has been tested. Exiting.');
                    fprintf(logfile, 'Solution found, or every rule has been tested. Exiting.\r\n');
                    stopappnow = 1;
                else
                    R = [];

                    idx = kmeans(R_tmp, k_value, 'Distance', 'sqeuclidean', 'EmptyAction', 'drop');

                    for cluster = 1:k_value

                        if size(R_tmp(idx == cluster, :), 1) < 2
                            R = [R; R_tmp(idx == cluster, :)]; %#ok<AGROW>
                            continue
                        end

                        C = R_tmp(idx == cluster, :);
                        [~, maxindex] = max(abs(C(:, numofstates + 2)));
                        R = [R; C(maxindex, :)]; %#ok<AGROW>
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
                            && ((prev_total_reward_friq <= total_reward_friq) || (abs(diff_reward_friq) <= FRIQ_param_reduction_reward_tolerance))

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
                    disp('Solution found, or every rule has been tested. Exiting.');
                    fprintf(logfile, 'Solution found, or every rule has been tested. Exiting.\r\n');
                    stopappnow = 1;
                else
                    R = [];

                    idx = kmeans(R_tmp, k_value, 'Distance', 'cosine', 'EmptyAction', 'drop');

                    for cluster = 1:k_value

                        if size(R_tmp(idx == cluster, :), 1) < 2
                            R = [R; R_tmp(idx == cluster, :)]; %#ok<AGROW>
                            continue
                        end

                        C = R_tmp(idx == cluster, :);
                        [~, minindex] = min(abs(C(:, numofstates + 2)));
                        R = [R; C(minindex, :)]; %#ok<AGROW>
                    end

                end

            end
            
            %% end of loop
            if stopappnow == 1
                dlmwrite(reduction_strategy_rb_filename, R);
                stopappnow = 0;
                break
            end

        end

    %% remove membership functions where every rules' antecedent is nan (whole column)
    
    if FRIQ_param_remove_unnecessary_membership_functions == 1
        FRIQ_reduction_remove_unnecessary_MFs(reduction_strategy_rb_filename);
    end
