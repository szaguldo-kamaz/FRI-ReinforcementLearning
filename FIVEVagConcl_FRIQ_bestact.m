function [Y] = FIVEVagConcl_FRIQ_bestact(U, VE, R, rd, P)
%FIVEVagConcl: Calculate the conclusion from the observation and the rulebase
%
%                            [Y]=FIVEVagConcl(U,VE,R,X,P)
%
%          Where:
%          U: is the universe (a vector of discrete values in increasing order),
%          VE: is the generated vague environment (the scaled distances on the universe U)
%             If VE(k,1)=0, it is the primitive integral of the scaling function according
%               to the elements of U
%             If VE(k,1)=-1, it is the integral of the scaling function between
%               the neighboring elements of U
%          R: is the Rulebase
%          X: is the observation
%          P: is the power factor in the Shepard interpolation formula: wi=1./dist(i).^p
%             optional, if not given, by default it is equal to the
%             antecedent dimensions of the rulebase R
%          In case of U,VE,X, the rows are the dimensions
%          y: is the conclusion
%
%          Rulebase:
%
%            R1: a1 a2 a3 ... am -> b       [a1 a2 a3 ... am b;...
%            R2: a1 a2 a3 ... am -> b        a1 a2 a3 ... am b;...
%            R3: a1 a2 a3 ... am -> b        a1 a2 a3 ... am b;...
%             ...                             ...
%            Rn: a1 a2 a3 ... am -> b        a1 a2 a3 ... am b]
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2008 by Szilveszter Kovacs
    %   Last modified: 15.07.08
    % FRIQ-BestAct selection optimization by David Vincze

    if (nargin < 4) || (nargin > 5), error('Invalid number of arguments!'); end

    if any(size(U) ~= size(VE)), error('Input arguments U,VE must be the same length!'); end

    [n, m] = size(R);

    if nargin == 4 % P is not given
        P = m - 1; % the number of the antecedents
    end

    [nu, mu] = size(U); % nu is the number of the given universes

    if (m < nu) || (m > (nu + 1))
        error('Dimension mismatch between the rulebase and the antecedent universes!');
    end

    % Go through all rules; R(i,m) is the i. conclusion;
    %    rd(i) is the i. distance of the i. antecedent to the observation

    if sum(rd == 0) > 0% at least one rule antecedent had exactly hit
        vrconc = []; % resetting temp variables

        for i = 1:n % for all the rules

            if rd(i) == 0

                if m == nu % the consequent universe also has a vague environment
                    % vague distance from the first (smallest) element of the conclusion universe
                    vrconc = [vrconc, FIVEVagDist_fixres(U(m, :), VE(m, :), U(m, 1), R(i, m))];
                else % the rule consequences are singletons
                    vrconc = [vrconc, R(i, m)];
                end

            end % if

        end % for i

        if m == nu % the consequent universe also has a vague environment

            if min(vrconc) < 0 % at least one rule consequent is in inf distance
                vagc = sum(vrconc(vrconc <= 0)) ./ size(vrconc(vrconc <= 0), 2);
            else % no rule consequent is in inf distance
                vagc = sum(vrconc) ./ size(vrconc, 2);
            end % if

        else % the rule consequences are singletons
            vagc = sum(vrconc) ./ size(vrconc, 2);
        end

    else % Shepard interpolation

        if max(rd) > 0% at least one rule antecedent is not in inf distance
            rd(rd < 0) = inf; % rd<0 denotes that rd=inf
        end % if

        for i = 1:n% for all the rules
            wi(i) = 1 ./ abs(rd(i)).^P;

            if m == nu% the consequent universe also has a vague environment
                % vague distance from the first (smallest) element of the conclusion universe
                vrconc(i) = FIVEVagDist_fixres(U(m, :), VE(m, :), U(m, 1), R(i, m));
            else % the rule consequences are singletons
                vrconc(i) = R(i, m);
            end

        end % for i

        if m == nu % the consequent universe also has a vague environment

            if min(vrconc) < 0% at least one rule consequent is in inf distance
                ws = sum(wi(vrconc <= 0)); % inf and zero only
                vagc = sum(wi(vrconc <= 0) .* vrconc(vrconc <= 0));
            else % no rule consequent is in inf distance
                ws = sum(wi);
                vagc = sum(wi .* vrconc);
            end % if

        else % the rule consequences are singletons
            ws = sum(wi);
            vagc = sum(wi .* vrconc);
        end

        if ws == 0
            vagc = NaN; % There is no valid conclusion (infinite distances from all the rules)
        else
            vagc = vagc ./ ws; % The valid interpolated conclusion
        end

    end

    if isnan(vagc)
        Y = NaN; % There is no valid conclusion (infinite distances from all the rules)
    else

        if m == nu % the consequent universe also has a vague environment
            Y = FIVEValVag(U(m, :), VE(m, :), vagc); % The valid conclusion
        else % the rule consequences are singletons
            Y = vagc; % The valid conclusion
        end

    end
