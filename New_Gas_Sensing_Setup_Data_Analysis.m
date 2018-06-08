%Show plot? yes/no

To_Plot = 'yes';
To_Save = 'yes';
Multiple_File = 'yes';

%Type out file directory and sensor conductivity data.

Directory = 'C:\Users\Sean\Box Sync\Graduate School\Research\Data\Sensor\New Gas Sensing\THC Sensor\2018-04-30 to 05-04 - Cannabix Sensors Calibration';
SourceMeter_File = 'Iso-sol CT 5 Blank Ethanol Bubbler Voff Electrical.xlsx';

cd(Directory);
Raw_SourceMeter_Data = importdata(SourceMeter_File);

%Fill out information below.

Material = 'Iso-sol'; %Sensor chemistry/material used
Chip_ID = 'Iso-sol CT 5'; %Names of chips used
Media = 'Air'; %Carrier gas
Analyte = 'Blank ethanol vapor'; %Analyte(s) exposed to the sensor

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

Experiment_Details = 'Blank ethanol vapor 5 min exposure 10 min purge';

%Set the output file root name.

Output_File_Name = 'Analysis - Exposure & Response Fitting - ';

%Verifies that the number of exposure time points match with number of
%exposures

if size(Exposure_Time_Points,1) ~= size(Exposure_Concentrations,1)
    
    throw(MException('Exposure_Times_Points and Exposure_Concentrations do not correspond'));

end

Chip_Count = size(Chip_ID, 2);
Devices = 'DBAC';
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
    
    Sensing_Data.(Field_Variable).Normalized_Response_Time = Normalized_Response_Time;
    Sensing_Data.(Field_Variable).Normalized_Response_Current = Normalized_Response_Current;
    
    Recovery_Start_Index = 371;
    Recovery_End_Index = Recovery_Start_Index + 250;
    
    Normalized_Recovery_Time = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index, 1)-Sensing_Data.(Field_Variable).Time(Recovery_Start_Index, 1);
    Normalized_Recovery_Current = Current_Normalization(Recovery_Start_Index:Recovery_End_Index, :)./Current_Normalization(Recovery_Start_Index, :);
    
    Sensing_Data.(Field_Variable).Normalized_Recovery_Time = Normalized_Recovery_Time;
    Sensing_Data.(Field_Variable).Normalized_Recovery_Current = Current_Normalization(Recovery_Start_Index:Recovery_End_Index, :)./Current_Normalization(Recovery_Start_Index, :);
    
    Fit_Options = fitoptions('exp2','MaxFunEvals',10000,'MaxIter',10000);
    
    Sensing_Data.(Field_Variable).Fitting_Data = cell(8,Devices_Count);
    Sensing_Data.(Field_Variable).Response_Recovery = cell(2,Devices_Count);
    
    for count2 = 1:Devices_Count
        
        Normalized_Response = (Normalized_Response_Current(1,count2) - Normalized_Response_Current(200,count2)) ./ Normalized_Response_Current(1,count2);
        
        try
            
            [Response_Fit, Goodness_of_Fit1, Algo_Info1] = fit(Normalized_Response_Time(:,1),Normalized_Response_Current(:,count2),'exp2');
            Response_Coeff = coeffvalues(Response_Fit);
            
        catch
            
            Message = join(['Response data for', 'Device', Devices(count2), Field_Variable, 'cannot be fitted.']);
            warning(Message);
            
            Response_Fit = 0;
            Response_Coeff = [0, 0, 0, 0];
            Goodness_of_Fit1 = 0;
            Algo_Info1 = 0;
                        
        end
        
        Normalized_Recovery = (Normalized_Recovery_Current(1,count2) - Normalized_Recovery_Current(200,count2)) ./ Normalized_Recovery_Current(1,count2);
        
        try
            
            [Recovery_Fit, Goodness_of_Fit2, Algo_Info2] = fit(Normalized_Recovery_Time(:,1),Normalized_Recovery_Current(:,count2),'exp2');
            Recovery_Coeff = coeffvalues(Recovery_Fit);
            
        catch
            
            Message = join(['Recovery data for', 'Device', Devices(count2), Field_Variable, 'cannot be fitted.']);
            warning(Message);
            
            Recovery_Fit = 0;
            Recovery_Coeff = [0, 0, 0, 0];
            Goodness_of_Fit2 = 0;
            Algo_Info2 = 0;
            
        end
        
        Sensing_Data.(Field_Variable).Response_Recovery{1,count2} = Normalized_Response;
        Sensing_Data.(Field_Variable).Response_Recovery{2,count2} = Normalized_Recovery;
        
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

%Generates fitted data points that are offset to match the time and
%position of the response and recovery.

for count1 = 1:Devices_Count
    
    for count2 = 1:Exposures
        
        Field_Variable = compose("Exposure%d", count2);
        
        try
            
            x_response = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index) - Sensing_Data.(Field_Variable).Time(Exposure_Start_Index);
            a_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(1);
            b_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(2);
            c_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(3);
            d_response = Sensing_Data.(Field_Variable).Fitting_Data{2,count1}(4);
    
            y_response = a_response*exp(b_response*x_response) + c_response*exp(d_response*x_response);
    
            Sensing_Data.(Field_Variable).x_res_offset(:,count1) = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index);
            Sensing_Data.(Field_Variable).y_res_offset(:,count1) = y_response * Sensing_Data.(Field_Variable).Normalized_Current_Change(Exposure_Start_Index, count1);
    
        catch
            
            Message = join(['Response data for ', string(count2), ' is missing.']);
            warning(Message);
        
            Sensing_Data.(Field_Variable).x_res_offset(:,count1) = Sensing_Data.(Field_Variable).Time(Exposure_Start_Index:Exposure_End_Index);
            Sensing_Data.(Field_Variable).y_res_offset(:,count1) = zeros(Exposure_End_Index - Exposure_Start_Index + 1, 1);
                        
        end
    
        try
            
            x_recovery = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index)-Sensing_Data.(Field_Variable).Time(Recovery_Start_Index);
            a_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(1);
            b_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(2);
            c_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(3);
            d_recovery = Sensing_Data.(Field_Variable).Fitting_Data{6,count1}(4);
    
            y_recovery = a_recovery*exp(b_recovery*x_recovery) + c_recovery*exp(d_recovery*x_recovery);
    
            Sensing_Data.(Field_Variable).x_rec_offset(:,count1) = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index);
            Sensing_Data.(Field_Variable).y_rec_offset(:,count1) = y_recovery * Sensing_Data.(Field_Variable).Normalized_Current_Change(Recovery_Start_Index, count1);        
        
        catch
        
            Message = join(['Recovery data for Device', string(count1), 'Exposure', string(count2), 'is missing.']);
            warning(Message);
        
            Sensing_Data.(Field_Variable).x_rec_offset(:,count1) = Sensing_Data.(Field_Variable).Time(Recovery_Start_Index:Recovery_End_Index);
            Sensing_Data.(Field_Variable).y_rec_offset(:,count1) = zeros(Recovery_End_Index - Recovery_Start_Index + 1, 1);
        
        end        
    end
end

%Plots the data that are generated.

if strcmp(To_Plot, 'yes')    
    
    figure('Name','Full Data')
    plot(Sensing_Data.Time,Sensing_Data.Normalized_Current_Change(:,:))
    legend('1D','1B','1A','1C')

    figure('Name','Slope Data')
    plot(Sensing_Data.Time(1:end-1), Sensing_Data.Normalized_Slope_Change)
    legend('1D','1B','1A','1C')

    for count1 = 1:Devices_Count
    
        for count2 = 1:Exposures
            
            Field_Variable = compose("Exposure%d", count2);
            
            Figure_Name = compose("Device %s - Exposure %d - %.1f ppm", Devices(count1), count2, Sensing_Data.Concentrations(count2));
            figure('Name', Figure_Name)
    
            plot(Sensing_Data.(Field_Variable).Time, Sensing_Data.(Field_Variable).Normalized_Current_Change(:,count1))
            hold on
    
            plot(Sensing_Data.(Field_Variable).x_res_offset(:,count1), Sensing_Data.(Field_Variable).y_res_offset(:,count1))
            plot(Sensing_Data.(Field_Variable).x_rec_offset(:,count1), Sensing_Data.(Field_Variable).y_rec_offset(:,count1))
            
            hold off
            
        end
    end
end

%Code to save the data are generated.

if strcmp(To_Save, 'yes')

    fileID = fopen([Output_File_Name, SourceMeter_File, '.txt'], 'w');
    fprintf(fileID, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Chip_ID:', Chip_ID, 'Experimental Details:', Experiment_Details);
    fprintf(fileID, '%s\n', '');
    fprintf(fileID, '%s\t', '');
    
    for count1 = 1:Devices_Count

        for count2 = 1:Exposures
            
            Field_Variable = compose("Exposure%d", count2);
        
            Figure_Name = compose("Device %s - Exposure %d - %.1f ppm", Devices(count1), count2, Sensing_Data.Concentrations(count2));
    
            Exp_Fit_Eq = compose("%.4e*exp(%.4e*x)+%.4e*exp(%.4e*x)",Sensing_Data.(Field_Variable).Fitting_Data{2, count1});
            Rec_Fit_Eq = compose("%.4e*exp(%.4e*x)+%.4e*exp(%.4e*x)",Sensing_Data.(Field_Variable).Fitting_Data{6, count1});
    
            fprintf(fileID, '%s\t', Figure_Name);
            fprintf(fileID, '%s\t', Exp_Fit_Eq);
            fprintf(fileID, '%s\t', Rec_Fit_Eq);
    
        end
    end

    fprintf(fileID, '%s\n', '');
    fprintf(fileID, '%s\t', 'Time(s)');

    for count1 = 1:Devices_Count
    
        for count2 = 1:Exposures
    
            fprintf(fileID, '%s\t', 'Normalized Current');
            fprintf(fileID, '%s\t', 'Response Current');
            fprintf(fileID, '%s\t', 'Recovery Fit');

        end
    end

    fprintf(fileID, '%s\n', '');    
    
    Combined_Fit_Data = [];
    
    for count1 = 1:Devices_Count
    
    Combined_Fit_Data = [Combined_Fit_Data, Sensing_Data.(Field_Variable).Time];
    
        for count2 = 1:Exposures
            
            Fit_Data = zeros(size(Time_Normalization, 1), 3);
            Fit_Data(1:end, 1) = Sensing_Data.(Field_Variable).Normalized_Current_Change(:, count1);
            Fit_Data(Exposure_Start_Index:Exposure_End_Index, 2) = Sensing_Data.(Field_Variable).y_res_offset;
            Fit_Data(Recovery_Start_Index:Recovery_End_Index, 3) = Sensing_Data.(Field_Variable).y_rec_offset;
    
            Combined_Fit_Data = [Combined_Fit_Data, Fit_Data];
            
        end
    end
            
            
    for count1 = 1:size(Combined_Fit_Data,1)
    
        fprintf(fileID, '%e\t', Combined_Fit_Data(count1, :));
        fprintf(fileID, '%s\n', '');
    
    end

    fclose('all');
    
    fileID = fopen(['Analysis - Fit Coeff - ', SourceMeter_File, '.txt'], 'w');
    fprintf(fileID, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Chip_ID:', Chip_ID, 'Experimental Details:', Experiment_Details, 'File Name', SourceMeter_File);
    fprintf(fileID, '%s\n', '');
    fprintf(fileID, '%s\t', 'Response');

    for count1 = 1:Devices_Count
        
        Column_Names = compose("Device %s", Devices(count1));
        fprintf(fileID, '%s\t', Column_Names);
        fprintf(fileID, '%s\t', '', '', '');
            
    end

    fprintf(fileID, '%s\n', '');
    fprintf(fileID, '%s\t', 'Exposure # and Conc');

    for count1 = 1:Devices_Count
    
       fprintf(fileID, '%s\t', 'a','b','c','d'); 
    
    end

    fprintf(fileID, '%s\n', '');

    for count1 = 1:Exposures
    
        fprintf(fileID, '%.1f\t', Exposure_Concentrations(count1));
    
        Field_Variable = compose("Exposure%d", count1);
    
        for count2 = 1:Devices_Count
        
            fprintf(fileID, '%e\t', Sensing_Data.(Field_Variable).Fitting_Data{2, count2});
        
        end
    
        fprintf(fileID, '%s\n', '');
    
    end

    fprintf(fileID, '%s\n', '');
    fprintf(fileID, '%s\n', 'Recovery');

    for count1 = 1:Exposures
    
        fprintf(fileID, '%.1f\t', Exposure_Concentrations(count1));
    
        Field_Variable = compose("Exposure%d", count1);
    
        for count2 = 1:Devices_Count
        
            fprintf(fileID, '%e\t', Sensing_Data.(Field_Variable).Fitting_Data{6, count2});
        
        end
    
        fprintf(fileID, '%s\n', '');
    
    end

    fclose('all');

    Saveas = [Output_File_Name, SourceMeter_File, '.m'];

    save(Saveas);

end