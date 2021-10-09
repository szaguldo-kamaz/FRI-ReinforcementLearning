function [VE] = FIVEDrawMergedPart(U, PSCa, PSCo, NLS)
%FIVEDrawMergedPart:  Draw a fuzzy partition in a merged vague environment, as it describes it
%
%                            [VE]=FIVEDrawMergedPart(U,PSCa,PSCo,NLS)
%
%          Where:
%          U: is the universe (a vector of discrete values in increasing order),
%          PSCa: contains the points of the antecedent scaling function
%          PSCo: contains the points of the observation scaling function
%               NaN:
%                   not given, the observation is crisp
%               PSC: S
%                   where S is the scaling value of the whole universe, or
%               PSC: P1,S1;P2,S2;...
%                   where P is the point, S is the scaling function value, or
%               PSC: P1,S1l,S1r;P2,S2l,s2r;...
%                   where P is the point, Sl the left, Sr the right scaling function value.
%          NLS: optional,
%               if not given: linear scaling function approximation
%               if given: NLS is the constant factor of sensitivity for
%                   neighbouring scaling factor differences in nonlinear
%                   scaling function approximation
%          VE: is the generated merged vague environment
%               (the scaled distances of the universe U)
%               (the primitive integral of the scaling function according
%               to the elements of U)
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2008 by Szilveszter Kovacs
    %   Last modified: 30.07.08

    clc;

    % Generating the scaling functions [SCF]=FIVEGScFunc(U,PSC,NLS)
    % Generating the vague environment

    SP = PSCa; % points of the antecedent scaling function
    i = 1; % init
    j = 1;
    mpos = [];

    while i <= size(SP, 1)

        if SP(i, 1) < U(1)% SP is outside the universe
            mpos = [mpos; U(1)]; % let the first element of the universe the position of the membership functions
        elseif SP(i, 1) > U(size(U, 2))% SP is outside the universe
            mpos = [mpos; U(size(U, 2))]; % let the last element of the universe the position of the membership functions
        else
            mpos = [mpos; SP(i, 1)]; % position of the membership functions
        end

        if (i < size(SP, 1)) && (size(SP, 2) == 3) && (SP(i, 3) == 0) && (SP(i + 1, 2) == 0)% filtering trapesoidal membership functions
            SFS = FIVEGScFunc(U, [SP(i, :); SP(i + 1, :)]); % U
            VES(j, :) = FIVEGVagEnv(U, SFS); % U
            i = i + 2;
            j = j + 1;
        else
            SFS = FIVEGScFunc(U, SP(i, :)); % U
            VES(j, :) = FIVEGVagEnv(U, SFS); % U
            i = i + 1;
            j = j + 1;
        end

    end

    mnum = j - 1; % number of the membership functions

    if ~isnan(PSCo)% a fuzzy observation is given
        SP = PSCo; % points of the observation scaling function

        if SP(1, 1) < U(1)% SP is outside the universe
            mposo = U(1); % let the first element of the universe the position of the membership functions
        elseif SP(1, 1) > U(size(U, 2))% SP is outside the universe
            mposo = U(size(U, 2)); % let the last element of the universe the position of the membership functions
        else
            mposo = SP(1, 1); % the position of the observation membership functions
        end

        SFS = FIVEGScFunc(U, SP); % U
        VESo = FIVEGVagEnv(U, SFS); % U
    end

    if nargin == 4
        SFa = FIVEGScFunc(U, PSCa, NLS); % U
        SFo = FIVEGScFunc(U, PSCo, NLS); % U
        SFm = FIVEMergeScF(SFa, SFo); % U
    else
        SFa = FIVEGScFunc(U, PSCa); % U
        SFo = FIVEGScFunc(U, PSCo); % U
        SFm = FIVEMergeScF(SFa, SFo); % U
    end

    VE = FIVEGVagEnv(U, SFm); % U

    % Draw

    figure;
    clf; set(gcf, 'units', 'normal', 'position', [.1 .1 .8 .8])

    hold off;

    subplot(3, 1, 1);

    if isnan(PSCo)% not a fuzzy observation is given
        title('Membership functions.');
    else
        title('Antecedent and observation membership functions.');
    end

    % original partition
    SP = PSCa; % points of the antecedent scaling function

    for i = 1:mnum
        mf = FIVEVagMemb(U, VES(i, :), mpos(i));
        hold on;
        plot(U, mf, 'b')
    end

    % original observation
    if ~isnan(PSCo)% a fuzzy observation is given
        mf = FIVEVagMemb(U, VESo, mposo);
        hold on;
        plot(U, mf, 'm')
    end

    subplot(3, 1, 2);

    if isnan(PSCo)% not a fuzzy observation is given
        title('Scaling functions.');
    else
        title('Antecedent, observation and the merged scaling functions.');
    end

    % antecedent scaling function
    SP = PSCa; % points of the antecedent scaling function
    SF = SFa; % antecedent scaling function

    for i = 1:size(SP, 1)

        if size(SP(i, :), 2) == 3
            hold on;
            plot(SP(i, 1), SP(i, 2), 'bo');
            hold on;
            plot(SP(i, 1), SP(i, 3), 'b*');
        elseif size(SP(i, :), 2) == 2
            hold on;
            plot(SP(i, 1), SP(i, 2), 'b*');
        end % if

    end % for

    i = 1; % init

    for j = 1:size(SP, 1)
        UT = [];
        SFT = [];

        while (U(i) < SP(j, 1)) && (i < size(U(i), 2))
            UT = [UT, U(i)];
            SFT = [SFT, SF(i)];
            i = i + 1;
        end

        hold on;
        plot(UT, SFT, 'b');
    end

    UT = U([i:size(U, 2)]);
    SFT = SF([i:size(SF, 2)]);
    hold on;
    plot(UT, SFT, 'b');

    % observation scaling function
    if ~isnan(PSCo)% a fuzzy observation is given
        SP = PSCo; % points of the observation scaling function
        SF = SFo; % observation scaling function

        for i = 1:size(SP, 1)

            if size(SP(i, :), 2) == 3
                hold on;
                plot(SP(i, 1), SP(i, 2), 'mo');
                hold on;
                plot(SP(i, 1), SP(i, 3), 'm*');
            elseif size(SP(i, :), 2) == 2
                hold on;
                plot(SP(i, 1), SP(i, 2), 'm*');
            end % if

        end % for

        i = 1;

        for j = 1:size(SP, 1)
            UT = [];
            SFT = [];

            while (U(i) < SP(j, 1)) && (i < size(U(i), 2))
                UT = [UT, U(i)];
                SFT = [SFT, SF(i)];
                i = i + 1;
            end

            hold on;
            plot(UT, SFT, 'm');
        end

        UT = U([i:size(U, 2)]);
        SFT = SF([i:size(SF, 2)]);
        hold on;
        plot(UT, SFT, 'm');

        % merged scaling function
        SP = PSCa(:, 1); % core points of the observation scaling function

        if ~isnan(PSCo)% a fuzzy observation is given

            if size(PSCo, 2) > 1

                for i = 1:size(PSCo, 1)
                    SP = [SP; PSCo(i, 1)]; % core points of the observation scaling function
                end

            end

        end

        SP = sortrows(SP, 1); % sort the points in ascending order
        SF = SFm; % merged scaling function
        i = 1; % init

        for j = 1:size(SP, 1)

            while (U(i) < SP(j)) && (i < size(U(i), 2))
                i = i + 1;
            end

            hold on;

            if i > 1
                plot(SP(j), SF(i - 1), 'ro');
            else
                plot(SP(j), SF(1), 'ro'); % limit
            end

            hold on;
            plot(SP(j), SF(i), 'r*');
        end

        i = 1;

        for j = 1:size(SP, 1)
            UT = [];
            SFT = [];

            while (U(i) < SP(j)) && (i < size(U(i), 2))
                UT = [UT, U(i)];
                SFT = [SFT, SF(i)];
                i = i + 1;
            end

            hold on;
            plot(UT, SFT, 'r');
        end

        UT = U([i:size(U, 2)]);
        SFT = SF([i:size(SF, 2)]);
        hold on;
        plot(UT, SFT, 'r');
    end

    subplot(3, 1, 3);

    if isnan(PSCo)% not a fuzzy observation is given
        title('Membership functions.');
    else
        title('Merged antecedent and observation membership functions.');
    end

    % merged antecedents
    SP = PSCa; % points of the antecedent scaling function
    SF = SFm; % merged scaling function

    for i = 1:mnum
        mf = FIVEVagMemb(U, VE, mpos(i));
        hold on;
        plot(U, mf, 'b')
    end
