%Type out file directory and sensor conductivity data.

Directory = 'C:\Users\seani\Box Sync\Graduate School\Research\Data\Sensor\New Gas Sensing\THC Sensor\2018-04-30 to 05-04 - Cannabix Sensors Calibration';
SourceMeter_File = 'Iso-sol CT 1 Blank Ethanol Bubbler Voff Electrical.xlsx';

cd(Directory);
Raw_SourceMeter_Data = importdata(SourceMeter_File);

%Fill out information below.

Material = 'Iso-sol'; %Sensor chemistry/material used
Chip_ID = {'Iso-sol CT 1'}; %Names of chips used
Media = 'Air'; %Carrier gas
Analyte = 'Blank ethanol'; %Analyte(s) exposed to the sensor

%Experimental Parameters

DAQ_Interval = 1; %Time delay between each measurement cycle in seconds.
Background_Collection_Period = 0; %Time before MFC starts
Exposure_Period = 5; %Duration of the analyte exposure in minutes
Purge_Period = 10; %Duration of the purge in minutes
Exposure_Time_Points = [5; 20; 35]; %
Exposure_Concentrations = [100; 100; 100];
Exposures = size(Exposure_Concentrations, 1);

Exposure_Fitting_Offset = [
    
];

%Include any additional experimental details.

Experiment_Details = '3x 1 ppm, 2.5 ppm, 5 ppm, 10 ppm, 3x 100 ppm, 250 ppm, 400 ppm, 573 ppm, 90% RH at Room Temp';

%Type in the exposure number to plot and export data.

Exposure_Plot = 1;

%Set the output file root name.

Output_File_Name = compose('Fitting Analysis Exposure %d', Exposure_Plot);

%Verifies that the number of exposure time points match with number of
%exposures

if size(Exposure_Time_Points,1) ~= size(Exposure_Concentrations,1)
    
    throw(MException('Exposure_Times_Points and Exposure_Concentrations do not correspond'));

end

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
    Exposure_Start = fix((Exposure_Time_Points(count1) - 1 + Background_Collection_Period) * 60 / DAQ_Interval);    
    Purge_End = fix(Exposure_Start + (Exposure_Period + Purge_Period + 1) * 60 / DAQ_Interval);
    
    %Fits exposure and response to separate biexponentials.
    
    Time_Normalization = Sensing_Data.Time(Exposure_Start:Purge_End,:);
    Current_Normalization = Sensing_Data.Current(Exposure_Start:Purge_End,:);
    
    %Sets point of exposure to t = 0 sec; normalizes current to relative
    %change from t = 0
    
    Exposure_Start_Index = 62;
    Exposure_End_Index = Exposure_Start_Index + 200;
    
    Sensing_Data.(Field_Variable).Time = Time_Normalization(:,1) - Time_Normalization(1,1);
    Sensing_Data.(Field_Variable).Normalized_Current_Change = Current_Normalization(:,:)./Current_Normalization(1,:);
    
    Normalized_Response_Time = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index,1)-Sensing_Data.(Field_Variable).Time(Exposure_Start_Index,1);
    Normalized_Response_Current = Current_Normalization(Exposure_Start_Index:Exposure_End_Index,:)./Current_Normalization(Exposure_Start_Index,:);
    
    Recovery_Start_Index = 370;
    Recovery_End_Index = Recovery_Start_Index + 300;
    
    Normalized_Recovery_Time = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index, 1)-Sensing_Data.(Field_Variable).Time(Recovery_Start_Index, 1);
    Normalized_Recovery_Current = Current_Normalization(Recovery_Start_Index:Recovery_End_Index, :)./Current_Normalization(Recovery_Start_Index, :);
    
    Fit_Options = fitoptions('exp2','MaxFunEvals',1000,'MaxIter',1000);
    
    Sensing_Data.(Field_Variable).Plots = cell(3,Devices_Count);
    Sensing_Data.(Field_Variable).Fitting_Data = cell(8,Devices_Count);
    
    for count2 = 1:Devices_Count
        
        try
            
            [Response_Fit, Goodness_of_Fit1, Algo_Info1] = fit(Normalized_Response_Time(:,1),Normalized_Response_Current(:,count2),'exp2');
            Response_Coeff = coeffvalues(Response_Fit);
            
        catch
            
            Message = join(['Response data for ', string(count2), ' cannot be fitted.']);
            warning(Message);
            
            Response_Fit = 0;
            Response_Coeff = 0;
            Goodness_of_Fit1 = 0;
            Algo_Info1 = 0;
                        
        end
        
        try
            
            [Recovery_Fit, Goodness_of_Fit2, Algo_Info2] = fit(Normalized_Recovery_Time(:,1),Normalized_Recovery_Current(:,count2),'exp2');
            Recovery_Coeff = coeffvalues(Recovery_Fit);
            
        catch
            
            Message = join(['Recovery data for ', string(count2), ' cannot be fitted.']);
            warning(Message);
            
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
legend('1D','1B','1A','1C')

figure('Name','Slope Data')
plot(Sensing_Data.Time(1:end-1), Sensing_Data.Normalized_Slope_Change)
legend('1D','1B','1A','1C')

fileID = fopen([Output_File_Name{1}, SourceMeter_File, '.txt'], 'w');
fprintf(fileID, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Chip_ID:', Chip_ID{1,1}, 'Experimental Details:', Experiment_Details);
fprintf(fileID, '%s\n', '');
fprintf(fileID, '%s\t', '');

for count1 = 1:Devices_Count

    Field_Variable = compose("Exposure%d", Exposure_Plot);
        
    Figure_Name = compose("Device %d - Exposure %d - %.1f ppm", count1, 1, Sensing_Data.Concentrations(Exposure_Plot));
    
    Exp_Fit_Eq = compose("%.4e*exp(%.4e*x)+%.4e*exp(%.4e*x)",Sensing_Data.(Field_Variable).Fitting_Data{2, count1});
    Rec_Fit_Eq = compose("%.4e*exp(%.4e*x)+%.4e*exp(%.4e*x)",Sensing_Data.(Field_Variable).Fitting_Data{6, count1});
    
    fprintf(fileID, '%s\t', Figure_Name);
    fprintf(fileID, '%s\t', Exp_Fit_Eq);
    fprintf(fileID, '%s\t', Rec_Fit_Eq);
    
end

fprintf(fileID, '%s\n', '');
fprintf(fileID, '%s\t', 'Time(s)');

for count1 = 1:Devices_Count
    
    fprintf(fileID, '%s\t', 'Normalized Current');
    fprintf(fileID, '%s\t', 'Response Current');
    fprintf(fileID, '%s\t', 'Recovery Fit');

end

fprintf(fileID, '%s\n', '');
Combined_Fit_Data = Sensing_Data.(Field_Variable).Time;

for count1 = 1:Devices_Count
    
    Field_Variable = compose("Exposure%d", Exposure_Plot);
    
    Figure_Name = compose("Device %d - Exposure %d - %.1f ppm", count1, Exposure_Plot, Sensing_Data.Concentrations(Exposure_Plot));
    figure('Name', Figure_Name)
    
    plot(Sensing_Data.(Field_Variable).Time, Sensing_Data.(Field_Variable).Normalized_Current_Change(:,count1))
    hold on
    
    try
        
        x_response = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index) - Sensing_Data.(Field_Variable).Time(Exposure_Start_Index);
        a_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(1);
        b_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(2);
        c_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(3);
        d_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(4);
    
        y_response = a_response*exp(b_response*x_response) + c_response*exp(d_response*x_response);
    
        x_res_offset = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index);
        y_res_offset = y_response * Sensing_Data.(Field_Variable).Normalized_Current_Change(Exposure_Start_Index, count1);
    
        plot(x_res_offset, y_res_offset)
    
    catch
        
        Message = join(['Response data for ', string(count2), ' is missing.']);
        warning(Message);
        
        y_res_offset = zeros(Exposure_End_Index - Exposure_Start_Index, 1);
        
    end
    
    try
        
        x_recovery = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index)-Sensing_Data.Exposure1.Time(Recovery_Start_Index);
        a_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(1);
        b_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(2);
        c_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(3);
        d_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(4);
    
        y_recovery = a_recovery*exp(b_recovery*x_recovery) + c_recovery*exp(d_recovery*x_recovery);
    
        x_rec_offset = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index);
        y_rec_offset = y_recovery * Sensing_Data.(Field_Variable).Normalized_Current_Change(Recovery_Start_Index, count1);

        plot(x_rec_offset, y_rec_offset)
    
    catch
        
        Message = join(['Recovery data for ', string(count2), ' is missing.']);
        warning(Message);
        
        y_rec_offset = zeros(Recovery_End_Index - Recovery_Start_Index, 1);
        
    end
        
    hold off
    
    Fit_Data = zeros(size(Time_Normalization, 1), 3);
    Fit_Data(1:end, 1) = Sensing_Data.Exposure1.Normalized_Current_Change(:, count1);
    Fit_Data(Exposure_Start_Index:Exposure_End_Index, 2) = y_res_offset;
    Fit_Data(Recovery_Start_Index:Recovery_End_Index, 3) = y_rec_offset;
    
    Combined_Fit_Data = [Combined_Fit_Data, Fit_Data];
    
end

for count1 = 1:size(Combined_Fit_Data,1)
    
    fprintf(fileID, '%e\t', Combined_Fit_Data(count1, :));
    fprintf(fileID, '%s\n', '');
    
end

Saveas = [Output_File_Name{1}, SourceMeter_File];

fclose('all');
save(Saveas);