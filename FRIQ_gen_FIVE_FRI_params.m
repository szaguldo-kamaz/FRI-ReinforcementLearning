function [UD, VED, R] = FRIQ_gen_FIVE_FRI_params(UD, states, states_steepness, actions)
% FRIQ_gen_five_fri_params: Generate parameters for FRIQ-learning framework
%
% FRIQ-learning framework v0.70
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2022 by David Vincze
%

    Ulen = size(UD, 2);
    num_of_states = length(states);
    num_of_antecedents = num_of_states + 1;
    num_of_actions = length(actions);
    VED = zeros(num_of_states + 1, Ulen);

    for currstate = 1:num_of_states
        statedims = length(states{currstate});
        steepness = states_steepness(currstate);
        currSP = zeros(statedims, 2);

        for curstatedim = 1:statedims
            currSP(curstatedim, :) = [states{currstate}(curstatedim) steepness];
        end

        VED(currstate, :) = FIVEGVagEnv(UD(currstate, :), FIVEGScFunc(UD(currstate, :), currSP));
    end

%     dlmwrite('ved.txt',VED,'precision',64,'delimiter','\n');
%     dlmwrite('ud.txt',UD,'precision','%.32f','delimiter','\n');
%     dlmwrite('ved.txt',VED,'precision','%.32f','delimiter','\n');

    % generate actions partition
    act = zeros(1,num_of_actions);
    SPact = [0, 0];
    divratio = 1 / (num_of_actions - 1) * 2;

    for i = 1:num_of_actions
        act(i) = (i - 1) * divratio - 1;
        SPact(i, 1) = act(i);
        SPact(i, 2) = (num_of_actions - 1) / 2;
    end

    VED(num_of_antecedents, :) = FIVEGVagEnv(UD(num_of_antecedents, :), FIVEGScFunc(UD(num_of_antecedents, :), SPact));

    %FIVEDrawPart(U,SP,1);

    R = FRIQ_gen_initial_RB(num_of_antecedents);
    maxvals = zeros(1, num_of_antecedents);
    minvals = zeros(1, num_of_antecedents);

    for i = 1:num_of_states
        maxvals(i) = max(states{i});
        minvals(i) = min(states{i});
    end

    maxvals(num_of_antecedents) = max(actions);
    minvals(num_of_antecedents) = min(actions);

    % Prepare initial rule-base
    for j = 1:num_of_antecedents
        for i = 1:(2^num_of_antecedents)
            if R(i, j) == 1
                R(i, j) = maxvals(j);
            else
                R(i, j) = minvals(j);
            end
        end
    end
