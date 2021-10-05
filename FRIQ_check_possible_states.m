function [possiblestate, newrule] = FRIQ_check_possible_states(obs, possiblestate, possiblestate_epsilon)
%FRIQ_check_possible_states
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2021 by David Vincze
%

    num_of_possiblestates = size(possiblestate, 2);
    newrule = inf; %#ok<NASGU>

    % check possible rule places for state
    tmpover = 1;

    for possiblestate_no = 1:num_of_possiblestates % search among possible rule places
        if obs < possiblestate(possiblestate_no)
            tmpover = 0;
            break % found
        end
    end

    possiblestate_no = possiblestate_no - 1;
    % hit before first rule ?
    if ~tmpover & (obs < possiblestate(1))
        newrule = possiblestate(1);
        return
    end

    if tmpover % did not hit, and went over the last possible rule place
        newrule = possiblestate(num_of_possiblestates);
    else % hit between possible rule places
        pstatediff = abs(possiblestate(possiblestate_no + 1) - possiblestate(possiblestate_no)); % distance betwen the two adjacent points
        pstatecenterstart = pstatediff ./ 4 + possiblestate(possiblestate_no); % where to start looking for new rule center ( found state + 1/4 of distance = 1/4 from center (left))
        pstatecenterstop = pstatediff ./ 4 .* 3 + possiblestate(possiblestate_no); % where to stop looking for new rule center ( found state + 3/4 of distance = 1/4 from center (right))

        if (possiblestate_epsilon <= (pstatediff / 2)) && (pstatecenterstart <= obs) && (obs <= pstatecenterstop) % new possible rule place should be added
            possiblestate = [possiblestate(1:possiblestate_no), possiblestate(possiblestate_no) + pstatediff ./ 2, possiblestate((possiblestate_no + 1):end)];
            newrule = possiblestate(possiblestate_no + 1);
        else % close to a possible rule place, select the closer one
            relativeobs = obs - possiblestate(possiblestate_no);
            relativeobs_next = possiblestate(possiblestate_no + 1) - obs;

            if relativeobs < relativeobs_next % previous one is closer
                newrule = possiblestate(possiblestate_no);
            else % next one is closer
                newrule = possiblestate(possiblestate_no + 1);
            end

        end

    end
