function motion_compensate(fnInput1,fnInput2,fnMatch,fnDeepMatching,fnOut1,fnOut2,fnColor,N,step,param)
%% Description
% Motion is estimated with a brigthness constancy data term defined on fnInput1 
% and a feature matching similarity term defined on fnMatch. The sequences fnIput1 and
% fnInput2 are warped according to the estimated motion field.
% For more details see the paper: "Imaging neural activity in the ventral
% nerve cord of behaving adult Drosophila", bioRxiv
%
%% Input
% fnInput1: filename of the  sequence used for the brightness constancy term, in TIF format
% fnInput2: filename of the sequence warped with the motion field estimated from fnInput1 and fnMatch, in TIF format
% fnMatch: filename of the sequence used for feature matching, in TIF format
% fnDeepMatching: filename of the deepmatching code
% fnOut1: filename used to save the warped version of fnInput1, in TIF format
% fnOut2: filename used to save the warped version of fnInput2, in TIF format
% fnOut2: filename used to save the color visualization of the estimated motion, in TIF format
% N: number of frames to process
% param: parameters of the algorithm (see 'default_parameters.m')
%
%     Copyright (C) 2017 D. Fortun, denis.fortun@epfl.ch
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.

%% Temp folder
start_time = datestr(now, 'yyyymmddHHMM');
tmpdir = ['tmp', start_time];
if ~exist(tmpdir, 'dir')
    mkdir(tmpdir);
end

%% Input data
original_seq=mijread_stack(fnInput1);

if N==-1
    N=size(original_seq,3);
end
if step==-1
    step = N;
end

for N1=1:step:N
    original_seq=mijread_stack(fnInput1);
    %whos original_seq
    original_seqW=mijread_stack(fnInput2);
    %whos original_seqW
    original_seqMatch=mijread_stack(fnMatch);
    %whos original_seqMatch

    N2=min(N1+step, N);
    seq=double(cat(3, original_seq(:,:,1), original_seq(:,:,N1:N2)));
    % whos seq
    seqRescale=(seq-min(seq(:)))/(max(seq(:))-min(seq(:)))*255;
    % whos seqRescale
    seqW=double(cat(3, original_seqW(:,:,1), original_seqW(:,:,N1:N2)));
    % whos seqW
    seqMatch=double(cat(3, original_seqMatch(:,:,1), original_seqMatch(:,:,N1:N2)));
    % whos seqMatch
    seqMatch=(seqMatch-min(seqMatch(:)))/(max(seqMatch(:))-min(seqMatch(:)))*255;
    % whos seqMatch

    clear original_seq original_seqW original_seqMatch
    
    %% Motion estimation
    w=zeros(size(seqRescale,1),size(seqRescale,2),2,size(seqRescale,3)-1);
    %colorFlow=zeros(size(seqRescale,1),size(seqRescale,2),3,size(seqRescale,3)-1);
    i1=seqRescale(:,:,1);
    i1Match=seqMatch(:,:,1);
    parfor t=1:step%-1 % Replace parfor by for if you don't want to parallelize
        fprintf('Frame %i\n',t);
        i2=seqRescale(:,:,t+1);
        i2Match=seqMatch(:,:,t+1);
    
        [i10,i2]=midway(i1,i2);
    
        w(:,:,:,t) = compute_motion(i10,i2,i1Match,i2Match,fnDeepMatching,param,t, tmpdir);
        %colorFlow(:,:,:,t)=flowToColor(w(:,:,:,t));
    end
    
    clear i1 i1Match seqMatch seqRescale
    
    %% Registration
    seqWarped=seq;
    seqwWarped=seqW;
    
    for t=1:step%-1
        seqWarped(:,:,t+1)=warpImg(seq(:,:,t+1), w(:,:,1,t), w(:,:,2,t));
        seqwWarped(:,:,t+1)=warpImg(seqW(:,:,t+1), w(:,:,1,t), w(:,:,2,t));
    end
    
    clear seq seqRescale seqW w seqMatch
    
    % Save
    if isfile(fnOut1)
        previous=mijread_stack(fnOut1);
        %mijwrite_stack(single(cat(3, previous, seqWarped(:,:,2:end))), fnOut1);
        mijwrite_stack(cat(3, previous, uint16(seqWarped(:,:,2:end))), fnOut1);
        fprintf(strcat('fnOut1 updated with frames', {' '}, num2str(N1), {' '}, 'to', {' '}, num2str(N2), '\n'))
    else
        %mijwrite_stack(single(seqWarped(:,:,2:end)), fnOut1);
        mijwrite_stack(uint16(seqWarped(:,:,2:end)), fnOut1);
        fprintf(strcat('fnOut1 updated with frames', {' '}, num2str(N1), {' '}, 'to', {' '}, num2str(N2), '\n'))
    end
    if isfile(fnOut2)
        previous=mijread_stack(fnOut2);
        %mijwrite_stack(single(cat(3, previous, seqWarped(:,:,2:end))), fnOut2);
        mijwrite_stack(cat(3, previous, uint16(seqWarped(:,:,2:end))), fnOut2);
        fprintf(strcat('fnOut2 updated with frames', {' '}, num2str(N1), {' '}, 'to', {' '}, num2str(N2), '\n'))
    else
        %mijwrite_stack(single(seqwWarped(:,:,2:end)), fnOut2);
        mijwrite_stack(uint16(seqwWarped(:,:,2:end)), fnOut2);
        fprintf(strcat('fnOut2 updated with frames', {' '}, num2str(N1), {' '}, 'to', {' '}, num2str(N2), '\n'))
    end
    %mijwrite_stack(single(colorFlow),fnColor,1);
end

if exist(tmpdir, 'dir')
    rmdir(tmpdir, 's');
end
