function FRIQ_update_RB(state, action, reward, state_p, action_p, alpha, gamma)
% FRIQ_update_RB: FRIQ-learning framework: Update the fuzzy rule-base
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2021 by David Vincze
%

    global FRIQ_param_qdiff_pos_boundary FRIQ_param_qdiff_neg_boundary
    global U VE R numofrules
    global possiblestates possiblestates_epsilons
    global possibleaction possibleaction_epsilon
    global debug_on


    FRIQ_check_universes('q_now', state, action);   % just to be on the safe side
    Q_now = FIVEVagConcl_fixres(U, VE, R, [state,   action]);   % Q(s,a)
    FRIQ_check_universes('q_p', state_p, action_p); % just to be on the safe side
    Q_p   = FIVEVagConcl_fixres(U, VE, R, [state_p, action_p]); % Q(sp,ap)
    Qdiff = alpha * (reward + gamma * Q_p - Q_now);

    if debug_on == 1
        disp(['state: '   num2str(state,   '%.18f') ' action: '   num2str(action,   '%.18f')]);
        disp(['state_p: ' num2str(state_p, '%.18f') ' action_p: ' num2str(action_p, '%.18f')]);
        disp(['Q_now: ' num2str(Q_now, '%.18f') ' Q_p: ' num2str(Q_p, '%.18f') ' Qdiff: ' num2str(Qdiff, '%.18f')]);
    end

    numofstates = length(state);
    numofantecedents = numofstates + 1;
    RBcolumns = numofantecedents + 1;

    % insert new rule - if it does not exist
    if (Qdiff > FRIQ_param_qdiff_pos_boundary) || (Qdiff < FRIQ_param_qdiff_neg_boundary)

        newpossiblestates = {};
        newrulestates = zeros(1, numofstates);

        for current_possible_state = 1:numofstates
            [newpossiblestates{current_possible_state}, newrulestates(current_possible_state)] = FRIQ_check_possible_states(state(current_possible_state), possiblestates{current_possible_state}, possiblestates_epsilons{current_possible_state});
            if newrulestates(current_possible_state) == inf
                current_possible_state
                CHKPOSSSTATEBUG
            end
        end

        [newpossibleaction, newruleaction] = FRIQ_check_possible_states(action, possibleaction, possibleaction_epsilon);

        if newruleaction == inf
            POSSACTBUG
        end

        possibleaction = newpossibleaction;
        possiblestates = newpossiblestates;

        Q_newrule = FIVEVagConcl_fixres(U, VE, R, [ newrulestates newruleaction ]); % Q(s,a)
        newrule = [ newrulestates newruleaction Q_newrule+Qdiff ];

        % check whether the proposed new rule already exists or not
        rulefound = 0;
        search_for_this_rule = newrule(1:numofantecedents);
        search_in_this_R = R(:, 1:numofantecedents);
        numofrules = size(search_in_this_R, 1);

        for rno = 1:numofrules
            if search_for_this_rule == search_in_this_R(rno, :)
                rulefound = 1;
                break
            end
        end

        if debug_on == 1
            disp(['rulefound: ' int2str(rulefound)]);
        end

        if rulefound == 0 % append new rule to the end of the existing rulebase
            R(size(R, 1) + 1, 1:RBcolumns) = newrule;
%             numofrules=numofrules+1; % TODO: make this an option, use the newly added rule on not in the next iteration
            if debug_on >= 1
                format long
                newrule
                format
            end

        else % or update existing rules
            %- FIVEVagConclWeight_fixres - nincs sulyozva a konkluzioval!
            rulestoupdate = FIVEVagConclWeight_fixres(U, VE, R, [state, action]);

            for rule = 1:numofrules
                if rulestoupdate(rule) > 0.05
                    if debug_on == 1
                        disp(['updaterule ' int2str(rule) '. weight: ' num2str(rulestoupdate(rule)) ': oldQ: ' num2str(R(rule, RBcolumns), 18) ' -> newq: ' num2str(Q_now + Qdiff * rulestoupdate(rule), 18)]);
                    end
                    R(rule, RBcolumns) = Q_now + Qdiff * rulestoupdate(rule);
                end
            end

        end

    else % if deltaq is not so big then just update existing rules
%         [Q_now Q_p Qdiff ]
        rulestoupdate = FIVEVagConclWeight_fixres(U, VE, R, [state, action]);

        for rule = 1:numofrules
            if debug_on == 1
                disp([ 'rule ' num2str(rule) ' weight ' num2str(rulestoupdate(rule),18) ]);
            end
            if rulestoupdate(rule) > 0.05
                if debug_on == 1
                    [rule R(rule, RBcolumns) Q_now + Qdiff * rulestoupdate(rule)]
                    disp(['updating rule ' num2str(rule) ' from ' num2str(R(rule, RBcolumns), 18) ' to ' num2str(Q_now + Qdiff * rulestoupdate(rule), 18)]);
                end
                R(rule, RBcolumns) = Q_now + Qdiff * rulestoupdate(rule);
            end
        end

    end
