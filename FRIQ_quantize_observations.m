function [ state_quantized ] = FRIQ_quantize_observations(state, states, statedivs)
% FRIQ_quantize_observations: perform quantization of the inputs, use only the allowed state values
%
% FRIQ-learning framework v0.70
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2022 by David Vincze
%

    global numofstates

    state_quantized = zeros(1, numofstates);

    for stateno = 1:numofstates
        nosubstates = size(states{stateno}, 2);
        where = round((state(stateno) + abs(states{stateno}(1))) ./ statedivs{stateno}) + 1;
        if where < 1
            where = 1;
        elseif where > nosubstates
            where = nosubstates;
        end

        state_quantized(stateno) = states{stateno}(where);
    end
