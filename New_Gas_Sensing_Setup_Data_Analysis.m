%Type out file directory

Directory = 'C:\Users\seani\Box Sync\Graduate School\Research\Data\Sensor\New Gas Sensing';
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

Sensing_Data.Device_ID = Raw_SourceMeter_Data.textdata(1,:);
Sensing_Data.Full_Data = Raw_SourceMeter_Data.data;
Sensing_Data.Concentrations = Exposure_Concentrations;

for count1 = 1:Exposures
    
    Field_Variable = compose("Exposure%d", count1);
    Exposure_Start = fix((Exposure_Time_Points(count1)+Background_Collection_Period)*60/DAQ_Interval+3);    
    Purge_End = fix(Exposure_Start + (Exposure_Period + Purge_Period)*60/DAQ_Interval);
    
    %Sets point of exposure to t = 0 sec; normalizes current to relative
    %change from t = 0
    Data_Normalization = Sensing_Data.Full_Data(Exposure_Start:Purge_End,:);
    Sensing_Data.(Field_Variable).Normalized_Data = Data_Normalization;
    Sensing_Data.(Field_Variable).Normalized_Data(:,1) = Data_Normalization(:,1)-Data_Normalization(1,1);
    Sensing_Data.(Field_Variable).Normalized_Data(:,2:end) = (Data_Normalization(:,2:end)-Data_Normalization(1,2:end))./Data_Normalization(1,2:end);
    
    %Fits exposure and response to separate biexponentials.
    Exposure_End_Index = Exposure_Period*60/DAQ_Interval;
    
    Normalized_Response = Data_Normalization(1:Exposure_End_Index,:)-Data_Normalization(1,:);
    Normalized_Response = Normalized_Response(:,2:end)./Data_Normalization(1,2:end);
    
    Recovery_Start_Index = Exposure_End_Index + 1;
    
    Normalized_Recovery = Data_Normalization(Recovery_Start_Index:end,:)-Data_Normalization(Recovery_Start_Index,:);
    Normalized_Recovery = Normalized_Recovery(:,2:end)./Data_Normalization(Recovery_Start_Index,2:end);
    
    Sensing_Data.(Field_Variable).Fitting_Data = cell(3,Devices_Count);
    
    for count2 = 1:Devices_Count
        try
            
            [Response_Fit, Goodness_of_Fit, Algo_Info] = fit(Normalized_Response(:,1),Normalized_Response(:,count2+1),'exp2');
            
        catch
            
            warning('Data for a broken device is attempting to be processed');
            Response_Fit = 0;
            Goodness_of_Fit = 0;
            Algo_Info = 0;
            
        end
            
        Sensing_Data.(Field_Variable).Fitting_Data{1,count2} = Response_Fit;
        Sensing_Data.(Field_Variable).Fitting_Data{2,count2} = Goodness_of_Fit;
        Sensing_Data.(Field_Variable).Fitting_Data{3,count2} = Algo_Info;
        
    end    
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

Chip1_Dev_A_X = Sensing_Data.Exposure7.Normalized_Data(:,1);
Chip1_Dev_A_Y = Sensing_Data.Exposure7.Normalized_Data(:,2);
X1 = Chip1_Dev_A_X(1:100);
Y1 = Chip1_Dev_A_Y(1:100);

Chip2_Dev_A_X = Sensing_Data.Exposure7.Normalized_Data(:,1);
Chip2_Dev_A_Y = Sensing_Data.Exposure7.Normalized_Data(:,8);
X2 = Chip2_Dev_A_X(1:100);
Y2 = Chip2_Dev_A_Y(1:100);

X3 = Sensing_Data.Full_Data(:,1)-Sensing_Data.Full_Data(1,1);
Y3_1 = (Sensing_Data.Full_Data(:,2)-Sensing_Data.Full_Data(1,2))/Sensing_Data.Full_Data(1,2);
Y3_2 = (Sensing_Data.Full_Data(:,8)-Sensing_Data.Full_Data(1,8))/Sensing_Data.Full_Data(1,8);

figure
plot(X3,Y3_1,X3,Y3_2)

[fit1, gof, output] = fit(X1,Y1,'exp2');
figure
plot(fit1,X1,Y1)

fit2 = fit(X2,Y2,'exp2');
figure
plot(fit2,X2,Y2)

%figure
%plot(A_Response_Change)

%figure
%plot(A_Recovery_Change)