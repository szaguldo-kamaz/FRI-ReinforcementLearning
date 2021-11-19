function [ action ] = FRIQ_get_best_action(state, actionset)
%FRIQ_get_best_action: return the proposed best action for the current state
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2021 by David Vincze
%

    global U VE R numofactions

    actionconclusions = zeros(1,numofactions);

    % calculate distances from rules for the 'state' antecedents excluding 'action'
    [numofrules, rulewidth] = size(R);
    Ustates  = U(1:rulewidth - 2, :);
    VEstates = VE(1:rulewidth - 2, :);
    [nU, mU] = size(Ustates);
    vagdist_states = zeros(numofrules, rulewidth - 2);
    dmlen=rulewidth-1;
    dm=zeros(1, dmlen);

    % This is from FIVERuleDist!
    % current state distance from each rule
    Ronlystates=R(:, 1:rulewidth - 2);
    for i = 1:numofrules
        vagdist_states(i, :) = FIVEVagDist_fixres(Ustates, nU, mU, VEstates, Ronlystates(i, :), state);
    end

    % now calculate distance for possible actions:
    % for 'action' values no alignment needed, because they must hit exactly in the action dimension

    VEk = VE(rulewidth - 1, :); % VE of action dimension
    Uk = U(rulewidth - 1, :); % U of action dimension
    [~, Uk_n] = size(Uk);
    Uk_size = Uk_n - 1;
    Uk_domain = Uk(Uk_n) - Uk(1);

    % This is from FIVEVagDist_FixRes !
    for actno = 1:numofactions
        FRIQ_check_universes('actionconclusions', state, actionset(actno));

        P2 = actionset(actno); % action point value

        % This is from FIVEVagDist
        if isnan(P2)% not a valid scaled distance (D=0)
            Da = 0; % indifferent (not existing) rule antecedent
        else % valid scaled distance

            if (P2 < Uk(1)) || (P2 > Uk(Uk_n))
                error('The points are out of range!');
            end

            tempP2 = (P2 - Uk(1)) / Uk_domain;

            if P2 ~= Uk(Uk_n)
                where = floor(tempP2 * Uk_size) + 1;
                if where > 0
                    if abs(Uk(where) - P2) <= abs(Uk(where + 1) - P2)
                        j = where;
                    else
                        j = where + 1;
                    end
                else
                    j = 1;
                end
            else
                j = Uk_size + 1;
            end

        end

        RD = zeros(1,numofrules);

        for curruleno = 1:numofrules % Check all rules
            P1 = R(curruleno, rulewidth - 1); % action dimension from rulebase

            % This is from FIVEVagDist
            if isnan(P1)% not a valid scaled distance (D=0)
                Da = 0; % indifferent (not existing) rule antecedent
            else % valid scaled distance

                if (P1 < Uk(1)) || (P1 > Uk(Uk_n))
                    error('The points are out of range!');
                end

                tempP1 = (P1 - Uk(1)) / Uk_domain;

                if P1 ~= Uk(Uk_n)
                    where = floor(tempP1 * Uk_size) + 1;
                    if where > 0
                        if abs(Uk(where) - P1) <= abs(Uk(where + 1) - P1)
                            i = where;
                        else
                            i = where + 1;
                        end
                    else
                        i = 1;
                    end
                else
                    i = Uk_size + 1;
                end

                Da = abs(VEk(j) - VEk(i)); % the scaled distance of P1 and P2 (P2>P1)
            end

%            dm = [vagdist_states(curruleno, :) Da];
% This is much faster:
            for dmindex = 1:rulewidth-2
                dm(dmindex)=vagdist_states(curruleno,dmindex);
            end
            dm(dmlen)=Da;

            %- This is from FIVERuleDist!
            if min(dm) < 0 % there are inf elements (denoted by <0 value)
                dm = dm(dm < 0); % vector of elements <0 from dm
%                 RD(curruleno)=-sqrt(sum(dm.^2));    % RD<0 denotes that RD=inf, norm is faster
                RD(curruleno) = -norm(dm, 2);    % RD<0 denotes that RD=inf
            else % there are no inf elements
                % Euclidean distance of the observation from the rule antecedents
                RD(curruleno) = norm(dm, 2);
%                 RD(curruleno)=sqrt(sum(dm.^2));  % norm is faster
            end

        end

        actionconclusions(actno) = FIVEVagConcl_FRIQ_bestact(U, VE, R, RD);
    end

    [~, action] = max(actionconclusions);

    % TODO: think:
    %- calculate distance once instead of 'numofactions'
    %- for 'action' values no alignment needed, because they must exactly hit in the action dimension
    %-  what if it is missing? - no problem because it is aligned to the universe not to existing rules
    %- ?
