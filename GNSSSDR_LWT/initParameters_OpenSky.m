function [file, signal, acq, track, solu, cmn] = initParameters_OpenSky()
%Purpose:
%   Parameter initialization
%Inputs: 
%	None
%Outputs:
%	file        - parameters related to the data file to be processed,a structure
%	signal      - parameters related to signals,a structure
%	acq         - parameters related to signal acquisition,a structure
%	track       - parameters related to signal tracking,a structure
%	solu        - parameters related to navigation solution,a structure
%	cmn         - parameters commmonly used,a structure
%--------------------------------------------------------------------------
%                           SoftXXXGPS v1.0
% 
% Copyright (C) X X
% Written by X X

%% File parameters
file.fileName       = 'Opensky';  
file.fileRoute      = ['D:\00_HK\Class_GNSS\Demo_V\New version Supporting 16bit - Copy\New version Supporting 16bit\DataSample\',file.fileName,'.bin'];  
file.skip        	= 0; % in unit of ms
solu.iniPos	= [22.328444770087565/180 * pi, 114.1713630049711/180 * pi, 3]; % Ground truth location 
global ALPHA BETA % Parameters for iono. and trop. correction; From RINEX file
ALPHA = [0.1118e-07  0.7451e-08 -0.5960e-07 -0.5960e-07];
BETA  = [0.9011e+05  0.1638e+05 -0.1966e+06 -0.6554e+05];  
cmn.doy = 273; % Day of year 

%% File parameters
file.fid           	= fopen(file.fileRoute,'r','ieee-le');
file.skiptimeVT     = 1000; % skip time from the first measurement epoch of CT, in uint of msec
file.dataType       = 2;    %1:I; 2:IQ
file.dataPrecision  = 1;    %1:int8 or byte; 2; int16 

%% Signal parameters
signal.IF               = 4.58e6; % unit: Hz 
signal.Fs               = 58e6;	% unit: Hz
signal.Fc               = 1575.42e6; % unit: Hz	
signal.codeFreqBasis	= 1.023e6; % unit: Hz 	
signal.ms               = 1e-3; % unit: s
signal.Sample           = ceil(signal.Fs*signal.ms);	
signal.codelength       = signal.codeFreqBasis * signal.ms;

%% Acquisition parameters
acq.prnList     = 1:32;	% PRN list
acq.freqStep    = 500;	% unit: Hz
acq.freqMin     = -10000;   % Minimum Doppler frequency
acq.freqNum     = 2*abs(acq.freqMin)/acq.freqStep+1;    % number of frequency bins
acq.L           = 10;   % number of ms to perform FFT

%% Tracking parameters
track.mode                  = 0;    % 0:conventional tracking; 1:vector tracking
track.CorrelatorSpacing  	= 0.1;  % unit: chip
track.DLLBW               	= 2;	% unit: Hz
track.DLLDamp           	= 0.707; 
track.DLLGain            	= 0.1;	
track.PLLBW              	= 15;
track.PLLDamp             	= 0.707;
track.PLLGain              	= 0.25; 	
track.msToProcessCT       	= 90000; % unit: ms 40000
track.msPosCT               = 90000; % unit: ms
track.msToProcessVT         = 89000; %track.msPosCT - file.skiptimeVT; %
track.pdi                   = 1; %

%% Navigation solution parameters
solu.navSolPeriod = 20; % unit: ms 
solu.mode  	= 0;    % 0:conventional WLS; 1:conventional EKF


%% commonly used parameters
cmn.vtEnable  	= 0;%   % 0: disable vector tracking; 1:enable vector tracking
cmn.cSpeed      = 299792458;    % speed of light, [m/s]

%% end

