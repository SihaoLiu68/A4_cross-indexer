Assignment 4 Cross-Indexing 

Yangwei Yang     yyang105
Sihao Liu        sliu68

Files: xref.rb, main.rb, myfile2.rs, myfile2, README.txt
Folder: XREF


(We have provided myfile2.rs and myfile2 as test file and executable file)
To run the program:
(1) Compile your test file with "rustc -g -o test test.rs"
(2) Run xref.rb by typing in "ruby xref.rb test test.rs"
(3) You can find home.html and main.html file in the XREF folder
(4) Open home.html and click on the link to go to the main.html

Code explanations:
The readllvm function reads a llvm-dwarfdump file and the name of the rust file.
It returns one mapping table and two addresses. The table stores the file as the key, and the mapping information as the value.
The mapping information stores a set of assembly addresses as key, and their corresponding source code as the value.
The first returned address is the start of assembly code in mapping, the second returned address is the end of assembly code in mapping.
The jmp_callq_helper adds href to the assembly codes in html code when it sees jump or callq followed by an assembly address.
The assembly_to_use stores all assembly address that have corresponding source line, and it's stored in "assembly".
Then we go through the "assembly" line by line and add them to "html_output". href is added when sees jmp or callq.
The html_output is attached to the html header to create the final html code in two kinds of situations: one is when multiple assembly 
line maps to one source line, another is when exactly one assembly line maps to one source line.

Code features:
(1) We have placed the assembly-language in address order on the left side of html page, and source code on the right.
(2) We have displayed assembly and source code side-by-side.
(3) We have arranged HTML link in the assembly code which can jump to the target line when it's possible.
(4) We have arranged for all fixed-address control transfer in assembly code to be rendered as HTML links that jump to correct locations.
(5) The grey background-color is just for the clarity, does not indicate the subsequent occurence.
(6) We have printed the second and subsequent occurrences of source code in green color.


