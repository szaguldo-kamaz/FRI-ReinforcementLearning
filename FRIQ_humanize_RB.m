function FRIQ_humanize_RB(RBbasefilename)
% FRIQ_humanize_RB: convert RB into a human readable form
%
% FRIQ-learning framework v0.70
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2022 by David Vincze
%

global FRIQ_param_states FRIQ_param_actions
global FRIQ_param_antecedent_terms FRIQ_param_antecedent_names

float_diff_tolerance = 0.0001;

    % load rule-base
    if exist([ RBbasefilename '_with_usage.csv'], 'file')
        RBfilename=[ RBbasefilename '_with_usage.csv'];
        with_usage=1;
    else
        if exist([ RBbasefilename '.csv'], 'file')
            RBfilename=[ RBbasefilename '.csv'];
            with_usage=0;
        else
            disp(['humanize_rb: rule-base file not found: ' RBbasefilename '.csv ! Please run the construction process first (set FRIQ_param_construct_rb = 1).']);
            return;
        end
    end
    RB = dlmread(RBfilename);
    numofrules = size(RB, 1);
    rulesize = size(RB(1,:),2);
    RBhuman=cell(numofrules,rulesize+1);
    numofantecs=rulesize-1;
    if with_usage == 1
        numofantecs=numofantecs-2;
    end
    antecedents=FRIQ_param_states;
    antecedents{numofantecs}=FRIQ_param_actions;

    maxQ=max(RB(:,numofantecs+1));
    minQ=min(RB(:,numofantecs+1));
    Qrange=max(abs(maxQ),abs(minQ));
    if with_usage == 1
        maxusage=max(RB(:,numofantecs+2));
        maxnormusage=max(RB(:,numofantecs+3));
    end

    for currantec=1:numofantecs
        RBhuman{1,currantec}=FRIQ_param_antecedent_names{currantec};
    end
    RBhuman{1,currantec+1}='Q';
    if with_usage == 1
        RBhuman{1,currantec+2}='Usage/max';
        RBhuman{1,currantec+3}='Usage/all';
        RBhuman{1,currantec+4}='Usage/all %';
    end

    Qtermspos={'neutral', 'slightly good', 'good', 'very good'};
    Qtermsneg={'neutral', 'slightly bad',  'bad',  'very bad'};
    Qintervalspos=[0.1, 0.4, 0.7, inf];
    Qintervalsneg=[0.1, 0.4, 0.7, inf];
    
    if with_usage == 1
        usageterms={'zero', 'negligible', 'very low', 'low', 'medium', 'high', 'very high'};
        usageintervals=[0.005, 0.01, 0.1, 0.4, 0.6, 0.85, inf];
    end

    for ruleno=1:numofrules
        for currantec=1:numofantecs
            for currterm=1:size(antecedents{currantec},2)
                if isnan(RB(ruleno,currantec))
                    RBhuman{ruleno+1,currantec}='*';
                    break
                else
                    % float magic
                    if abs(RB(ruleno,currantec) - antecedents{currantec}(currterm)) < float_diff_tolerance
                        RBhuman{ruleno+1,currantec}=FRIQ_param_antecedent_terms{currantec}{currterm};
                        break
                    end
                end
            end
        end
        
        currQ=RB(ruleno,numofantecs+1);
        if currQ > 0
            for Qtermposno=1:size(Qtermspos,2)
                if (currQ/Qrange) < Qintervalspos(Qtermposno)
                    RBhuman{ruleno+1,numofantecs+1}=Qtermspos{Qtermposno};
                    break
                end
            end
        else
            for Qtermnegno=1:size(Qtermspos,2)
                if (abs(currQ)/Qrange) < Qintervalsneg(Qtermnegno)
                    RBhuman{ruleno+1,numofantecs+1}=Qtermsneg{Qtermnegno};
                    break
                end
            end
        end
        
        if with_usage == 1
            currusage=RB(ruleno,numofantecs+2);
            for usagetermno=1:size(usageterms,2)
                if (currusage/maxusage) < usageintervals(usagetermno)
                    RBhuman{ruleno+1,numofantecs+2}=usageterms{usagetermno};
                    %                 RBhuman{ruleno+1,numofantecs+2}=currusage/maxusage;
                    break
                end
            end
            
            currnormusage=RB(ruleno,numofantecs+3);
            for usagetermno=1:size(usageterms,2)
                if (currnormusage/maxnormusage) < usageintervals(usagetermno)
                    RBhuman{ruleno+1,numofantecs+3}=usageterms{usagetermno};
                    RBhuman{ruleno+1,numofantecs+4}=[num2str((currnormusage*100)) '%'];
                    break
                end
            end
        end
    end

    writecell(RBhuman,[ RBbasefilename '_humanized.csv']);
