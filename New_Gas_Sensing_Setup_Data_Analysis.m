%Type out file directory

Directory = 'C:\Users\Sean\Box Sync\Graduate School\Research\Data\Sensor\New Gas Sensing';
cd(Directory);
%Fill out information below.

Material = 'P3-TiO2';
Media = 'Air';
Analyte = 'Acetone';
Chip_ID = {'TiO2-1', 'TiO2-2'};

%Experimental Parameters

DAQ_Interval = 1; %Time delay between each measurement cycle in seconds.
Background_Collection_Period = 5 + 3/60; %Time before MFC starts
Exposure_Period = 5; %Duration of the analyte exposure in minutes
Purge_Period = 10; %Duration of the purge in minutes
Exposure_Time_Points = [60; 75; 90; 105; 120; 135; 150; 165; 180; 195; 210; 225; 240]; %
Exposure_Concentrations = [1; 1; 1; 2.5; 5; 10; 100; 100; 100; 250; 400; 573; 90];
Exposures = size(Exposure_Concentrations, 1);

%Verifies that the number of exposure time points match with number of
%exposures

if size(Exposure_Time_Points,1) ~= size(Exposure_Concentrations,1)
    throw(MException('Exposure_Times_Points and Exposure_Concentrations do not correspond'));
end
    
%Include any additional experimental details.

Experiment_Details = '3x 1 ppm, 2.5 ppm, 5 ppm, 10 ppm, 3x 100 ppm, 250 ppm, 400 ppm, 573 ppm, 90% RH at Room Temp';

%Set the output file root name.

Output_File_Name = 'Analysis iT';

%Inputs all the raw data from working devices into a structure matrix,
%where the rows indicate the experiment order and columns are functioning
%devices. The start and end rows indicate the range of rows that correspond 
%to 1 IVg plot measurement.

Raw_SourceMeter_Data =  importdata('2018-05-10 - P3-TiO2 Acetone and Humidity Sensing 1 Electrical.xlsx');
%Raw_MFC_Data =          importdata('2018-05-11 - P3-TiO2 Pd Pt Iso-sol Purus Nano Acetone and Humidity Sensing 2 MFC.xlsx');

Chip_Count = size(Chip_ID, 2);
Devices_Count = size(Raw_SourceMeter_Data.data,2)-1;

NSensing_Data.Device_ID = Raw_SourceMeter_Data.textdata(1,:);
Sensing_Data.Full_Data = Raw_SourceMeter_Data.data;
Sensing_Data.Concentrations = Exposure_Concentrations;

for count1 = 1:Exposures
    
    Field_Variable = compose("Exposure%d", count1);
    Exposure_Start = fix((Exposure_Time_Points(count1)+Background_Collection_Period)*60/DAQ_Interval+3);
    Purge_End = fix(Exposure_Start + (Exposure_Period + Purge_Period)*60/DAQ_Interval);
    Sensing_Data.(Field_Variable) = Sensing_Data.Full_Data(Exposure_Start:Purge_End,:);
    Sensing_Data.(Field_Variable)(:,1) = Sensing_Data.(Field_Variable)(:,1)-Sensing_Data.(Field_Variable)(1,1);
    
end

%Data_Points = size(Experimental_Data.data,1);

%x_time = Experimental_Data.data(:,1);
%x_linspace = linspace(1,Data_Points,Data_Points);

%A_Response_1 = Experimental_Data.data(Response_Start:Response_End,2);
%A_Response_Change = Experimental_Data.data(Response_Start:Response_End,2)-Experimental_Data.data(Response_Start,2);
%A_Response_Time = (Experimental_Data.data(Response_Start:Response_End,1)-Experimental_Data.data(Response_Start,1))/1000;

%A_Recovery_1 = Experimental_Data.data(Recovery_Start:Recovery_End,2);
%A_Recovery_Change = Experimental_Data.data(Recovery_Start:Recovery_End,2)-Experimental_Data.data(Response_Start,2);
%A_Recovery_Time = (Experimental_Data.data(Recovery_Start:Recovery_End,1)-Experimental_Data.data(Recovery_Start,1))/1000+1;

X = Sensing_Data.Exposure7(:,1);
Y = (Sensing_Data.Exposure7(:,5)-Sensing_Data.Exposure7(1,5))/Sensing_Data.Exposure7(1,5);
X1 = X(1:300);
Y1 = Y(1:300);

X2 = X(301:901);
Y2 = Y(301:901);

X3 = Sensing_Data.Full_Data(305:605,1)-Sensing_Data.Full_Data(305,1);
Y3 = (Sensing_Data.Full_Data(305:605,5)-Sensing_Data.Full_Data(305,5))/Sensing_Data.Full_Data(305,5);

figure
plot(X3,Y3)

figure
plot(Sensing_Data.Full_Data(:,1),Sensing_Data.Full_Data(:,5))

figure
plot(X1,Y1)

figure
plot(X2,Y2)

%figure
%plot(A_Response_Change)

%figure
%plot(A_Recovery_Change)