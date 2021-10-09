function [PSC] = FIVEMf2PSc(Type, Params, Paramsy)
%FIVEMf2PSc:  Convert a membership function to a scaling function points
%
%                            [PSC]=FIVEMf2PSc(Type,Params,Paramsy)
%
%          Where:
%          Type: is the type of the membership function: trimf,trapmf
%          Params: vector of membership function type parameters
%          Paramsy: optional, vector of additional membership function type parameters
%          PSC: a point of the scaling function according to the given membership function
%               PSC: P1,S1l,S1r;P2,S2l,s2r;...
%                   where P is the point, Sl the left, Sr the right scaling function value.
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2006 by Szilveszter Kovacs

    if (nargin < 2) || (nargin > 3), error('Invalid number of arguments!'); end

    switch lower(Type)
        case 'trimf'

            if (nargin == 3) &&~all(Paramsy == [0, 1, 0])% not normal
                error('Only the normal membership functions are supported!');
            end

            PSC(1) = Params(2); % the core of the triangle

            if (Params(2) - Params(1)) == 0 % the left scaling function value
                PSC(2) = Inf;
            else
                PSC(2) = 1 ./ (Params(2) - Params(1)); % the left scaling function value
            end

            if (Params(3) - Params(2)) == 0 % the right scaling function value
                PSC(3) = Inf;
            else
                PSC(3) = 1 ./ (Params(3) - Params(2)); % the right scaling function value
            end

        case 'trapmf'

            if (nargin == 3) &&~all(Paramsy == [0, 1, 1, 0]) % not normal
                error('Only the normal membership functions are supported!');
            end

            PSC(1, 1) = Params(2); % the left side of the core

            if (Params(2) - Params(1)) == 0 % the left scaling function value
                PSC(1, 2) = Inf;
            else
                PSC(1, 2) = 1 ./ (Params(2) - Params(1)); % the left scaling function value
            end

            PSC(1, 3) = 0; % the right scaling function value
            PSC(2, 1) = Params(3); % the right side of the core
            PSC(2, 2) = 0; % the left scaling function value

            if (Params(4) - Params(3)) == 0 % the right scaling function value
                PSC(2, 3) = Inf;
            else
                PSC(2, 3) = 1 ./ (Params(4) - Params(3)); % the right scaling function value
            end

        otherwise
            error('Membership function type! The supported ones: trimf,trapmf!');
    end
