;pro moses_tempcorrelation
	directory='/disk/data/kankel/MOSEStest/'
	foo=['flight_test2_07-25-15', $
'flight_test2_07-26-15', $
'flight_test2_07-27-15', $
;'flight_test2_07-29-15', $
'flight_test3_07-26-15', $
'flight_test3_07-27-15']
	
;flight_test3_07-29-15/
;flight_test4_07-26-15/
;flight_test_07-25-15/
;flight_test_07-26-15/
;flight_test_07-27-15/
;flight_test_07-29-15/
;flight_test_7-23-15/
			total_median_minus=0
		total_median_zero=0
		total_median_plus=0
		total_temp_lower=0
		total_temp_upper=0

	for k=0, n_elements(foo)-1 do begin
		Nx=2048
		Ny=1024
	dark_list = 0

	print, directory,foo[k]
	index=mxml2('imageindex.xml',directory+foo[k])
	N_images=n_elements(index.filename)
  for i=0, N_images-1 do begin 
	if (strpos(index.seqname[i],'dark') ne -1) then begin
      print,'Found DARK image ',index.seqname[i]
      add_element, dark_list, i
    endif
  endfor
	Nexptimes = n_elements(exp_list)
	;Ndarks = 6
	Ndarks = n_elements(dark_list)
  darks_minus = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
  darks_zero  = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
  darks_plus  = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
	median_minus=fltarr(Ndarks)
	median_zero=fltarr(Ndarks)
	median_plus=fltarr(Ndarks)
	temp_lower=fltarr(Ndarks)
	temp_upper=fltarr(Ndarks)
  for j = 0, Ndarks-1 do begin
    i = dark_list[j]
    error=0L
    moses2_read, index.filename[i],minus,zero,plus,noise,          $
      directory=directory+foo[k], error=error, $
      byteorder=byteorder
	print, index.filename[i]
	;print, index.temp_lower[i]
	darks_minus[*,*,j]=minus
	darks_zero[*,*,j]=zero
	darks_plus[*,*,j]=plus
	median_minus[j]=median(minus)
	median_zero[j]=median(zero)
	median_plus[j]=median(plus)
	temp_lower[j]=index.temp_lower[i]
	temp_upper[j]=index.temp_upper[i]
	endfor
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
	;print, total_temp_upper
	endfor
	window,0
	loadct,39
	minus_lower_fit=linfit(total_temp_lower,total_median_minus)
	minus_upper_fit=linfit(total_temp_upper,total_median_minus)
	zero_lower_fit=linfit(total_temp_lower,total_median_zero)
	zero_upper_fit=linfit(total_temp_upper,total_median_zero)
	plus_lower_fit=linfit(total_temp_lower,total_median_plus)
	plus_upper_fit=linfit(total_temp_upper,total_median_plus)
	x = findgen(40)
	;plot, temp_lower,median_minus, psym=1, color=85, title='ROE Lower Temp vs. Pedestal Value', ytitle='Median Dark Exposure Value', xtitle='Temperature (C)', /ynozero
	plot, total_temp_lower,total_median_minus, psym=1, color=85, title='ROE Lower Temp vs. Pedestal Value', ytitle='Median Dark Exposure Value', xtitle='Temperature (C)'
	minus_lower_coef=CORRELATE(total_temp_lower,total_median_minus)
	minus_upper_coef=CORRELATE(total_temp_upper,total_median_minus)
	zero_lower_coef=CORRELATE(total_temp_lower,total_median_zero)
	zero_upper_coef=CORRELATE(total_temp_upper,total_median_zero)
	plus_lower_coef=CORRELATE(total_temp_lower,total_median_plus)
	plus_upper_coef=CORRELATE(total_temp_upper,total_median_plus)
	print, "the minus, lower coefficient is: ",minus_lower_coef
	print, "the minus, upper coefficient is: ",minus_upper_coef
	print, "the plus, lower coefficient is: ",plus_lower_coef
	print, "the plus, upper coefficient is: ",plus_upper_coef
	print, "the zero, lower coefficient is: ",zero_lower_coef
	print, "the zero, upper coefficient is: ",zero_upper_coef
	oplot, total_temp_lower,total_median_zero, psym=2, color=100
	oplot, total_temp_lower,total_median_plus, psym=4, color=150
	oplot, x, minus_lower_fit[0] + minus_lower_fit[1]*x, color=85
	;oplot, x, minus_upper_fit[0] + minus_upper_fit[1]*x, color=85
	oplot, x, zero_lower_fit[0] + zero_lower_fit[1]*x, color=100
	;oplot, x, zero_upper_fit[0] + zero_upper_fit[1]*x, color=100
	oplot, x, plus_lower_fit[0] + plus_lower_fit[1]*x, color=150
	;oplot, x, plus_upper_fit[0] + plus_upper_fit[1]*x, color=150
	al_legend, ['Minus','Zero','Plus'],psym=[1,2,4],color=[85,100,150]
	window,1
	print, 'the minus, lower line of best fit is:',minus_lower_fit[1], "x + ", minus_lower_fit[0]
	print, 'the minus, upper line of best fit is:',minus_upper_fit[1], "x + ", minus_upper_fit[0]
	print, 'the zero, lower line of best fit is:',zero_lower_fit[1], "x + ", zero_lower_fit[0]
	print, 'the zero, upper line of best fit is:',zero_upper_fit[1], "x + ", zero_upper_fit[0]
	print, 'the plus, lower line of best fit is:',plus_lower_fit[1], "x + ", plus_lower_fit[0]
	print, 'the plus, upper line of best fit is:',plus_upper_fit[1], "x + ", plus_upper_fit[0]
	;plot, temp_upper,median_minus, psym=1, color=85, title='ROE Upper Temp vs. Pedestal Value', ytitle='Median Dark Exposure Value', xtitle='Temperature (C)', /ynozero
	plot, total_temp_upper,total_median_minus, psym=1, color=85, title='ROE Upper Temp vs. Pedestal Value', ytitle='Median Dark Exposure Value', xtitle='Temperature (C)'
	oplot, total_temp_upper,total_median_zero, psym=2, color=100
	oplot, total_temp_upper,total_median_plus, psym=4, color=150
	oplot, x, minus_upper_fit[0] + minus_upper_fit[1]*x, color=85
	oplot, x, zero_upper_fit[0] + zero_upper_fit[1]*x, color=100
	oplot, x, plus_upper_fit[0] + plus_upper_fit[1]*x, color=150
	al_legend, ['Minus','Zero','Plus'],psym=[1,2,4],color=[85,100,150]
end
  

