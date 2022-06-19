require 'uri'
require 'net/http'
require 'yajl'
require 'csv'

@args = []
ARGV.each do |a|
  @args << a
end

if @args.empty?
  abort "\nYou must provide a source_url\n\n"
end

url = URI(@args[0])
@host = url.host
unless @host
  abort "\nInvalid URL!\n\n"
end

confirm_token = rand(36**2).to_s(36)
puts "\nFetch JSON from #{@host}? Enter '#{confirm_token}' to confirm:"
input = STDIN.gets.chomp
abort "\nAborting JSON fetch. You entered #{input} instead of #{confirm_token}!\n\n" unless input == confirm_token
puts "\nFetching JSON from #{@host}\n\n"

payload = Net::HTTP.get(url)
@filename = "#{@host}_#{Time.now.to_i}"
output = IO.write("#{@filename}.json", payload)
unless output
  abort "\nFailed to fetch JSON\n\n" unless output
end

@headers = [
  "CPT/DRG Code", 
  "Code Type", 
  "Procedure Description", 
  "Gross Charge", 
  "Insurance Payer Name", 
  "Insurance Rate"
]
@skiplist = [
  "Code",
  "Description",
  "Code Type",
  "Type",
  "RevCode",
  "Gross Charge",
  "Discounted Cash Price",
  "Min",
  "Max"
]

case @host
when 'www.centinelamed.com'
  json0 = File.read("#{@filename}.json")
  parser = Yajl::Parser.new
  puts "\nParsing JSON from #{@host}\n\n"
  json1 = json0.encode('UTF-8', :invalid => :replace, :undef => :replace)
  json2 = json1.gsub("<U+200B>", "")
  hash = parser.parse(json2)
  unless hash
    abort "\nCould not parse JSON!\n\n"
  else
    puts "\nWriting CSV for #{@host}\n\n"
    input1 = hash['StandardCharges']['CDM']
    input2 = hash['StandardCharges']['HIMCPT']
    input3 = hash['StandardCharges']['DRG-ICD10']

    File.write("#{@filename}.csv", "#{@headers.join(",")}\n")
    
    # ['AltCodes']['CPT'] becomes CPT/DRG Code else ProcedureCode
    # "CPT" or "NOT-CPT" becomes Code Type
    # ProcedureName becomes Procedure Description
    # Charge becomes Gross Charge
    # loop InsuranceRates hash
    # payer[0] becomes Insurance Payer Name
    # payer[1] becomes Insurance Rate

    def process_cent_obj(obj)
      if obj.key?('InsuranceRates')
        obj['InsuranceRates'].each do |a|
          @arr1 = []
          @arr2 = []
          if obj['AltCodes'] && obj['AltCodes']['CPT']
            @arr1 << obj['AltCodes']['CPT']
            @arr1 << 'CPT'
          else
            @arr1 << obj['ProcedureCode']
            @arr1 << "NOT-CPT"
          end
          @arr1 << obj['ProcedureName'] ? obj['ProcedureName'] : ""
          @arr1 << obj['Charge'] ? obj['Charge'] : ""
          @arr2 << a[0]
          @arr2 << a[1]
        end
      end
      arr = @arr1.concat(@arr2)
      CSV.open("#{@filename}.csv", "a") do |csv|
        csv << arr
      end
    end

    input1.each do |obj|
      process_cent_obj(obj)
    end

    input2.each do |obj|
      process_cent_obj(obj)
    end

    input3.each do |obj|
      process_cent_obj(obj)
    end

    puts "\nFinished successfully\n\n\n"
  end
    
when 'www.adventhealth.com'
  json0 = File.read("#{@filename}.json")
  parser = Yajl::Parser.new
  puts "\nParsing JSON from #{@host}\n\n"
  json1 = json0.encode('UTF-8', :invalid => :replace, :undef => :replace)
  json2 = json1.gsub("<U+200B>", "")
  hash = parser.parse(json2)
  unless hash
    abort "\nCould not parse JSON!\n\n"
  else
    puts "\nWriting CSV for #{@host}\n\n"
    input1 = hash[0]
    input2 = hash[1]
    input3 = hash[2]
    input4 = hash[3]

    File.write("#{@filename}.csv", "#{@headers.join(",")}\n")

    # when Payer key exists
      # Code becomes CPT/DRG Code
      # Code Type becomes Code Type
      # Charge Description becomes Procedure Description
      # Gross Charge becomes Gross Charge
      # Payer becomes Insurance Payer Name
      # Contracted Allowed becomes Insurance Rate
    # else (no Payer)
      # Code becomes CPT/DRG Code
      # Code Type becomes Code Type
      # Charge Description becomes Procedure Description
      # Gross Charge becomes Gross Charge
      # loop !@skiplist items (payers)
      # payer[0] becomes Insurance Payer Name
      # payer[1] becomes Insurance Rate

    def process_adve_obj(obj)
      if obj.key?('Payer')
        arr1 = []
        arr1 << obj['Code']
        arr1 << obj['Code Type']
        arr1 << obj['Charge Description']
        arr1 << obj['Gross Charge']
        arr1 << obj['Payer']
        arr1 << obj['Contracted Allowed']
        CSV.open("#{@filename}.csv", "a") do |csv|
          csv << arr1
        end
      else
        obj.each do |a|
          @arr1 = []
          @arr2 = []
          unless @skiplist.include? a[0]
            @arr2 << a[0]
            @arr2 << a[1]
            @arr1 << obj['Code']
            @arr1 << obj['Code Type']
            @arr1 << obj['Description']
            @arr1 << obj['Gross Charge']
            arr = @arr1.concat(@arr2)  
            CSV.open("#{@filename}.csv", "a") do |csv|
              csv << arr
            end
          end
        end
      end
    end
  
    input1.each do |obj|
      process_adve_obj(obj)
    end

    input2.each do |obj|
      process_adve_obj(obj)
    end

    input3.each do |obj|
      process_adve_obj(obj)
    end

    input4.each do |obj|
      process_adve_obj(obj)
    end

    puts "\nFinished successfully\n\n\n"

  end
end
