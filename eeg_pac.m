% eeg_pac() - Given to time series (continues of epoched),compute cross-frequency-coupling 
%             (currently phase-amplitude coupling only). There is no graphical output to 
%             this function.   
%
% Usage:
%   >> eeg_pac(x,y,srate);
%   >> [crossfcoh, timesout1, freqs1, freqs2, alltfX, alltfY,crossfcoh_pval, pacstruct] ...
%                     = eeg_pac(x,y,srate,'key1', 'val1', 'key2', val2' ...);
% Inputs:
%    x       - [float array] 2-D data array of size (times,trials) or
%              3-D (1,times,trials). Note that data channel dimensions is 1.
%    y       - [float array] 2-D data array of size (times,trials) or
%              3-D (1,times,trials). Note that data channel dimensions is 1.
%    srate   - data sampling rate (Hz)
%
%    Most important optional inputs
%       'alpha'     - Significance level of the statistical test. If
%                     empty no statistical test is done. Empty by Default.                     
%       'bonfcorr'  - Logical. Apply Bonferroni correction to the alpha value
%                     if true. Default [false]
%       'freqs'     - [min max] frequency limits. Default [minfreq 50], 
%                     minfreq being determined by the number of data points, 
%                     cycles and sampling frequency. Use 0 for minimum frequency
%                     to compute default minfreq. You may also enter an 
%                     array of frequencies for the spectral decomposition
%                     (for FFT, closest computed frequency will be returned; use
%                     'padratio' to change FFT freq. resolution).
%       'freqs2'    - [float array] array of frequencies for the second
%                     argument. 'freqs' is used for the first argument. 
%                     By default it is the same as 'freqs'.
%       'method' - {'mvlmi', 'klmi', 'glm'} Method to be use
%                     to compute the phase amplitude coupling. 
%                     mvlmi : Mean Vector Length Modulation Index (Canolty et al. 2006)
%                     klmi  : Kullback-Leibler Modulation Index (Tort et al. 2010)
%                     glm   : Generalized Linear Model (Penny et al. 2008)
%                     Default {'glm'}
%       'nbinskl'   - Number of bins to use for the Kullback Leibler
%                     Modulation Index. Default [18].
%       'nboot'     - Number of surrogate data to use. Default [200]
%       'ntimesout' - Number of output times (int<frames-winframes). Enter a 
%                     negative value [-S] to subsample original time by S.
%       'timesout'  - Enter an array to obtain spectral decomposition at 
%                     specific time values (note: algorithm find closest time 
%                     point in dafreqs1ta and this might result in an unevenly spaced
%                     time array). Overwrite 'ntimesout'. {def: automatic}
%       'powerlat'  - [float] latency in ms at which to compute phase
%                     histogram
%       'ptspercent'- Size in percentage of data of the segments to shuffle 
%                     when creating surrogate data. Default [0.05]
%       'tlimits'   - [min max] time limits in ms. Default [0 number of
%                     time points / sampling rate]
%
%    Optional Detrending:
%       'detrend'   - ['on'|'off'], Linearly detrend each data epoch   {'off'}
%       'rmerp'     - ['on'|'off'], Remove epoch mean from data epochs {'off'}
%
%    Optional FFT/DFT Parameters:
%       'winsize'   - If cycles==0: data subwindow length (fastest, 2^n<frames);
%                     If cycles >0: *longest* window length to use. This
%                     determines the lowest output frequency. Note that this
%                     parameter is overwritten if the minimum frequency has been set
%                     manually and requires a longer time window {~frames/8}
%       'padratio'  - FFT-length/winframes (2^k)                    {2}
%                     Multiplies the number of output frequencies by dividing
%                     their spacing (standard FFT padding). When cycles~=0, 
%                     frequency spacing is divided by padratio.
%       'nfreqs1'    - number of output frequencies for modulating signal (phase). 
%                     For FFT, closest computed frequency will be returned. 
%                     Overwrite 'padratio' effects for wavelets.
%                     Default: usfreqs1e 'padratio'.
%       'nfreqs2'    - number of output frequencies for modulated signal (amplitude). 
%                     For FFT, closest computed frequency will be returned. 
%                     Overwrite 'padratio' effects for wavelets.
%                     Default: usfreqs1e 'padratio'.
%       'freqscale' - ['log'|'linear'] frequency scale. Default is 'linear'.
%                     Note that for obtaining 'log' spaced freqs using FFT, 
%                     closest correspondant frequencies in the 'linear' space 
%                     are returned.
%       'subitc'    - ['on'|'off'] subtract stimulus locked Inter-Trial Coherence 
%                    (ITC) from x and y. This computes the  'intrinsic' coherence
%                     x and y not arising from common synchronization to 
%                     experimental events. See notes. {default: 'off'}
%       'itctype'   - ['coher'|'phasecoher'] For use with 'subitc', see timef()
%                     for more details {default: 'phasecoher'}.
%       'subwin'    - [min max] sub time window in ms (this windowing is
%                     performed after the spectral decomposition).
%       'alltfXstr' - Structure with the TF decomposition. The strcucture
%                     have the fields {alltfs, freqs, timesout}. This is intended to be
%                     used from pop_pac when several channels/components are comuted at a
%                     time. IN this way the TF decompositio does not have to be computed every time.
%       'alltfYstr' - same as 'alltfXstr'
%                     
% Outputs: 
%        crossfcoh      - Matrix (nfreqs1,nfreqs2,length(timesout1)) of phase amplitude 
%                       coupling values.
%        timesout1      - Vector of output times (window centers) (ms).
%        freqs1         - Vector of frequency bin centers for first argument (Hz).
%        freqs2         - Vector of frequency bin centers for second argument (Hz).
%        alltfX         - spectral decomposition of X
%        alltfY         - spectral decomposition of Y
%        crossfcoh_pval - Matrix (nfreqs1,nfreqs2,length(timesout1)) of Pvalues for the
%                        phase amplitude coupling values.
%        pacstruct      - structure containing the paramters and results of the computation             
% Authors: Arnaud Delorme, SCCN, INC, UCSD 
%          Ramon Martinez-Cancino, SCCN, INC, UCSD 
%          
%
% See also: timefreq(), crossf()
%
% Copyright (C) 2002 Arnaud Delorme, SCCN, INC, UCSD 
%               2019 Ramon Martinez-Cancino, SCCN, INC, UCSD 
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [crossfcoh, timesout1, freqs1, freqs2, alltfX, alltfY,crossfcoh_pval, pacstruct] = eeg_pac(X, Y, srate, varargin)
    
if nargin < 3
    help pac; 
    return; 
end

% deal with 3-D inputs
% --------------------
if ndims(X) == 3, X = reshape(X, size(X,2), size(X,3)); end
if ndims(Y) == 3, Y = reshape(Y, size(Y,2), size(Y,3)); end

frame = size(X,1);
pacmethods_list = {'plv','mvlmi','klmi','glm','plv', 'instmipac', 'ermipac'} ;

[g,gsubf] = finputcheck(varargin, ...
                { 'alpha'            'real'           [0 1]                     [];
                  'alltfXstr'        'struct'         struct                    struct;
                  'alltfYstr'        'struct'         struct                    struct;
                  'ptspercent'       'float'          [0 1]                     0.05;
                  'nboot'            'real'           [0 Inf]                   200;
                  'baseboot'         'float'          []                        0;                       
                  'boottype'         'string'         {'times','trials','timestrials'}  'timestrials';   
                  'bonfcorr'         'integer'        [0 1]                     0;
                  'detrend'          'string'         {'on','off'}              'off';
                  'freqs'            'real'           [0 Inf]                   [0 srate/2];
                  'freqs2'           'real'           [0 Inf]                   [];
                  'freqscale'        'string'         { 'linear','log' }        'linear';
                  'itctype'          'string'         {'phasecoher','phasecoher2','coher'}  'phasecoher';
                  'nfreqs1'          'integer'        [0 Inf]                   [];
                  'nfreqs2'          'integer'        [0 Inf]                   [];
                  'lowmem'           'string'         {'on','off'}              'off';                   
                  'naccu'            'integer'        [1 Inf]                   250;                     
                  'newfig'           'string'         {'on','off'}              'on';                    
                  'padratio'         'integer'        [1 Inf]                   2;
                  'rmerp'            'string'         {'on','off'}              'off';
                  'rboot'            'real'           []                        [];                      
                  'subitc'           'string'         {'on','off'}              'off';
                  'subwin'           'real'           []                        []; ...
                  'gammapowerlim'    'real'           []                        []; ...                  
                  'powerlim'         'real'           []                        []; ...                  
                  'powerlat'         'real'           []                        []; ...                  
                  'gammabase'        'real'           []                        []; ...                  
                  'timesout'         'real'           []                        []; ...
                  'ntimesout'        'integer'        []                        length(X)/2; ...
                  'tlimits'          'real'           []                        [0 frame/srate];
                  'title'            'string'         []                        '';                      
                  'vert'             {'real','cell'}  []                        [];
                  'cycles'           'real'           [0 Inf]                   [3 0.5];
                  'cycles2'          'real'           [0 Inf]                   [3 0.5];   
                  'verbose'          'string'         {'on','off'}              'off';...
                  'butterorder'      'real'           [1 20]                     6; 
                  'winsize'          'integer'        [0 Inf]                   max(pow2(nextpow2(frame)-3),4);
                  'method'           'string'         pacmethods_list           'glm';                    
                  'timefreq'         'real'           [0 1]                      1; % Flag to use filters or TF decomposition  
                  'nparpools'        'real'           [1 100]                    1 }, 'eeg_pac','ignore');
if ischar(g), error(g); end

% Parallelization stuff (work in progress)
parclust = parcluster;
if g.nparpools>parclust.NumWorkers
    g.nparpools = parclust.NumWorkers;
    disp(['eeg_pac: Number of clusters modified to fit the maximum number of workers allowed (' num2str(parclust.NumWorkers)  ')']);
end

% remove ERP if asked
% -----------------------
X = squeeze(X);
Y = squeeze(Y);
trials = size(X,2);
if strcmpi(g.rmerp, 'on')
    X = X - repmat(mean(X,2), [1 trials]);
    Y = Y - repmat(mean(Y,2), [1 trials]);
end

% Check validity of the method to be run and the data provided
if trials ~=1 && strcmp(g.method, 'instmipac'), disp('eeg_pac: Method not supported for data format provided'); return; end
if trials ==1 && strcmp(g.method, 'ermipac'),   disp('eeg_pac: Method not supported for data format provided'); return; end

%%
% perform timefreq decomposition
% ------------------------------
if g.timefreq
    % Using TF decomposition here
    if isempty(fieldnames(g.alltfXstr))
        [alltfX, freqs1, timesout1] = timefreq(X, srate, 'ntimesout',  g.ntimesout, 'timesout',  g.timesout,  'winsize',  g.winsize, ...
                                                'tlimits',    g.tlimits,   'detrend',   g.detrend,   'itctype',  g.itctype, ...
                                                'subitc',     g.subitc,    'cycles',    g.cycles,    'padratio', g.padratio, ...
                                                'freqs',      g.freqs,     'freqscale', g.freqscale, 'nfreqs',   g.nfreqs1,...
                                                'verbose',    g.verbose);
    else
        alltfX    = g.alltfXstr.alltf;
        freqs1    = g.alltfXstr.freqs;
        timesout1 = g.alltfXstr.timesout;
    end
    
    if isempty(fieldnames(g.alltfYstr))
        [alltfY, freqs2, timesout2] = timefreq(Y, srate, 'ntimesout',  g.ntimesout, 'timesout',  g.timesout,  'winsize',  g.winsize, ...
                                                'tlimits',    g.tlimits,   'detrend',   g.detrend,   'itctype',  g.itctype, ...
                                                'subitc',     g.subitc,    'cycles',    g.cycles2,   'padratio', g.padratio, ...
                                                'freqs',      g.freqs2,    'freqscale', g.freqscale, 'nfreqs',   g.nfreqs2,...
                                                'verbose',    g.verbose);
    else
        alltfY    = g.alltfYstr.alltf;
        freqs2    = g.alltfYstr.freqs;
        timesout2 = g.alltfYstr.timesout;
    end
    
else
    % Using Filters here
    timesout1 = g.tlimits(1):1/srate:g.tlimits(2);
    timesout2 = timesout1;
    
    % PHS
    if numel(g.freqs)>1
        freqs1 = g.freqs(1):(g.freqs(2)-g.freqs(1))/g.nfreqs1:g.freqs(2);
    else
        freqs1 = g.freqs;
    end
    
    if numel(g.freqs2)>1
        freqs2 = g.freqs2(1):(g.freqs2(2)-g.freqs2(1))/g.nfreqs2:g.freqs2(2);
    else
        freqs2 = g.freqs2;
    end
       
    for ifreq1 =1: length(freqs1)
        % Phases
        for itrials = 1:size(X,3)         
            alltfX(ifreq1,:,itrials) = eegfilt(X', srate, freqs1(ifreq1) - 1, 0);
            alltfX(ifreq1,:,itrials) = eegfilt(alltfX(ifreq1,:,itrials), srate, 0, freqs1(ifreq1) + 1);
            alltfX(ifreq1,:,itrials) = hilbert(alltfX(ifreq1,:,itrials));
            
            % Amplitude
            for ifreq2 =1:length(freqs2)
                alltfY{ifreq1}(ifreq2,:,itrials) = eegfilt(Y', srate, freqs2(ifreq2) - freqs1(ifreq1) - 1, 0);
                alltfY{ifreq1}(ifreq2,:,itrials) = eegfilt(alltfY{ifreq1}(ifreq2,:,itrials), srate, 0, freqs2(ifreq2) + freqs1(ifreq1) + 1);
                alltfY{ifreq1}(ifreq2,:,itrials) = hilbert(alltfY{ifreq1}(ifreq2,:,itrials));
            end
        end
    end
end
 
%%
% check time limits
% -----------------
if ~isempty(g.subwin)
    ind1      = find(timesout1 > g.subwin(1) & timesout1 < g.subwin(2));
    ind2      = find(timesout2 > g.subwin(1) & timesout2 < g.subwin(2));
    alltfX    = alltfX(:, ind1, :);
    if ~iscell(alltfY)
        alltfY    = alltfY(:, ind2, :);
    else
        for icell = 1:length(alltfY)
            alltfY{icell} = alltfY{icell}(:, ind2, :);
        end
    end
    timesout1 = timesout1(ind1);
    timesout2 = timesout2(ind2);
end

if length(timesout1) ~= length(timesout2) || any( timesout1 ~= timesout2)
    if strcmpi(g.verbose, 'on')
        disp('Warning: Time points are different for X and Y. Use ''timesout'' to specify common time points');
    end
    [vals, ind1, ind2 ] = intersect_bc(timesout1, timesout2);
    if strcmpi(g.verbose, 'on')
        fprintf('Searching for common time points: %d found\n', length(vals));
    end
    if length(vals) < 10, error('Less than 10 common data points'); end
    timesout1 = vals;
    %timesout2 = vals;
    alltfX = alltfX(:, ind1, :);
    if ~iscell(alltfY)
        alltfY    = alltfY(:, ind2, :);
    else
        for icell = 1:length(alltfY)
            alltfY{icell} = alltfY{icell}(:, ind2, :);
        end
    end
end

%%
% scan accross frequency and time
% -------------------------------
if numel(size(alltfX)) ==2
    ti_loopend = 1; 
    strial_flag = 1; 
    ntrials = 1;
else
    ti_loopend = length(timesout1);
    strial_flag = 0;
    ntrials = size(alltfX,3);
end

% Getting array length to store results
if strial_flag && strcmp(g.method,'instmipac') || strcmp(g.method,'ermipac')
    arraylength = length(timesout1);
else
    arraylength = length(ti_loopend);
end

% Apply Bonferroni correction
if g.bonfcorr && ~isempty(g.alpha), g.alpha = g.alpha / (length(freqs1) * length(freqs2) * arraylength); end

%--------------------------------------------------------------------------
% get data and transform it
% ---
% alltfYlooptmp = alltfY; if iscell(alltfY), alltfYlooptmp = alltfY{find1};end

% Angle and abs from phase and amp
alltfX = angle(alltfX);
alltfY = abs(alltfY);
% ---
% Loop  phase frequencies
for find1 = 1:length(freqs1)
    if strcmpi(g.verbose, 'on')
        fprintf('Progress : %.2f %% \n', 100*(find1-1)/length(freqs1));
    end
    % Defining time vector and other stuff before runnning the loops
    if strcmp(g.method, 'ermipac')
        windowsearchsize = round(srate/freqs1(find1));
        micomplimits    = [round(windowsearchsize/2)+1 ti_loopend-round(windowsearchsize/2)-1];
        tvector         = micomplimits(1):micomplimits(2);
    else
        tvector = 1:ti_loopend;
    end
    %---
    % Loop  amplitude frequencies
    for find2 = 1:length(freqs2)
        
        % Time loop here( ti =1 if single trial, otherwise the number of timepoints)
        % Check for parpool and adjust the number of workers to the value in parpools.
        if g.nparpools > 1 && length(tvector) > 1
            hpool = gcp('nocreate');
            if isempty(hpool)
                parpool(g.nparpools)
            elseif hpool.NumWorkers ~= g.nparpools
                delete(gcp('nocreate'))
                parpool(g.nparpools);
            end
            parforArg = g.nparpools;
        else
            parforArg = 0;
        end
            
%         parfor (ti = 1:length(tvector), parforArg)
         for ti = 1:length(tvector)
            
            % Retreiving the data
            if strial_flag % Single trial case
                tmpalltfx = squeeze(alltfX(find1,:))';
                tmpalltfy = squeeze(alltfY(find2,:))';
                
            elseif strcmp (g.method,'ermipac')
                
                % Extracting windows of data for ERMPAC
                single_alltfx = squeeze(alltfX(find1,:,:));
                single_alltfy = squeeze(alltfY(find2,:,:));
                
                tmpalltfx = nan(windowsearchsize+1 ,size(single_alltfx,2));
                tmpalltfy = nan(windowsearchsize+1 ,size(single_alltfy,2));
                
                tmpalltfx(1,:) = single_alltfx(tvector(ti),:);
                tmpalltfy(1,:) = single_alltfy(tvector(ti),:);
                
                for k = 1:round(windowsearchsize/2)
                    tmpalltfx(k+1,:) = single_alltfx(tvector(ti)-k,:);
                    tmpalltfy(k+1,:) = single_alltfy(tvector(ti)-k,:);
                    
                    tmpalltfx(end-k+1,:) = single_alltfx(tvector(ti)+k,:);
                    tmpalltfy(end-k+1,:) = single_alltfy(tvector(ti)+k,:);
                end
                %---
            else
                tmpalltfx = squeeze(alltfX(find1,tvector(ti),:));
                tmpalltfy = squeeze(alltfY(find2,tvector(ti),:));
            end
                        
            % ERMIPAC
            if strcmp(g.method,'ermipac')
                tmparg = {gsubf{:} 'xdistmethod' 'circular'};
                [~,pactmp,kconv] = minfokraskov_convergencewin(tmpalltfx',tmpalltfy', tmparg{:});
                
                if ~isempty(g.alpha)
                    [trash, zerolat] = min(abs(timesout1));
                    Xbaseline = single_alltfx(1:zerolat,:);
                    Ybaseline = single_alltfy(1:zerolat,:);
                    
                    tmparg = {gsubf{:} 'k' kconv 'xdistmethod' 'circular'};
                    surrdata = minfokraskov_computesurrfrombaseline([size(single_alltfx,2), windowsearchsize+1] ,Xbaseline, Ybaseline, g.nboot,tmparg{:});
                    
                    % Statistical testing
                    Iloc_zscore         = (pactmp' - repmat(mean(surrdata(:)),size(pactmp',1),size(pactmp',2))) ./ repmat(std(surrdata(:)),size(pactmp',1),size(pactmp',2));
                    Iloc_pval           = 1-normcdf(abs(Iloc_zscore));
                    %                    Iloc_pval           = 2*normcdf(-abs(Iloc_zscore));
                    Iloc_sigval = zeros(size(Iloc_pval));
                    Iloc_sigval(Iloc_pval<g.alpha) = 1;
                    signiftmp = Iloc_sigval;
                    pval      = Iloc_pval;
                end
            
            % Inst MIPAC
            elseif strcmp(g.method,'instmipac')              
                % Inst MIPAC with and withoth signif (controled by g.alpha)
                tmparg = {gsubf{:} 'xdistmethod' 'circular' 'filterfreq' freqs1(find1) 'alpha' g.alpha};
                [pactmp, kconv, signiftmp, pval] = minfokraskov_convergence_signif(tmpalltfx,tmpalltfy,srate,tmparg{:});
                
            % PAC Methods.
            else
                tmparg = {gsubf{:} 'alpha' g.alpha};
                [pactmp,~,~,pacstructtmp] = eeg_comppac(tmpalltfx,tmpalltfy, g.method, tmparg{:}) ;
            end
            
            %--------------------------------------------------------------
            % Specific for methods
            % Default methods
            switch g.method
                case {'mvlmi', 'klmi', 'glm', 'plv'}
                    % Methods with dimension = 1
                    %---------------------------
                    if length(tvector)==1
                        pacstruct.(g.method).dim                       = 1;
                        pacstruct.(g.method).pacval(find1,find2)       = pacstructtmp.pacval;
                        
                        % Specific to each method
                        if strcmp(g.method, 'mvlmi')
                            pacstruct.mvlmi.composites(find1,find2,:) = pacstructtmp.composites(:); % mvlmi
                            pacstruct.mvlmi.peakangle(find1,find2)    = pacstructtmp.peakangle;     % mvlmi
                        elseif strcmp(g.method, 'klmi')
                            pacstruct.klmi.peakangle(find1,find2)   = pacstructtmp.peakangle; % klmi
                            pacstruct.klmi.nbinskl(find1,find2)     = pacstructtmp.nbinskl;   % klmi
                            [pacstruct.klmi.bin_average{find1,find2,1:pacstructtmp.nbinskl}] = deal(pacstructtmp.bin_average); % klmi
                        elseif strcmp(g.method, 'glm')
                            pacstruct.glm.beta(find1, find2, 1:3) = pacstructtmp.beta(:); % glm
                        end   
                        %-
                        if ~isempty(g.alpha)
                            pacstruct.(g.method).signif.pval(find1,find2)           = pacstructtmp.pval;
                            pacstruct.(g.method).signif.signifmask(find1,find2)     = pacstructtmp.significant;
                            pacstruct.(g.method).signif.surrogate_pac(find1,find2,:) = pacstructtmp.surrogate_pac;
                        end
                    else
                        % Methods with dimension = 2
                        %---------------------------
                        pacstruct.(g.method).dim                          = 2;
                        pacstruct.(g.method).pacval(find1,find2, ti,:)    = pacstructtmp.pacval;
                        
                        % Specific to each method
                        if strcmp(g.method, 'mvlmi')
                            pacstruct.mvlmi.composites(find1,find2,ti,:) = pacstructtmp.composites(:); % mvlmi
                            pacstruct.mvlmi.peakangle(find1,find2,ti)    = pacstructtmp.peakangle;     % mvlmi
                        elseif strcmp(g.method, 'klmi')
                            pacstruct.klmi.peakangle(find1,find2, ti)   = pacstructtmp.peakangle; % klmi
                            pacstruct.klmi.nbinskl(find1,find2, ti)     = pacstructtmp.nbinskl;   % klmi
                            [pacstruct.klmi.bin_average{find1,find2, ti, 1:pacstructtmp.nbinskl}] = deal(pacstructtmp.bin_average); % klmi
                        elseif strcmp(g.method, 'glm')
                            pacstruct.glm.beta (find1, find2, 1:3, ti) = pacstructtmp.beta; % glm
                        end
                        %-
                        if ti==1, pacstruct.(g.method).times              = timesout1; end
                        if ~isempty(g.alpha)
                            pacstruct.(g.method).signif.pval(find1,find2,ti)            = pacstructtmp.pval;
                            pacstruct.(g.method).signif.signifmask(find1,find2,ti)      = pacstructtmp.significant;
                            pacstruct.(g.method).signif.surrogate_pac(find1,find2,ti, 1:length(pacstructtmp.surrogate_pac)) = pacstructtmp.surrogate_pac;
                        end
                    end
                case 'ermipac'                             
                    pacstruct.ermipac.dim                             = 3;
                    pacstruct.ermipac.pacval(find1,find2,1:trials,ti) = pactmp;
                    pacstruct.ermipac.kconv(find1,find2,ti)           = kconv;
                    pacstruct.ermipac.times                           = timesout1(tvector);
                    
                    if ~isempty(g.alpha)
                        pacstruct.ermipac.signif.pval(find1,find2,:,ti)          = pval;
                        pacstruct.ermipac.signif.signifmask(find1,find2,:,ti)     = signiftmp;
                        %pacstruct.ermipac.signif.surrogate_pac(find1,find2,:, ti, 1:size(surrdata,1)) = surrdata';
                    end
                case 'instmipac'
                    pacstruct.instmipac.dim                   = 2;
                    pacstruct.instmipac.pacval(find1,find2,:) = pactmp;
                    pacstruct.instmipac.kconv(find1,find2)    = kconv;
                    pacstruct.instmipac.times                 = timesout1;
                    
                    if ~isempty(g.alpha)
                        pacstruct.instmipac.signif.pval(find1,find2, :)                  = pval;
                        pacstruct.instmipac.signif.signifmask(find1,find2, :)            = signiftmp;
                        %pacstruct.instmipac.signif.surrogate_pac(find1,find2,1:g.nboot,:) = surrdata;
                    end                         
            end    
        end
    end
end
%--------------------------------------------------------------------------
% Just for ER MIPAC methods
if  strcmp(g.method,'ermipac')
    for i = 1:length(freqs1)
        for j = 1:length(freqs2)
            for k = 1:trials
                % Filtering the MIPAC etsimates
                [b,a] = butter(g.butterorder,freqs1(find1)/(srate/2),'low');
                pacstruct.ermipac.pacval(find1,find2,k,:) = filtfilt(b,a,squeeze(pacstruct.ermipac.pacval(i,j,k,:))');
            end
        end
    end
end
%--------------------------------------------------------------------------
%% Populating pacstruct
pacstruct.params.freqs_phase        = freqs1;
pacstruct.params.freqs_amp          = freqs2;
pacstruct.params.signif.alpha       = g.alpha;
pacstruct.params.signif.ptspercent  = g.ptspercent;
pacstruct.params.signif.nboot       = g.nboot;
pacstruct.params.signif.bonfcorr    = g.bonfcorr;
pacstruct.params.srate              = srate;

crossfcoh      = pacstruct.(g.method).pacval;
if ~isempty(g.alpha)
    crossfcoh_pval = pacstruct.(g.method).signif.pval;
else
    crossfcoh_pval = [];
end
end