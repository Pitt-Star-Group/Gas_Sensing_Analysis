%Type out file directory

Directory = 'C:\Users\Sean\Box Sync\Graduate School\Research\Data\Sensor\Gas Sensing Setup\Acetone';
cd(Directory);
%Fill out information below.

Material = 'Iso-sol';
Media = 'ethanol';
Analyte = 'THC';
Chip_ID = 'FET-6-Iso-sol';

%Include any additional experimental details.

Experiment_Details = 'Nanopure H2O liquid gated, 3x measurements 1 per 30 sec, -0.5 to +0.5 Vd, THC sensing, THC-BSA treatment';

%Set the output file root name.

Output_File_Name = 'Analysis iT';

%Inputs all the raw data from working devices into a structure matrix,
%where the rows indicate the experiment order and columns are functioning
%devices. The start and end rows indicate the range of rows that correspond 
%to 1 IVg plot measurement.

Experimental_Data = importdata('Chip 61 - 4 - selectivity test.txt');
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

A_Response_1 = Experimental_Data.data(Response_Start:Response_End,2);
A_Response_Change = Experimental_Data.data(Response_Start:Response_End,2)-Experimental_Data.data(Response_Start,2);
A_Response_Time = (Experimental_Data.data(Response_Start:Response_End,1)-Experimental_Data.data(Response_Start,1))/1000;

A_Recovery_1 = Experimental_Data.data(Recovery_Start:Recovery_End,2);
A_Recovery_Change = Experimental_Data.data(Recovery_Start:Recovery_End,2)-Experimental_Data.data(Response_Start,2);
A_Recovery_Time = (Experimental_Data.data(Recovery_Start:Recovery_End,1)-Experimental_Data.data(Recovery_Start,1))/1000+1;

figure
plot(A)

figure
plot(A_Response_Change)

figure
plot(A_Recovery_Change)

