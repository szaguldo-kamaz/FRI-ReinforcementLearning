function [mf] = FIVEVagMemb(u, ve, p)
%FIVEVagMemb:  Membership function of a point in a vague environment
%
%                            [mf]=FIVEVagMemb(u,ve,p)
%
%          Where:
%          MF is the membership function to generate,
%          U is the universe, VE is the vague environment,
%          P is the point describes the membership function.
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2008 by Szilveszter Kovacs
    %   Last modified: 14.07.08

    if nargin ~= 3, error('Invalid number of arguments!'); end

    if length(u) ~= length(ve)
        error('Input arguments must be the same length!');
    end

    [m, n] = size(u);

    for i = 1:m
        [dm, j] = min(abs(u(i, :) - p(i))); % closest element of the universe of discourse

        if (p(i) > u(i, j)) && (j < n)
            pm(i) = u(i, j + 1); % the modified point position for the better look of the graph
        else
            pm(i) = u(i, j); % the modified point position for the better look of the graph
        end % if

    end % for i

    for i = 1:n
        dist = FIVEVagDist(u, ve, u(:, i)', pm);
        dist(dist < 0) = inf; % dist<0 denotes that dist=inf
        mf(:, i) = max(0, (1 - abs(dist)))';
    end % for i
