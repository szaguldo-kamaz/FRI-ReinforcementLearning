function FRIQ_init_constants()
% FRIQ_init_constants: define constants
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2021 by David Vincze
%

    %% Define constants - for the names of the strategies
    global FRIQ_const_reduction_strategy__MIN_Q
    global FRIQ_const_reduction_strategy__MAX_Q
    global FRIQ_const_reduction_strategy__HALF_GROUP_REMOVAL
    global FRIQ_const_reduction_strategy__BUILD_MINANDMAXQ
    global FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY 
    global FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST
    global FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MINQ
    global FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MAXQ
    global FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MERGE_MEAN
    global FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST
    global FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MINQ
    global FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MAXQ
    global FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MERGE_MEAN
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_ONE
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_MANY
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_ONE
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_MANY
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_CENTROID
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINANDMAXQ
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MAXABSQ
    global FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINABSQ
    global FRIQ_const_reduction_strategy__CLUSTER__HIERARCHICAL
    % special value to run all the reduction strategies on the same rule-base
    global FRIQ_const_reduction_strategy__ALL

    FRIQ_const_reduction_strategy__MIN_Q=1;
    FRIQ_const_reduction_strategy__MAX_Q=2;
    FRIQ_const_reduction_strategy__HALF_GROUP_REMOVAL=3;
    FRIQ_const_reduction_strategy__BUILD_MINANDMAXQ=4;

    FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY=5;
    FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST=6;
    FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MINQ=7;
    FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MAXQ=8;
    FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MERGE_MEAN=9;
    FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST=10;
    FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MINQ=11;
    FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MAXQ=12;
    FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MERGE_MEAN=13;

    FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_ONE=14;
    FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_MANY=15;
    FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_ONE=16;
    FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_MANY=17;
    FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_CENTROID=18;
    FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINANDMAXQ=19;
    FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MAXABSQ=20;
    FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINABSQ=21;

%    FRIQ_const_reduction_strategy__CLUSTER__HIERARCHICAL=100; % Tamas - TODO

    FRIQ_const_reduction_strategy__ALL=1000;

    global FRIQ_const_reduction_secondary_strategies
    FRIQ_const_reduction_secondary_strategies=[ ...
            FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST, ...
            FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MINQ, ...
            FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MAXQ, ...
            FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MERGE_MEAN ...
            FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST ...
            FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MINQ ...
            FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MAXQ ...
            FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MERGE_MEAN ];

    global FRIQ_const_reduction_strategy__names
    FRIQ_const_reduction_strategy__names={};
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__MIN_Q}='MIN_Q';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__MAX_Q}='MAX_Q';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__HALF_GROUP_REMOVAL}='HALF_GROUP_REMOVAL';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__BUILD_MINANDMAXQ}='BUILD_MINANDMAXQ';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ANTECEDENT_REDUNDANCY}='ANTECEDENT_REDUNDANCY';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__FIRST}='ELIMINATE_DUPLICATED__FIRST';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MINQ}= 'ELIMINATE_DUPLICATED__MINQ';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MAXQ}= 'ELIMINATE_DUPLICATED__MAXQ';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ELIMINATE_DUPLICATED__MERGE_MEAN}='ELIMINATE_DUPLICATED__MERGE_MEAN';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__FIRST}='ELIMINATE_SIMILAR__FIRST';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MINQ}= 'ELIMINATE_SIMILAR__MINQ';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MAXQ}= 'ELIMINATE_SIMILAR__MAXQ';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__ELIMINATE_SIMILAR__MERGE_MEAN}='ELIMINATE_SIMILAR__MERGE_MEAN';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_ONE}= 'CLUSTER__KMEANS_REMOVE_ONE';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REMOVE_MANY}='CLUSTER__KMEANS_REMOVE_MANY';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_ONE}= 'CLUSTER__KMEANS_REPLACE_ONE';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__KMEANS_REPLACE_MANY}='CLUSTER__KMEANS_REPLACE_MANY';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_CENTROID}=  'CLUSTER__KMEANS_BUILD_CENTROID';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINANDMAXQ}='CLUSTER__KMEANS_BUILD_MINANDMAXQ';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MAXABSQ}='CLUSTER__KMEANS_BUILD_MAXABSQ';
    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__KMEANS_BUILD_MINABSQ}='CLUSTER__KMEANS_BUILD_MINABSQ';
%    FRIQ_const_reduction_strategy__names{FRIQ_const_reduction_strategy__CLUSTER__HIERARCHICAL}='CLUSTER__HIERARCHICAL';
