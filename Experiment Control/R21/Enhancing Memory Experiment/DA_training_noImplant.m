%% prep 1 - clear history, workspace, get working directory
% _____________________________________________________

% --- MAKE SURE YOU RUN STARTUP_EXPERIMENTCONTROL --- %

%______________________________________________________

%% 
% sometimes if the session is not exceeding the time limit of 30 minutes,
% then the code will continue performing trials, but not save the data.
% Cheetah w%%

% clear/clc
clear; clc

% get directory that houses this code
codeDir = getCurrentPath();
addpath(codeDir)

%% confirm this is the correct code
prompt = ['What is your rats name? '];
targetRat = input(prompt,'s');

prompt   = ['Confirm that your rat is ' targetRat,' [y/Y OR n/N] '];
confirm  = input(prompt,'s');

if ~contains(confirm,[{'y'} {'Y'}])
    error('This code does not match the target rat')
end

prompt = ['What day of DA training is this? '];
FRday  = str2num(input(prompt,'s'));

prompt = ['Will treadmill be used? '];
tmUse  = (input(prompt,'s'));

prompt = ['Is this a treadmill training session? '];
tm_training  = (input(prompt,'s'));

if contains(tm_training,[{'y'} {'Y'}])
    prompt = ['What treadmill training day are you on? '];
    tDay  = str2num(input(prompt,'s'));
end

pause(20);

%% prep 2 - define parameters for the session

% how long should the session be?
session_length = 30; % minutes

% pellet count and machine timeout
pellet_count = 1;
timeout_len  = 60*15;

% define a looping time - this is in minutes
amountOfTime = (70/60); %session_length; % 0.84 is 50/60secs, to account for initial pause of 10sec .25; % minutes - note that this isn't perfect, but its a few seconds behind dependending on the length you set. The lag time changes incrementally because there is a 10-20ms processing time that adds up

%% experiment design prep.

% define number of trials
<<<<<<< Updated upstream:Experiment Control/R21/Enhancing Memory Experiment/DA_training_noImplant.m
<<<<<<< Updated upstream
numTrials  = 24;
=======
numTrials  = 25;
>>>>>>> Stashed changes
=======
numTrials  = 25;
>>>>>>> Stashed changes:Experiment Control/R21/Experimental Code/DA_training_noImplant.m

%% auto maze prep.

% -- automaze set up -- %

% check port
if exist("s") == 0
    % connect to the serial port making an object
    s = serialport("COM6",19200);
end

% load in door functions
doorFuns = DoorActions;

% test reward wells
rewFuns = RewardActions;

% get IR information
irBreakNames = irBreakLabels;

% for arduino
if exist("a") == 0
    % connect arduino
    a = arduino('COM5','Uno','Libraries','Adafruit\MotorShieldV2');
end

% digital ports for reverse maze
irArduino.Delay     = 'D8';
irArduino.rGoalArm  = 'D10';
irArduino.lGoalArm  = 'D12';
irArduino.rGoalZone = 'D7';
irArduino.lGoalZone = 'D2';
irArduino.Treadmill = 'D6';

%{
for i = 1:10000000
    readDigitalPin(a,irArduino.Treadmill)
end
%}

%% treadmill setup
% get treadmill
[treadFuns,treadSpeed] = TreadMillFuns;

% load treadmill functions and settings
[treadFuns,treadSpeeds] = TreadMillFuns;

% make an empty array
speed_cell = cell(size(fieldnames(treadSpeeds),1)+1,1);

% fill the first cell with nan because there is no 1mpm rate
speed_cell{1} = NaN;

% make an array where its row index is the speed
speed_cell(2:end) = struct2cell(treadSpeeds);

% randomize treadmill running durations
minDelay = 5;  % minimum delay duration set to 5 seconds
maxDelay = 15; % maximum delay duration set to 15 seconds
delay_durations = (maxDelay-minDelay).*rand(numTrials-1,1) + minDelay; % vector of values

%% clean the stored data just in case IR beams were broken
s.Timeout = 1; % 1 second timeout
next = 0; % set while loop variable
while next == 0
   irTemp = read(s,4,"uint8"); % look for stored data
   if isempty(irTemp) == 1     % if there are no stored ir beam breaks
       next = 1;               % break out of the while loop
       disp('IR record empty - ignore the warning')
   else
       disp('IR record not empty')
       disp(irTemp)
   end
end

% close all maze doors - this gives problems with solenoid box
pause(0.25)
writeline(s,[doorFuns.centralClose doorFuns.sbLeftClose ...
    doorFuns.sbRightClose doorFuns.tLeftClose doorFuns.tRightClose]);

pause(0.25)
writeline(s,[doorFuns.gzLeftClose doorFuns.gzRightClose])

%% start recording - make a noise when recording begins
load gong.mat;
sound(y);
pause(5)

%% trials
open_t  = [doorFuns.tLeftOpen doorFuns.tRightOpen];
close_t = [doorFuns.tLeftClose doorFuns.tRightClose];
maze_prep = [doorFuns.sbLeftOpen doorFuns.sbRightOpen ...
    doorFuns.tRightClose doorFuns.tLeftClose doorFuns.centralOpen ...
    doorFuns.gzLeftClose doorFuns.gzRightClose];

% mark session start
sStart = [];
sStart = tic;
sessEnd = 0;

c = clock;
session_start = str2num(strcat(num2str(c(4)),num2str(c(5))));
session_time  = session_start-session_start; % quick definitio of this so it starts the while loop
writeline(s,doorFuns.centralOpen);

% make this array ready to track amount of time spent at choice
time2choice = [];
for triali = 1:numTrials

    % start out with this as a way to make sure you don't exceed 30
    % minutes of the session
    if toc(sStart)/60 > session_length
        writeline(s,doorFuns.closeAll)
        %sessEnd = 1;            
        break % break out of for loop
    end        

    % set central door timeout value
    s.Timeout = .05; % 5 minutes before matlab stops looking for an IR break    

    % first trial - set up the maze doors appropriately
    writeline(s,[doorFuns.sbRightOpen doorFuns.sbLeftOpen doorFuns.centralOpen]);

    % set irTemp to empty matrix
    irTemp = []; 

    % t-beam
    tEntry = [];
    tEntry = tic;
    % check which direction the rat turns at the T-junction
    next = 0;
    while next == 0
        if readDigitalPin(a,irArduino.rGoalArm)==0
            
            % track the trajectory_text
            time2choice(triali) = toc(tEntry); % amount of time it took to make a decision
            trajectory_text{triali} = 'R';
            trajectory(triali)      = 0;            
            
            %pause(1);
            % Reward zone and eating
            % send to netcom 
            if triali > 1
                if contains(trajectory_text{triali-1},'L')
                    % only reward on an alternation
                    for rewardi = 1:pellet_count
                        %pause(0.25)
                       % writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightClose doorFuns.centralOpen]);
                        writeline(s,rewFuns.right)
                        %writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightClose doorFuns.centralOpen]);
                        %pause(0.25)
                    end    
                    
                end
            elseif triali == 1
                
                    for rewardi = 1:pellet_count
                        %pause(0.25)
                       % writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightClose doorFuns.centralOpen]);
                        writeline(s,rewFuns.right)
                        %writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightClose doorFuns.centralOpen]);
                        %pause(0.25)
                    end 
                    
            end
            pause(5)
            writeline(s,[doorFuns.gzRightOpen doorFuns.gzLeftOpen doorFuns.sbRightClose doorFuns.sbLeftClose doorFuns.tLeftClose doorFuns.tRightOpen]);
            %pause(5)
            %writeline(s,[doorFuns.gzRightOpen doorFuns.gzLeftOpen doorFuns.sbRightClose doorFuns.sbLeftClose doorFuns.tLeftClose doorFuns.tRightOpen]);

            % break while loop
            next = 1;

        elseif readDigitalPin(a,irArduino.lGoalArm)==0
            
            % track the trajectory_text
            time2choice(triali) = toc(tEntry); % amount of time it took to make a decision
            trajectory_text{triali} = 'L';
            trajectory(triali)      = 1;            
            
            %pause(1);
            % Reward zone and eating
            % send to netcom 
            if triali > 1
                % only reward on an alternation
                if contains(trajectory_text{triali-1},'R')
                    
                    for rewardi = 1:pellet_count
                        %pause(0.25)
                       % writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightClose doorFuns.centralOpen]);
                        writeline(s,rewFuns.left)
                        %writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightClose doorFuns.centralOpen]);
                        %pause(0.25)
                    end    
                    
                end
            elseif triali == 1
                
                    for rewardi = 1:pellet_count
                        %pause(0.25)
                       % writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightClose doorFuns.centralOpen]);
                        writeline(s,rewFuns.left)
                        %writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightClose doorFuns.centralOpen]);
                        %pause(0.25)
                    end 
                    
            end                      

            pause(5)
            writeline(s,[doorFuns.gzRightOpen doorFuns.gzLeftOpen doorFuns.sbRightClose doorFuns.sbLeftClose doorFuns.tRightClose doorFuns.tLeftOpen]);
           % pause(5)
            %writeline(s,[doorFuns.gzRightOpen doorFuns.gzLeftOpen doorFuns.sbRightClose doorFuns.sbLeftClose doorFuns.tRightClose doorFuns.tLeftOpen]);

            % break out of while loop
            next = 1;
        end
    end    

    % return arm
    next = 0;
    while next == 0
        %irTemp = read(s,4,"uint8");  

        if readDigitalPin(a,irArduino.lGoalZone)==0
            % send neuralynx command for timestamp

            % close both for audio symmetry
            pause(0.25)
            writeline(s,[doorFuns.gzLeftClose])
            pause(0.25)
            writeline(s,[doorFuns.gzRightClose])
            pause(0.25)
            writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightOpen]);
            pause(0.25)
            writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightOpen]);
            
            next = 1;                          
        elseif readDigitalPin(a,irArduino.rGoalZone)==0
            % send neuralynx command for timestamp

            % close both for audio symmetry
            pause(0.25)
            writeline(s,[doorFuns.gzLeftClose])
            pause(0.25)
            writeline(s,[doorFuns.gzRightClose])
            pause(0.25)
            writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightOpen]);
            pause(0.25)
            writeline(s,[doorFuns.sbLeftOpen doorFuns.sbRightOpen]);            

            next = 1;
        end

    end  
    writeline(s,doorFuns.centralClose);
    
    % startbox beam
    % return arm
    next = 0;
    while next == 0
        if readDigitalPin(a,irArduino.Delay)==0
            writeline(s,doorFuns.closeAll) 
            if triali ~= numTrials
                pause(10);
                next = 1;
            else
                next = 1;
            end
        end
    end

    if triali == numTrials || toc(sStart)/60 > session_length
        break % break out of for loop
    end       
    
    % open central door
    writeline(s,doorFuns.centralOpen)
    
    next = 0;
    while next == 0
        if readDigitalPin(a,irArduino.Treadmill)==0
            if contains(tmUse,[{'y'} {'Y'}])
                % treadmill run after the delay
                write(s,treadFuns.start,'uint8');
                
                if contains(tm_training,[{'y'} {'Y'}])
                    if tDay == 1
                        speedVector = [1 2 2 2];
                    elseif tDay == 2
                        speedVector = [1 2 3 3];
                    elseif tDay == 3
                        speedVector = [1 3 3 4];                
                    elseif tDay == 4
                        speedVector = [1 3 4 5];
                    elseif tDay == 5
                        speedVector = [1 3 5 5];
                    elseif tDay == 6
                        speedVector = [1 3 5 7];                
                    end                    
                else       
                    speedVector = [1 3 5 7];   
                end

                for i = speedVector
                    % set treadmill speed
                    write(s,uint8(speed_cell{i}'),'uint8'); % add a second command in case the machine missed the first one
                    pause(0.25)
                end   

                % pause for random time interval during delay
                disp(['Pausing for delay of ',num2str(delay_durations(triali)) ' seconds'])
                pause(delay_durations(triali))

                % stop treadmill and breakout
                write(s,treadFuns.stop,'uint8');
                next = 1;
            else
                % pause for random time interval during delay
                disp(['Pausing for delay of ',num2str(delay_durations(triali)) ' seconds'])
                pause(delay_durations(triali))
                next=1;
            end
        end
    end    
    

    if toc(sStart)/60 > session_length
        break % break out of for loop
    end      
end 

% get amount of time past since session start
c = clock;
session_time_update = str2num(strcat(num2str(c(4)),num2str(c(5))));
session_time = session_time_update-session_start;

% compute accuracy array
accuracy = [];
accuracy_text = cell(1, length(trajectory_text)-1);
for triali = 1:length(trajectory_text)-1
    if trajectory_text{triali} ~= trajectory_text{triali+1}
        accuracy(triali) = 0; % correct trial
        accuracy_text{triali} = 'correct';
    elseif trajectory_text{triali} == trajectory_text{triali+1}
        accuracy(triali) = 1; % incorrect trial
        accuracy_text{triali} = 'incorrect';
    end
end
percentAccurate = ((numel(find(accuracy==0)))/(numel(accuracy)))*100;

% perseveration index
for i = 2:numTrials-1
    % if the previous trajectory equals the future trajectory and the
    % previous trajectory is the current trajectory and the current trajectory is the future trajectory
    if (trajectory(i-1) == trajectory(i+1))  && (trajectory(i-1) == trajectory(i)) && (trajectory(i) == trajectory(i+1))
        persev(i-1) = 1;
    else
        persev(i-1) = 0;
    end
end

% perseveration index - because of indexing (consideration of 3 consecutive
% turns = perseveration), we have to do numTrials-2
percentPerseveration = (sum(persev)/(numTrials-2))*100;

% turn bias
rTurn = numel(find(contains(trajectory_text,'R')==1));
lTurn = numel(find(contains(trajectory_text,'L')==1));
percentBias = ((abs(rTurn-lTurn))/(rTurn+lTurn))*100;
disp(['Rat performed at ', num2str(percentAccurate), '%', ' perseverated ', num2str(percentPerseveration), '%', ' with a turn bias of ',num2str(percentBias),'%'])

%% ending noise - a fitting song to end the session
load handel.mat;
sound(y, 2*Fs);
writeline(s,[doorFuns.centralClose])

%% save data
% save data
c = clock;
c_save = strcat(num2str(c(2)),'_',num2str(c(3)),'_',num2str(c(1)),'_','EndTime',num2str(c(4)),num2str(c(5)));

prompt   = 'Please enter the rats name ';
rat_name = input(prompt,'s');

prompt   = 'Please enter the task ';
task_name = input(prompt,'s');

%prompt   = 'Enter the directory to save the data ';
%dir_name = input(prompt,'s');

save_var = strcat(rat_name,'_',task_name,'_',c_save);

place2store = ['X:\01.Experiments\R21\Experimental Cohort\Training Data'];
cd(place2store);
save(save_var);

%% clean maze

% close doors
writeline(s,doorFuns.closeAll);  

% treadmill run after the delay
write(s,treadFuns.start,'uint8');

for i = speedVector
    % set treadmill speed
    write(s,uint8(speed_cell{i}'),'uint8'); % add a second command in case the machine missed the first one
    pause(0.25)
end   
          
next = 0;
while next == 0
    
    % open doors and stop treadmill
    prompt = ['Are you finished cleaning (ie treadmill, walls, floors clean)? '];
    cleanUp = input(prompt,'s');

    if contains(cleanUp,[{'Y'} {'y'}])
        next = 1;
    else
        disp('Clean the maze!!!')
    end
end

write(s,treadFuns.stop,'uint8');

