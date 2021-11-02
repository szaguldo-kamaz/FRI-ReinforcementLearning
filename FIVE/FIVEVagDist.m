function [D] = FIVEVagDist(U, VE, P1, P2)
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
    %   Last modified: 14.07.08

    if nargin ~= 4, error('Invalid number of arguments!'); end

    if any(size(U) ~= size(VE)), error('Input arguments U,VE must be the same length!'); end

    [m, n] = size(U);

    for k = 1:m % the number of the dimension

        if isnan(P1(k)) || isnan(P2(k)) % not a valid scaled distance (D=0)
            D(k) = 0; % indifferent (not existing) rule antecedent
        else % valid scaled distance

            if (min(P1(k), P2(k)) < U(k, 1)) || (max(P1(k), P2(k)) > U(k, n))
                error('The points are out of range!');
            end

            % i is the index of the element in U, which has the min distance from P1
            [dm, i] = min(abs(U(k, :) - P1(k)));
            % j is the index of the element in U, which has the min distance from P2
            [dm, j] = min(abs(U(k, :) - P2(k)));

            if VE(k, 1) < 0 % VE(k,1)=-1, VE is the integral of the scaling function between the neighboring elements of U

                if i < j
                    D(k) = sum(VE(k, (i + 1):j)); % the scaled distance of P1 and P2 (P2>P1)

                    if isinf(D(k)) % infinite distance
                        D(k) = -sum(isinf(VE(k, (i + 1):j))); % the number of inf values in VE between P1 and P2
                    end

                elseif i > j
                    D(k) = sum(VE(k, (j + 1):i)); % the scaled distance of P1 and P2 (P1>P2)

                    if isinf(D(k))% infinite distance
                        D(k) = -sum(isinf(VE(k, (j + 1):i))); % the number of inf values in VE between P2 and P1
                    end

                else
                    D(k) = 0; % the scaled distance of P1 and P2 (P2=P1)
                end

            else % VE(k,1)=0, VE is the primitive integral of the scaling function according to the elements of U

                if i < j
                    D(k) = VE(k, j) - VE(k, i); % the scaled distance of P1 and P2 (P2>P1)
                elseif i > j
                    D(k) = VE(k, i) - VE(k, j); % the scaled distance of P1 and P2 (P1>P2)
                else
                    D(k) = 0; % the scaled distance of P1 and P2 (P2=P1)
                end

            end % if

        end % if

    end % for k
