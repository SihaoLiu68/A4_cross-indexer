#this function is used to process the objdump output and the llvm-dwarfdump output
#it returns two tables, the first table is new_lookup_table, which stores and source code file name, the assembly addresses and the corresponding source code.
def readllvm(dwarf_file, exe)
  new_lookup_table = {}
  file_indexes = []
  myfile_name = ""
  flag = false
  head = true
  head_add = ""
  tail_add = ""
  lookup_table = {}
  myfile_index = -1
  #this part generates the temporary lookup_table which looks like
  # {file_1: {assembly_addr_1=>source_code_line_1, assembly_addr_2=>source_code_line_2 ...}
  #  file_2: {assembly_addr_1=>source_code_line_1, assembly_addr_2=>source_code_line_2... }
  #  ......}

  dwarf_file.each_line do |line|
      if flag == false
        if line.match(/file_names/)
          file_index = line.scan(/\d/).join('').to_s
          file_indexes.push(file_index)
          myfile_index = file_index
        elsif line.match(/name:/)
          file_name = line.scan(/"[^"]*"/).to_s.gsub('"', '').gsub("\\", '')
          
          if file_name == "[" + exe.to_s + "]"
            flag = true
            myfile_name = file_name.to_s
          end
        end
      end
      if flag == true
        if line.match(/debug_line/)
          break
        end

        if line.match(/0[xX][0-9a-fA-F]+/)
          if line.match(/mod_time/)
            
          elsif line.match(/length/)
            
          else 
            arr = line.gsub(/\s+/m, ' ').strip.split(" ")
            assembly_addr = arr[0]
            line_number = arr[1]
            file_number = arr[3]
            tail_add = assembly_addr
            
            
            if line_number != "0" && file_number.to_s == myfile_index.to_s
              if head == true
                head_add = assembly_addr
                head = false
              end
              file = myfile_name.to_s.gsub("[", '').gsub("]", '')
              if lookup_table.has_key?(file)
                value = lookup_table[file]
                value[assembly_addr] = line_number
                lookup_table[file] = value
                
              else
                lookup_table[file] ={assembly_addr => line_number}
                
              end 
            end
          end
        end 

      
      end 
  end

  #this part processes the lookup_table which is generated from the previous part, replaces the line_number by the source code in the corresponding source file. If multiple assembly code lines refer to the same source code line, then grouping all the assembly code lines together to form a new key, and the value is the source code line. 
  #e.g., lookup_table {file_1: {0x0001=>1, 0x0002=>2, 0x0003=>2}}
  #      new_lookup_table {file_1: {0x0001=>first source code line, [0x0002, 0x0003]=>second source code line}} 
  #new_lookup_table = {}
  src_line = 1;

  lookup_table.each do |key, value|
    new_value = {}
    value.each do |k, v|
      
      if value.select{|k_1, v_1| v_1 == v}.keys.length > 1
        new_value[value.select{|k_1, v_1| v_1 == v}.keys] = value[k]+". "+IO.readlines(key)[v.to_i-1] #value[k] is the line number
      else
        new_value[k] = value[k] +". "+ IO.readlines(key)[v.to_i-1]
      end
    end
    new_value = new_value
    new_lookup_table[key] = new_value
  end

  #this part generate a unused_source_code table, which contains source code that doesn’t have corresponding assembly code
  unused_source_code = {}
  lookup_table.each do |file, code_line_number|
    line_num = 0
    source_code = File.open(file).read
    source_code.gsub!(/\r\n?/, "\n")
    source_code.each_line do |code|
      
      line_num = line_num + 1

      if !code_line_number.values.include?(line_num.to_s)
        if unused_source_code.has_key?(file)  
          value = unused_source_code[file]
          value[line_num] = code
          unused_source_code[file] = value
        else
          unused_source_code[file] = {line_num => code}
        end
      else 
        if code_line_number.select{|k_1, v_1| v_1 == line_num.to_s}.keys.length > 1
          
          temp = new_lookup_table[file][code_line_number.select{|k_1, v_1| v_1 == line_num.to_s}.keys]
          temp_2 = ""
          if unused_source_code[file] != nil
            unused_source_code[file].each do |key, item_element|
              temp_3 = key.to_s + ". " + item_element.to_s
              temp_2 = temp_2 + "<br>" + temp_3
            end
            if ! temp.nil?
              new_lookup_table[file][code_line_number.select{|k_1, v_1| v_1 == line_num.to_s}.keys] = temp_2 + "<br>" + temp
            end
          end
          unused_source_code = {}
        else 
          temp = new_lookup_table[file][code_line_number.select{|k_1, v_1| v_1 == line_num.to_s}.keys[0]]
          temp_2 = ""
          if unused_source_code[file] != nil
            unused_source_code[file].each do |key, item_element|
              temp_3 = key.to_s + ". " + item_element.to_s
              temp_2 = temp_2 + "<br>" + temp_3
            end
            if ! temp.nil?
              new_lookup_table[file][code_line_number.select{|k_1, v_1| v_1 == line_num.to_s}.keys[0]] = temp_2 + "<br>" + temp
            end
          end
          unused_source_code = {}
        end
      end
    end
  end

  head_add_temp = head_add.gsub(/0x[0]*/, "")
  tail_add_temp = tail_add.gsub(/0x[0]*/, "")
  # puts head_add_temp

  return [new_lookup_table, head_add_temp, tail_add_temp]
end
