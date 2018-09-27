%% Lines to edit
fnIJ='/usr/local/MATLAB/R2018a/java/jar/ij.jar';     % Path to "ij.jar"
fnMIJ='/usr/local/MATLAB/R2018a/java/jar/mij.jar';   % Path to "mij.jar"

%%
javaaddpath(fnIJ);
javaaddpath(fnMIJ);
addpath('code');
addpath('code/external/utils');
addpath(genpath('code/external/InvPbLib'));
