require 'iHybrid/stat_nfunc_new.rb'
require 'iHybrid/autocorrelation.rb'
require 'iHybrid/normalization.rb'
require 'iHybrid/alarm_new.rb'
require 'socket'
require 'time'
require 'thread'
require 'optparse'
require 'yaml'

tol= 0.01
limit=1.4
downstype='mean'
dfactor = 10
out_port=false

#command line options
OptionParser.new do |opts|
  opts.banner = 'Usage: iHybrid.rb <host> <port>'
  opts.on('-p', '--port [port]', OptionParser::DecimalNumeric, 'Port (default: 7878)') do  |v|
    port = v
  end
  opts.on('-d', '--dfactor [dfactor]', OptionParser::DecimalNumeric, 'Downscale factor (default: 10)') do  |v|
    dfactor = v
  end
  opts.on('-h', '--help', 'Show help') do
    puts opts
    exit 1
  end
  opts.on('-o', '--[no-]outputtrue', 'Output to a port') do |v|
    out_port = v
  end
  opts.on('-m', '--[no-]mean', 'Use mean to downscale using mean') do |v|
    downstype = 'mean'
  end
  opts.on('-e', '--[no-]median', 'Use median to downscale using mean') do |v|
    downstype = 'median'
  end
  opts.parse!
  if ARGV.length < 2
    puts "usage: iHybrid.rb <host> <port>"
    puts opts
    exit 1
  end
end

#Variable Decleration for Labjack Adapter Data
data_in=[]
name= Array.new
dtype = Array.new
ltype = Array.new
p1= Array.new
p2= Array.new
p3= Array.new
p4= Array.new
status = Array.new

#Variable Decleration for ConnectOne Adapter Data
cdata_in=[]
cname= Array.new
cddtype= Array.new 
cltype= Array.new 
cparam1= Array.new
cparam2= Array.new
cparam3= Array.new
cparam4= Array.new
cstatus =Array.new

buff=Array.new 

mwindow_size=100
maximum_packet=2000

#######Reading Content from the labjack yaml file
config = YAML::parse( File.open( 'config_lj.yaml' ) )
  host = config.select('/connection/host')[0].value
  port = config.select('/connection/port')[0].value
  device = config.select('/device')[0].value
  puts "Connected to Device #{device}, host #{host} at port #{port}"
  num_channels = config.select("/params/*/name")
  for i in 0..(num_channels.size-1)
    name[i] = config.select("/params/*/name")[i].value
    p1[i] = config.select("/params/*/p1")[i].value
    p2[i] = config.select("/params/*/p2")[i].value
    p3[i] = config.select("/params/*/p3")[i].value
    p4[i] = config.select("/params/*/p3")[i].value
    status[i] = 'N'
    ltype[i] = config.select("/params/*/ltype")[i].value
    dtype[i] = config.select("/params/*/dtype")[i].value
  end
################################################


#######Reading Content from the connectone yaml file
config_co = YAML::parse( File.open( 'config_dA.yaml' ) )
  chost = config_co.select('/connection/host')[0].value
  cport = config_co.select('/connection/port')[0].value
  cdevice = config_co.select('/device')[0].value
  puts "Connected to Device #{cdevice}, host #{chost} at port #{cport}"
  cnum_channels = config_co.select("/params/*/name")
  for i in 0..(cnum_channels.size-1)
    cname[i] = config_co.select("/params/*/name")[i].value
    cddtype[i] = config_co.select("/params/*/dtype")[i].value
    cparam1[i] = config_co.select("/params/*/p1")[i].value
    cparam2[i] = config_co.select("/params/*/p2")[i].value
    cparam3[i] = config_co.select("/params/*/p3")[i].value
    cparam4[i] = config_co.select("/params/*/p3")[i].value
    cstatus[i] = 'N'
    cltype[i] = config.select("/params/*/ltype")[i].value
  end
################################################


#Array to store all incoming data  
name.size.times { data_in << Array.new() } 
cname.size.times { cdata_in << Array.new() } 

streamSock = TCPSocket.new(ARGV[0], ARGV[1].to_i)
streamSock_co = TCPSocket.new(chost,cport.to_i)

chunks=Array.new()

if out_port
server1 = TCPServer.open(5001)
$socket2 = server1.accept
end

mutex=Mutex.new

##Sending Normal Condition
for i in 0..name.size-1
  line = "\n#{format_time}|c_#{name[i]}|NORMAL||||"
  puts  line         
  $socket2.puts line
  $socket2.flush
end
for i in 0..cname.size-1
  line = "\n#{format_time}|c_#{cname[i]}|NORMAL||||"
  puts  line         
  $socket2.puts line
  $socket2.flush
end
###########################


#The main loop begins here
loop do


Thread.new do
    #Taking data from ConnectOne
    if (rr = streamSock_co.gets) =~ /\* PING/
        puts "Received #{rr.strip}, responding with pong" if out_port
        Mutex.new.synchronize {
          socket.puts "* PONG 10000"
        }
    else
	ctimeSt, cnameA, cval = rr.chomp.split('|', 3)
        cname_len=cname.size-1
        for i in 0..cname_len
	  case cnameA
           when cname[i]
             if cval.to_f != nil
		cdata_in[i] << cval.to_f 
             end
	  end
	  if cddtype[i]== 'energy'
	 #   cdata_in[i]=energy_norm(cdata_in[i],1)          
	     alarm_sys(cddtype[i],cname[i],cdata_in[i],cparam1[i],cparam2[i],cparam3[i],cparam4[i],cstatus[i],cltype[i])
	  else
	    if cdata_in[i].size > 8
	      alarm_sys(cddtype[i],cname[i],cdata_in[i],cparam1[i],cparam2[i],cparam3[i],cparam4[i],cstatus[i],cltype[i])
	    end
	 end
	  if cdata_in[i].size > 9
           cdata_in[i].shift
          end
       end
	if out_port
	  line = "\n#{format_time}|#{cnameA}|#{cval}"
	     puts line
            $socket2.puts line
            $socket2.flush
	end
    end 
end


  
Thread.new do
      #Taking data from labjack
      if (r = streamSock.gets) =~ /\* PING/
        puts "Received #{r.strip}, responding with pong" if out_port
        Mutex.new.synchronize {
          socket.puts "* PONG 10000"
        }
      else
	resting,restAll = r.chomp.split('||',2);
	timeSt, nameA, numb = resting.chomp.split('|', 3);
	for i in 0..(name.size-1)
 	  case nameA
            when name[i]
		data_in[i] += restAll.split(" ").map {|i| i.to_f} 
          end
        end
        
	#######calling function for ACF########
	#  x=acf(data_in[i],100)	
	#   puts x, "\n"
	#######################################

	for i in 0..(name.size-1)
         if (data_in[i].size>=mwindow_size)
	   buff=data_in[i].slice!(0,mwindow_size-1)
	   data_in[i].drop(mwindow_size)
           alarm_sys(dtype[i],name[i],buff,p1[i],p2[i],p3[i],p4[i],status[i],ltype[i])
	   chunks=downsamp(buff,dfactor,downstype)
	   sendpack(chunks,name[i])
	   if out_port
	     line = "\n#{format_time}|#{name[i]}|#{chunks.size}||" + chunks.join(" ")
             puts  line         
            # last = time
            $socket2.puts line
            $socket2.flush
	   end

	  chunks.clear

         end
        end
    end

end

end
