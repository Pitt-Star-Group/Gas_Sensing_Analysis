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
Background_Collection_Period = 4.5; %Time before MFC starts
Exposure_Period = 5; %Duration of the analyte exposure in minutes
Purge_Period = 10; %Duration of the purge in minutes
Exposure_Time_Points = [60; 75; 90; 105; 120; 135; 150; 165; 180; 195; 210; 225; 360]; %
Exposure_Concentrations = [1; 1; 1; 2.5; 5; 10; 100; 100; 100; 250; 400; 573; 90];
Exposures = size(Exposure_Concentrations, 1);

Exposure_Fitting_Offset = [
    
];
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

Sensing_Data.Device_ID = Raw_SourceMeter_Data.textdata(1,2:end);
Sensing_Data.Time = Raw_SourceMeter_Data.data(:,1);
Sensing_Data.Current = Raw_SourceMeter_Data.data(:,2:end);
Sensing_Data.Normalized_Current_Change = (Sensing_Data.Current-Sensing_Data.Current(1,:))./Sensing_Data.Current(1,:);
Sensing_Data.Normalized_Slope_Change = (Sensing_Data.Current(2:end,:)-Sensing_Data.Current(1:end-1,:))./Sensing_Data.Current(1,:);

Sensing_Data.Concentrations = Exposure_Concentrations;

Sensing_Data.Full_Plots = cell(1,Devices_Count);

for count1 = 1:Exposures
    
    Field_Variable = compose("Exposure%d", count1);
    Exposure_Start = fix((Exposure_Time_Points(count1)+Background_Collection_Period)*60/DAQ_Interval+3);    
    Purge_End = fix(Exposure_Start + (Exposure_Period + Purge_Period)*60/DAQ_Interval);
    
    %Fits exposure and response to separate biexponentials.
    
    Time_Normalization = Sensing_Data.Time(Exposure_Start:Purge_End,:);
    Current_Normalization = Sensing_Data.Current(Exposure_Start:Purge_End,:);
    
    %Sets point of exposure to t = 0 sec; normalizes current to relative
    %change from t = 0
    
    Exposure_Start_Index = 37;
    Exposure_End_Index = Exposure_Start_Index + 200;
    
    Sensing_Data.(Field_Variable).Time = Time_Normalization(:,1) - Time_Normalization(Exposure_Start_Index,1);
    Sensing_Data.(Field_Variable).Normalized_Current_Change = Current_Normalization(:,:)./Current_Normalization(Exposure_Start_Index,:);
    
    Normalized_Response_Time = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index,1)-Sensing_Data.(Field_Variable).Time(Exposure_Start_Index,1);
    Normalized_Response_Current = Current_Normalization(Exposure_Start_Index:Exposure_End_Index,:)./Current_Normalization(Exposure_Start_Index,:);
    
    Recovery_Start_Index = Exposure_Start_Index + Exposure_Period * 60 / DAQ_Interval + 15;
    Recovery_End_Index = Recovery_Start_Index + 200;
    
    Normalized_Recovery_Time = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index,1)-Sensing_Data.(Field_Variable).Time(Recovery_Start_Index,1);
    Normalized_Recovery_Current = Current_Normalization(Recovery_Start_Index:Recovery_End_Index,:)./Current_Normalization(Recovery_Start_Index,:);
    
    Fit_Options = fitoptions('exp2','MaxFunEvals',1000,'MaxIter',1000);
    
    Sensing_Data.(Field_Variable).Plots = cell(3,Devices_Count);
    Sensing_Data.(Field_Variable).Fitting_Data = cell(8,Devices_Count);
    
    for count2 = 1:Devices_Count
        
        try
            
            [Response_Fit, Goodness_of_Fit1, Algo_Info1] = fit(Normalized_Response_Time(:,1),Normalized_Response_Current(:,count2),'exp2');
            [Recovery_Fit, Goodness_of_Fit2, Algo_Info2] = fit(Normalized_Recovery_Time(:,1),Normalized_Recovery_Current(:,count2),'exp2');
            Response_Coeff = coeffvalues(Response_Fit);
            Recovery_Coeff = coeffvalues(Recovery_Fit);
            
        catch
            
            warning('Data for a broken device is attempting to be processed');
            Response_Fit = 0;
            Response_Coeff = 0;
            Goodness_of_Fit1 = 0;
            Algo_Info1 = 0;
            Recovery_Fit = 0;
            Recovery_Coeff = 0;
            Goodness_of_Fit2 = 0;
            Algo_Info2 = 0;
            
        end
            
        Sensing_Data.(Field_Variable).Fitting_Data{1,count2} = Response_Fit;
        Sensing_Data.(Field_Variable).Fitting_Data{2,count2} = Response_Coeff;
        Sensing_Data.(Field_Variable).Fitting_Data{3,count2} = Goodness_of_Fit1;
        Sensing_Data.(Field_Variable).Fitting_Data{4,count2} = Algo_Info1;
        Sensing_Data.(Field_Variable).Fitting_Data{5,count2} = Recovery_Fit;
        Sensing_Data.(Field_Variable).Fitting_Data{6,count2} = Recovery_Coeff;
        Sensing_Data.(Field_Variable).Fitting_Data{7,count2} = Goodness_of_Fit2;
        Sensing_Data.(Field_Variable).Fitting_Data{8,count2} = Algo_Info2;
        
    end    
end

figure('Name','Full Data')
plot(Sensing_Data.Time,Sensing_Data.Normalized_Current_Change(:,:))
legend('1D','1B','1C','2D','2B','2A','2C')

figure('Name','Slope Data')
plot(Sensing_Data.Time(1:end-1), Sensing_Data.Normalized_Slope_Change)
legend('1D','1B','1C','2D','2B','2A','2C')
%{
for count1 = 1:Exposures
    
    Field_Variable = compose("Exposure%d", count1);
    
    for count2 = 1:Devices_Count
        
        Figure_Name = compose("Device %d - Exposure %d - %.1f ppm", count2, count1, Sensing_Data.Concentrations(count1));
        figure('Name', Figure_Name)
        plot(Sensing_Data.(Field_Variable).Time, Sensing_Data.(Field_Variable).Normalized_Current_Change(:,count2))
        hold on

        plot(Sensing_Data.(Field_Variable).Fitting_Data{1,count2}, Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:end), Sensing_Data.(Field_Variable).Normalized_Current_Change(Exposure_Start_Index:end,count2))
        hold off
    
    end
end
%}

Exposure_Analysis = 1;

fileID = fopen([Output_File_Name, '.txt'], 'w');
fprintf(fileID, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Chip_ID:', Chip_ID{1,1}, 'Experimental Details:', Experiment_Details);
fprintf(fileID, '%s\n', '');
fprintf(fileID, '%s\t', 'Time(s)');

for count1 = 1:Devices_Count

    Field_Variable = compose("Exposure%d", Exposure_Analysis);
    
    Figure_Name = compose("Device %d - Exposure %d - %.1f ppm", count1, 1, Sensing_Data.Concentrations(Exposure_Analysis));
    
    fprintf(fileID, '%s\t', Figure_Name);
    fprintf(fileID, '%e\t', Sensing_Data.(Field_Variable).Fitting_Data{2, count1});
    fprintf(fileID, '%e\t', Sensing_Data.(Field_Variable).Fitting_Data{6, count1});
    
end

fprintf(fileID, '%s\t', 'Time(s)');

for count1 = 1:Devices_Count
    
    fprintf(fileID, '%s\t', 'Normalized Current');
    fprintf(fileID, '%s\t', 'Response Current');
    fprintf(fileID, '%s\t', 'Recovery Fit');

end

fprintf(fileID, '%s\n', '');
Combined_Fit_Data = Sensing_Data.(Field_Variable).Time;

for count1 = 1:Devices_Count
    
    Field_Variable = compose("Exposure%d", Exposure_Analysis);
    
    Figure_Name = compose("Device %d - Exposure %d - %.1f ppm", count1, Exposure_Analysis, Sensing_Data.Concentrations(Exposure_Analysis));
    figure('Name', Figure_Name)
    
    plot(Sensing_Data.(Field_Variable).Time, Sensing_Data.(Field_Variable).Normalized_Current_Change(:,count1))
    hold on
    
    x_response = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index) - Sensing_Data.(Field_Variable).Time(Exposure_Start_Index);
    a_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(1);
    b_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(2);
    c_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(3);
    d_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(4);
    
    y_response = a_response*exp(b_response*x_response) + c_response*exp(d_response*x_response);
    
    x_res_offset = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index);
    y_res_offset = y_response - (y_response(1) - Sensing_Data.(Field_Variable).Normalized_Current_Change(Exposure_Start_Index, count1));
    
    plot(x_res_offset, y_res_offset)
    
    x_recovery = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index)-Sensing_Data.Exposure1.Time(Recovery_Start_Index);
    a_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(1);
    b_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(2);
    c_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(3);
    d_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(4);
    
    y_recovery = a_recovery*exp(b_recovery*x_recovery) + c_recovery*exp(d_recovery*x_recovery);
    
    x_rec_offset = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index);
    y_rec_offset = y_recovery - (y_recovery(1) - Sensing_Data.(Field_Variable).Normalized_Current_Change(Recovery_Start_Index, count1));

    plot(x_rec_offset, y_rec_offset)
    hold off
    
    Fit_Data = zeros(size(Time_Normalization,1),1);
    Fit_Data(Exposure_Start_Index:Exposure_End_Index) = y_res_offset;
    Fit_Data(Recovery_Start_Index:Recovery_End_Index) = y_rec_offset;
    
    Combined_Fit_Data = [Combined_Fit_Data, Fit_Data];
    
end

for count1 = 1:size(Combined_Fit_Data,1)
    
    fprintf(fileID, '%e\t', Combined_Fit_Data(count1, :));
    fprintf(fileID, '%s\n', '');
    
end

fclose('all');