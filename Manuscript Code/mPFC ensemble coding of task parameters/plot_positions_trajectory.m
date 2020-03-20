%% plot running positions
% this script compares trajectory data
%
clear; clc

% load data
load('data_Capn_Trajectory_position');

data2_X = data.sampleR_X;
data2_Y = data.sampleR_Y;
data1_X = data.sampleL_X;
data1_Y = data.sampleL_Y;

ExtractedX = data.ExtractedX;
ExtractedY = data.ExtractedY;
try
sessions = data.sessions;
catch
end

% fix arrays - note that this arrays first shell is the sessions, second is
% the lags, 3rd is trials, 4th is doubles that represent the position data
data2_X = data2_X(~cellfun('isempty',data2_X));
data2_Y = data2_Y(~cellfun('isempty',data2_Y));
data1_X = data1_X(~cellfun('isempty',data1_X));
data1_Y = data1_Y(~cellfun('isempty',data1_Y));

% interpolate to 15 data points. This is bc the srate is 30 data1s per
% second, but sometimes there are less
xq = 1:16; % interpolate to 16 - it doesn't really change anything.

for i = 1:length(data2_X)
    for ii = 1:length(data2_X{i})
        for iii = 1:length(data2_X{i}{ii}) % number of trials
        
            if length(data2_X{i}{ii}{iii}) < 16
                if length(data2_X{i}{ii}{iii}) == 13
                    x = 1:13;
                elseif length(data2_X{i}{ii}{iii}) == 14
                    x = 1:14;
                elseif length(data2_X{i}{ii}{iii}) == 15
                    x = 1:15;
                end
                v = data2_X{i}{ii}{iii};
                data2_X{i}{ii}{iii} = round(interp1(x,v,xq,'spline'));
            end
            
            if length(data2_Y{i}{ii}{iii}) < 16   
                if length(data2_Y{i}{ii}{iii}) == 13
                    x = 1:13;
                elseif length(data2_Y{i}{ii}{iii}) == 14
                    x = 1:14;
                elseif length(data2_Y{i}{ii}{iii}) == 15
                    x = 1:15;
                end                
                v = data2_Y{i}{ii}{iii};
                data2_Y{i}{ii}{iii} = round(interp1(x,v,xq,'spline'));
            end            
        end

        for iii = 1:length(data1_X{i}{ii}) % number of trials (num can differ depending on left/right)

            if length(data1_X{i}{ii}{iii}) < 16 
                if length(data1_X{i}{ii}{iii}) == 13
                    x = 1:13;
                elseif length(data1_X{i}{ii}{iii}) == 14
                    x = 1:14;
                elseif length(data1_X{i}{ii}{iii}) == 15
                    x = 1:15;
                end                
                v = data1_X{i}{ii}{iii};
                data1_X{i}{ii}{iii} = round(interp1(x,v,xq,'spline'));
            end
            
            if length(data1_Y{i}{ii}{iii}) < 16 
                if length(data1_Y{i}{ii}{iii}) == 13
                    x = 1:13;
                elseif length(data1_Y{i}{ii}{iii}) == 14
                    x = 1:14;
                elseif length(data1_Y{i}{ii}{iii}) == 15
                    x = 1:15;
                end                
                v = data1_Y{i}{ii}{iii};
                data1_Y{i}{ii}{iii} = round(interp1(x,v,xq,'spline'));
            end                          
        end
    end
end

% concatenate across trials
for i = 1:length(data2_X)
    for ii = 1:length(data2_X{i})
        data2_X{i}{ii} = vertcat(data2_X{i}{ii}{:});
        data1_X{i}{ii} = vertcat(data1_X{i}{ii}{:});
        data2_Y{i}{ii} = vertcat(data2_Y{i}{ii}{:});
        data1_Y{i}{ii} = vertcat(data1_Y{i}{ii}{:});
    end
end

% average across 4th shell (trials)
for i = 1:length(data2_X)
    data2_X{i} = cellfun(@mean,data2_X{i},'UniformOutput',false);
    data1_X{i} = cellfun(@mean,data1_X{i},'UniformOutput',false);
    data2_Y{i} = cellfun(@mean,data2_Y{i},'UniformOutput',false);
    data1_Y{i} = cellfun(@mean,data1_Y{i},'UniformOutput',false);
end

% horizontally concatenate data into one string per session, concatenating
% the bins of position data
for i = 1:length(data2_X)
    data2_X{i} = horzcat(data2_X{i}{:});
    data2_Y{i} = horzcat(data2_Y{i}{:});
    data1_X{i} = horzcat(data1_X{i}{:});
    data1_Y{i} = horzcat(data1_Y{i}{:});
end

% vertically concatenate across sessions
data2_X = vertcat(data2_X{:});
data2_Y = vertcat(data2_Y{:});
data1_X = vertcat(data1_X{:});
data1_Y = vertcat(data1_Y{:});

% average across sessions
xdata2Mean = mean(data2_X);
xdata1Mean = mean(data1_X);
ydata2Mean = mean(data2_Y);
ydata1Mean = mean(data1_Y);

% load in data1 data
data1_dir = 'X:\01.Experiments\John n Andrew\Dual optogenetics w mPFC recordings\All Subjects - DNMP\Good performance\Medial Prefrontal Cortex\Baby Groot 9-11-18';
data1_data = load(strcat(data1_dir,'\VT1.mat'));

% correct tracking errors
addpath('X:\03. Lab Procedures and Protocols\MATLABToolbox\chronux\spectral_analysis\continuous');
addpath('X:\03. Lab Procedures and Protocols\MATLABToolbox\Basic Functions')
[ExtractedX,ExtractedY] = correct_tracking_errors(data1_dir);
% convert to cm
ExtractedX = round(ExtractedX);
ExtractedY = round(ExtractedY);

% plot figure
figure('color','w');
subplot 121
plot(xdata1Mean,ydata1Mean','b');
subplot 122
plot(xdata2Mean,ydata2Mean,'r');

figure('color','w'); hold on;
plot(ydata1Mean,xdata1Mean,'b','LineWidth',1.5);
errorbar(ydata1Mean(17:48),xdata1Mean(17:48),stderr(data1_X(:,17:48)),'b');
plot(ydata2Mean,xdata2Mean,'r','LineWidth',1.5);
errorbar(ydata2Mean(17:48),xdata2Mean(17:48),stderr(data2_X(:,17:48)),'r');
numbins = 8;
ymin = 135; % do not underestimate - you'll end up in start-box
ymax = 400; % over estimate - this doesn't hurt anything
bins = round(linspace(ymin,ymax,numbins));
y = [345 356];
for i = 1:length(bins)
    x = [bins(i) bins(i)];
    line(x,y,'Color','k','LineStyle','-','LineWidth',2)
end

figure('color','w'); hold on;
plot(ExtractedY,ExtractedX,'Color',[0.9 0.9 0.9])
plot(ydata1Mean,xdata1Mean,'b','LineWidth',1.5);
plot(ydata2Mean,xdata2Mean,'r','LineWidth',1.5);
numbins = 8;
ymin = 135; % do not underestimate - you'll end up in start-box
ymax = 400; % over estimate - this doesn't hurt anything
bins = round(linspace(ymin,ymax,numbins));
y = [345 356];
for i = 1:length(bins)
    x = [bins(i) bins(i)];
    line(x,y,'Color','k','LineStyle','-','LineWidth',2)
end

figure('color','w'); hold on;
plot(ExtractedX,ExtractedY,'Color',[0.9 0.9 0.9])
plot(xdata1Mean,ydata1Mean,'b','LineWidth',1.5);
plot(xdata2Mean,ydata2Mean,'r','LineWidth',1.5);
numbins = 8;
ymin = 135; % do not underestimate - you'll end up in start-box
ymax = 400; % over estimate - this doesn't hurt anything
bins = round(linspace(ymin,ymax,numbins));
x = [345 356];
for i = 1:length(bins)
    y = [bins(i) bins(i)];
    line(x,y,'Color','k','LineStyle','-','LineWidth',2)
end
xlim([300 400])
ylim([100 400])
axis off

figure('color','w')
plot(ExtractedX,ExtractedY,'Color',[0.9 0.9 0.9])
hold on
plot(xdata1Mean,ydata1Mean,'b','LineWidth',1.5);
plot(xdata2Mean,ydata2Mean,'r','LineWidth',1.5);
box off
set(gca,'FontSize',12)


% stats
[h,p,k]=kstest2(xdata1Mean(17:64),xdata2Mean(17:64))


% plot figure showing the different bins
bin_len = size(data1_X,2)/5; % I chose 5 diff lags in the code prior to this

figure('color','w')
plot(ExtractedX,ExtractedY,'Color',[0.9 0.9 0.9])
ylim([140 400])
xlim([300 400])
box off
hold on;
plot(xdata1Mean(1:16),ydata1Mean(1:16),'b','LineWidth',1.5);
plot(xdata1Mean(17:32),ydata1Mean(17:32),'m','LineWidth',1.5);
plot(xdata1Mean(33:48),ydata1Mean(33:48),'k','LineWidth',1.5);
plot(xdata1Mean(49:64),ydata1Mean(49:64),'g','LineWidth',1.5);
plot(xdata1Mean(65:80),ydata1Mean(65:80),'c','LineWidth',1.5);
title('data1 phase')
set(gca,'FontSize',12)

figure('color','w')
plot(ExtractedX,ExtractedY,'Color',[0.9 0.9 0.9])
ylim([140 400])
xlim([300 400])
box off
hold on;
plot(xdata2Mean(1:16),ydata2Mean(1:16),'b','LineWidth',1.5);
plot(xdata2Mean(17:32),ydata2Mean(17:32),'m','LineWidth',1.5);
plot(xdata2Mean(33:48),ydata2Mean(33:48),'k','LineWidth',1.5);
plot(xdata2Mean(49:64),ydata2Mean(49:64),'g','LineWidth',1.5);
plot(xdata2Mean(65:80),ydata2Mean(65:80),'c','LineWidth',1.5);
title('data2 phase')
set(gca,'FontSize',12)


%{
%% average across rats
rat1 = load('data_BabyGroot_positions');
rat2 = load('data_Capn_Trajectory_position');
rat3 = load('data_Groot_position');
rat4 = load('data_Meusli_position');
rat5 = load('data_Thanos_position');

% get data into a struct array
dataAll.sampleL_X{1} = rat1.data.sampleL_X;
dataAll.sampleR_X{1} = rat1.data.sampleR_X;
dataAll.sampleL_X{1} = rat1.data.sampleL_Y;
dataAll.sampleR_X{1} = rat1.data.sampleR_Y;

dataAll.sampleL_X{2} = rat2.data.sampleL_X;
dataAll.sampleR_X{2} = rat2.data.sampleR_X;
dataAll.sampleL_X{2} = rat2.data.sampleL_Y;
dataAll.sampleR_X{2} = rat2.data.sampleR_Y;

dataAll.sampleL_X{2} = rat1.data.sampleL_X;
dataAll.sampleR_X{2} = rat1.data.sampleR_X;
dataAll.sampleL_X{2} = rat1.data.sampleL_Y;
dataAll.sampleR_X{2} = rat1.data.sampleR_Y;


for i = 1:5
    

rat1.data.sampleL_X

data2_X = data.choiceR_X;
data2_Y = data.choiceR_Y;
data1_X = data.choiceL_X;
data1_Y = data.choiceL_Y;

ExtractedX = data.ExtractedX;
ExtractedY = data.ExtractedY;
try
sessions = data.sessions;
catch
end

% fix arrays - note that this arrays first shell is the sessions, second is
% the lags, 3rd is trials, 4th is doubles that represent the position data
data2_X = data2_X(~cellfun('isempty',data2_X));
data2_Y = data2_Y(~cellfun('isempty',data2_Y));
data1_X = data1_X(~cellfun('isempty',data1_X));
data1_Y = data1_Y(~cellfun('isempty',data1_Y));

% interpolate to 15 data points. This is bc the srate is 30 data1s per
% second, but sometimes there are less
xq = 1:16; % interpolate to 16 - it doesn't really change anything.

for i = 1:length(data2_X)
    for ii = 1:length(data2_X{i})
        for iii = 1:length(data2_X{i}{ii}) % number of trials
        
            if length(data2_X{i}{ii}{iii}) < 16
                if length(data2_X{i}{ii}{iii}) == 13
                    x = 1:13;
                elseif length(data2_X{i}{ii}{iii}) == 14
                    x = 1:14;
                elseif length(data2_X{i}{ii}{iii}) == 15
                    x = 1:15;
                end
                v = data2_X{i}{ii}{iii};
                data2_X{i}{ii}{iii} = round(interp1(x,v,xq,'spline'));
            end
            
            if length(data2_Y{i}{ii}{iii}) < 16   
                if length(data2_Y{i}{ii}{iii}) == 13
                    x = 1:13;
                elseif length(data2_Y{i}{ii}{iii}) == 14
                    x = 1:14;
                elseif length(data2_Y{i}{ii}{iii}) == 15
                    x = 1:15;
                end                
                v = data2_Y{i}{ii}{iii};
                data2_Y{i}{ii}{iii} = round(interp1(x,v,xq,'spline'));
            end            
        end

        for iii = 1:length(data1_X{i}{ii}) % number of trials (num can differ depending on left/right)

            if length(data1_X{i}{ii}{iii}) < 16 
                if length(data1_X{i}{ii}{iii}) == 13
                    x = 1:13;
                elseif length(data1_X{i}{ii}{iii}) == 14
                    x = 1:14;
                elseif length(data1_X{i}{ii}{iii}) == 15
                    x = 1:15;
                end                
                v = data1_X{i}{ii}{iii};
                data1_X{i}{ii}{iii} = round(interp1(x,v,xq,'spline'));
            end
            
            if length(data1_Y{i}{ii}{iii}) < 16 
                if length(data1_Y{i}{ii}{iii}) == 13
                    x = 1:13;
                elseif length(data1_Y{i}{ii}{iii}) == 14
                    x = 1:14;
                elseif length(data1_Y{i}{ii}{iii}) == 15
                    x = 1:15;
                end                
                v = data1_Y{i}{ii}{iii};
                data1_Y{i}{ii}{iii} = round(interp1(x,v,xq,'spline'));
            end                          
        end
    end
end

% concatenate across trials
for i = 1:length(data2_X)
    for ii = 1:length(data2_X{i})
        data2_X{i}{ii} = vertcat(data2_X{i}{ii}{:});
        data1_X{i}{ii} = vertcat(data1_X{i}{ii}{:});
        data2_Y{i}{ii} = vertcat(data2_Y{i}{ii}{:});
        data1_Y{i}{ii} = vertcat(data1_Y{i}{ii}{:});
    end
end

% average across 4th shell (trials)
for i = 1:length(data2_X)
    data2_X{i} = cellfun(@mean,data2_X{i},'UniformOutput',false);
    data1_X{i} = cellfun(@mean,data1_X{i},'UniformOutput',false);
    data2_Y{i} = cellfun(@mean,data2_Y{i},'UniformOutput',false);
    data1_Y{i} = cellfun(@mean,data1_Y{i},'UniformOutput',false);
end

% horizontally concatenate data into one string per session, concatenating
% the bins of position data
for i = 1:length(data2_X)
    data2_X{i} = horzcat(data2_X{i}{:});
    data2_Y{i} = horzcat(data2_Y{i}{:});
    data1_X{i} = horzcat(data1_X{i}{:});
    data1_Y{i} = horzcat(data1_Y{i}{:});
end

% vertically concatenate across sessions
data2_X = vertcat(data2_X{:});
data2_Y = vertcat(data2_Y{:});
data1_X = vertcat(data1_X{:});
data1_Y = vertcat(data1_Y{:});

% average across sessions
xdata2Mean = mean(data2_X);
xdata1Mean = mean(data1_X);
ydata2Mean = mean(data2_Y);
ydata1Mean = mean(data1_Y);
%}
