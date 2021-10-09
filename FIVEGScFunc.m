function [SCF] = FIVEGScFunc(U, PSC, NLS)
%FIVEGScFunc:  Generate the scaling function SCF
%
%                            [SCF]=FIVEGScFunc(U,PSC,NLS)
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
%          SCF: is the generated scaling function
%               (scaling factors according to the elements of U)
%          In case of U,PSC,SCF the rows are the dimensions
%
%          In nonlinear case, the scaling function is approximated by the
%          following function (y = 1/(x^w)) between the neighbouring scaling factor
%          values (Pn,Pn+1):
%
%               SCF(x)=w.*(((d+1)./(x+1)).^w-1)./((d+1).^w-1), or
%               SCF(x)=w.*(((d+1)./(d-x+1)).^w-1)./((d+1).^w-1),
%                   where
%                       w = NLS*abs(S(n+1)-S(n)), d=P(n+1)-P(n)
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2006 by Szilveszter Kovacs

    if (nargin < 2) || (nargin > 3), error('Invalid number of arguments!'); end

    [m, n] = size(U);
    [l, k] = size(PSC);

    if (k > 3) || ((k == 1) && (l > 1)), error('Invalid matrix type of scaling function points!'); end

    if nargin == 3

        if NLS <= 0
            error('NLS must be positive!');
        else
            c = NLS; % nonlinear approximation, scaling of the power function
        end

    else
        c = NaN; % linear approximation
    end

    PSC = sortrows(PSC, 1); % sort the points in ascending order

    if l > 1    % more points

        for i = 1:m

            for j = 1:n

                if U(i, j) < PSC(1, 1)  % first
                    SCF(i, j) = PSC(1, 2);
                end

                for p = 1:l - 1

                    if (U(i, j) >= PSC(p, 1)) && (U(i, j) < PSC(p + 1, 1))
                        p1 = PSC(p, 1);
                        p2 = PSC(p + 1, 1);

                        if k == 2   % Sl and Sr are the same
                            s1 = PSC(p, 2);
                        else        % Sl and Sr are different
                            s1 = PSC(p, 3);
                        end

                        s2 = PSC(p + 1, 2);

                        if s1 == s2 % the scaling function is constant
                            SCF(i, j) = s1;
                        else % the scaling function is not constant

                            if isnan(c)% linear approximation
                                SCF(i, j) = ((s2 - s1) ./ (p2 - p1)) .* (U(i, j) - p1) + s1;
                            else % nonlinear approximation
                                d = p2 - p1;

                                if s1 > s2
                                    w = s1 - s2;

                                    if isinf(w)% s1==inf

                                        if U(i, j) > p1
                                            SCF(i, j) = s2;
                                        else
                                            SCF(i, j) = s2 + w;
                                        end

                                    else
                                        cw = c .* w;
                                        SCF(i, j) = s2 + w .* (((d + 1) ./ (U(i, j) - p1 + 1)).^cw - 1) ./ ((d + 1).^cw - 1);
                                        % SCF(x)=w.*(((d+1)./(d-x+1)).^w-1)./((d+1).^w-1);
                                    end

                                else
                                    w = s2 - s1;

                                    if isinf(w) % s2==inf

                                        if p2 > U(i, j)
                                            SCF(i, j) = s1;
                                        else
                                            SCF(i, j) = s1 + w;
                                        end

                                    else
                                        cw = c .* w;
                                        SCF(i, j) = s1 + w .* (((d + 1) ./ (p2 - U(i, j) + 1)).^cw - 1) ./ ((d + 1).^cw - 1);
                                        % SCF(x)=w.*(((d+1)./(x+1)).^w-1)./((d+1).^w-1);
                                    end

                                end

                            end

                        end

                    end

                end % for p

                if U(i, j) >= PSC(l, 1) % last

                    if k == 2   % Sl and Sr are the same
                        SCF(i, j) = PSC(l, 2);
                    else        % Sl and Sr are different
                        if (j == n) && (U(i, j) == PSC(l, 1))  % the last scaling point is at the end
                        SCF(i, j) = PSC(l, 2);  % the Sl left scaling value is applied
                    else
                        SCF(i, j) = PSC(l, 3);  % the Sr right scaling value is applied
                    end

                end

            end

        end % for j

    end % for i

else % only one element (single value, or one point)

    if k == 1   % single value

        for i = 1:m

            for j = 1:n
                SCF(i, j) = PSC;
            end % for j

        end % for i

    else        % single point

        for i = 1:m

            for j = 1:n

                if U(i, j) < PSC(1, 1)  % before the given point (left side scaling)
                    SCF(i, j) = PSC(1, 2);
                else                    % after the given point (right side scaling)

                    if k == 2   % Sl and Sr are the same
                        SCF(i, j) = PSC(l, 2);
                    else        % Sl and Sr are different
                        SCF(i, j) = PSC(l, 3);
                    end

                end

            end % for j

        end % for i

    end

end
