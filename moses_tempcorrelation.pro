;pro moses_tempcorrelation
	
;Purpose:
;The purpose of this code is to determine relationship between temperature, median exposure value, and pedestal. This is so we can average and sort of predict how the pedestal behaves as temperature varies. We want to be able to average pedestal value so that we can subtract it from the flight data. Once that is done, there will be usable science data (Level 1 data) that actually represents intensity measurements gathered during flight.


;Assign which directory to run through the code
	directory='/disk/data/kankel/MOSEStest/'
		foo=['flight_test2_07-25-15', $
			'flight_test2_07-26-15', $
			'flight_test2_07-27-15', $
			'flight_test3_07-26-15', $
			'flight_test3_07-27-15', $
			'flight_test3_07-29-15', $
			'flight_test4_07-26-15', $
			'flight_test_07-25-15', $
			'flight_test_07-26-15', $
			'flight_test_07-27-15', $
			'flight_test_07-29-15', $
			'launch_day_darks_08-27-15']
			;'flight_test2_07-29-15' Does not work
			;'flight_test_7-23-15'  Does not work

		total_median_minus=0
		total_median_zero=0
		total_median_plus=0
		total_temp_lower=0
		total_temp_upper=0

;Assigns pixel size of images. First for loop begins entire analysis procedure. It ends below on line 91.
	for k=0, n_elements(foo)-1 do begin
		Nx=2048
		Ny=1024
	dark_list = 0

;Prints in the terminal page which directory is running.
	print, directory,foo[k]
		index=mxml2('imageindex.xml',directory+foo[k])
		N_images=n_elements(index.filename)
  		for i=0, N_images-1 do begin 
			if (strpos(index.seqname[i],'dark') ne -1) then begin
      	print,'Found DARK image ',index.seqname[i]
      			add_element, dark_list, i
    		endif
  		endfor

;Reads data and assigns array structure to meta-data
	Nexptimes = n_elements(exp_list)
	Ndarks = n_elements(dark_list)
 		darks_minus = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
		darks_zero  = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
 		darks_plus  = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
			median_minus=fltarr(Ndarks)
			median_zero=fltarr(Ndarks)
			median_plus=fltarr(Ndarks)
		temp_lower=fltarr(Ndarks)
		temp_upper=fltarr(Ndarks)

;Reads file data and determines median values from each image.
 	 	for j = 0, Ndarks-1 do begin
   	 		i = dark_list[j]
   	 		error=0L
    		moses2_read, index.filename[i],minus,zero,plus,noise, $
      		directory=directory+foo[k], error=error, $
      		byteorder=byteorder
		print, index.filename[i]
			darks_minus[*,*,j]=minus
			darks_zero[*,*,j]=zero
			darks_plus[*,*,j]=plus
			median_minus[j]=mean(minus) ;Finds mean dark value from -1, 0, and +1 data
			median_zero[j]=mean(zero)
			median_plus[j]=mean(plus)
			temp_lower[j]=index.temp_lower[i]
			temp_upper[j]=index.temp_upper[i]
		endfor

;????????? Not entirely sure what this portion is for.
		if n_elements(total_median_zero) eq 1 then begin
			total_median_minus=median_minus
			total_median_zero=median_zero
			total_median_plus=median_plus
			total_temp_lower=temp_lower
			total_temp_upper=temp_upper
		endif else begin
			total_median_minus=[total_median_minus,median_minus]
			total_median_zero=[total_median_zero,median_zero]
			total_median_plus=[total_median_plus,median_plus]
			total_temp_lower=[total_temp_lower,temp_lower]
			total_temp_upper=[total_temp_upper,temp_upper]
		endelse
	endfor
		window,0
		loadct,39

;Finds line of best fit between temperature and median value
	minus_lower_fit=linfit(total_temp_lower,total_median_minus)
	minus_upper_fit=linfit(total_temp_upper,total_median_minus)
	zero_lower_fit=linfit(total_temp_lower,total_median_zero)
	zero_upper_fit=linfit(total_temp_upper,total_median_zero)
	plus_lower_fit=linfit(total_temp_lower,total_median_plus)
	plus_upper_fit=linfit(total_temp_upper,total_median_plus)
	
	
	x = findgen(40)

;Plots temperature data with median values for -1 image.
	plot, total_temp_lower,total_median_minus, psym=1, color=85, title='ROE Lower Temp vs. Pedestal Value', ytitle='Median Dark Exposure Value', xtitle='Temperature (C)'

;Finds a correlation coefficient between temperature and median dark value
	minus_lower_coef=CORRELATE(total_temp_lower,total_median_minus)
	minus_upper_coef=CORRELATE(total_temp_upper,total_median_minus)
	zero_lower_coef=CORRELATE(total_temp_lower,total_median_zero)
	zero_upper_coef=CORRELATE(total_temp_upper,total_median_zero)
	plus_lower_coef=CORRELATE(total_temp_lower,total_median_plus)
	plus_upper_coef=CORRELATE(total_temp_upper,total_median_plus)

;Prints return value from correlate function (value between 0 and 1)
	print, "the minus, lower coefficient is: ",minus_lower_coef
	print, "the minus, upper coefficient is: ",minus_upper_coef
	print, "the plus, lower coefficient is: ",plus_lower_coef
	print, "the plus, upper coefficient is: ",plus_upper_coef
	print, "the zero, lower coefficient is: ",zero_lower_coef
	print, "the zero, upper coefficient is: ",zero_upper_coef

;Plots values from lower temp and median for 0 and +1 images on the same plot as the -1 image. Also plots line of best fit for each image.
	oplot, total_temp_lower,total_median_zero, psym=2, color=100
	oplot, total_temp_lower,total_median_plus, psym=4, color=150
	oplot, x, minus_lower_fit[0] + minus_lower_fit[1]*x, color=85
	oplot, x, minus_upper_fit[0] + minus_upper_fit[1]*x, color=85
	oplot, x, zero_lower_fit[0] + zero_lower_fit[1]*x, color=100
	oplot, x, zero_upper_fit[0] + zero_upper_fit[1]*x, color=100
	oplot, x, plus_lower_fit[0] + plus_lower_fit[1]*x, color=150
	oplot, x, plus_upper_fit[0] + plus_upper_fit[1]*x, color=150
	al_legend, ['Minus','Zero','Plus'],psym=[1,2,4],color=[85,100,150]
	window,1
	
;Prints the return value from linfit in the form y=mx+b (slope-intercept)	
	print, 'the minus, lower line of best fit is:',minus_lower_fit[1], "x + ", minus_lower_fit[0]
	print, 'the minus, upper line of best fit is:',minus_upper_fit[1], "x + ", minus_upper_fit[0]
	print, 'the zero, lower line of best fit is:',zero_lower_fit[1], "x + ", zero_lower_fit[0]
	print, 'the zero, upper line of best fit is:',zero_upper_fit[1], "x + ", zero_upper_fit[0]
	print, 'the plus, lower line of best fit is:',plus_lower_fit[1], "x + ", plus_lower_fit[0]
	print, 'the plus, upper line of best fit is:',plus_upper_fit[1], "x + ", plus_upper_fit[0]

;Plots upper temperature with median values from -1, 0, and +1 images, including line of best fit for each set of points.
	plot, total_temp_upper,total_median_minus, psym=1, color=85, title='ROE Upper Temp vs. Pedestal Value', ytitle='Median Dark Exposure Value', xtitle='Temperature (C)'
		oplot, total_temp_upper,total_median_zero, psym=2, color=100
		oplot, total_temp_upper,total_median_plus, psym=4, color=150
		oplot, x, minus_upper_fit[0] + minus_upper_fit[1]*x, color=85
		oplot, x, zero_upper_fit[0] + zero_upper_fit[1]*x, color=100
		oplot, x, plus_upper_fit[0] + plus_upper_fit[1]*x, color=150
	al_legend, ['Minus','Zero','Plus'],psym=[1,2,4],color=[85,100,150]

;Try multiple regression. We want to predict the pedestal value based on temperature and median value from darks.
	total_temp=[TRANSPOSE(total_temp_upper),TRANSPOSE(total_temp_lower)] ;Use a regression to compare pedestal values
		plus_fit=REGRESS(total_temp, total_median_plus, CONST=plus_const)	 ;between upper and lower temps.
		minus_fit=REGRESS(total_temp, total_median_minus, CONST=minus_const)
		zero_fit=REGRESS(total_temp, total_median_zero, CONST=zero_const)
		
				;z_plus=plus_const + plus_fit[0]*x + plus_fit[1]*y
				;z_zero=zero_const + zero_fit[0]*x + zero_fit[1]*y
				;z_minus=minus_const + minus_fit[0]*x + minus_fit[1]*y

;Prints return value from regression function.
	print, 'the minus, line of best fit is:',minus_fit[0], "x + ", minus_fit[1], "y + ", minus_const
	print, 'the zero, line of best fit is:',zero_fit[0], "x + ", zero_fit[1], "y + ", zero_const
	print, 'the plus, line of best fit is:',plus_fit[0], "x + ", plus_fit[1], "y + ", plus_const
	
plus_eq = string(format = '(F0, "*x + ", F0, "*y + ", F0)', plus_fit[0], plus_fit[1], plus_const)
zero_eq = string(format = '(F0, "*x + ", F0, "*y + ", F0)', zero_fit[0], zero_fit[1], zero_const)
minus_eq = string(format = '(F0, "*x + ", F0, "*y + ", F0)', minus_fit[0], minus_fit[1], minus_const)

;Plots a 3-dimensional graph for each set of images that contains upper and lower temperatures versus and median exposure values. Then overplots on each plot the regression line of best fit for those points.
	threeD_plot_plus=SCATTERPLOT3D(total_temp_upper, total_temp_lower, total_median_plus, title='Plus Plot')
		s_plus = SURFACE(plus_eq, /OVERPLOT)
	threeD_plot_zero=SCATTERPLOT3D(total_temp_upper, total_temp_lower, total_median_zero, title='Zero Plot') 
		s_zero = SURFACE(zero_eq, /OVERPLOT)
	threeD_plot_minus=SCATTERPLOT3D(total_temp_upper, total_temp_lower, total_median_minus, title='Minus Plot')
		s_minus=SURFACE(minus_eq, /OVERPLOT)
		

end
  

