function [P] = FIVEValVag_fixres(U, VE, VP)
%FIVEValVag:  Value of a vague point VP
%
%                            [P]=FIVEValVag(U,VE,VP)
%
%          Where:
%          U: is the universe (a vector of discrete values in increasing order),
%          VE: is the generated vague environment (the scaled distances on the universe U)
%             If VE(1)=0, it is the primitive integral of the scaling function according
%               to the elements of U
%             If VE(1)=-1, it is the integral of the scaling function between
%               the neighboring elements of U
%          VP: is the scaled distance of a point P from the first element
%               of the vague environment
%               VP<0 denotes infinite conclusion distance
%          P: is the point which has the VP scaled distance from the first element
%               of the vague environment
%          In case of U,VE,VP,P the rows are the dimensions
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2008 by Szilveszter Kovacs
    %   Last modified: 14.07.08

    % global FIVEdebug
    %
    % if FIVEdebug == 1
    %     if nargin~=3,error('Invalid number of arguments!');end
    %     if any(size(U)~=size(VE)),error('Input arguments U,VE must be the same length!');end
    % end

    [m, n] = size(U);

    for k = 1:m % for all the dimensions

        if VE(k, 1) < 0 % VE(k,1)=-1, VE is the integral of the scaling function between the neighboring elements of U
            if VP(k) > sum(VE(k, 2:n)), error('The points are out of range!'); end

            if VP(k) < 0 % denotes infinite conclusion distance
                i = 2; %init
                vpc = VP(k); % temp counter

                while (vpc < 0) && (i < n)

                    if isinf(VE(k, i)) % count inf
                        vpc = vpc + 1; % inc
                    end

                    i = i + 1; % inc
                end

            else
                i = 2; %init
                sVP = VE(k, i); % init, VE(k,1)=-1 this case

                while (sVP < VP(k)) && (i < n)
                    i = i + 1; % inc
                    sVP = sVP + VE(k, i); % sum up the neighbouring differences in VE
                end

                if (sVP - VP(k)) > (VP(k) - (sVP - VE(k, i))) % the previous was closer
                    i = i - 1; % previos index
                end

            end % if

        else % VE(k,1)=0, VE is the primitive integral of the scaling function according to the elements of U
            if (VP(k) < 0) || (VP(k) > VE(k, n)), error('The points are out of range!'); end
            [dm, i] = min(abs(VE(k, :) - VP(k))); % i is the index of the min distance from vp (VE(k,1)=0)
        end % if

        P(k) = U(k, i); % the point which has the VP scaled distance from the first element of the vague environment

    end % for k
