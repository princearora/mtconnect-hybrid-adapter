def format_time
  time = Time.now.utc
  time.strftime("%Y-%m-%dT%H:%M:%S.") + ("%06d" % time.usec)
end


def alarm_sys(dtype,name,field,max,min,max2,min2,status,ltype='1',tol1='0.5')
if dtype=='sensor' 
 case ltype
    when '1'
      if geq(field,max)
	if geq(field,max2) 
           nstatus = 'F'
	else
           nstatus = 'W'
	end
        if status != nstatus
	  alarm(name,'HIGH',nstatus,'CRITICAL','ACTIVE')
	  status[0]=nstatus[0]
	  *status=*nstatus
        end
      elsif leq(field,min)
	if leq(field,min2) 
           nstatus = 'F'
         else
           nstatus = 'W'
	 end
	 if status != nstatus
         alarm(name,'LOW',nstatus,'CRITICAL','ACTIVE')
	 status[0]=nstatus[0]
	 *status=*nstatus
        end
      else
        nstatus = 'N'
        if status != nstatus
         alarm(name,'MESSAGE',nstatus,'CRITICAL','ACTIVE')
         status[0]=nstatus[0]
         *status = *nstatus 
        end
      end
   when '2'
      if geq(field,max)
	if trend(field,max2) 
	  nstatus = 'F'
         else
           nstatus = 'W'
	 end
        if status != nstatus
         alarm(name,'HIGH',nstatus,'CRITICAL','ACTIVE')
         status[0]=nstatus[0]
         *status=*nstatus
        end
     elsif leq(field,min)
         if !trend(field,min2) 
           nstatus = 'F'
         else
           nstatus = 'W'
	 end
        if status != nstatus
         alarm(name,'LOW',nstatus,'CRITICAL','ACTIVE')
         status[0]=nstatus[0]
         *status=*nstatus
        end
     else
        nstatus = 'N'
        if status != nstatus
         alarm(name,'MESSAGE',nstatus,'CRITICAL','ACTIVE')
         status[0]=nstatus[0]
         *status = *nstatus 
        end
      end
   when '3'
      if trend(field,max)
         if trend(field,max2) 
           nstatus = 'F'
         else
           nstatus = 'W'
	 end
        if status != nstatus
         alarm(name,'HIGH',nstatus,'CRITICAL','ACTIVE')
         status[0]=nstatus[0]
         *status=*nstatus
        end
     elsif !trend(field,min)
         if !trend(field,min2) 
           nstatus = 'F'
         else
           nstatus = 'W'
	 end
        if status != nstatus
         alarm(name,'LOW',nstatus,'CRITICAL','ACTIVE')
         status[0]=nstatus[0]
         *status=*nstatus
        end
     else
        nstatus = 'N'
        if status != nstatus
         alarm(name,'MESSAGE',nstatus,'CRITICAL','ACTIVE')
         status[0]=nstatus[0]
         *status = *nstatus 
        end
      end
  end

  
  if emergency(field,tol1)
    nstatus = 'E'
    if status != nstatus
     status[0]=nstatus[0]
     alarm(name,'ESTOP','ESTOP','CRITICAL','ACTIVE')
    end
  end
elsif dtype=='energy'
  if field.standard_deviation>=1.0   
    nstatus = 'S'
    if status != nstatus
     status[0]=nstatus[0]
     *status=*nstatus
     alarm(name,'SPINDLE','ESTOP','CRITICAL','ACTIVE')
    end
  else
    nstatus = 'N'
    if status != nstatus
     status[0]=nstatus[0]
     *status=*nstatus
     alarm(name,'MESSAGE',nstatus,'NORMAL','ACTIVE')
    end
  end
end
end



def alarm(item_name,code,ncode,severity,a_state,a_desc="Alarm")
  case ncode
    when 'N'
       ncode = 'NORMAL'
    when 'W'
       ncode = 'WARNING'
    when 'F'
       ncode = 'FAULT'
  end

  case code
    when 'SPINDLE'
        a_desc = 'The Spindle is Faulty'
    when 'FAILURE'
	a_desc = 'The component has failed'
    when 'FAULT'
	a_desc = 'A fault occurred'
    when 'CRASH'
	a_desc = 'A spindle crash'
    when 'JAM'
	a_desc =  'A component related to '+ item_name +' has jammed'
    when 'OVERLOAD'
	a_desc = 'The component related to '+ item_name +' has been overloaded'
    when 'ESTOP'
	a_desc = 'E-Stop was pushed'
    when 'MATERIAL'
	a_desc = 'A material failure has occurred'
    when 'MESSAGE'
	a_desc = 'Directly paas on the info from the adpter. Used with INFO severity'
        if ncode == 'NORMAL'
         a_desc = item_name + ' is Normal'
        end
    when 'HIGH'
      a_desc = item_name + ' is high'
    when 'LOW'
      a_desc = item_name + ' is low'
  end
  line = "\n#{format_time}|c_#{item_name}|#{ncode}|#{item_name.capitalize}|1|#{code}|#{a_desc}"
  puts  line         
      $socket2.puts line
      $socket2.flush
end

