JBT_IPHONE = 'E4:25:E7:C0:52:BB'
PERIOD = 15 # seconds
AWAY_TIME = 2 # minutes
SUNRISE_TIME = '5:40:AM' # 6/7/13
SUNSET_TIME = '7:54PM' # 6/7/13
DATE_FORMAT = '%Y-%m-%d %l:%M:%S%p (%a)'

@on_time = @off_time = @last_seen_time = nil

def is_dark?
  Time.now < sunrise_time || Time.now > sunset_time
end

def lights_off
  Light.all_off
end

def lights_on
  Light.all.each do |l|
    l.on bri: 255, hue: 255
  end
end

def now
  DateTime.now.in_time_zone.strftime(DATE_FORMAT)
end

i = 0
loop do
	i += 1
  ping_result = `sudo l2ping -c 1 #{JBT_IPHONE}`
  today = DateTime.now.in_time_zone.to_date
  sunrise_time = Time.zone.parse("#{today} #{SUNRISE_TIME}")
  sunset_time = Time.zone.parse("#{today} #{SUNSET_TIME}")
  action = nil
  if ping_result.match(/1 sent, 1 received/)
    status = "PRESENT"
    @last_seen_time = Time.now
    if is_dark?
      if @on_time.blank? || (@off_time.present? && @off_time > @on_time)
        action = "ON"
        @on_time = @last_seen_time
        lights_on
      end
    end
  elsif @last_seen_time.blank? || Time.now - @last_seen_time > AWAY_TIME * 60 #sec/min
    status = "MISSING"
    if @off_time.blank? || (@on_time.present? && @off_time < @on_time)
      action = "OFF"
      @off_time = Time.now
      lights_off
    end
  else
    status = "RECENTLY MISSING"
  end

  unless ping_result.match(/1 sent, 1 received/)
    status += " (#{((Time.now - @last_seen_time) / 60.0).round(2)} minutes)" if @last_seen_time.present?
  end

  puts "#{i}:  #{now}"
  puts "   status:  #{status}"
  puts "   last seen:  #{@last_seen_time.try{|t| t.strftime(DATE_FORMAT)}}"
  puts "   sunrise:  #{sunrise_time.try{|t| t.strftime(DATE_FORMAT)}}"
  puts "   sunset:  #{sunset_time.try{|t| t.strftime(DATE_FORMAT)}}"
  puts "   is dark:  #{is_dark?}"
  puts "   on:  #{@on_time.try{|t| t.strftime(DATE_FORMAT)}}"
  puts "   off:  #{@off_time.try{|t| t.strftime(DATE_FORMAT)}}"
  puts "   action:  #{action}" if action.present?
  puts "\n\n"

  sleep PERIOD

end

