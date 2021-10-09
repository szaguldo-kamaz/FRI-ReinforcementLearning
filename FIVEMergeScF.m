function [SCF] = FIVEMergeScF(SCF1, SCF2)
%FIVEMergeScF:  Merge two scaling functions to a single one
%
%                            [SCF]=combscf(SCF1,SCF2)
%
%          Where:
%          SCF1, SCF2: are the two scaling functions to merge.
%                       In case of NaN the scaling function is not exists.
%          SCF: is the merged scalling function,
%               (scaling factors according to the elements of U)
%          In case of SCF the rows are the dimensions
%
%             SCF(i,j)=(SCF1(i,j).*SCF2(i,j))./(SCF1(i,j)+SCF2(i,j))
%

    % Fuzzy Inference by Interpolation in Vague Environment toolbox for MATLAB
    % By Szilveszter Kovacs
    % e-mail: szkovacs@iit.uni-miskolc.hu
    %   Copyright (c) 2006 by Szilveszter Kovacs

    if nargin ~= 2, error('Invalid number of arguments!'); end

    [m, n] = size(SCF1);

    if any(size(SCF1) ~= size(SCF2))
        error('The size of the two scaling functions due to merge must be equal!');
    end

    if any(isnan(SCF1)) && any(isnan(SCF2))
        SCF = NaN;  % none of them exist
    elseif isnan(SCF1)
        SCF = SCF2; % SCF1 does not exist
    elseif isnan(SCF2)
        SCF = SCF1; % SCF2 dodes not exist
    else
        % merging the two scaling functions
        for i = 1:m

            for j = 1:n

                if SCF1(i, j) < 0 || SCF2(i, j) < 0
                    error('The scaling functions must not be negative!');
                end

                if isinf(SCF1(i, j))
                    SCF(i, j) = SCF2(i, j);
                elseif isinf(SCF2(i, j))
                    SCF(i, j) = SCF1(i, j);
                elseif (SCF1(i, j) + SCF2(i, j)) == 0
                    SCF(i, j) = 0;
                else
                    SCF(i, j) = (SCF1(i, j) .* SCF2(i, j)) ./ (SCF1(i, j) + SCF2(i, j)); % merge
                end

            end % for j

        end % for i

    end % if
