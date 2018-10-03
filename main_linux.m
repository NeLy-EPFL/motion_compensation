function main_linux(pathToData, varargin)
%% Description
% Motion is estimated with a brigthness constancy data term and a feature 
% matching similarity term. The sequences are warped according to the 
% estimated motion field.
% For more details see the paper: "Imaging neural activity in the ventral
% nerve cord of behaving adult Drosophila", bioRxiv
% 
% This function serves primarily as a basis to create an executable on Linux.
% 
%% Input
% pathToData: path to the folder containing the sequences in TIF format.
%             It should contain two files:
%               - tdTom.tif: sequence used for the brightness constancy
%               term and feature matching similarity term
%               - GC6*.tif: sequence warped with the motion field. Note
%               that the name should start with 'GC6' (any capitalization 
%               patern, e.g.: GC6, Gc6, gc6,...). If multiple exist, only 
%               the first found is used.
% 
%% Optional Input
% Optional input should be used as `-option` or `-option VALUE`. Order of
% the optional inputs does not matter.
% -h or -help: ignore the whole program and print the help message
% -l VALUE: regularization parameter lambda, default is 1000.
%           Can be multiple values, e.g.: "[100 500 1000]" 
% -g VALUE: strength of the feature matching constraint gamma, default is 100.
%           Can be multiple values, e.g.: "[10 50 100]" 
% -N VALUE: number of frames to process (use -1 for all frames), default is -1
% -results_dir PATH: path to the result folder, default is 'results/'
% 
%% Examples
% The executable has to be launched through the run_*.sh script with MATLAB
% or MCR root as the first argument. To simplify this, make an alias.
% E.g.: alias motion_compensation="run_motion_compensation.sh /usr/local/MATLAB/R2018a"
% Then, use it as any command:
%   $ motion_compensation -help
%   $ motion_compensation data/experiment_1 -l 500 -g 100 -results_dir results_1 
%   $ motion_compensation data/experiment_2 -results_dir results_2 -g 10
%   $ motion_compensation data/experiment_3 -mac -N 5

%% Input - Output initialization
% Boolean to see if we perform multi motion compensation (i.e. multiple lambas/gammas)
multi_compensation = false;

% Parse varargin for the optional inputs
% Help message
if sum(strcmp(varargin, '-h')) || sum(strcmp(varargin, '-help')) || ...
        strcmp(pathToData, '-h') || strcmp(pathToData, '-help') % can be used without giving pathToData
    fprintf([
        'Usage: motion_compensation pathToData [-option | -option VALUE]\n\n' ...
        '    pathToData         - Path to the folder containing the 2 sequences:\n' ...
        '                           1. tdTom.tif: used for computing the motion field\n' ...
        '                           2. GC6*.tif: sequence to be warped by the motion\n' ...
        '                                        field (capitalization does not matter)\n\n' ...
        '    -h|-help           - Display this help message\n' ...
        '    -l VALUE           - Regularization parameter lambda, default is 1000\n' ...
        '                         Can be multiple values, e.g.: -l "[100 500 1000]"\n' ...
        '    -g VALUE           - Strength of the feature matching constraint gamma,\n' ...
        '                         default is 100\n' ...
        '                         Can be multiple values, e.g.: -g "[10 50 100]"\n' ...
        '    -N VALUE           - Number of frames to process (use -1 for all frames),\n' ...
        '                         default is -1\n' ...
        '    -results_dir PATH  - Path to the result folder, default is results/\n\n' ...
        'Examples:\n' ...
        '  $ motion_compensation data/experiment_1 -l 500 -g 100 -result_dir results_1\n' ... 
        '  $ motion_compensation data/experiment_2 -result_dir results_2 -g "[10 20]"\n' ...
        '  $ motion_compensation data/experiment_3 -N 5\n'])
    return
end
% Lambda(s) parameter
if sum(strcmp(varargin, '-l')) 
    lambdaIndex = find(strcmp(varargin, '-l'));
    lambda = str2num(varargin{lambdaIndex + 1});
    if ~isscalar(lambda)
        lambdas = lambda;
        multi_compensation = true;
    end
else
    lambda = 1000;
end
% Gamma(s) parameter
if sum(strcmp(varargin, '-g')) 
    gammaIndex = find(strcmp(varargin, '-g'));
    gamma = str2num(varargin{gammaIndex + 1});
    if ~isscalar(gamma)
        gammas = gamma;
        multi_compensation = true;
    end
else
    gamma = 100;
end
% Number of frames to process
% Motion is estimated on frames 1 to N. If N == -1, motion is estimated on
% the whole sequence
if sum(strcmp(varargin, '-N')) 
    NIndex = find(strcmp(varargin, '-N'));
    N = str2double(varargin{NIndex + 1});
    if N == 1
        fprintf('Requires at least 2 frames to process a motion field.\n')
        return
    end
else
    N = -1;
end
% Results folder
if sum(strcmp(varargin, '-results_dir')) 
    fnSaveIndex = find(strcmp(varargin, '-results_dir'));
    fnSave = varargin{fnSaveIndex + 1};
else
    fnSave = 'results/';
end

% Initialize filenames
fnMatch = fullfile(pathToData, 'tdTom.tif');  % Sequence used for the feature matching similarity term
fnIn1 = fullfile(pathToData, 'tdTom.tif');    % Sequence used for the brightness constancy term 
% Find sequence warped with the motion field estimated from fnIn1 and fnMatch
dataFiles = dir(pathToData);
matchingFn = regexp({dataFiles.name}, '^GC6.*\.tif$', 'match', 'once', 'ignorecase');
gc6Fn = matchingFn{find(~cellfun(@isempty, matchingFn), 1)}; % find the first 'GC6*.tif' match
fnIn2 = fullfile(pathToData, gc6Fn);

fnOut1 = fullfile(fnSave, 'tdTom_warped.tif');    % Sequence fnIn1 warped
fnOut2 = fullfile(fnSave, [gc6Fn(1:end-4) '_warped.tif']);    % Sequence fnIn2 warped
fnColor = fullfile(fnSave, 'colorFlow.tif'); % Color visualization of the motion field

% Create results folder if not already existing
if ~exist(fnSave, 'dir')
    mkdir(fnSave);
end


%% Set Paths
% Uses the setPath.m script to find correct paths
% Path to ij.jar and mij.jar should be edited there !
setPath;

% Folder of the DeepMatching executable
fnDeepMatching = fullfile(path_mc, 'code/external/deepmatching_1.2.2_c++_linux');


%% Start parallel pool
poolobj = gcp('nocreate');
if isempty(poolobj)
    parpool;
end

%% Perform motion compensation
if ~multi_compensation
    % Parameters
    param = default_parameters();
    param.lambda = lambda;    % Regularization parameter
    param.gamma = gamma;      % Sets the strength of the feature matching constraint

    motion_compensate(fnIn1, fnIn2, fnMatch, fnDeepMatching, ...
                      fnOut1, fnOut2, fnColor, N, param);
end
              
%% Perform parallelized motion compensation for multiple lambdas and gammas
% In addition to the output of motion_compensate, it saves images of the 
% vector fields and several metrics to judge registration quality:
%   cY = correlation coefficient of each frame with the mean
%   mY = mean image
%   ng = norm of gradient of mean image

if multi_compensation
    % Parameters
    param = default_parameters();
    
    % Make sure that we have all variables
    if ~exist('lambdas', 'var')
        lambdas = lambda;
    end
    if ~exist('gammas', 'var')
        gammas = gamma;
    end
    
    % Create output folders
    outdir = cell(length(lambdas) * length(gammas), 1);
    idx = 1;
    for l = lambdas
        for g = gammas
           outdir(idx) = cellstr(fullfile(fnSave, ['l' num2str(l) 'g' num2str(g)]));
           if ~exist(char(outdir(idx)), 'dir')
               mkdir(char(outdir(idx)));
           end
           idx = idx + 1;
       end
    end
    
    multi_motion_compensate(fnIn1, fnIn2, fnMatch, fnDeepMatching, ...
                            N, param, outdir, lambdas, gammas)
end
