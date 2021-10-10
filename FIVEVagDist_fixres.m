function [D] = FIVEVagDist_fixres(U, nu, mu, VE, P1, P2)
%FIVEVagDist:  Calculate the scaled distance of two points in the vague environment
%
%                            [D]=FIVEVagDist(U,VE,P1,P2)
%
%          Where:
%          U: is the universe (a vector of discrete values in increasing order),
%          VE: is the generated vague environment (the scaled distances on the universe U)
%             If VE(k,1)=0, it is the primitive integral of the scaling function according
%               to the elements of U
%             If VE(k,1)=-1, it is the integral of the scaling function between
%               the neighboring elements of U
%          P1,P2 is two points (values), inside U
%               If P1=NaN, or P2=NaN, then the vague distance is null (D=0)
%          D: is the scaled distance of the two points P1,P2.
%               D<0 denotes that D=inf. This case abs(D) is the number of inf
%               values in VE between P1 and P2
%          In case of U,VE,P,D the rows are the dimensions
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2008 by Szilveszter Kovacs
    % "Fixed resolution" optimization (C) David Vincze
    % vincze.david@iit.uni-miskolc.hu
    %   Last modified: 12.08.10

    % global FIVEdebug
    %
    % if FIVEdebug == 1
    %     if nargin~=4,error('Invalid number of arguments!');end
    %     if any(size(U)~=size(VE)),error('Input arguments U,VE must be the same length!');end
    % end

    % all the "U"s should be the same length, so
    %uksize=(size(U(k,:),2)-1); --> mu-1
    uksize = mu - 1;

    for k = 1:nu % the number of the dimension
    % O(m) - m*

        if isnan(P1(k)) || isnan(P2(k))% not a valid scaled distance (D=0)
        % O(1) - 1+1+1+1 = 4  (isnan isnan || if)
            D(k) = 0; % indifferent (not existing) rule antecedent - O(1) - 1  (=) - the other branch is more complex count that as upper bound, ignore this
        else % valid scaled distance

            if (min(P1(k), P2(k)) < U(k, 1)) || (max(P1(k), P2(k)) > U(k, mu))% O(1)
            % O(1) - 1+1+1+1+1+1 = 6  (<> < <> > || if)
                error('The points are out of range!'); % O(1) - 1 - don't count this, normally this does not happen
            end

            Ukdomain = U(k, mu) - U(k, 1); % 1+1
            tempP1 = (P1(k) - U(k, 1)) / Ukdomain; % 1+1+1
            tempP2 = (P2(k) - U(k, 1)) / Ukdomain; % 1+1+1

%             ik = nk * (Pk - Uk1) / round(Ukn - Uk1) + 1 ?

            % O(1) - 2 + 4 + 2 + 7 + 2 = 17
            % SC = 1 + 2 + 1 = 4 - overwritten in every iteration, so m* does not count
            if P1(k) ~= U(k, mu) % O(1) - 1 + 1 = 2  (~= if)
                where = floor(tempP1 * uksize) + 1;
                % O(1) - 1 + 1 + 1 + 1 = 4  (* floor + =)
                % SC: 1
                if where > 0 % O(1) - 1 + 1 = 2 (> if)

                    if abs(U(k, where) - P1(k)) <= abs(U(k, where + 1) - P1(k))
                    % O(1) - 1 + 1 + 1 + 1 + 1 + 1 + 1 = 7  (- abs + - abs <= if)
                    % SC: 1 + 1 = 2 (needs two values simultaneously for comparison)
                        i = where; % O(1) - 1 (=)% SC: 1% don't count not worst
                    else
                        i = where + 1; % O(1) - 1 + 1 = 2 (+ =), SC: 1% count
                    end

                else
                    i = 1; % O(1) - 1 (=), SC: 1% don't count this SC - not worst
                end

            else
                i = uksize + 1; % O(1) - 1 + 1 = 2 (+ =), SC: 1% don't count not worst
            end

%SC: -2 (from two temp abs() in if)

            % O(1) - 2 + 4 + 2 + 7 + 2 = 17
            % SC = 0 + 2 + 1 = 3 - overwritten in every iteration, so m* does not count
            if P2(k) ~= U(k, mu)% O(1)
                where = floor(tempP2 * uksize) + 1; % O(1)
                % SC+: already allocated and overwritten, so 0
                if where > 0% O(1)

                    if abs(U(k, where) - P2(k)) <= abs(U(k, where + 1) - P2(k))% O(1)
                    % SC: 1 + 1 = 2 (needs two values simultaneously for comparison)
                        j = where; % O(1)
                    else
                        j = where + 1; % O(1)
                        % SC: 1  % count
                    end

                else
                    j = 1; % O(1)
                end

            else
                j = uksize + 1; % O(1)
            end

%SC+ : -2 (from two temp abs() in if)

            if VE(k, 1) >= 0% VE(k,1)=0, VE is the primitive integral of the scaling function according to the elements of U% O(1)
            % O(1) - 1+1 = 2  (>= if)

%                         if i<j
%                             D(k)=VE(k,j)-VE(k,i);   % the scaled distance of P1 and P2 (P2>P1)
%                         elseif i>j
%                             D(k)=VE(k,i)-VE(k,j);    % the scaled distance of P1 and P2 (P1>P2)
%                         else
%                             D(k)=0;                 % the scaled distance of P1 and P2 (P2=P1)
%                         end

                % slightly faster
                D(k) = abs(VE(k, j) - VE(k, i)); % O(1) - 1 + 1 + 1 = 3  (- abs =) - not worst case, don't count!
                % SC: 1
            else
                % VE(k,1)=-1, VE is the integral of the scaling function between the neighboring elements of U
                if i < j % O(1) - 1+1 = 2  (< if)
                    D(k) = sum(VE(k, (i + 1):j)); % the scaled distance of P1 and P2 (P2>P1)% O(n)
                    % O(n) - (n-1-1)*1 + 1 = n - 1  ((n-1-1)*(+) =)
                    % SC: n - 1 ((n-1)*:)
                    if isinf(D(k)) % infinite distance% O(1) - 1+1 = 2  (isinf if)
                        D(k) = -sum(isinf(VE(k, (i + 1):j))); % the number of inf values in VE between P1 and P2% O(n)
                        % O(n) - (n-1)*1 + (n-1-1)*1 + 1 + 1 = 2n - 1 ((n-1)*(isinf) (n-1-1)*(+) - =)
                        % SC: same as previous, and overwritten, so SC=0
                    end

                elseif i > j % O(1) - 1+1 = 2  (< if)% worst case is when this branch runs (two 'if's fire)
                    D(k) = sum(VE(k, (j + 1):i)); % the scaled distance of P1 and P2 (P1>P2)% O(n)
                    % O(n) - (n-1-1)*1 + 1 = n - 1  ((n-1-1)*(+) =)
                    % SC: n - 1 ((n-1)*:)
                    if isinf(D(k)) % infinite distance% O(1) - 1+1 = 2  (isinf if)
                        D(k) = -sum(isinf(VE(k, (j + 1):i))); % the number of inf values in VE between P2 and P1% O(n)
                        % O(n) - (n-1)*1 + (n-1-1)*1 + 1 + 1 = 2n - 1 ((n-1)*(isinf) (n-1-1)*(+) - =)
                        % SC: same as previous, and overwritten, so SC=0
                    end

                else
                    D(k) = 0; % the scaled distance of P1 and P2 (P2=P1)% O(1)
                    % O(1) - 1 (=) but this is not the upper bound (previous two branches are more complex) so ignore
                    % SC: 1
                end

            end % if

        end % if

    end % for k

    % O(mn) - m*(4+6+17+17+2+2+2+n-1+2+2n-1) = m*(3n+50)
    % SC: (4-2+3-2+n-1) + (m-1)*(1) = 2+n + m-1 = m+n+1

    % O(mn) - m*(4+6+17+17+2+3) = m*49
    % SC: (4-2+3-2+1) + (m-1)*(1) = 4 + m-1 = m+3
