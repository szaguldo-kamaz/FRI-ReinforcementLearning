function [leftBranch, rightBranch, reducedR] =  FRIQ_reduction_strategy_cluster_hierarchical(RB)
% FRIQ-learning rule-base hierarchical clustering reduction strategy
% Based on hierarchical clustering of rules
%   Developed by Tamas Tompa 2016 <tompa@iit.uni-miskolc.hu> 

    global numofstates finalReducedR U VE
    global FRIQ_param_reward_good_above FRIQ_param_maxsteps FRIQ_param_epsilon

    % initialize variables
    [rows columns] = size(RB);

    tempReducedR = zeros(rows,rows);
    ruleDistance = zeros(rows,rows);
  
    tempReducedMaxR = zeros(rows,rows);
    tempReducedMinR = zeros(rows,rows);
   
    % while the rules are exist
    if(rows >= 4)
        % distance matrix of the rule-base 
        for i=1:rows
            observation = RB(i,1:(numofstates+1));
            ruleDistance(i,:) = FIVERuleDist_fixres(U,VE,RB,observation); 
        end
        
  
        % pivot objects search, the two furthest rule
        % pivot1 object
        [minDists minIndexes] = min(ruleDistance(:,:),[],2);
        minDist = min(minDists);
        minIndex = min(minIndexes);
        Pivot1 = RB(minIndex,:);
       
        % pivot2 object, the furthest rule from the pivot1
        [maxDists maxIndexes] = max(ruleDistance(:,:),[],2);
        maxDist = max(maxDists);
        maxIndex = max(maxIndexes);
        Pivot2 = RB(maxIndex,:);

        % pivot objects
        Pivots = [Pivot1; Pivot2];

        % rules distance from the pivot1 and the pivot2 objects
        distRP1s(:,:) = FIVERuleDist_fixres(U,VE,RB,Pivot1(1:(numofstates+1)));
        distRP2s(:,:) = FIVERuleDist_fixres(U,VE,RB,Pivot2(1:(numofstates+1)));
 
        % distance threshold, based on furthest rules 
        [maxThP1 maxThP1Index] = max(distRP1s(:,:),[],2);
        [maxThP2 maxThP2Index] = max(distRP2s(:,:),[],2);
        tresholdP1 = distRP1s(maxThP1Index) / 2;
        tresholdP2 = distRP2s(maxThP2Index) / 2;
        treshold = (tresholdP1 + tresholdP2) / 2;
     
        % tree building
        % initialize branches
        tempLeftBranch = zeros(rows, columns);
        tempRightBranch = zeros(rows, columns);

        % create branches
        for j=1:rows-2
            if(distRP1s(j) <= treshold)
                tempLeftBranch(j,:) = RB(j,:);
            elseif(distRP1s(j) > treshold)
                tempRightBranch(j,:) = RB(j,:); 
            end 
        end
     
        
        % cleaning, 0 rows remove  
        leftBranch = tempLeftBranch(any(tempLeftBranch,2),:);
        rightBranch = tempRightBranch(any(tempRightBranch,2),:);
       
        % indexes of the min and max Q-value rules of the clusters
        [leftBranchMinValue, leftBranchMinIndex] = min(leftBranch(:,numofstates+2));
        [rightBranchMinValue, rightBranchMinIndex] = min(rightBranch(:,numofstates+2));
        [leftBranchMaxValue, leftBranchMaxIndex] = max(leftBranch(:,numofstates+2));
        [rightBranchMaxValue, rightBranchMaxIndex] = max(rightBranch(:,numofstates+2));
        

        % max and min Q-value rules of the clusters
        tempReducedMaxR = [leftBranch(leftBranchMaxIndex,:); rightBranch(rightBranchMaxIndex,:)];
        tempReducedMinR = [leftBranch(leftBranchMinIndex,:); rightBranch(rightBranchMinIndex,:)];
        
        % cleaning, remove the max and min Q-value rules from the branches, not
        % add these rules again to the branches
        if((leftBranchMaxIndex ~= leftBranchMinIndex) && (rightBranchMaxIndex ~= rightBranchMinIndex))
            [leftBranch] = removerows(leftBranch, [leftBranchMaxIndex leftBranchMinIndex]);
            [rightBranch] = removerows(rightBranch, [rightBranchMaxIndex rightBranchMinIndex]);
        end
        
      
        % cleaning, 0 rows remove
        reducedMaxR = tempReducedMaxR(any(tempReducedMaxR,2),:);
        reducedMinR = tempReducedMinR(any(tempReducedMinR,2),:);
       
        reducedR = [reducedMaxR;reducedMinR];
 
        % trying the rule-base
        [total_reward_friq, steps_friq] = FRIQ_rulebase_load(FRIQ_param_maxsteps, FRIQ_param_epsilon, finalReducedR);
        %disp([num2str(total_reward_friq) ' < ' num2str(FRIQ_param_reward_good_above) ' num2str(total_reward_friq < FRIQ_param_reward_good_above)]);
       
        % bad rule-base, next iteration
        if (total_reward_friq < FRIQ_param_reward_good_above)                
             disp(['FRIQ_steps: ',int2str(steps_friq),' FRIQ_reward: ',num2str(total_reward_friq),' rules: ' num2str(length(finalReducedR))]);
             disp('The rule-base did not solve the problem! Next iteration...');
             disp(' ');
             
             % merged the max and min Q-value rules of the clusters 
             finalReducedR = [finalReducedR;reducedR];
             
             FRIQ_reduction_strategy_cluster_hierarchical(rightBranch);
             FRIQ_reduction_strategy_cluster_hierarchical(leftBranch);
        else
             % good rule-base, end    
             disp(['FRIQ_steps: ',int2str(steps_friq),' FRIQ_reward: ',num2str(total_reward_friq),' rules: ' num2str(length(finalReducedR))]);
             disp('The rule-base solved the problem, smallest rule-base found. Exiting!');
             return; 
        end
 
    end % main if   
end