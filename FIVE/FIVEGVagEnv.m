function [VE] = FIVEGVagEnv(U, SCF)
%FIVEGVagEnv:  Generate the vague environment VE (the scaled distances of the U universe)
%
%                            [VE]=FIVEGVagEnv(U,SCF)
%
%          Where:
%          U: is the universe (a vector of discrete values in increasing order),
%          SCF: is the scaling function
%               (scaling factors according to the elements of U)
%          VE: is the generated vague environment (the scaled distances on the universe U)
%             If VE(k,1)=0, it is the primitive integral of the scaling function according
%               to the elements of U
%             If VE(k,1)=-1, it is the integral of the scaling function between
%               the neighboring elements of U
%          In case of U,SCF,VE the rows are the dimensions
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2008 by Szilveszter Kovacs
    %   Last modified: 11.07.08

    if nargin ~= 2, error('Invalid number of arguments!'); end

    if any(size(U) ~= size(SCF)), error('Input arguments U,SCF must be the same length!'); end

    [m, n] = size(U);

    for k = 1:m

        if isinf(max(SCF(k, :)))% there is an inf scaling factor exists
            VE(k, 1) = -1; % first element
            VE(k, 2:n) = diff(U(k, :)) .* (SCF(k, 1:n - 1) + SCF(k, 2:n)) / 2; % Trapezoidal area between neighbors
        else
            e = diff(U(k, :)) .* (SCF(k, 1:n - 1) + SCF(k, 2:n)) / 2; % Trapezoidal area
            VE(k, 1) = 0;  % first element

            for i = 1:n - 1
                VE(k, i + 1) = VE(k, i) + e(i); % primitive integral of the scaling function
            end % for i

        end % if

    end % for k
