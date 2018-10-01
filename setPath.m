%% Lines to edit
fnIJ  = '/usr/local/MATLAB/R2018a/java/jar/ij.jar';    % Path to "ij.jar"
fnMIJ = '/usr/local/MATLAB/R2018a/java/jar/mij.jar';   % Path to "mij.jar"
path_mc = '~/talabot/motion_compensation'; % Path to motion_compensation

% Add paths
javaaddpath(fnIJ);
javaaddpath(fnMIJ);

% Add paths if not a deployed app
if ~isdeployed
    addpath('code');
    addpath('code/external/utils');
    addpath(genpath('code/external/InvPbLib'));
end
