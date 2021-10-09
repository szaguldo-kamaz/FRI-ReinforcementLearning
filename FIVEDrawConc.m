function FIVEDrawConc(output, params)
%FIVEDrawConc:  Draw the conclusions of FIVE
%
%                            FIVEDrawConc(output,params)
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

    for i = 1:length(output.fis.output)

        if ~isnan(output.fis.output(i).SCF)% the output has a scaling function too
            [VE] = FIVEDrawPart(...
                output.fis.output(i).U, ...
                output.fis.output(i).PSC, ...
                params.NLS);
            hold on;
            subplot(3, 1, 3);
            title(['Membership functions: ', output.fis.output(i).name]);
        else
            figure;
            xrange = output.fis.output(i).range; % range of the con
            axis([xrange(1), xrange(2), 0, 1]); % set the axis

            for j = 1:length(output.fis.output(i).mf)
                scval = output.fis.output(i).mf(j).params(1); % singleton consequences
                hold on;
                plot([scval, scval], [0, 1], 'b-'); % plot the singleton consequence
                plot(scval, 1, 'b*');
            end

        end

        cval = output.concl(i).params; % conclusion value
        plot([cval, cval], [0, 1], 'r-'); % plot the conclusion
        plot(cval, 1, 'r*');
    end
