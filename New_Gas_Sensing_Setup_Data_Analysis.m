%Type out file directory

Directory = 'C:\Users\seani\Box Sync\Graduate School\Research\Data\Sensor\New Gas Sensing\Analysis';
cd(Directory);
%Fill out information below.

Material = 'P3-TiO2';
Media = 'Air';
Analyte = 'Acetone';
Chip_ID = {'TiO2-1', 'TiO2-2'};

%Experimental Parameters

DAQ_Interval = 1; %Time delay between each measurement cycle in seconds.
Exposure_Time = 5; %Duration of the analyte exposure
Purge_Time = 10; %Duration of the purge
Exposure_Time_Points = [60; 75; 90; 105; 120; 135; 150; 165; 180; 195; 210; 225; 240;];
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

Sensing_Data = table(Raw_SourceMeter_Data.data);

%Creates parameters for the table to insert in respone and recovery data

Rows = Exposures+1;
Columns = size(Raw_SourceMeter_Data.textdata,2)+1;

%Data_Points = size(Experimental_Data.data,1);

%x_time = Experimental_Data.data(:,1);
%x_linspace = linspace(1,Data_Points,Data_Points);

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