#! /usr/bin/octave --no-gui

###########################################################################################
#
#
#  OCTAVE SCRIPT TO READ THE DATA FROM STREAK IMAGES, 
#     TRANFORM AND USE THEM 
#    Made by Gonzalo Rodríguez Prieto
#       (gonzalo#rprietoATuclm#es)
#       (Mail: change "#" by "." and "AT" by "@"
#              Version 1.00
#
#
#########################################################
#
#  It uses the functions: 
#            supsmu
#			 findpeaksx
#			 display_runded_matrix
#			 deri
#
#  They must be in the same directory.
#
###########################################################################################



clear; %Just in case there is some data in memory.

files = dir('ALEX*.dat'); #Take the files with an'ALEX' in.
#The script assumes all the script images to be analized are in the the same folder than the script.


tic; #Counting time

########
# Some variables and data scaling.
########

um = 95; #um/px (Streak space scaling)

mm = um*1e-3; #mm/px

us = 20/1024; #us/px (Streak time scaling) (IT IS ASSUMED THAT ALL THE STREAKS SHARE THE SWEEP TIME!!!!)

space = [1:1:1344]; #Space vector in pixels
time = [1:1:1024]; #Time vector, in pixels

picos = []; #Variable to contain the peaks



########
# Loop through all the files to find peaks, smooth them, find velocity and save the data.
########

for i=1 : numel(files) #In each file name...



	disp(files(i).name) #Shot identification

	[file, msg] = fopen(files(i).name, "r");
	if (file == -1) 
	   error ("ALEX-str script: Unable to open file name: %s, %s",filename, msg); 
	endif; 

	#Charge the image as a matrix: (IT MUST BE ALREADY FORMATTED AS SUCH)
	streak = dlmread(file);
	fclose(file);
	
	streak = streak(:,1:end-1); #To remove a zeros line that Octave add. Well know bug...

	streak = streak(:,:) - mean(streak(1:10,:)); #To eliminate the back illuminated laser light
	
	#FINDING THE PEAKS EN EACH TIME:
	for j=1:size(streak)(1)
		line = streak(j,:);
		line(line<0) = 0;
		pic = findpeaksx(space,line, 10,500,1,1,1); #Check the parameters in the next lines:
		#function taken from: https://terpconnect.umd.edu/~toh/spectrum/PeakFindingandMeasurement.htm
		# findpeaksx(x,y, SlopeThreshold, AmpThreshold, SmoothWidth, PeakGroup, smoothtype)
		#ALL THE PARAMETERES ARE NUMBERS OR VECTORS.
		# x, y are the vectro witht eh funxction x and y data...
		# SlopeThreshold is the slope of the derivative to be used to find the peaks. 
				#The larger, the broader elements will be ruled out.
		#AmpThreshold is the minimum peak value. Looks like with ALEX streaks, 500 points is Ok to rule our all crap.
		#SmoothWidth is the size of the smooth window to use on the data. 
				#Larger values will rule out sharp peaks, that we do not want.
		#PeakGroup It affects how the function calculates the peak value. not interesting for me here.
		#smoothtype determines the smoothing algorithm (see http://terpconnect.umd.edu/~toh/spectrum/Smoothing.html)
		picos = [picos; pic(1,2:3) pic(end,2:3) ]; #Peak positions and values.
	endfor
	
	#FINDING THE CENTER:
	pic_cent_01 = picos(500:600,1);
	pic_cent_03 = picos(500:600,3);
	center = ( mean(pic_cent_01) + mean(pic_cent_03) )/ 2
	
	#PUTTING THE DATA AS FUNCTION OF THE CENTER:
	picos(:,1) = abs(picos(:,1) - center); #Needs the "abs" function because is the lower part.
	picos(:,3) = picos(:,3) - center;

	shock_rad = supsmu(time,(picos(:,1)+picos(:,3))*0.5); #radial shock as smoothed version of finded peaks to make derivatives and so on.
	
	shock_vel = deri(shock_rad,1); #shock velocity in pixels/pixels
	shock_vel = [0 0 deri(shock_rad,1)]'; #shock velocity in pixels/pixels with the 2 missed values...
	
	shock_rad_mm = shock_rad * mm; #Passing the pixels to mm
	shock_vel_dim = shock_vel*(mm/us); #Passing the px/px to mm/us	

	#SAVING RAW DATA:
	[file_shock_raw, msg] = fopen( horzcat(files(i).name(1:index(files(1).name,".")-1), "_shock_raw_all.txt"), "w");
	if (file_shock_raw == -1) 
	   error ("ALEXstr script: Unable to open file name: %s, %s",filename, msg); 
	endif; 	
	
	fdisp(file_shock_raw,"time(px) shock_rad_01(px) shock_rad_02(px) shock_rad_smooth(px)");#first line (Columns Descriptor)
	redond = [4	4	4	4]; #Saved precision
	shock_raw = [time', picos(:,1), picos(:,3), shock_rad]; #Matrix with data
	display_rounded_matrix(shock_raw,redond,file_shock_raw); #Saving RAW data
	fclose(file_shock_raw); #Closing the file
	
	#SAVING DIMENSIONAL DATA:
	[file_shock_dim, msg] = fopen( horzcat(files(i).name(1:index(files(1).name,".")-1), "_shock_dim.txt"), "w");
	if (file_shock_dim == -1) 
	   error ("ALEXstr script: Unable to open file name: %s, %s",filename, msg); 
	endif; 	
	#first line (Columns Descriptor)
	fdisp(file_shock_dim,"time(us) shock_rad(mm) shock_vel(mm/us)");
	redond = [4	4	4]; #Saved precision
	shock_dim = [time'*us, shock_rad_mm, shock_vel_dim]; #Matrix with data
	display_rounded_matrix(shock_dim,redond,file_shock_dim); #Saving DIMENSIONAL data
	fclose(file_shock_dim); #Closing the file
	
	#SAVING CENTER DATA:
	[file_shock_cent, msg] = fopen( horzcat(files(i).name(1:index(files(1).name,".")-1), "_shock_center.txt"), "w");
	if (file_shock_cent == -1) 
	   error ("ALEXstr script: Unable to open file name: %s, %s",filename, msg); 
	endif; 	
	#first line (Columns Descriptor)
	fdisp(file_shock_cent, horzcat(files(i).name," ",num2str(center)," px"))
	fclose(file_shock_cent); #Closing the file
	
	picos = []; #To avoid overacumulation of data in the vector.


endfor;

timing = toc;
###
# Total processing time
###

disp("Script ALEXstr.m execution time:")
disp(timing /60)
disp(" min.")  




#That's...that's all folks!!!

