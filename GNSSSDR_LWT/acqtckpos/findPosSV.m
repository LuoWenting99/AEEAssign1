function  posSV = findPosSV(file,Acquired,ephemeris)
%Purpose
%   Vector tracking and positioning
%Inputs: 
%	file        - parameters related to the data file to be processed,a structure 
%	Acquired 	- acquisition results
%	ephemeris         - ephemeris 
%Outputs:
%	posSV     	- satellites that can be used to calculation user position
%--------------------------------------------------------------------------
%                           SoftXXXGPS v1.0
%This function filters out valid satellites based on the ephemeris, 
% ensuring the accuracy of subsequent positioning calculations, while organizing and saving the refined satellite data.
% Copyright (C) X X
% Written by X X

%% 
sv = Acquired.sv;
posSV           = [];
maxEphUptTime   = 0;
idx             = 0;
for svindex = 1 : length(Acquired.sv) %Traverse all satellites
    prn = sv(svindex);
    if ephemeris(prn).updateflag == 1 %Check if the ephemeris for each satellite has been updated
        idx = idx + 1;
        posSV = [posSV prn];%If the ephemeris has been updated, add the satellite's PRN number to the output list posSV
        if ephemeris(prn).updatetime(1) > maxEphUptTime
            maxEphUptTime = ephemeris(prn).updatetime(1);%Record the latest ephemeris update time among all selected satellites (maxEphUptTime)
        end
        nAcquired.sv(idx)           = prn;
        nAcquired.SNR(idx)          = Acquired.SNR(svindex);
        nAcquired.Doppler(idx)      = Acquired.Doppler(svindex);
        nAcquired.codedelay(idx)    = Acquired.codedelay(svindex);
        nAcquired.fineFreq(idx)     = Acquired.fineFreq(svindex);
        %Copy the satellite signal information (such as SNR, Doppler shift, etc.) of the qualifying satellites to a new structure nAcquired
    end
end
save(['nAcquired_',file.fileName,'_',num2str(file.skip)],'nAcquired');%Save the file



