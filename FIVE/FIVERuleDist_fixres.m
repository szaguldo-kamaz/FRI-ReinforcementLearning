function [RD] = FIVERuleDist_fixres(U, VE, R, X)
%FIVERuleDist: Calculate the distances of the observation from the rule antecedents
%
%                            [RD]=FIVERuleDist(U,VE,R,X)
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
%          In case of U,VE,X, the rows are the dimensions
%          RD: is the scaled distance of the observation from the rule antecedents
%               RD<0 denotes that RD=inf. This case abs(RD) is a distance
%               counted based on the number of inf values in VE between the
%               observation from the rule antecedents.
%
%          Rulebase:
%
%            R1: a1 a2 a3 ... am -> b
%            R2: a1 a2 a3 ... am -> b
%            R3: a1 a2 a3 ... am -> b
%             ...
%            Rn: a1 a2 a3 ... am -> b
%
%            If ai=NaN then the rule antecedent ai is not given
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2008 by Szilveszter Kovacs
    %   Last modified: 14.07.08
    % FixRes by David Vincze

    % global FIVEdebug
    %
    % if FIVEdebug == 1
    %     if nargin~=4,error('Invalid number of arguments!');end
    %     if any(size(U)~=size(VE)),error('Input arguments U,VE must be the same length!');end
    % end

    [nr, mr] = size(R); % m-1 is the dimension of the antecedent universe
    tempU = U(1:mr - 1, :);
    tempVE = VE(1:mr - 1, :);
    [nu, mu] = size(tempU);
    %nu = mr - 1; % according to the profiler, the above line is faster...
    RD = zeros(1, nr);
    Rnoconcl=R(:, 1:mr - 1);

    for i = 1:nr % Go through all rules
        dm = FIVEVagDist_fixres(tempU, nu, mu, tempVE, Rnoconcl(i, :), X);

        if min(dm) < 0 % there are inf elements (denoted by <0 value)
            dm = dm(dm < 0); % vector of elements <0 from dm
%            RD(i) = -sqrt(sum(dm.^2));    % RD<0 denotes that RD=inf
            RD(i) = -norm(dm, 2); % RD<0 denotes that RD=inf
        else % there are no inf elements
            % Euclidean distance of the observation from the rule antecedents
%            RD(i) = sqrt(sum(dm.^2));
            RD(i) = norm(dm, 2);
        end % if

    end % for i
