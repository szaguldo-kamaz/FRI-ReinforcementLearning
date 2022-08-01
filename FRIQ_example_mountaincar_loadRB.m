% MountainCar Problem example - Load a previously constructed RB
% with FRI-based Reinforcement Learning
%
% FRIQ-learning framework v0.60
% https://github.com/szaguldo-kamaz/
%
% Author: David Vincze <david.vincze@uni-miskolc.hu>
% Copyright (c) 2013-2022 by David Vincze
%

clear all;
close all;

global FRIQ_param_norandom  FRIQ_param_construct_rb FRIQ_param_reduce_rb FRIQ_param_drawsim
global FRIQ_param_test_previous_rb FRIQ_param_test_previous_rb_filename

FRIQ_init_constants();
FRIQ_example_mountaincar_setup();

FRIQ_param_norandom                     = 1;
FRIQ_param_construct_rb                 = 0;
FRIQ_param_reduce_rb                    = 0;
FRIQ_param_test_previous_rb             = 1;
FRIQ_param_test_previous_rb_filename    = 'rulebases\FRIQ_example_mountaincar_incrementally_constructed_RB.csv';
FRIQ_param_drawsim                      = false; % indicates whether to display the graphical interface or not

FRIQ_mainloop();

clear all;
close all;
