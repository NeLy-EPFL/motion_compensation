%% Lines to edit
fnIJ  = '/home/aymanns/motion_compensation/code/external/ij.jar';    % Path to "ij.jar"
fnMIJ = '/home/aymanns/motion_compensation/code/external/mij.jar';   % Path to "mij.jar"
path_mc = '~/motion_compensation'; % Path to motion_compensation

% Add paths
javaaddpath(fnIJ);
javaaddpath(fnMIJ);

% Add paths if not a deployed app
if ~isdeployed
    addpath('code');
    addpath('code/external/utils');
    addpath(genpath('code/external/InvPbLib'));
end
