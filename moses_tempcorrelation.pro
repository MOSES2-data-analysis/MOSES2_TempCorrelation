pro moses_tempcorrelation

		Nx=2048
		Ny=1024
	index=mxml2('imageindex.xml','/disk/data/kankel/MOSES2flight')
	N_images=n_elements(index.filename)
  for i=0, N_images-1 do begin
	if (strpos(index.seqname[i],'dark') ne -1) then begin
      print,'Found DARK image ',index.seqname[i]
      add_element, dark_list, i
    endif
  endfor
	Nexptimes = n_elements(exp_list)
	Ndarks = n_elements(dark_list)
  darks_minus = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
  darks_zero  = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
  darks_plus  = fltarr(Nx, Ny, Ndarks) ;array of darks (DN)
  for j = 0, 8-1 do begin
    i = dark_list[j]
    error=0L
    moses2_read, index.filename[i],minus,zero,plus,noise,          $
      directory='/disk/data/kankel/MOSES2flight', error=error, $
      byteorder=byteorder
	print, index.filename[i]
	xtv, zero
	endfor
end
  

