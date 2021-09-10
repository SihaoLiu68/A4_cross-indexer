
require_relative "main.rb"


llvm= `llvm-dwarfdump --debug-line #{ARGV[0]}` 
assembly = `objdump --disassemble #{ARGV[0]}` 
exe = ARGV[1]
llvm_return = readllvm(llvm, exe) 
mapping_table = llvm_return[0]
head_add = llvm_return[1]
tail_add = llvm_return[2]

# modify href in HTML code when sees jump or callq in assembly code
def jmp_callq_helper(tmp_arr_2)
  instruct = ""
  next_jmp_add = false

  tmp_arr_2.each do |tmp_arr_2_ele|
    if ((tmp_arr_2_ele.include? "j") || (tmp_arr_2_ele.include? "call"))
      instruct = instruct + " " + tmp_arr_2_ele 
      next_jmp_add = true
    elsif next_jmp_add == true
      if tmp_arr_2_ele.match(/[0-9a-f]{#{tmp_arr_2_ele.length}}/)
        instruct = instruct + " " + "<a href=\"#asmline#{tmp_arr_2_ele}\">#{tmp_arr_2_ele}</a>"
      else 
        instruct = instruct + " " +tmp_arr_2_ele
      end
      next_jmp_add = false
    else
      instruct = instruct + " " +tmp_arr_2_ele
    end
  end
  
  return instruct
end

#replace < and > with &lt and &gt in assembly
assembly.each_line do |line|
  line =line.gsub("<", "&lt").gsub(">", "&gt")
end

# varibles that will be used to help finding useful assembly code
head_flag = false
start_line_num = 0
temp = 0

#store assembly address between head_add and tail_add to assembly_to_use
assembly_to_use= "" 
assembly.each_line do |line|
  current_line= line.strip 
  temp = temp + 1
  temp_add = current_line.split(':')
  if temp_add[0] == head_add #finds the start line in objdump file
    start_line_num = temp
    head_flag = true
  end
  if head_flag == true
    assembly_to_use = assembly_to_use + line # update assembly_to_use
  end

  if temp_add[0] == tail_add # stop when finds the end line in objdump file
    break
  end
end
assembly = assembly_to_use # updates the assembly

time = Time.new # the time when the xref tool was run
path = Dir.pwd # the place where the xref tool was run

# create home.html
home_file =
"<!DOCTYPE html>
<html>
<body>

<h2>Assignment 4 Cross-Indexing</h2>

<p>This link leads to the main HTML file: </p>

<p><a href=\"main.html\">main.html</a></p>
<p>XREF is ran at : #{time} in the directory of #{path}</p>

</body>
</html>
"

# create main.html
output_file = 
"<!DOCTYPE html> 
<html>
  <h1>Assignment 4 Cross-Indexing<h1>
  <h3>Yanwei Yang & Sihao Liu</h3>
  <style>
  table {
  border-collapse: collapse;
  width: 100%;
  }
  th, td {
  text-align: left;
  padding: 16px;
  }
    table, th, td {
    border: 1px solid black;
    border-collapse: collapse;
  }
  tr:nth-child(odd) {background-color: #EEEEEE;}
  </style>
<div>"
html_output =  "  <table style=\"float: left\">
<tr>
  <th>Assembly</th>
  <th>Source</th>
</tr>"

# variables and maps used for mapping
check_corres = false # check whether an assembly line has corresponding source line
first_line = true
line_number =start_line_num
previous_src_line = 1
grey_area_map = {} # mark the reoccurrence of source code 

previous_addr = ""
current_addr = ""

# loop through the updated assembly which contains useful assembly addresses
assembly.each_line do |line|
  line_number = line_number + 1 
  line_number_string = line_number.to_s
  line_number_string= line_number_string + ". "
  tmp = line.strip
  array = line.gsub(/\s/m, ' ').strip.split(" ")
  address = array[0]
  if !address.nil? == true && address.match(/:/)
    address = address.gsub(/:/, '')
    mapping_table.each do |key, value| 
    
    assembly_address = value.keys
    assembly_address.each do |addr|
      current_source_line = value[addr].split('.')[0].to_i 
      current_addr = value[addr]

      if addr.kind_of?(Array) # multiple assembly line maps to one source line
        addr.each do |addr_element| 
          if addr_element.match(/#{address}/)
            html_output = html_output + "<tr><td>"
        
            if first_line == true 
              previous_addr = current_addr
              previous_src_line = current_source_line
              tmp_arr = tmp.split(':')
              tmp_arr_2 = tmp_arr[1].split(' ')

               # helper function for jmp
              instruct = jmp_callq_helper(tmp_arr_2)

              html_output = html_output +"#{line_number_string} <a name=\"asmline#{tmp_arr[0].strip}\" href=\"#asmline#{tmp_arr[0].strip}\">#{tmp_arr[0].strip}</a> #{instruct} </td><td>#{value[addr]}</td></tr>"
              first_line = false
            end
            
            if previous_addr != current_addr
              previous_addr = current_addr
              if grey_area_map[value[addr]] == true
                tmp_arr = tmp.split(':')
                tmp_arr_2 = tmp_arr[1].split(' ')
                
                # helper function for jmp
                instruct = jmp_callq_helper(tmp_arr_2)

                html_output = html_output +"#{line_number_string} <a name=\"asmline#{tmp_arr[0].strip}\" href=\"#asmline#{tmp_arr[0].strip}\">#{tmp_arr[0].strip}</a> #{instruct} </td><td style = \"background-color:#00FF00\">#{value[addr]}</td></tr>"
              else 
                tmp_arr = tmp.split(':')
                tmp_arr_2 = tmp_arr[1].split(' ')

                 # helper function for jmp
                instruct = jmp_callq_helper(tmp_arr_2)

                html_output = html_output +"#{line_number_string} <a name=\"asmline#{tmp_arr[0].strip}\" href=\"#asmline#{tmp_arr[0].strip}\">#{tmp_arr[0].strip}</a> #{instruct} </td><td>#{value[addr]}</td></tr>"
              end
            end
            
            grey_area_map[value[addr]] = true

            check_corres = true
          end
        end # end of addr_element
        
      else # single assembly line maps to one source line
        if addr.match(/#{address}/)
          html_output = html_output + "<tr><td>"
          if first_line == true 
            previous_addr = current_addr
            tmp_arr = tmp.split(':')
            tmp_arr_2 = tmp_arr[1].split(' ')

            # helper function for jmp
            instruct = jmp_callq_helper(tmp_arr_2)

            html_output = html_output +"#{line_number_string} <a name=\"asmline#{tmp_arr[0].strip}\" href=\"#asmline#{tmp_arr[0].strip}\">#{tmp_arr[0].strip}</a> #{instruct} </td><td>#{value[addr]}</td></tr>" 
            first_line = false
          end

          if previous_addr != current_addr
            previous_addr = current_addr
            if grey_area_map[value[addr]] == true
              tmp_arr = tmp.split(':')
              tmp_arr_2 = tmp_arr[1].split(' ')

              # helper function for jmp
              instruct = jmp_callq_helper(tmp_arr_2)

              html_output = html_output +"#{line_number_string} <a name=\"asmline#{tmp_arr[0].strip}\" href=\"#asmline#{tmp_arr[0].strip}\">#{tmp_arr[0].strip}</a> #{instruct} </td><td style = \"background-color:#00FF00\">#{value[addr]}</td></tr>"
            else 
              tmp_arr = tmp.split(':')
              tmp_arr_2 = tmp_arr[1].split(' ')
              
              # helper function for jmp
              instruct = jmp_callq_helper(tmp_arr_2)
              
              html_output = html_output +"#{line_number_string} <a name=\"asmline#{tmp_arr[0].strip}\" href=\"#asmline#{tmp_arr[0].strip}\">#{tmp_arr[0].strip}</a> #{instruct} </td><td>#{value[addr]}</td></tr>"
            end
          end
          grey_area_map[value[addr].to_s] = true
          check_corres = true
        end
      end #end of if/else
    end #end of addr loop
  end #end of |key,value| loop
  end
  
 if check_corres == false  
   if line.match(/main/) && line.split(' ').length() == 2
    html_output = html_output + "<tr><td><a id=\"target\"></a>"
            
   else
      html_output = html_output +  "<tr><td>"
      
   end
   line_arr = line.split(':')
   if line_arr[1].nil?
    instruct = line_arr[1]
   else
    tmp_arr_2 = line_arr[1].split(' ')
   # helper function for jmp
    instruct = jmp_callq_helper(tmp_arr_2)
   end

   html_output = html_output  +line_number_string + "<a name=\"asmline#{line_arr[0].strip}\" href=\"#asmline#{line_arr[0].strip}\">#{line_arr[0].strip}</a> #{instruct}" + "</td></tr>"
 end
 check_corres = false
end

output_file = output_file + html_output + "
</div>
</html>"
puts "HTML code has been generated in XREF directory"


#Create directory XREF and write html files home.html and main.html
Dir.mkdir('XREF') unless Dir.exist?('XREF') # creates directory if it does not already exist
File.open('XREF/home.html','w') do |file|
  file.write(home_file) 
end
Dir.mkdir('XREF') unless Dir.exist?('XREF') 
File.open('XREF/main.html','w') do |file|
  file.write(output_file) 
end

