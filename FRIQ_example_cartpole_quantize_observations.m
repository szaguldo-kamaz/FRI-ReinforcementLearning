function [ state_quantized ] = FRIQ_example_cartpole_quantize_observations(state, ~, ~)
% FRIQ_example_cartpole_quantize_observations: Cart-Pole specific state quantization
%
% FRIQ-learning framework v0.70
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2022 by David Vincze
%

    state(1) = sign(state(1));
    state(2) = round(state(2));
    state(3) = floor(state(3) / deg2rad(3)) * deg2rad(3);
    state(4) = sign(state(4));

    if state(1) <- 1
        state(1) = -1;
    end

    if state(1) > 1
        state(1) = 1;
    end

    if state(2) <- 1
        state(2) = -1;
    end

    if state(2) > 1
        state(2) = 1;
    end

    if state(3) > deg2rad(12)
        state(3) = deg2rad(12);
    end

    if state(3) < -deg2rad(12)
        state(3) = -deg2rad(12);
    end

    if state(4) < -1
        state(4) = -1;
    end

    if state(4) > 1
        state(4) = 1;
    end

    state_quantized = state;
