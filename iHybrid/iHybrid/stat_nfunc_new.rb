require 'rubygems'
require 'matrix'
require 'gsl'


module Enumerable

  def sum
    return self.inject(0){|accum, i| accum + i }
  end

  def mean
    return self.sum / self.length.to_f
  end

  def sample_variance
    m = self.mean
    sum = self.inject(0){|accum, i| accum + (i - m) ** 2 }
    return sum / (self.length - 1).to_f
  end

  def standard_deviation
    return Math.sqrt(self.sample_variance)
  end

end


#Function to find slope
def trend(field,slope)
  n = field.size
  x = GSL::Vector[field]
  y = GSL::Vector.linspace(0,1,n)
   c0, c1= GSL::Fit.linear(x,y)
 #  printf("# Slope = %g \n", c1);
   if c1.to_f > slope.to_f
     return true
   else
     return false
   end
end


#Function to Normalize the incoming Energy Data (Remove Spikes)
def energy_norm(field,latest=1)
 len=field.size
 if len<=latest.to_i+1
  return field
   break
 end
 new_field=field
 for i in 0..(latest.to_i -1) 
  new_field.pop
 end
 mean=new_field.mean
 std_dev=field.standard_deviation
 start=len.to_i - latest.to_i
 for i in start..len.to_i
  if field[i+1].to_f>=3*std_dev.to_f
   field[i+1]=mean
  end
 end
 field
end


#Function to find ACF
def acf(field,window_size)
   x=autocorrelate(field,window_size)
   normalize(x)
end

class Array
# Functions to find mean and median
def median(ary)
  return nil if ary.empty?
  mid, rem = ary.length.divmod(2)
  if rem == 0
    ary.sort[mid-1,2].inject(:+) / 2.0
  else
    ary.sort[mid]
  end
end

end



#Function to find the standard deviation of the given parameter
def stddev(field)
  sd(field, na.rm = TRUE)
end


# Function to split into smaller arrays for downsampling
def downsamp(field, n, type)
  chunks=field.each_slice(n).map
  x=Array.new
  for i in 0..(chunks.size-1)
  case type
  when 'mean'
    x << chunks[i].mean
  when 'median'
    x << chunks[i].median
  end
end
 x
end

#####################################



# Function to send packet of different sizes based on the phase
def sendpack(field,fname)
 j=1
 pack_pos=Array.new()
 pack_pos[0]=0
 for i in 0..(field.size-1)
   if (field[i]==1.0000)
     pack_pos[j]=i+1
     j=j+1;
    end
 end
 num_pack=pack_pos.size + 1
 pack_pos << (field.size-1)
 pack = Array.new(num_pack-1){Array.new()}
 for i in 0..(num_pack-1)
   k=0
   for j in (pack_pos[i].to_i)..(pack_pos[i+1].to_i)
     pack[i][k]=field[j]
     k=k+1
   end
 end
 pack_pos.clear 
end


# Function to find whether the value is greater than or equal to a limit
def geq(field,limit)
  len=field.size
  for i in 0..(len-1)
    if ((field[i].to_f-limit.to_f)>= 0.0)
     return true
    end
  end
  return false
end
############################################################################


# Function to find whether the value is less than or equal to a limit
def leq(field,limit)
  len=field.size
  while len>=0
    if ((field[len-1].to_f-limit.to_f)<=0.0)
	len=len-1
	return true
    end
  end
  return false
end
############################################################################


#Function to find Emergency Stop
def emergency(field,tol)
  if field.size==1
    if field.to_f <= tol.to_f
      flag=1
      return true
    end
  else
    for i in 0..(field.size-6)
     flag=0
     for j in 0..4
       if (field[i+j].abs.to_f<=tol.to_f)
         flag=1
       else
         flag=0
         break
       end
     end
     if flag==1
       return true
     end 
    end
  end
 return false
end
############################################################################

#Function to find High Temperature
def high_temp(field,limit,tol)
  len=field.size
  for i in 0..(len-1)
    if ((field[i].to_f-limit.to_f)>=tol.to_f)
     return true
    end
  end
  return false
end
############################################################################
