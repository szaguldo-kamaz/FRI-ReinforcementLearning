function FRIQ_check_universes(ident, state, action)
% FRIQ_check_universes: check boundaries (just for detecting errors)
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2021 by David Vincze
%

    global FRIQ_param_FIVE_UD numofstates Usize

    outside = 0;

    for i = 1:numofstates
        if (state(i) < FRIQ_param_FIVE_UD(i, 1)) || (state(i) > FRIQ_param_FIVE_UD(i, Usize))
            disp(['outside of the universe - s' num2str(i) ' : ' ident ' ' num2str(state(i))]);
            outside = 1;
        end
    end

    if (action < FRIQ_param_FIVE_UD((numofstates + 1), 1)) || (action > FRIQ_param_FIVE_UD((numofstates + 1), Usize))
        disp(['outside of the universe - a : ' ident ' ' num2str(action)]);
        outside = 1;
    end

    % help the user to notice the error...
    if outside == 1
        pause(10);
    end
