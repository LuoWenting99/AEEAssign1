%Purpose:
%   Main function of the software-defined radio (SDR) receiver platform
%
%--------------------------------------------------------------------------
%                           SoftXXXGPS v1.0
% 
% Copyright (C) X X  
% Written by X X

% 
clear; 
format long g;
addpath geo             %  
addpath acqtckpos       % Acquisition, tracking, and postiong calculation functions
addpath plot
addpath OpenSky_Result
addpath Urban_Result 



%% Parameter initialization 
[file, signal, acq, track, solu, cmn] = initParameters_OpenSky();

%% Acquisition 
if ~exist(['Acquired_',file.fileName,'_',num2str(file.skip),'.mat'])
    Acquired = acquisition_hs(file,signal,acq); %
    save(['Acquired_',file.fileName,'_',num2str(file.skip)],'Acquired');    
else
    load(['Acquired_',file.fileName,'_',num2str(file.skip),'.mat']);%
end 
fprintf('Acquisition Completed. \n\n');



%% Plot acquisition results
if exist('Acquired', 'var')
    plotAcquisition(Acquired, file.fileName); % Plotting Call
    fprintf('Acquisition plot generated.\n\n');
end

%% Do conventional signal tracking and obtain satellites ephemeris
fprintf('Tracking ... \n\n');
if ~exist(['eph_',file.fileName,'_',num2str(track.msToProcessCT/1000),'.mat'])
    % tracking using conventional DLL 
    fprintf('eph_exist');
    if ~exist(['TckResult_Eph',file.fileName,'_',num2str(track.msToProcessCT/1000),'.mat']) %
        [TckResultCT, CN0_Eph] =  trackingCT_V(file,signal,track,Acquired); 
        TckResult_Eph = TckResultCT;
        save(['TckResult_Eph',file.fileName,'_',num2str(track.msToProcessCT/1000)], 'TckResult_Eph','CN0_Eph');        
    else   
        load(['TckResult_Eph',file.fileName,'_',num2str(track.msToProcessCT/1000),'.mat']);
    end 
 
    % navigaion data decode
    fprintf('Navigation data decoding ... \n\n');
    [eph, ~, sbf] = naviDecode_updated(Acquired, TckResult_Eph);
    save(['eph_',file.fileName,'_',num2str(track.msToProcessCT/1000)], 'eph');
    save(['sbf_',file.fileName,'_',num2str(track.msToProcessCT/1000)], 'sbf');
%     save(['TckRstct_',file.fileName,'_',num2str(track.msToProcessCT/1000)], 'TckResultCT'); % Track results are revised in function naviDecode for 20 ms T_coh
else
    load(['eph_',file.fileName,'_',num2str(track.msToProcessCT/1000),'.mat']);
    load(['sbf_',file.fileName,'_',num2str(track.msToProcessCT/1000),'.mat']);
    load(['TckResult_Eph',file.fileName,'_',num2str(track.msToProcessCT/1000),'.mat']);
end 

%% Plot Multi-Satellite E/L/P Correlation Diagram
if exist('TckResult_Eph', 'var') && ~isempty(TckResult_Eph)
    fprintf('Generating multi-satellite correlation plot...\n');
    svList = Acquired.sv; % Satellite PRN list
    plotCorrelation(TckResult_Eph, svList);
    fprintf('Saved: ELP_Correlation_Multi.png\n\n');
end


%% Find satellites that can be used to calculate user position
posSV  = findPosSV(file,Acquired,eph);
fprintf('findPosSV finished');

%%  Find satellites that can be used to calculate user position
cnslxyz = llh2xyz(solu.iniPos); % initial position in ECEF coordinate
 
if cmn.vtEnable == 1    
    fprintf('Positioning (VTL) ... \n\n');
  
    % load data to initilize VT
    load(['nAcquired_',file.fileName,'_',num2str(file.skip),'.mat']); % load acquired satellites that can be used to calculate position  
    Acquired = nAcquired;  
    
    load(['eph_',file.fileName,'_',num2str(track.msToProcessCT/1000),'.mat']); % load eph
    load(['sbf_',file.fileName,'_',num2str(track.msToProcessCT/1000),'.mat']); % 
    
    load(['tckRstCT_1ms_',file.fileName,'.mat']);%,'_Grid'
    load(['navSolCT_1ms_',file.fileName,'.mat']); 
     
    [TckResultVT, navSolutionsVT] = ...
                  trackingVT_POS_updated(file,signal,track,cmn,solu,Acquired,cnslxyz,eph,sbf,TckResult_Eph, TckResultCT_pos,navSolutionsCT); 

else 
    load(['nAcquired_',file.fileName,'_',num2str(file.skip),'.mat']); % load acquired satellites that can be used to calculate position  
    Acquired = nAcquired;
    
    % WLS positioning mode£¨solu.mode=0£©
    if solu.mode == 0
        wls_filename = ['navSolCT_WLS_', num2str(track.pdi), 'ms_', file.fileName, '.mat'];
        if exist(wls_filename, 'file')
            % if file exits,directly save the results
            fprintf('WLS result exist, skipping calculation: %s\n', wls_filename);
            load(wls_filename, 'navSolutionsCT');
        else
            % File doesn't exist,perform WLS positioning and save the results
            fprintf('Running WLS Positioning...\n');
            [TckResultCT_POS, navSolutionsCT] = trackingCT_POS(...
                file,signal,track,cmn, Acquired,TckResult_Eph,cnslxyz,eph,sbf,solu...
                );

            save(wls_filename, 'navSolutionsCT'); 
        end
    end
    % ---------------------------------------------------------------------
    % EKF positioning mode£¨solu.mode=1£©
    if solu.mode == 1 
        ekf_filename = ['navSolCT_EKF_', num2str(track.pdi), 'ms_', file.fileName, '.mat'];        
        if exist(ekf_filename, 'file')
            % if file exits,directly save the results
            fprintf('EKF result exist, skipping calculation: %s\n', ekf_filename);
            load(ekf_filename, 'navSolutionsCT');
        else
             % File doesn't exist,perform EKF positioning and save the results
            fprintf('Running EKF Positioning...\n');
            [TckResultCT_POS, navSolutionsCT] = trackingCT_POS(...
                file,signal,track,cmn, Acquired,TckResult_Eph,cnslxyz,eph,sbf,solu...
              );
            save(ekf_filename, 'navSolutionsCT'); 
        end
    end
end
fprintf('Tracking and Positioing Completed.\n\n');

%% Plot Position Error Curve
MatPath=['navSolCT_WLS_', num2str(track.pdi), 'ms_', file.fileName, '.mat'];       
plotDir = 'D:/00_HK/Class_GNSS/Demo_V/New version Supporting 16bit - Copy/New version Supporting 16bit/'
SaveErrPosPng=fullfile(plotDir,['scatter_EKF_Pos',file.fileName,'plot.png']);
SaveVelPng=fullfile(plotDir,['scatter_EKF_Vel',file.fileName,'plot.png']);

%Plot WLS position error results
plotPositionScatter(MatPath, SaveErrPosPng);

%Plot EKF velocity results
plotVelocityScatter(MatPath,SaveVelPng);




