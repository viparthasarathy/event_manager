require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("output") unless Dir.exists?("output")

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

def clean_phone_numbers(homephone)
  number = homephone.to_s.gsub(/\D/, "")
    if number.length == 10
	  number
	elsif number.length == 11 && number[0] == "1"
		number[1..-1]
	else
		"0000000000"
	end
end

def peak_hour(hash)
peak = hash.select { |hour, num_of_reg| num_of_reg == hash.values.max }
peak.keys.join(', ')
end

def peak_day(hash)
peak = hash.select { |day, num_of_reg| num_of_reg == hash.values.max }
days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
peak = peak.keys
days[peak[0]]
end



puts "EventManager initialized!"

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hour_counter = Hash.new(0)
day_counter = Hash.new(0)
contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)

  time = DateTime.strptime(row[:regdate], "%m/%d/%y %k:%M")
  hour_counter[time.hour] += 1
  day_counter[time.wday] += 1

end

puts "The most popular hours are #{ peak_hour(hour_counter) }"
puts "The most popular day is #{ peak_day(day_counter) }"

