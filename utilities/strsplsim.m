function [c, matches] = strsplsim(str, aDelim)
% strsplsim is a reduced version of Matlab's strsplit "strsplit simple"
% I just removed some back end processing and some extra lines that make
% strsplit flexible but take long time 
% Optimized for speed, doesn't provide informative error messages

if (nargin ~= 2), error('Not enough input arguments'); end

if ~isempty(strfind(aDelim,'\')) && sum(strfind(aDelim(1:end-1),'\'))==1 %#ok(~isempty(strfind()) is faster
    % Handle escape sequences and translate.
    idx = strfind(aDelim,'\');
    aDelim(idx) = [];
    aDelim(idx) = escapeChar(aDelim(idx));
    aDelim = regexptranslate('escape', aDelim);
elseif ~isempty(strfind(aDelim,'\')) %#ok(~isempty(strfind()) is faster
    error('Only one escape sequence allowed');
end

aDelim = ['(?:', aDelim, ')+']; % regular expression defining delimiters of arbitrary characters

% Split
[c, matches] = regexp(str, aDelim, 'split', 'match');
end

%-Taken from private string functions, this is local function in strescape-
function c = escapeChar(c)
    switch c
    case '0'  % Null.
        c = char(0);
    case 'a'  % Alarm.
        c = char(7);
    case 'b'  % Backspace.
        c = char(8);
    case 'f'  % Form feed.
        c = char(12);
    case 'n'  % New line.
        c = char(10);
    case 'r'  % Carriage return.
        c = char(13);
    case 't'  % Horizontal tab.
        c = char(9);
    case 'v'  % Vertical tab.
        c = char(11);
    case '\'  % Backslash.
        c = '\';
    otherwise
        warning(message('MATLAB:strescape:InvalidEscapeSequence', c, c));
    end
end