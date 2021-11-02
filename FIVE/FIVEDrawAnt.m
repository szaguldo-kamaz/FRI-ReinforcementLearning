function FIVEDrawAnt(output, params)
%FIVEDrawAnt:  Draw the antecedents of FIVE
%
%                            FIVEDrawAnt(output,params)
%
%          Where:
%          output: is the set of the FIVE outputs
%               output.concl
%                   set the conclusion vector in the output
%               output.obs
%                   set the obs in the output
%               output.fis
%                   set the fis in the output
%                   fis.input(i).PASC
%                       save the antecedent scaling points in fis
%                   fis.input(i).ASCF
%                       save the antecedent scaling function in fis
%                   fis.input(i).POSC
%                       save the observation scaling points in fis
%                       (if exists - trimf, trapmf case only), NaN if not exists
%                   fis.input(i).OSCF
%                       save the observation scaling function in fis
%                       (if exists - trimf, trapmf case only), NaN if not exists
%                   fis.input(i).SCF
%                       save the merged scaling function in fis
%                   fis.input(i).U
%                       save the universe in fis
%                   fis.input(i).VE
%                       save the vague environment in fis
%                   fis.output(i).SCF
%                       save the scaling function in fis, NaN if not exists
%                   fis.output(i).U
%                       save the universe in fis, NaN if not exists
%                   fis.output(i).VE
%                       save the vague environment in fis, NaN if not exists
%                   fis.output(i).R;
%                       save the single conclusion rulebase for output(i) in fis
%          params: is the set of parameters
%               params.NumOfPoints
%                   size (resolution) of the antecedent, consequent universes
%                   (optional, if not given it is set to 101)
%               params.ShepardPower
%                   power factor in the Shepard interpolation formula, optional,
%                   if not given, by default it is equal to the antecedent dimensions of the rulebase R
%               params.NLS
%                   NLS: optional, if not given: linear scaling function approximation
%                   if given: NLS is the constant factor of sensitivity for
%                   neighbouring scaling factor differences in nonlinear scaling function approximation
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2006 by Szilveszter Kovacs

    clc;

    for i = 1:length(output.fis.input)
        [VE] = FIVEDrawMergedPart(...
            output.fis.input(i).U, ...
            output.fis.input(i).PASC, ...
            output.fis.input(i).POSC, ...
            params.NLS);

        if isnan(output.fis.input(i).POSC)% not a fuzzy observation is given
            hold on;
            subplot(3, 1, 1);
            title('Antecedent and observation membership functions.');
            oval = output.obs(i).params; % conclusion value
            plot([oval, oval], [0, 1], 'm-'); % plot the observation
            plot(oval, 1, 'm*');
        end

        hold on;
        subplot(3, 1, 3);
        title(['Merged membership functions: ', output.fis.input(i).name]);
    end
