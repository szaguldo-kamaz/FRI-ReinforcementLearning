function FRIQ_reduction_remove_unnecessary_MFs(rulebasefilename)
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
    global FRIQ_param_states FRIQ_param_statedivs FRIQ_param_states_steepness FRIQ_param_states_default
    global FRIQ_param_remove_unnecessary_membership_functions

    %% Init
    global filetimestamp
    global debug_on

    %% remove membership functions where every rules' antecedent is nan (whole column)
    if FRIQ_param_remove_unnecessary_membership_functions == 1

        if ~exist(rulebasefilename, 'file')
            disp('Rule-base file to be checked for unnecessary MFs not found, please run the construction/reduction process first.');
            return;
        end

        Rumf = dlmread(rulebasefilename);
        numofstates=size(Rumf,2)-2;
        for state = 1:numofstates

            if isnan(Rumf(:, state))
                Rumf(:, state) = [];
                FRIQ_param_states(state) = [];
                FRIQ_param_statedivs(state) = [];
                FRIQ_param_states_steepness(state) = [];
                FRIQ_param_states_default(state) = [];
                disp(['Membership function (' int2str(state) ') removed.']);
            end

        end

        rulebasefilename_base=rulebasefilename(1:length(rulebasefilename)-4);
        dlmwrite([rulebasefilename_base '_mf_removed_RB.csv'], Rumf);
        dlmwrite([rulebasefilename_base '_mf_removed_param_states.txt'], FRIQ_param_states);
        dlmwrite([rulebasefilename_base '_mf_removed_param_statedivs.txt'], FRIQ_param_statedivs);
        dlmwrite([rulebasefilename_base '_mf_removed_param_states_steepness.txt'], FRIQ_param_states_steepness);
        dlmwrite([rulebasefilename_base '_mf_removed_param_states_default.txt'], FRIQ_param_states_default);
    end
