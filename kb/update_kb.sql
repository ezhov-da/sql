SELECT id, name, ishide
	FROM public.t_e_note;
    
    
update public.t_e_note 
	set name = replace(
        	replace(name, ' -> ', '-'),
        ': ', '-')
        
update public.t_e_note 
	set name = replace(name, ' - ', '-')
        
update public.t_e_note 
	set name = replace(name, ' ', '-')        
    
update public.t_e_note 
	set name = lower(name)        
    
        