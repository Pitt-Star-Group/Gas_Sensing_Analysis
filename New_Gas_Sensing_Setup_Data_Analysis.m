%Type out file directory

Directory = 'C:\Users\seani\Box Sync\Graduate School\Research\Data\Sensor\New Gas Sensing\Analysis';
cd(Directory);
%Fill out information below.

Material = 'P3-TiO2';
Media = 'Air';
Analyte = 'Acetone';
Chip_ID = 'P3-TiO2-1, P3-TiO2-2';
Working_Devices = 21;

%Experimental Parameters

DAQ_Interval = 1; %Time delay between each measurement cycle in seconds.
Exposure_Time = 5; %Duration of the analyte exposure
Purge_Time = 10; %Duration of the purge
Exposure_Time_Points = [60; 75; 90; 105; 120; 135; 150; 165; 180; 195; 210; 225; 240;];
Exposure_Concentrations = [1; 1; 1; 2.5; 5; 7.5; 10; 100; 100; 100; 250; 400; 573; 90];

%Include any additional experimental details.

Experiment_Details = '3x 1 ppm, 2.5 ppm, 5 ppm, 7.5 ppm, 10 ppm, 3x 100 ppm, 250 ppm, 400 ppm, 573 ppm, 90% RH at Room Temp';

%Set the output file root name.

Output_File_Name = 'Analysis iT';

%Inputs all the raw data from working devices into a structure matrix,
%where the rows indicate the experiment order and columns are functioning
%devices. The start and end rows indicate the range of rows that correspond 
%to 1 IVg plot measurement.

Raw_Experimental_Data = importdata('2018-05-11 - P3-TiO2 Pd Pt Iso-sol Purus Nano Acetone and Humidity Sensing 2 Analysis.xlsx');
Organized_Experimental_Data = Raw_Experimental_Data.data(:,17:17 + Working_Devices);
Data_Points = size(Experimental_Data.data,1);

x_time = Experimental_Data.data(:,1);
x_linspace = linspace(1,Data_Points,Data_Points);

A = Experimental_Data.data(:,2);
B = Experimental_Data.data(:,3);
C = Experimental_Data.data(:,3);
D = Experimental_Data.data(:,3);

Response_Start = 36035;
Response_End = 36235;

Recovery_Start = 36376;
Recovery_End = 37800;

%A_Response_1 = Experimental_Data.data(Response_Start:Response_End,2);
%A_Response_Change = Experimental_Data.data(Response_Start:Response_End,2)-Experimental_Data.data(Response_Start,2);
%A_Response_Time = (Experimental_Data.data(Response_Start:Response_End,1)-Experimental_Data.data(Response_Start,1))/1000;

%A_Recovery_1 = Experimental_Data.data(Recovery_Start:Recovery_End,2);
%A_Recovery_Change = Experimental_Data.data(Recovery_Start:Recovery_End,2)-Experimental_Data.data(Response_Start,2);
%A_Recovery_Time = (Experimental_Data.data(Recovery_Start:Recovery_End,1)-Experimental_Data.data(Recovery_Start,1))/1000+1;

%figure
%plot(A)

%figure
%plot(A_Response_Change)

%figure
%plot(A_Recovery_Change)