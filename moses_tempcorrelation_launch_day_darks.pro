pro moses_tempcorrelation_launch_day_darks

		Nx=2048
		Ny=1024
	index=mxml2('imageindex.xml','/disk/data/kankel/MOSEStest/launch_day_darks_08-27-15/')
	N_images=n_elements(index.filename)
  for i=0, N_images-1 do begin
	if (strpos(index.seqname[i],'dark') ne -1) then begin
      print,'Found DARK image ',index.seqname[i]
      add_element, dark_list, i
    endif
  endfor
	Nexptimes = n_elements(exp_list)
	;Ndarks = 20
	Ndarks = N_images
	print, Ndarks
	;Ndarks = n_elements(dark_list)
  ;darks_minus = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
  ;darks_zero  = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
  ;darks_plus  = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
	median_minus=fltarr(Ndarks)
	median_zero=fltarr(Ndarks)
	median_plus=fltarr(Ndarks)
	temp_lower=fltarr(Ndarks)
	temp_upper=fltarr(Ndarks)
  for j = 0, Ndarks-1 do begin
    i = j
    error=0L
    moses2_read, index.filename[i],minus,zero,plus,noise,          $
      directory='/disk/data/kankel/MOSEStest/launch_day_darks_08-27-15/', error=error, $
      byteorder=byteorder
	print, index.filename[i]
	;print, index.temp_lower[i]
	;darks_minus[*,*,j]=minus
	;darks_zero[*,*,j]=zero
	;darks_plus[*,*,j]=plus
	median_minus[j]=median(minus)
	median_zero[j]=median(zero)
	median_plus[j]=median(plus)
	temp_lower[j]=index.temp_lower[i]
	temp_upper[j]=index.temp_upper[i]
	endfor
	plot, temp_lower,median_minus,YRANGE=[300,600]
	minus_lower_coef=CORRELATE(temp_lower,median_minus)
	minus_upper_coef=CORRELATE(temp_upper,median_minus)
	zero_lower_coef=CORRELATE(temp_lower,median_zero)
	zero_upper_coef=CORRELATE(temp_upper,median_zero)
	plus_lower_coef=CORRELATE(temp_lower,median_plus)
	plus_upper_coef=CORRELATE(temp_upper,median_plus)
	print, "the minus, lower coefficient is: ",minus_lower_coef
	print, "the minus, upper coefficient is: ",minus_upper_coef
	print, "the plus, lower coefficient is: ",plus_lower_coef
	print, "the plus, upper coefficient is: ",plus_upper_coef
	print, "the zero, lower coefficient is: ",zero_lower_coef
	print, "the zero, upper coefficient is: ",zero_upper_coef
	oplot, temp_lower,median_zero
	oplot, temp_lower,median_plus
end
  

