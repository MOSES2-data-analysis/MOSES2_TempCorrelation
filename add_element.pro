;+;NAME:;	ADD_ELEMENT;PURPOSE:;	Add one element to an array, whether or not the array;	variable has been defined before. For example, if you;	want to add an element to the array B in IDL you might;	say:;		IDL> B = [B, foo];	This works only if the variable B has already been ;	defined. It is not hard to imagine scenarios in which;	you don't know a priori whether B has been defined. ;	It is inelegant (and detrimental to the programmer's ;	virtue of laziness) to have to check explicitly every time.;CALLING SEQUENCE:;	add_element, array, new_element;MODIFICATION HISTORY:;	CCK 980325;-pro add_element, array, new_elementif n_elements(array) ne 0 then begin	array = [temporary(array), new_element]endif else begin	array = new_elementendelseend