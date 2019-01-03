function data = tifread(filepath)
% fastest tif reading possible, super stripped down and optimized for speed
% only works for grayscale with same width and height for each frame
% 
% filepath can be a local file in current directory or full filename
% Andrew Landau, January 2019

fid = fopen(filepath, 'rb');
tifname = fopen(fid); % get full filepath
info = matlab.io.internal.imagesci.tifftagsread(tifname,0,0,0); % get image info - internal mex function
numFrames = numel(info); % number of frames (directories)

% Can handle multiple data types
bd=info(1).BitDepth;
he=info(1).ByteOrder;
bo=strcmp(he,'big-endian');
if (bd==64)
	form='double';
elseif(bd==32)
    form='single';
elseif (bd==16)
    form='uint16';
elseif (bd==8)
    form='uint8';
end

% Strip offsets give position of data within each strip
% If multiple strips per frame, each bit is concatenated directly
ofds=zeros(1,numFrames);
for i=1:numFrames
    ofds(i)=info(i).StripOffsets(1);
end

% Get dimensions of tiff and preallocate array
cols = info(1).Width;
rows = info(1).Height;
data = zeros(rows,cols,numFrames,form);

% Depending on file type, read out binary data directly
if strcmpi(form,'uint16') || strcmpi(form,'uint8')
    if(bo)
        for cnt = 1:numFrames
            fseek(fid,ofds(cnt),'bof'); % go to start of data for each frame
            data(:,:,cnt) = fread(fid, [cols rows], form, 0, 'ieee-be')'; % read in and transpose
        end
    else
        for cnt = 1:numFrames
            fseek(fid,ofds(cnt),'bof');
            data(:,:,cnt) = fread(fid, [cols rows], 'int16', 0, 'ieee-le')';
        end
    end
elseif strcmpi(form,'single')
    for cnt = 1:numFrames
        fseek(fid,ofds(cnt),'bof');
        data(:,:,cnt) = fread(fid, [cols rows], form, 0, 'ieee-be');
    end
elseif strcmpi(form,'double')
    for cnt = 1:numFrames
        fseek(fid,ofds(cnt),'bof');
        data(:,:,cnt) = fread(fid, [cols rows], form, 0, 'ieee-le.l64');
    end
end

fclose(fid); % bye

