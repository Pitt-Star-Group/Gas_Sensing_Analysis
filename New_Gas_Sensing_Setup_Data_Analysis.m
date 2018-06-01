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
Background_Collection_Period = 5 + 7/60; %Time before MFC starts
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

Output_File_Name = 'Fitting Analysis';

%Inputs all the raw data from working devices into a structure matrix,
%where the rows indicate the experiment order and columns are functioning
%devices. The start and end rows indicate the range of rows that correspond 
%to 1 IVg plot measurement.

Raw_SourceMeter_Data =  importdata('2018-05-10 - P3-TiO2 Acetone and Humidity Sensing 1 Electrical.xlsx');
%Raw_MFC_Data =          importdata('2018-05-11 - P3-TiO2 Pd Pt Iso-sol Purus Nano Acetone and Humidity Sensing 2 MFC.xlsx');

Chip_Count = size(Chip_ID, 2);
Devices_Count = size(Raw_SourceMeter_Data.data,2)-1;

Sensing_Data.Device_ID = Raw_SourceMeter_Data.textdata(1,:);
Sensing_Data.Time = Raw_SourceMeter_Data.data(:,1);
Sensing_Data.Current = Raw_SourceMeter_Data.data(:,2:end);
Sensing_Data.Normalized_Current_Change = (Sensing_Data.Current-Sensing_Data.Current(1,:))./Sensing_Data.Current(1,:);
Sensing_Data.Concentrations = Exposure_Concentrations;

for count1 = 1:Exposures
    
    Field_Variable = compose("Exposure%d", count1);
    Exposure_Start = fix((Exposure_Time_Points(count1)+Background_Collection_Period)*60/DAQ_Interval+3);    
    Purge_End = fix(Exposure_Start + (Exposure_Period + Purge_Period)*60/DAQ_Interval);
    
    %Sets point of exposure to t = 0 sec; normalizes current to relative
    %change from t = 0
    Current_Normalization = Sensing_Data.Current(Exposure_Start:Purge_End,:);
    Sensing_Data.(Field_Variable).Time = Sensing_Data.Time(Exposure_Start:Purge_End,1)-Sensing_Data.Time(Exposure_Start,1);
    Sensing_Data.(Field_Variable).Normalized_Current_Change = (Current_Normalization(:,:)-Current_Normalization(1,:))./Current_Normalization(1,:);
    
    %Fits exposure and response to separate biexponentials.
    Exposure_End_Index = Exposure_Period*60/DAQ_Interval;
    
    Normalized_Response_Time = Sensing_Data.(Field_Variable).Time(1:Exposure_End_Index,1)-Current_Normalization(1,:);
    Normalized_Response_Current = (Current_Normalization(1:Exposure_End_Index,:)-Current_Normalization(1,:))./Current_Normalization(1,:);
    
    Recovery_Start_Index = Exposure_End_Index + 1;
    
    Normalized_Recovery_Time = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:end,1)-Sensing_Data.(Field_Variable).Time(1,1);
    Normalized_Recovery_Current = Current_Normalization(Recovery_Start_Index:end,:);
    
    Fit_Options = fitoptions('exp2','MaxFunEvals',1000,'MaxIter',1000);
    
    Sensing_Data.(Field_Variable).Fitting_Data = cell(6,Devices_Count);
    
    for count2 = 1:Devices_Count
        try
            
            [Response_Fit, Goodness_of_Fit1, Algo_Info1] = fit(Normalized_Response_Time(:,1),Normalized_Response_Current(:,count2),'exp2');
            [Recovery_Fit, Goodness_of_Fit2, Algo_Info2] = fit(Normalized_Recovery_Time(:,1),Normalized_Recovery_Current(:,count2),'exp2');
            
        catch
            
            warning('Data for a broken device is attempting to be processed');
            Response_Fit = 0;
            Goodness_of_Fit1 = 0;
            Algo_Info1 = 0;
            Recovery_Fit = 0;
            Goodness_of_Fit2 = 0;
            Algo_Info2 = 0;
            
        end
            
        Sensing_Data.(Field_Variable).Fitting_Data{1,count2} = Response_Fit;
        Sensing_Data.(Field_Variable).Fitting_Data{2,count2} = Goodness_of_Fit1;
        Sensing_Data.(Field_Variable).Fitting_Data{3,count2} = Algo_Info1;
        Sensing_Data.(Field_Variable).Fitting_Data{4,count2} = Recovery_Fit;
        Sensing_Data.(Field_Variable).Fitting_Data{5,count2} = Goodness_of_Fit2;
        Sensing_Data.(Field_Variable).Fitting_Data{6,count2} = Algo_Info2;
        
    end    
end

X1 = Sensing_Data.Exposure1.Time(:,1);
Y1_1 = Sensing_Data.Exposure1.Normalized_Current_Change(:,1);
Y1_2 = Sensing_Data.Exposure1.Normalized_Current_Change(:,8);

X3 = Sensing_Data.Time(:,1);
Y3_1 = Sensing_Data.Normalized_Current_Change(:,1);
Y3_2 = Sensing_Data.Normalized_Current_Change(:,8);

figure
plot(X3,Y3_2)

figure
plot(X1,Y1_2)

save(Output_File_Name);