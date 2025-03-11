function  [TckResultCT, CN0_Eph] = trackingCT_V(file,signal,track,Acquired)
%Purpose:
%   Perform signal tracking using conventional DLL and PLL
%Inputs:
%	file        - parameters related to the data file to be processed
%	signal      - parameters related to signals,a structure
%	track       - parameters related to signal tracking 
%	Acquired    - acquisition results
%Outputs:
%	TckResultCT	- conventional tracking results, e.g. correlation values in 
%                   inphase prompt (P_i) channel and in qudrature prompt 
%                   channel (P_q), etc.
%--------------------------------------------------------------------------
%                           SoftXXXGPS v1.0
% 
% Copyright (C) X X
% Written by X X 

%%
% Spacing = [ -track.CorrelatorSpacing 0 track.CorrelatorSpacing]; %[-0.5 0 0.5]
Spacing = [-0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5]; 

[tau1code, tau2code] = calcLoopCoef(track.DLLBW,track.DLLDamp,track.DLLGain);
[tau1carr, tau2carr] = calcLoopCoef(track.PLLBW,track.PLLDamp,track.PLLGain);

datalength = track.msToProcessCT;
delayValue = zeros(length(Acquired.sv),datalength);


svlength    = length(Acquired.sv);
snrIndex	= ones(1,svlength);
K           = 20;
flag_snr    = ones(1,svlength); % flag to calculate C/N0
index_int   = zeros(1,svlength);
pdi     = 1;%track.pdi; % To decode eph., 1ms T_coh is used. 
sv  = Acquired.sv;

for svindex = 1:length(Acquired.sv)
    remChip = 0;
    remPhase=0;
    remSample = 0;
    carrier_output=0; 
    carrier_outputLast=0;
    PLLdiscriLast=0;
    code_output=0;
    code_outputLast=0;
    DLLdiscriLast=0;
    Index = 0;
    AcqDoppler = Acquired.fineFreq(svindex)-signal.IF;
    AcqCodeDelay = Acquired.codedelay(svindex);
    
    Codedelay = AcqCodeDelay;
    codeFreq = signal.codeFreqBasis;
    carrierFreqBasis = Acquired.fineFreq(svindex);
    carrierFreq = Acquired.fineFreq(svindex);
    
    % set the file position indicator according to the acquired code delay
%     fseek(file.fid,(signal.Sample-AcqCodeDelay-1+file.skip*signal.Sample)*file.dataPrecision*file.dataType,'bof');  %
    fseek(file.fid,(signal.Sample-AcqCodeDelay+1 + file.skip*signal.Sample)*file.dataPrecision*file.dataType,'bof');  %  29/04/2020
%     fseek(file.fid,(AcqCodeDelay-1+file.skip*signal.Sample)*file.dataPrecision*file.dataType,'bof');  %
    
    Code = generateCAcode(Acquired.sv(svindex));
    Code = [Code(end) Code Code(1)];
    
    h = waitbar(0,['Ch:',num2str(svindex),' Please wait...']);
    
    for IndexSmall = 1: datalength 
        waitbar(IndexSmall/datalength)
        Index = Index + 1;
        
        
        remSample = ((signal.codelength-remChip) / (codeFreq/signal.Fs));
        numSample = round((signal.codelength-remChip)/(codeFreq/signal.Fs));%ceil
        delayValue(svindex,IndexSmall) = numSample - signal.Sample;
        
        if file.dataPrecision == 2
            rawsignal = fread(file.fid,numSample*file.dataType,'int16')'; 
%             rawsignal = rawsignal(1:2:length(rawsignal)) + 1i*rawsignal(2:2:length(rawsignal));% For NSL STEREO LBand only
            sin_rawsignal = rawsignal(1:2:length(rawsignal));
            cos_rawsignal = rawsignal(2:2:length(rawsignal));
            rawsignal0DC = sin_rawsignal - mean(sin_rawsignal) + 1i*(cos_rawsignal-mean(cos_rawsignal));
        else
            rawsignal0DC = fread(file.fid,numSample*file.dataType,'int8')';
            if file.dataType == 2
            rawsignal0DC = rawsignal0DC(1:2:length(rawsignal0DC)) + 1i*rawsignal0DC(2:2:length(rawsignal0DC));% For NSL STEREO LBand only 
            end
        end
        
%         t_CodeEarly    = (0 + Spacing(1) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(1) + remChip);
%         t_CodePrompt   = (0 + Spacing(2) + remChip ) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(2) + remChip);
%         t_CodeLate     = (0 + Spacing(3) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(3) + remChip);
        % 替换原有的 E_i/P_i/L_i 计算逻辑
        
        
        % 新增变量定义（示例，根据实际代码调整变量名）
        t_CodeE  = (0 + Spacing(1) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(1) + remChip);
        t_CodeE4  = (0 + Spacing(2) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(2) + remChip);
        t_CodeE3  = (0 + Spacing(3) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(3) + remChip);
        t_CodeE2  = (0 + Spacing(4) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(4) + remChip);
        t_CodeE1  = (0 + Spacing(5) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(5) + remChip);
        t_CodeP   = (0 + Spacing(6) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(6) + remChip);
        t_CodeL1  = (0 + Spacing(7) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(7) + remChip);
        t_CodeL2  = (0 + Spacing(8) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(8) + remChip);
        t_CodeL3  = (0 + Spacing(9) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(9) + remChip);
        t_CodeL4  = (0 + Spacing(10) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(10) + remChip);
        t_CodeL  = (0 + Spacing(11) + remChip) : codeFreq/signal.Fs : ((numSample -1) * (codeFreq/signal.Fs) + Spacing(11) + remChip);

        % 生成各点码序列
        CodeE  = Code(ceil(t_CodeE) + 1);
        CodeE4  = Code(ceil(t_CodeE4) + 1);
        CodeE3  = Code(ceil(t_CodeE3) + 1);
        CodeE2  = Code(ceil(t_CodeE2) + 1);
        CodeE1  = Code(ceil(t_CodeE1) + 1);
        CodeP   = Code(ceil(t_CodeP) + 1);
        CodeL1  = Code(ceil(t_CodeL1) + 1);
        CodeL2  = Code(ceil(t_CodeL2) + 1);
        CodeL3  = Code(ceil(t_CodeL3) + 1);
        CodeL4  = Code(ceil(t_CodeL4) + 1);
        CodeL  = Code(ceil(t_CodeL) + 1);
        
        remChip   = (t_CodeP(numSample) + codeFreq/signal.Fs) - signal.codeFreqBasis*signal.ms;
        
        CarrTime = (0 : numSample)./signal.Fs;
        Wave     = (2*pi*(carrierFreq .* CarrTime)) + remPhase ;  
        remPhase =  rem( Wave(numSample+1), 2*pi); 
        carrsig = exp(1i.* Wave(1:numSample));
        InphaseSignal    = imag(rawsignal0DC .* carrsig);
        QuadratureSignal = real(rawsignal0DC .* carrsig);
        
%         E_i  = sum(CodeEarly    .*InphaseSignal);  E_q = sum(CodeEarly    .*QuadratureSignal);
%         P_i  = sum(CodePrompt   .*InphaseSignal);  P_q = sum(CodePrompt   .*QuadratureSignal);
%         L_i  = sum(CodeLate     .*InphaseSignal);  L_q = sum(CodeLate     .*QuadratureSignal);
        
        % 计算所有相关点
        E_i = sum(CodeE .* InphaseSignal);   E_q = sum(CodeE .* QuadratureSignal);
        E4_i = sum(CodeE4 .* InphaseSignal);   E4_q = sum(CodeE4 .* QuadratureSignal);
        E3_i = sum(CodeE3 .* InphaseSignal);   E3_q = sum(CodeE3 .* QuadratureSignal);
        E2_i = sum(CodeE2 .* InphaseSignal);   E2_q = sum(CodeE2 .* QuadratureSignal);
        E1_i = sum(CodeE1 .* InphaseSignal);   E1_q = sum(CodeE1 .* QuadratureSignal);
        P_i  = sum(CodeP  .* InphaseSignal);  P_q  = sum(CodeP  .* QuadratureSignal);
        L1_i = sum(CodeL1 .* InphaseSignal);   L1_q = sum(CodeL1 .* QuadratureSignal);
        L2_i = sum(CodeL2 .* InphaseSignal);   L2_q = sum(CodeL2 .* QuadratureSignal);
        L3_i = sum(CodeL3 .* InphaseSignal);   L3_q = sum(CodeL3 .* QuadratureSignal);
        L4_i = sum(CodeL4 .* InphaseSignal);   L4_q = sum(CodeL4 .* QuadratureSignal);
        L_i = sum(CodeL .* InphaseSignal);   L_q = sum(CodeL .* QuadratureSignal);
           
                
        % Calculate CN0
        flag_snr(svindex)=1;
        if (flag_snr(svindex) == 1)
            index_int(svindex) = index_int(svindex) + 1;
            Zk(svindex,index_int(svindex)) = P_i^2 + P_q^2;
            if mod(index_int(svindex),K) == 0
                meanZk  = mean(Zk(svindex,:));
                varZk   = var(Zk(svindex,:));
                NA2     = sqrt(meanZk^2-varZk);
                varIQ   = 0.5 * (meanZk - NA2);
                CN0_Eph(snrIndex(svindex),svindex) =  abs(10*log10(1/(1*signal.ms*pdi) * NA2/(2*varIQ)));
                index_int(svindex)  = 0;
                snrIndex(svindex)   = snrIndex(svindex) + 1;
            end
        end
        
        % DLL
        E               = sqrt(E_i^2+E_q^2);
        L               = sqrt(L_i^2+L_q^2);
        P               = sqrt(P_i^2+P_q^2);
        DLLdiscri       = 0.5 * (E-L)/(E+L);
        code_output     = code_outputLast + (tau2code/tau1code)*(DLLdiscri - DLLdiscriLast) + DLLdiscri* (0.001/tau1code);
        DLLdiscriLast   = DLLdiscri;
        code_outputLast = code_output;
        codeFreq        = signal.codeFreqBasis - code_output;
        
        % PLL
        PLLdiscri           = atan(P_q/P_i) / (2*pi);
        carrier_output      = carrier_outputLast + (tau2carr/tau1carr)*(PLLdiscri - PLLdiscriLast) + PLLdiscri * (0.001/tau1carr);
        carrier_outputLast  = carrier_output;  
        PLLdiscriLast       = PLLdiscri;
        carrierFreq         = carrierFreqBasis + carrier_output;  % Modify carrier freq based on NCO command
        
        % Data Record
%         TckResultCT(Acquired.sv(svindex)).P_i(Index)            = P_i;
%         TckResultCT(Acquired.sv(svindex)).P_q(Index)            = P_q;
%         TckResultCT(Acquired.sv(svindex)).E_i(Index)            = E_i;
%         TckResultCT(Acquired.sv(svindex)).E_q(Index)            = E_q;
%         TckResultCT(Acquired.sv(svindex)).L_i(Index)            = L_i;
%         TckResultCT(Acquired.sv(svindex)).L_q(Index)            = L_q;

        
        TckResultCT(Acquired.sv(svindex)).E_i(Index) = E_i;
        TckResultCT(Acquired.sv(svindex)).E_q(Index) = E_q;
        TckResultCT(Acquired.sv(svindex)).E4_i(Index) = E4_i;
        TckResultCT(Acquired.sv(svindex)).E4_q(Index) = E4_q;
        TckResultCT(Acquired.sv(svindex)).E3_i(Index) = E3_i;
        TckResultCT(Acquired.sv(svindex)).E3_q(Index) = E3_q;
        TckResultCT(Acquired.sv(svindex)).E2_i(Index) = E2_i;
        TckResultCT(Acquired.sv(svindex)).E2_q(Index) = E2_q;
        TckResultCT(Acquired.sv(svindex)).E1_i(Index) = E1_i;
        TckResultCT(Acquired.sv(svindex)).E1_q(Index) = E1_q;
        TckResultCT(Acquired.sv(svindex)).P_i(Index) = P_i;
        TckResultCT(Acquired.sv(svindex)).P_q(Index) = P_q;
        TckResultCT(Acquired.sv(svindex)).L1_i(Index) = L1_i;
        TckResultCT(Acquired.sv(svindex)).L1_q(Index) = L1_q;
        TckResultCT(Acquired.sv(svindex)).L2_i(Index) = L2_i;
        TckResultCT(Acquired.sv(svindex)).L2_q(Index) = L2_q;
        TckResultCT(Acquired.sv(svindex)).L3_i(Index) = L3_i;
        TckResultCT(Acquired.sv(svindex)).L3_q(Index) = L3_q;
        TckResultCT(Acquired.sv(svindex)).L4_i(Index) = L4_i;
        TckResultCT(Acquired.sv(svindex)).L4_q(Index) = L4_q;
        TckResultCT(Acquired.sv(svindex)).L_i(Index) = L_i;
        TckResultCT(Acquired.sv(svindex)).L_q(Index) = L_q;

        TckResultCT(Acquired.sv(svindex)).PLLdiscri(Index)      = PLLdiscri;
        TckResultCT(Acquired.sv(svindex)).DLLdiscri(Index)      = DLLdiscri;
        TckResultCT(Acquired.sv(svindex)).codedelay(Index)      = Codedelay + sum(delayValue(1:Index));
        TckResultCT(Acquired.sv(svindex)).remChip(Index)        = remChip;
        TckResultCT(Acquired.sv(svindex)).codeFreq(Index)       = codeFreq;  
        TckResultCT(Acquired.sv(svindex)).carrierFreq(Index)    = carrierFreq;  
        TckResultCT(Acquired.sv(svindex)).remPhase(Index)       = remPhase;
        TckResultCT(Acquired.sv(svindex)).remSample(Index)      = remSample;
        TckResultCT(Acquired.sv(svindex)).numSample(Index)      = numSample;
        TckResultCT(Acquired.sv(svindex)).delayValue(Index)     = delayValue(svindex,IndexSmall);
        TckResultCT(Acquired.sv(svindex)).absoluteSample(Index)  = ftell(file.fid); 
        TckResultCT(Acquired.sv(svindex)).codedelay2(Index)       = mod( TckResultCT(Acquired.sv(svindex)).absoluteSample(Index)/(file.dataPrecision*file.dataType),signal.Fs*signal.ms);
    end
    close(h);
end % end for

