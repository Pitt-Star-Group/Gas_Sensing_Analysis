%Show plot? yes/no

To_Plot = 'no';
To_Save = 'no';
Multiple_File = '';
Devices_Count = 28;

%Fill out file directory and sensor conductivity data.

Directory = 'C:\Users\Sean\Box Sync\Graduate School\Research\Data\Sensor\New Gas Sensing\MOF\HKUST-1\2019-04-08 - Pd-IsoSol - H2 Sensing';
SMU_Files = '2019-04-05 - Pd-IsoSol 4-5-19 1 through 8 - H2 Sensing Stability Test 1 SMU.xlsx';

%Fill out information below.

Material = 'PdNP + IsoSol S-100'; %Sensor chemistry/material used
Package_ID = 'Pd-IsoSol 4-5-19'; %Names of chips used
Media = 'Air'; %Carrier gas
Analyte = '100.1 ppm and 10.00 vol% H2 balanced in H2'; %Analyte(s) exposed to the sensor

%Experimental Parameters

DAQ_Interval = 2; %Time delay between each measurement cycle in seconds.
Background_Collection_Period = 0; %Time before MFC starts
Exposure_Period =           [5;     5;      5;      5;      5;      5;      5;      5;      5;]; %Duration of the analyte exposure in minutes
Purge_Period =              [5;     5;      5;      5;      5;      5;      5;      5;      5;]; %Duration of the purge in minutes
Exposure_Time_Points =      [30;    40;     50;     60;     70;     80;     90;     100;    110;]; %Time points of analyte introduction
Exposure_Concentrations =   [25;    25;     25;     50;     75;     100;    5000;   10000;  20000;];
Exposures = size(Exposure_Concentrations, 1);

Exposure_Index_Offset = 2;

%Include any additional experimental details.

Experiment_Details = 'Pd-IsoSol 2019-02-01&08 H2 Sensing Stability Test';

%Set the output file root name.

Output_File_Name = 'Analysis - Exposure & Response Fitting - ';

cd(Directory);
SMU_File_Names = dir(['*SMU*']);

File_Count = size(SMU_File_Names, 1);
SMU_Data = struct('time_data', {}, 'current_data', {}, 'textdata', {}, 'colheaders', {}, 'current_data_normalized', {}, 'current_data_sgolay_smoothed', {}, 'current_data_1st_derivative', {});

First_Exposure = Exposure_Time_Points(1) * 60 / DAQ_Interval + Exposure_Index_Offset;

for count1 = 1:File_Count
    
    Imported_Data = importdata(SMU_File_Names(count1,1).name);
    SMU_Data(count1,1).time_data(:,1) = Imported_Data.data(:,1);
    SMU_Data(count1,1).time_data(:,2) = Imported_Data.data(:,1)/60;
    SMU_Data(count1,1).current_data = Imported_Data.data(:,2:Devices_Count+1);
    
    SMU_Data(count1,1).textdata = Imported_Data.textdata;
    SMU_Data(count1,1).colheaders = Imported_Data.colheaders;
    
    SMU_Data(count1,1).current_data_normalized = SMU_Data(count1).current_data(:,:)./SMU_Data(count1).current_data(First_Exposure,:);
    SMU_Data(count1,1).current_data_sgolay_smoothed = sgolayfilt(SMU_Data(count1).current_data_normalized, 2, 5);
    SMU_Data(count1,1).current_data_1st_derivative = diff(SMU_Data(count1).current_data_sgolay_smoothed)./diff(SMU_Data(count1).time_data(2,:));
    
    %Matches the row size of 1st derivative data to current data
    Row_Size_Difference = size(SMU_Data(count1,1).current_data_normalized,1) - size(SMU_Data(count1,1).current_data_1st_derivative,1);
    Deriv_1st_Empty_Rows = NaN(Row_Size_Difference, Devices_Count);
    SMU_Data(count1,1).current_data_1st_derivative = [SMU_Data(count1,1).current_data_1st_derivative; Deriv_1st_Empty_Rows];
    
    %Verifies that the number of exposure time points match with number of exposures
    
    if size(Exposure_Time_Points,1) ~= size(Exposure_Concentrations,1)
        
        throw(MException('Exposure_Times_Points and Exposure_Concentrations do not correspond'));
    
    end
        
    SMU_Data(count1,1).Response_Initial_Final(:,1) = Exposure_Concentrations;
    SMU_Data(count1,1).Response_Time_Final(:,1) = Exposure_Concentrations;
    SMU_Data(count1,1).Recovery_Initial_Final(:,1) = Exposure_Concentrations;
    SMU_Data(count1,1).Recovery_Time_Final(:,1) = Exposure_Concentrations;
    
    for count2 = 1:Exposures
        
        Exposure_Start = fix((Exposure_Time_Points(count2) - 1 + Background_Collection_Period) * 60 / DAQ_Interval);
        Exposure_End = fix(Exposure_Start + Exposure_Period(count2) * 60 / DAQ_Interval);
        
        Purge_Start = Exposure_End + 1;
        Purge_End = fix(Purge_Start + Purge_Period(count2) * 60 / DAQ_Interval);
        
        Exposure_Start_Current = SMU_Data(count1,1).current_data(Exposure_Start,:);
        First_Exposure_Start_Current = SMU_Data(count1,1).current_data(First_Exposure,:);
        Exposure_End_Current = SMU_Data(count1,1).current_data(Exposure_End,:);
        
        Purge_Start_Current = SMU_Data(count1,1).current_data(Purge_Start,:);
        Purge_End_Current = SMU_Data(count1,1).current_data(Purge_End,:);
        
        SMU_Data(count1,1).Response_Initial_Final(count2, 2:Devices_Count+1) = (Exposure_End_Current - Exposure_Start_Current) ./ Exposure_Start_Current;
        SMU_Data(count1,1).Response_Time_Final(count2, 2:Devices_Count+1) = (Exposure_End_Current - First_Exposure_Start_Current) ./ First_Exposure_Start_Current;
        SMU_Data(count1,1).Recovery_Initial_Final(count2, 2:Devices_Count+1) = (Purge_End_Current - Purge_Start_Current) ./ Exposure_Start_Current;
        SMU_Data(count1,1).Recovery_Time_Final(count2, 2:Devices_Count+1) = (Purge_End_Current - Purge_Start_Current) ./ First_Exposure_Start_Current;
        
    end
end

for count3 = 1:File_Count
    
    fileID1 = fopen(['Analysis - Full Data - Run ', num2str(count3), '.txt'], 'w');
    
    fprintf(fileID1, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Package_ID:', Package_ID, 'Experimental Details:', Experiment_Details);
    fprintf(fileID1, '%s\n', '');
    fprintf(fileID1, '%s\t', 'Time (s)');
    fprintf(fileID1, '%s\t', 'Time (min)');
    
    Combined_Data = [];
    Combined_Data = [Combined_Data, SMU_Data(count3,1).time_data(:,:)];
    Combined_Data = [Combined_Data, SMU_Data(count3,1).current_data(:,:)];
    Combined_Data = [Combined_Data, SMU_Data(count3,1).current_data_normalized(:,:)];
    Combined_Data = [Combined_Data, SMU_Data(count3,1).current_data_1st_derivative(:,:)];
    
    Package_Header = [];
    
    for count4 = 0:Devices_Count/2-1
        
        Chip_Number = fix(count4/4)+1;
        
        if mod(count4, 4) == 0
            Device_ID = 'A';
        elseif mod(count4, 4) == 1
            Device_ID = 'B';
        elseif mod(count4, 4) == 2
            Device_ID = 'C';
        elseif mod(count4, 4) == 3
            Device_ID = 'D';            
        end
            
        Package_Header = [Package_Header, string(['Chip ', num2str(Chip_Number), ' Device ', Device_ID])];
        
    end
    
    for count5 = Devices_Count/2:Devices_Count-1
        
        Chip_Number = fix((count5+2)/4)+1;
        
        if mod(count5, 4) == 2
            Device_ID = 'A';
        elseif mod(count5, 4) == 3
            Device_ID = 'B';
        elseif mod(count5, 4) == 0
            Device_ID = 'C';
        elseif mod(count5, 4) == 1
            Device_ID = 'D';            
        end
        
        Package_Header = [Package_Header, string(['Chip ', num2str(Chip_Number), ' Device ', Device_ID])];
        
    end
    
    for count7 = 1:Devices_Count
       
        Package_Header = [Package_Header, [Package_Header(count7) + " Norm"]];
        
    end
    
    for count8 = 1:Devices_Count
       
        Package_Header = [Package_Header, [Package_Header(count8) + " Deriv"]];
        
    end
    
    for count9 = 1:size(Package_Header, 2)
        
        fprintf(fileID1, '%s\t', Package_Header(count9));
        
    end
    
    fprintf(fileID1, '%s\n', '');
    
    for count6 = 1:size(Combined_Data, 1)
        
        fprintf(fileID1, '%e\t', Combined_Data(count6, :));
        fprintf(fileID1, '%s\n', '');
        
    end
            
    fileID2 = fopen(['Analysis - Calibration - Run ', num2str(count3), '.txt'], 'w');
    
    fprintf(fileID2, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Package_ID:', Package_ID, 'Experimental Details:', Experiment_Details);
    fprintf(fileID2, '%s\n', '');
    fprintf(fileID2, '%s\t', 'Concentration (ppm)');
    fprintf(fileID2, '%s\n', '');
    
    Combined_Calibration = [];
    Combined_Calibration = [Combined_Calibration, SMU_Data(count3,1).Response_Initial_Final];
    Combined_Calibration = [Combined_Calibration, SMU_Data(count3,1).Response_Time_Final];
    Combined_Calibration = [Combined_Calibration, SMU_Data(count3,1).Recovery_Initial_Final];
    Combined_Calibration = [Combined_Calibration, SMU_Data(count3,1).Recovery_Time_Final];
    
    for count10 = 1:size(Combined_Calibration, 1)
       
        fprintf(fileID2, '%e\t', Combined_Calibration(count10,:));
        fprintf(fileID2, '%s\n', '');
        
    end
    
    fclose('all');
    
end

%Code to save the data are generated.
if strcmp(To_Save, 'yes')

    fileID = fopen(['Analysis - Full Data - ', SMU_Files, '.txt'], 'w');
    fprintf(fileID, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Chip_ID:', Chip_ID, 'Experimental Details:', Experiment_Details);
    fprintf(fileID, '%s\n', '');
    fprintf(fileID, '%s\t', 'Time (s)');
    fprintf(fileID, '%s\t', 'Time (min)');
    
    for count1 = 1:Devices_Count
        
        Device_ID = ['Dev ', Devices(count1), ' - Normalized Current'];
        fprintf(fileID, '%s\t', Device_ID);
        fprintf(fileID, '%s\t', 'Rel. Change in Current');
        fprintf(fileID, '%s\t', 'Rel. Change in Slope');
        
    end
    
    fprintf(fileID, 's\n', '');
    
    for count1 = 1:size(SMU_Data.Normalized_Slope_Change,1)
        
        fprintf(fileID, '%d\t', SMU_Data.Time(count1));
        fprintf(fileID, '%d\t', SMU_Data.Time(count1)/60);
        
        for count2 = 1:Devices_Count
            
            fprintf(fileID, '%e\t', SMU_Data.Normalized_Current(count1,count2));
            fprintf(fileID, '%e\t', SMU_Data.Normalized_Current_Change(count1,count2));
            fprintf(fileID, '%e\t', SMU_Data.Normalized_Slope_Change(count1,count2));
            
        end
        
        fprintf(fileID, '\n', '');
        
    end
    
    fclose('all');
    
    fileID = fopen([Output_File_Name, SMU_Files, '.txt'], 'w');
    fprintf(fileID, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Chip_ID:', Chip_ID, 'Experimental Details:', Experiment_Details);
    fprintf(fileID, '%s\n', '');
    fprintf(fileID, '%s\t', '');
    
    for count1 = 1:Devices_Count

        for count2 = 1:Exposures
            
            Field_Variable = compose("Exposure%d", count2);
        
            Figure_Name = compose("Device %s - Exposure %d - %.1f ppm", Devices(count1), count2, SMU_Data.Concentrations(count2));
    
            Exp_Fit_Eq = compose("%.4e*exp(%.4e*x)+%.4e*exp(%.4e*x)",SMU_Data.(Field_Variable).Fitting_Data{2, count1});
            Rec_Fit_Eq = compose("%.4e*exp(%.4e*x)+%.4e*exp(%.4e*x)",SMU_Data.(Field_Variable).Fitting_Data{6, count1});
    
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
    
    Combined_Fit_Data = [Combined_Fit_Data, SMU_Data.(Field_Variable).Time];
    
        for count2 = 1:Exposures
            
            Fit_Data = zeros(size(Time_Normalization, 1), 3);
            Fit_Data(1:end, 1) = SMU_Data.(Field_Variable).Normalized_Current_Change(:, count1);
            Fit_Data(Exposure_Start_Index:Exposure_End_Index, 2) = SMU_Data.(Field_Variable).y_res_offset(:,count1);
            Fit_Data(Recovery_Start_Index:Recovery_End_Index, 3) = SMU_Data.(Field_Variable).y_rec_offset(:,count1);
    
            Combined_Fit_Data = [Combined_Fit_Data, Fit_Data];
            
        end
    end
            
            
    for count1 = 1:size(Combined_Fit_Data,1)
    
        fprintf(fileID, '%e\t', Combined_Fit_Data(count1, :));
        fprintf(fileID, '%s\n', '');
    
    end

    fclose('all');
    
    fileID = fopen(['Analysis - Fit Coeff - ', SMU_Files, '.txt'], 'w');
    fprintf(fileID, '%s\t', 'Material:', Material, 'Analyte:', Analyte, 'Media:', Media, 'Chip_ID:', Chip_ID, 'Experimental Details:', Experiment_Details, 'File Name', SMU_Files);
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
        
            fprintf(fileID, '%e\t', SMU_Data.(Field_Variable).Fitting_Data{2, count2});
        
        end
    
        fprintf(fileID, '%s\n', '');
    
    end

    fprintf(fileID, '%s\n', '');
    fprintf(fileID, '%s\n', 'Recovery');

    for count1 = 1:Exposures
    
        fprintf(fileID, '%.1f\t', Exposure_Concentrations(count1));
    
        Field_Variable = compose("Exposure%d", count1);
    
        for count2 = 1:Devices_Count
        
            fprintf(fileID, '%e\t', SMU_Data.(Field_Variable).Fitting_Data{6, count2});
        
        end
    
        fprintf(fileID, '%s\n', '');
    
    end

    fclose('all');
    
    Saveas = [Output_File_Name, SMU_Files, '.m'];

    save(Saveas);

end