;NAME:
;  MOSES2_READ
;PURPOSE:
;  Read .roe files from MOSES, as written by MSSL's EGSE computer. Orientation
;  of image[i,j] is in detector plane, facing detector from secondary mirror 
;  with connectors up:
;     increasing first index, i:   payload +y
;     increasing second index, j:  payload +z
;  These are focal plane coordinates, not plane-of-sky coordinates! 
;  If a dark image file is specified, then dark subtraction is done auto-
;  matically.
;CALLING SEQUENCE:
;  moses2_read, filename, minus, zero, plus, noise [, dark=dark]
;     [, /byteorder] [, /auto] [sizes=sizes] [error=error]
;INPUTS:
;  filename --- name of .roe file, including extension.
;OUTPUTS:
;  minus, zero, plus --- images from the 3 detector orders.
;  noise --- image from the zeroth channel, which contains only read noise.
;OPTIONAL KEYWORD INPUTS:
;  byteorder --- if set, then switch byte order. This helps when reading
;     data written by the Windows EGSE on a Mac (or Linux?) machine.
;  auto --- if set, attempt to get the byte order right automatically.
;     This somewhat experimental feature is intended to make moses2_read
;     completely platform independent. If auto is set, then the byteorder
;     keyword is superseded and may come back modified.
;  sizes --- 4-element long integer array containing the number of pixels
;     stored in channels 0, 1, 2 and 3.
;  directory --- a string to prepend to the filename.
;OPTIONAL KEYWORD OUTPUTS:
;  error --- value of the error keyword from openr. Nonzero is an error.
;HISTORY:
;  2005-Mar-15 CCK, based on MARF.PRO by RJT.
;  2005-Jul-24 CCK, SIZES keyword to handle incomplete data transfers.
;  2005-Nov-19 CCK, trap for nonexistent file; added ERROR keyword.
;  2005-Nov-30 CCK, trap for missing ('noise') channel 0,
;     trap for possible leading '/mdata/' in filename, and added
;     optional directory keyword.
;  2015-Jul-?? Jackson Remington added channel sorting for MOSES-II.
;  2015-Jul-27 CCK eliminated channels[] argument. Vectorized sorting code.
;     Changed name to MOSES2_READ. Eliminated DARK keyword that never worked.
;     Started using /RAWIO on OPENR, so that I do not need to know in advance
;     how big the file is going to be. A side-effect is that I'll probably
;     get a noise channel full of zeroes if only m/z/p have been saved.

pro moses2_read,filename,m,z,p,n, dark=dark, byteorder=byteorder, $
   auto=auto, size=size, error=error, directory=directory


if keyword_set(auto) then begin
   ;This assumes the .roe file was written by the Windows EGSE, which
   ;shares the same architecture as most Linux boxes but differes from
   ;the Macintosh, which has the opposite order for the bytes in a
   ;16-bit word.
   if (!version.arch eq "ppc") then byteorder=1 else byteorder=0
endif


;Read the raw data into unsigned integer (16 bit) arrays, sized
;to account for the number of pixels actually obtained. Sort the
;data by its respective channel.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;INITIALIZE SORTINGL:
buf_size = 2097152
next_pixel = uint(0)
num_chan = 4
   ;CCK moved this up from below and eliminated use of channels[] array.
   ;I always look for all 4 channels, even though channel 0 is normally
   ;being stripped out by flight s/w.
virt_buf = uintarr(num_chan * buf_size) ;CCK changed from 3* to num_chan*


;initialize arrays
;CCK eliminated "if" statements using channels[] array
n_read = uintarr(buf_size)
m_read = uintarr(buf_size)
z_read = uintarr(buf_size)
p_read = uintarr(buf_size)

;Open the file for reading.
openr,1,directory+"/"+filename, error = error, /rawio
if error ne 0 then begin
   ;Might need to strip leading /mdata/ from filename.
   filename2 = strmid(filename, 7)
   message,"Can't find "+directory+filename+"; trying "+filename2, $ 
      /informational    ;CCK uncommented to debug...
   openr,1,directory+"/"+filename2, error = error, /rawio
   ;print, directory+"/"+filename2
   ;wait, 20
   if error eq 0 then filename=filename2
endif
if error eq 0 then begin
   readu,1, virt_buf, transfer_count=transfer_count
   if error ne 0 then begin
      print, !ERROR_STATE.MSG
      print, 'moses-read error?'
   endif
   
   close,1
   
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;BEGIN SORTING
   ;CCK moved definition of num_chan up top, needed for initialization prior to sorting.
   
   ;CCK commented out old sorting code
   ;for i=0, (buf_size * num_chan) - 1 do begin
   ;   next_pixel = virt_buf[i]
   ;   if (next_pixel ge 49152) then begin              ; Channel 3
   ;      if channels[3] eq 1 then p_read[i3] = next_pixel & i3++
   ;   endif else if (next_pixel ge 32768) then begin
   ;      if channels[2] eq 1 then z_read[i2] = next_pixel & i2++
   ;   endif else if (next_pixel ge 16384) then begin
   ;      if channels[1] eq 1 then m_read[i1] = next_pixel & i1++
   ;   endif else begin
   ;      if channels[0] eq 1 then n_read[i0] = next_pixel & i0++
   ;   endelse
   ;endfor

   ;CCK new sorting code
   chan0 = where( virt_buf/(2^14) eq 0 )
   chan1 = where( virt_buf/(2^14) eq 1 )
   chan2 = where( virt_buf/(2^14) eq 2 )
   chan3 = where( virt_buf/(2^14) eq 3 )
   
   if  (n_elements(chan1) ne buf_size) $
    or (n_elements(chan2) ne buf_size) $
    or (n_elements(chan3) ne buf_size) then begin
      message,/informational,"Channel size does not match buffer size for "+filename
      save, filename = directory+"/"+filename+".problem_report"
      print,"Saved problem report: "+directory+"/"+filename+".problem_report"
   endif

   n_read = virt_buf[chan0]
   m_read = virt_buf[chan1]
   z_read = virt_buf[chan2]
   p_read = virt_buf[chan3]

   Nn = n_elements(n_read)
   Nm = n_elements(m_read)
   Nz = n_elements(z_read)
   Np = n_elements(p_read)

   ;CCK modified to use Nn/Nm/Nz/Np rather than channels[].
   ;Also made more robust, so that if the channels are over or undersized
   ;we don't crash.
   n = uintarr(2048,1024) & m=n & z=n & p=n ;allocate memory for channels.
   if Nn gt 0 then n[0:(buf_size<Nn)-1] = n_read[0:(buf_size<Nn)-1]
   if Nm gt 0 then m[0:(buf_size<Nm)-1] = m_read[0:(buf_size<Nm)-1]
   if Nz gt 0 then z[0:(buf_size<Nz)-1] = z_read[0:(buf_size<Nz)-1]
   if Np gt 0 then p[0:(buf_size<Np)-1] = p_read[0:(buf_size<Np)-1]

   ;Save memory space
   ;n_read=0
   ;m_read=0
   ;z_read=0
   ;p_read=0

   if keyword_set(byteorder) then begin
      ;if sizes[0] ne 0 then byteorder,n
      byteorder,m
      byteorder,z
      byteorder,p
   endif

   ;Our data occupies the lower 14 bits of the 16-bit word.
   ;Mask out the channel addresses, which occupy the leading two bits.
   ;if sizes[0] ne 0 then n = n AND '3FFF'X
   m = m AND '3FFF'X
   z = z AND '3FFF'X
   p = p AND '3FFF'X

   ;CCK eliminated non-working code for DARK keyword.
   ;CCK eliminated long() in next 3 lines...
   m = rotate(m,2)  ; View of detector face with connectors up
   z = rotate(z,2)
   p = rotate(p,2)
endif else begin
   ;file not valid
   print,"Read error = ",error
   m=0
   z=0
   p=0
   n=0
endelse

end
