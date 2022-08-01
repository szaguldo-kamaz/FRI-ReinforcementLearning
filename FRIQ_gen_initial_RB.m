function [rulebase] = FRIQ_gen_initial_RB(num_of_antecedents)
%FRIQ_gen_initial_RB: create the initial "empty" sparse fuzzy rule-base
%
% FRIQ-learning framework v0.70
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2022 by David Vincze
%

    rulebase = zeros(2^num_of_antecedents, num_of_antecedents + 1);

    for ruleno = 0:(2^num_of_antecedents) - 1
        s = dec2bin(ruleno, num_of_antecedents);

        for si = 1:num_of_antecedents
            rulebase(ruleno + 1, si) = str2double(s(si));
        end

    end
