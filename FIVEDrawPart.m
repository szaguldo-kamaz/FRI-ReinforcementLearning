function [VE] = FIVEDrawPart(U, PSC, NLS)
%FIVEDrawPart:  Draw a fuzzy partition in a vague environment, as it describes it
%
%                            [VE]=FIVEDrawPart(U,PSC,NLS)
%
%          Where:
%          U: is the universe (a vector of discrete values in increasing order),
%          PSC: contains the points of the scaling function
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
%          VE: is the generated vague environment (the scaled distances of the universe U)
%               (the primitive integral of the scaling function according
%               to the elements of U)
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2006 by Szilveszter Kovacs

    % draw the fuzzy partition as a special case of the merged partition drawing
    VE = FIVEDrawMergedPart(U, PSC, NaN, NLS);
