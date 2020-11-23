%% cleanLFP
%
% clean lfp data
%
% -- INPUTS -- %
% lfp_data: vector
% srate: sampling rate of lfp
% params: chronux parameters
% movingwin: [0.5 0.01] or [0.25 0.01] works. Adjust as needed. See chronux
% cleanFreqs: [58 62] tends to get the noise band out
% 
% -- OUTPUTS -- %
% cleaned_lfp_movingWin: detrended, then cleaned. This may change the size
%                           of your data. Use this if you're controlling
%                           for time (like 1 second around an event or
%                           something)
% cleaned_lfp_stationary: detrended, then cleaned. This wont change the
%                           size of your data. Use this when you're not
%                           controlling for time
% detrend_lfp: detrended, but not cleaned lfp
%
% written by John Stout

function [cleaned_lfp_movingWin,cleaned_lfp_stationary,detrend_lfp] = cleanLFP(lfp_data,srate,params,movingwin,cleanFreqs)

% defaults
if exist('params') == 0 | isempty(params)
    params.tapers    = [3 5];
    params.trialave  = 0;
    params.err       = [2 .05];
    params.pad       = 0;
    params.fpass     = [0 100]; % [1 100]
end

if exist('movingwin') == 0 | isempty(movingwin)
    movingwin = [.5 .01];
end

if exist('cleanFreqs') == 0 | isempty(cleanFreqs)
    cleanFreqs = [58 62];
end

% define Fs if it doesn't exist (srate)
try checkFields = extractfield(params,'Fs'); catch; params.Fs = srate; end

% detrend data, then remove 60Hz noise (chronux way)
detrend_lfp = locdetrend(lfp_data,srate,movingwin);

% account for 60hz noise
cleaned_lfp_movingWin = rmlinesmovingwinc2(detrend_lfp,movingwin,10,params,[],[],cleanFreqs);

% account for 60hz noise method 2
cleaned_lfp_stationary = rmlinesc2(detrend_lfp,params,[],[],cleanFreqs);

end




