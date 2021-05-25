%% down sample frequency and spectral data to plot out a freq x spec plot
%
% -- INPUTS -- %
% f: frequency cell array. Each cell contains a trials worth of data
% S: either power, coherence, or some other spectral analysis that is the
%       same size as f
% IMPORTANT: This only works with a vector of cell arrays. Not a matrix
%
% -- OUTPUTS -- %
% sOut: your S variable (whether it be power, or coherence etc...)
%        organized in a cell array where each cell contains data from 1
%        trial, where the spectral output is down sampled to match the
%        lowest frequency resolution
% fOut: same as above, but for frequency
%
% written by John Stout

function [sOut,fOut] = spectralDownSample(S,f)

% get a size to down sample frequencies to
downSize = min(cellfun(@length,f));

% identify an example trials worth of data that is the same size as
% downSize
for i = 1:length(f)
    sizeMet(i) = length(f{i}) == downSize;
end
idxMet = find(sizeMet == 1);
f2use = f{idxMet(1)}; % this assigns us a variable that is the minimum in size

% down sample S variable (spectral analysis input)
fOut = []; sOut = [];
for i = 1:length(f)
    fKeep   = dsearchn(f{i}',f2use');
    fOut{i} = f{i}(fKeep);
    
    % sanity check
    check = find(fOut{i}-f2use > 0);
    if isempty(check) == 0
        error('BUG ALERT: did not appropriately down-size. Code must be fixed')
    end
    
    % continue, down sample your S variable
    sOut{i} = S{i}(fKeep);
end

end
