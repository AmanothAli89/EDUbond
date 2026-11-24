import '../../models/quiz_question_model.dart';

/// Complete default MCQ quiz sets ported directly from `AppStorage.kt`.
abstract final class QuizSeedData {
  static QuizQuestionModel _q(
    String question,
    List<String> options,
    String answer,
  ) {
    return QuizQuestionModel(
      question: question,
      options: options,
      answer: answer,
    );
  }

  static List<List<QuizQuestionModel>>? getDefaultSetsForSubject(
    String subject,
  ) {
    switch (subject.trim()) {
      case 'Software Engineering':
        return _softwareEngineering;
      case 'Computer Architecture':
        return _computerArchitecture;
      case 'Data Communication':
      case 'Data Commutation':
        return _dataCommunication;
      case 'Microprocessor':
        return _microprocessor;
      case 'Compiler':
        return _compiler;
      case 'গনিত ৯-১০':
      case 'গনিত SSC':
        return _generalMath;
      case 'উচ্চতর গনিত ৯-১০':
      case 'উচ্চতর গনিত SSC':
        return _higherMath;
      case 'পদার্থবিজ্ঞান ৯-১০':
        return _physics;
      case 'অর্থনীতি ৯-১০':
      case 'অর্থনীতি SSC':
        return _economics;
      default:
        return null;
    }
  }

  static final List<List<QuizQuestionModel>> _softwareEngineering = [
    [
      _q('What is the first phase of the Software Development Life Cycle?', ['Testing', 'Design', 'Requirement gathering', 'Deployment'], 'Requirement gathering'),
      _q('Which model is known as the classic life cycle?', ['Spiral', 'Agile', 'Waterfall', 'V-Model'], 'Waterfall'),
      _q('What does UML stand for?', ['Unified Modeling Language', 'Universal Machine Language', 'Unified Machine Learning', 'None'], 'Unified Modeling Language'),
      _q('Which of the following is a functional requirement?', ['Response time', 'Security', 'Calculate tax', 'Availability'], 'Calculate tax'),
      _q('Cohesion measures:', ['Interdependence among modules', 'How closely elements inside a module are related', 'Number of modules', 'None'], 'How closely elements inside a module are related'),
      _q('Black-box testing focuses on:', ['Internal logic', 'External behavior', 'Code structure', 'All'], 'External behavior'),
      _q('Which is NOT a software process model?', ['Waterfall', 'RAD', 'ISO 9001', 'Spiral'], 'ISO 9001'),
      _q('Requirement elicitation mainly aims to:', ['Write code', 'Understand user needs', 'Test', 'Deploy'], 'Understand user needs'),
      _q('Which diagram shows dynamic behavior of a system?', ['Class diagram', 'Use case diagram', 'Sequence diagram', 'Deployment diagram'], 'Sequence diagram'),
      _q('Validation asks:', ['Are we building the product right?', 'Are we building the right product?', 'Code testing', 'Both a & b'], 'Are we building the right product?'),
    ],
    [
      _q('Which model emphasizes risk analysis?', ['Waterfall', 'Spiral', 'Incremental', 'Agile'], 'Spiral'),
      _q('Example of a non-functional requirement:', ['Login functionality', 'System response must be < 2 sec', 'Interest calculation', 'User registration'], 'System response must be < 2 sec'),
      _q('In Agile, a short development cycle is called a:', ['Sprint', 'Phase', 'Module', 'Iteration'], 'Sprint'),
      _q('Coupling indicates:', ['Internal strength of a module', 'Degree of interdependence between modules', 'Lines of code', 'Complexity'], 'Degree of interdependence between modules'),
      _q('End-users typically perform:', ['Unit testing', 'Integration testing', 'Alpha testing', 'Beta testing'], 'Beta testing'),
      _q('A class diagram displays:', ['Sequence of messages', 'Object states', 'Static structure of the system', 'Deployment architecture'], 'Static structure of the system'),
      _q('Which is a requirement elicitation technique?', ['Code review', 'Interview', 'Unit testing', 'Debugging'], 'Interview'),
      _q('Prototyping is mainly used for:', ['Final deployment', 'Requirement validation', 'Performance testing', 'Documentation'], 'Requirement validation'),
      _q('The V-Model emphasizes:', ['Risk analysis', 'Testing at each development stage', 'Repeated iterations', 'None'], 'Testing at each development stage'),
      _q('In SCM, a baseline is:', ['A code library', 'A formally reviewed specification', 'A testing tool', 'A programming language'], 'A formally reviewed specification'),
    ],
  ];

  static final List<List<QuizQuestionModel>> _computerArchitecture = [
    [
      _q('Brain of the computer?', ['ALU', 'CPU', 'RAM', 'ROM'], 'CPU'),
      _q('ALU stands for?', ['Arithmetic Logic Unit', 'Array Logic Unit', 'Arithmetic Local Unit', 'None'], 'Arithmetic Logic Unit'),
      _q('High-speed memory near CPU?', ['RAM', 'Hard Disk', 'Cache', 'Flash'], 'Cache'),
      _q('Separate memory for data and instructions?', ['Von Neumann', 'Harvard', 'RISC', 'CISC'], 'Harvard'),
      _q('Bus for memory location?', ['Data Bus', 'Control Bus', 'Address Bus', 'Expansion Bus'], 'Address Bus'),
      _q('Temporary storage in CPU?', ['Slots', 'Buses', 'Registers', 'Caches'], 'Registers'),
      _q('Von Neumann bottleneck is between?', ['CPU and RAM', 'RAM and Disk', 'ALU and CU', 'Input and Output'], 'CPU and RAM'),
      _q('Program Counter size depends on?', ['Data width', 'Address bus width', 'ALU size', 'Clock speed'], 'Address bus width'),
      _q('Parallel wires for data transfer?', ['Port', 'Cable', 'Bus', 'Line'], 'Bus'),
      _q('Control Unit sends?', ['Data signals', 'Control signals', 'Memory addresses', 'Interrupts'], 'Control signals'),
    ],
    [
      _q('Volatile memory?', ['ROM', 'RAM', 'EPROM', 'Flash'], 'RAM'),
      _q('SRAM uses?', ['Capacitors', 'Flip-flops', 'Transistors', 'Magnetic core'], 'Flip-flops'),
      _q('DRAM uses?', ['Flip-flops', 'Capacitors', 'Static power', 'Registers'], 'Capacitors'),
      _q('Virtual memory uses?', ['Paging', 'Caching', 'Registers', 'ROM'], 'Paging'),
      _q('Page fault occurs when?', ['Cache full', 'Requested page not in RAM', 'CPU idle', 'Disk slow'], 'Requested page not in RAM'),
      _q('Write-through is policy for?', ['RAM', 'Registers', 'Cache', 'I/O'], 'Cache'),
      _q('ROM stands for?', ['Read Only Memory', 'Random Only Memory', 'Ready On Memory', 'None'], 'Read Only Memory'),
      _q('Slowest access time?', ['Registers', 'Cache', 'Main Memory', 'Magnetic Disk'], 'Magnetic Disk'),
      _q('Hit ratio measures efficiency of?', ['ALU', 'Cache', 'Buses', 'Hard Disk'], 'Cache'),
      _q('EEPROM erased by?', ['Ultraviolet light', 'Electrical signal', 'Magnetic field', 'Heat'], 'Electrical signal'),
    ],
    [
      _q('RISC stands for?', ['Reduced Instruction Set Computer', 'Refined System Core', 'Rapid Serial Clock', 'None'], 'Reduced Instruction Set Computer'),
      _q('CISC emphasizes?', ['Simple instructions', 'Complex instructions', 'Zero registers', 'Software complexity'], 'Complex instructions'),
      _q('Instruction format includes Opcode and?', ['Operand', 'Register', 'Address', 'Bus'], 'Operand'),
      _q('Immediate addressing means operand is?', ['In register', 'In instruction itself', 'In memory', 'Indirect'], 'In instruction itself'),
      _q('Holds address of next instruction?', ['IR', 'MAR', 'PC', 'ACC'], 'PC'),
      _q('Stack pointer points to?', ['Bottom', 'Top', 'Middle', 'Instruction'], 'Top'),
      _q('Zero-address instructions use?', ['Array', 'Queue', 'Stack', 'Tree'], 'Stack'),
      _q('Cycle after fetch?', ['Execute', 'Decode', 'Write back', 'Interrupt'], 'Decode'),
      _q('Effective address calculated in?', ['Immediate', 'Direct', 'Addressing modes', 'Fetch'], 'Addressing modes'),
      _q('Accumulator is a?', ['Bus', 'Register', 'I/O port', 'Memory cell'], 'Register'),
    ],
    [
      _q('Pipelining increases?', ['Latency', 'Throughput', 'Clock speed', 'Memory size'], 'Throughput'),
      _q('Hazard when data not available?', ['Structural', 'Data', 'Control', 'Branch'], 'Data'),
      _q('Branch prediction reduces?', ['Data hazards', 'Structural hazards', 'Control hazards', 'ALU delay'], 'Control hazards'),
      _q('DMA stands for?', ['Direct Memory Access', 'Dynamic Memory Array', 'Direct Multi Access', 'None'], 'Direct Memory Access'),
      _q('I/O method where CPU polls?', ['Interrupt-driven', 'DMA', 'Programmed I/O', 'Serial'], 'Programmed I/O'),
      _q('SIMD stands for?', ['Single Instruction Multiple Data', 'Simple Multi Data', 'Serial Main Data', 'None'], 'Single Instruction Multiple Data'),
      _q('Vector processors are?', ['SISD', 'SIMD', 'MISD', 'MIMD'], 'SIMD'),
      _q('Superscalar execute?', ['One inst/cycle', 'Multiple inst/cycle', 'Zero inst', 'Slowly'], 'Multiple inst/cycle'),
      _q('Inter-process communication for?', ['Uniprocessors', 'Multiprocessors', 'Caches', 'ROM'], 'Multiprocessors'),
      _q("Amdahl's Law calculates?", ['Speedup', 'Clock speed', 'Power consumption', 'Memory leak'], 'Speedup'),
    ],
  ];

  static final List<List<QuizQuestionModel>> _dataCommunication = [
    [
      _q('OSI layers?', ['5', '7', '4', '6'], '7'),
      _q('Layer for routing?', ['Physical', 'Data Link', 'Network', 'Transport'], 'Network'),
      _q('TCP works at?', ['Network', 'Transport', 'Session', 'Application'], 'Transport'),
      _q('IP address layer?', ['Physical', 'Data Link', 'Network', 'Application'], 'Network'),
      _q('MAC address layer?', ['Data Link', 'Network', 'Session', 'Physical'], 'Data Link'),
      _q('Top layer of OSI?', ['Presentation', 'Session', 'Application', 'Transport'], 'Application'),
      _q('End-to-end delivery responsibility?', ['Network', 'Transport', 'Data Link', 'Physical'], 'Transport'),
      _q('Data encryption layer?', ['Application', 'Presentation', 'Session', 'Transport'], 'Presentation'),
      _q('Hub works at?', ['Physical', 'Data Link', 'Network', 'Transport'], 'Physical'),
      _q('Switch works at?', ['Physical', 'Data Link', 'Network', 'Application'], 'Data Link'),
    ],
    [
      _q('Highest bandwidth media?', ['Twisted pair', 'Coaxial cable', 'Fiber optics', 'Radio waves'], 'Fiber optics'),
      _q('Guided media?', ['Microwaves', 'Infrared', 'Coaxial cable', 'Satellite'], 'Coaxial cable'),
      _q('What is crosstalk?', ['Amplification', 'Interference from adjacent wires', 'Frequency shift', 'None'], 'Interference from adjacent wires'),
      _q('Fiber optics uses?', ['Electricity', 'Light', 'Sound', 'Radio'], 'Light'),
      _q('Modulation converts?', ['Decoding', 'Digital to analog', 'Error check', 'Routing'], 'Digital to analog'),
      _q('Baud means?', ['Bits/sec', 'Signal units/sec', 'Frequency', 'Amplitude'], 'Signal units/sec'),
      _q('Full-duplex is?', ['One way', 'Both ways simultaneously', 'Both ways not at once', 'None'], 'Both ways simultaneously'),
      _q('Human voice frequency?', ['300-3400 Hz', '20-20k Hz', '1-10 MHz', 'None'], '300-3400 Hz'),
      _q('Attenuation is?', ['Strength gain', 'Loss of signal energy', 'Noise addition', 'Phase shift'], 'Loss of signal energy'),
      _q('Sampling theorem name?', ['Shannon', 'Nyquist', 'Ohm', 'Fourier'], 'Nyquist'),
    ],
    [
      _q('Multiplexing shares?', ['Noise', 'One link among many signals', 'Speed', 'Signals'], 'One link among many signals'),
      _q('FDM stands for?', ['Frequency Division Multiplexing', 'Fast Data Multiplexing', 'File Data Method', 'None'], 'Frequency Division Multiplexing'),
      _q('Digital signal multiplexing?', ['FDM', 'WDM', 'TDM', 'None'], 'TDM'),
      _q('Checksum for?', ['Routing', 'Error detection', 'Flow control', 'Encryption'], 'Error detection'),
      _q('CRC based on?', ['Addition', 'Binary division', 'Multiplication', 'Subtraction'], 'Binary division'),
      _q('ARQ stands for?', ['Automatic Repeat Request', 'Automatic Routing Query', 'Access Remote Queue', 'None'], 'Automatic Repeat Request'),
      _q('Flow control prevents?', ['Speed up', 'Overwhelming receiver', 'Error check', 'Identify user'], 'Overwhelming receiver'),
      _q('Pure ALOHA max throughput?', ['18.4%', '36.8%', '100%', '50%'], '18.4%'),
      _q('CSMA/CD used in?', ['Token Ring', 'Ethernet', 'Wi-Fi', 'Bluetooth'], 'Ethernet'),
      _q('Sliding window for?', ['Routing', 'Flow control', 'Modulation', 'Encryption'], 'Flow control'),
    ],
    [
      _q('IPv4 size?', ['32 bits', '64 bits', '128 bits', '48 bits'], '32 bits'),
      _q('IPv6 size?', ['32 bits', '64 bits', '128 bits', '256 bits'], '128 bits'),
      _q('DNS translates names to?', ['MAC', 'IP', 'Port', 'Binary'], 'IP'),
      _q('HTTP port?', ['443', '21', '80', '25'], '80'),
      _q('Connectionless protocol?', ['TCP', 'UDP', 'FTP', 'HTTP'], 'UDP'),
      _q('ICMP for?', ['File transfer', 'Error reporting', 'Routing', 'Email'], 'Error reporting'),
      _q('DHCP provides?', ['Static IP', 'Dynamic IP', 'Security', 'Domain'], 'Dynamic IP'),
      _q('SMTP used for?', ['Web', 'File', 'Sending emails', 'Login'], 'Sending emails'),
      _q('Remote login protocol?', ['FTP', 'Telnet', 'SMTP', 'SNMP'], 'Telnet'),
      _q('Firewall purpose?', ['Backup', 'Security', 'Speed', 'Monitoring'], 'Security'),
    ],
  ];

  static final List<List<QuizQuestionModel>> _microprocessor = [
    [
      _q('First 8-bit Intel processor?', ['4004', '8008', '8080', '8085'], '8008'),
      _q('8085 bits?', ['4', '8', '16', '32'], '8'),
      _q('8085 pins?', ['20', '30', '40', '16'], '40'),
      _q('8085 Accumulator?', ['B', 'C', 'A', 'H'], 'A'),
      _q('8086 bits?', ['8', '16', '32', '64'], '16'),
      _q('8085 address bus?', ['8 bit', '16 bit', '20 bit', '32 bit'], '16 bit'),
      _q('8086 address bus?', ['16 bit', '20 bit', '24 bit', '32 bit'], '20 bit'),
      _q('Flag for zero result?', ['Sign', 'Zero', 'Parity', 'Carry'], 'Zero'),
      _q('8085 General Purpose Registers?', ['4', '6', '8', '10'], '6'),
      _q('8085 Stack Pointer bits?', ['8', '16', '20', '32'], '16'),
    ],
    [
      _q('MOV A, B addressing?', ['Immediate', 'Register', 'Direct', 'Indirect'], 'Register'),
      _q('MVI A, 05H addressing?', ['Immediate', 'Direct', 'Implicit', 'None'], 'Immediate'),
      _q('Instruction to stop?', ['STOP', 'HALT', 'END', 'HLT'], 'HLT'),
      _q('LDA 2000H length?', ['1 byte', '2 byte', '3 byte', 'None'], '3 byte'),
      _q('XCHG exchanges?', ['H-L with D-E', 'A with B', 'SP with PC', 'None'], 'H-L with D-E'),
      _q('Change flow instruction group?', ['Arithmetic', 'Logical', 'Branch', 'Data transfer'], 'Branch'),
      _q('PUSH/POP work with?', ['ALU', 'Stack', 'I/O', 'Registers'], 'Stack'),
      _q('Instruction cycle consists of?', ['Fetch', 'Execute', 'Fetch and Execute', 'None'], 'Fetch and Execute'),
      _q('Opcode fetch T-states?', ['3', '4', '6', '10'], '4'),
      _q('INR A affects?', ['Carry', 'All flags except Carry', 'Zero only', 'No flags'], 'All flags except Carry'),
    ],
    [
      _q('TRAP interrupt type?', ['Maskable', 'Non-maskable', 'Software', 'None'], 'Non-maskable'),
      _q('Highest priority interrupt?', ['TRAP', 'RST 7.5', 'RST 6.5', 'INTR'], 'TRAP'),
      _q('RST 7.5 Vector address?', ['003CH', '0034H', '002CH', '0024H'], '003CH'),
      _q('SIM instruction for?', ['Serial Input', 'Serial Output/Masking', 'Arithmetic', 'Interrupt'], 'Serial Output/Masking'),
      _q('8255 PPI chip?', ['PPI', 'DMA', 'PIC', 'PIT'], 'PPI'),
      _q('8259 used for?', ['DMA', 'PIC', 'PIT', 'USART'], 'PIC'),
      _q('8237 is a?', ['PIC', 'DMA', 'Keyboard', 'Display'], 'DMA'),
      _q('8255 ports?', ['2', '3', '4', '1'], '3'),
      _q('Wait state used to?', ['Speed up', 'Sync with slow memory', 'Stop', 'None'], 'Sync with slow memory'),
      _q('ALE stands for?', ['Address Latch Enable', 'Logic Enable', 'Line Enable', 'None'], 'Address Latch Enable'),
    ],
    [
      _q('Intel 80386 bits?', ['16', '32', '64', '8'], '32'),
      _q('8086 segmentation addressing limit?', ['64 KB', '1 MB', '16 MB', '4 GB'], '1 MB'),
      _q('80386 mode for 8086 apps?', ['Protected', 'Real', 'Virtual 8086', 'SMM'], 'Virtual 8086'),
      _q('Multicore has?', ['One CPU', 'Multiple CPUs on one chip', 'Multiple RAMs', 'None'], 'Multiple CPUs on one chip'),
      _q('L1 Cache is?', ['Outside CPU', 'Inside CPU', 'On MB', 'In RAM'], 'Inside CPU'),
      _q('Hyper-threading by?', ['AMD', 'Intel', 'ARM', 'Apple'], 'Intel'),
      _q('64-bit extension of x86?', ['x86-64', 'ARM64', 'MIPS', 'PowerPC'], 'x86-64'),
      _q('8086 code segment register?', ['DS', 'SS', 'CS', 'ES'], 'CS'),
      _q('8085 Bi-directional bus?', ['Address', 'Data', 'Control', 'None'], 'Data'),
      _q('Min/Max mode features of?', ['8085', '8086', '80386', 'Pentium'], '8086'),
    ],
  ];

  static final List<List<QuizQuestionModel>> _compiler = [
    [
      _q('Compiler translates?', ['High to Machine', 'Machine to High', 'High to High', 'None'], 'High to Machine'),
      _q('First phase?', ['Syntax', 'Lexical', 'Semantic', 'Generation'], 'Lexical'),
      _q('Lexical analyzer produces?', ['Characters', 'Tokens', 'Bits', 'Sentences'], 'Tokens'),
      _q('Lexical tool?', ['Yacc', 'Lex', 'Gcc', 'Debugger'], 'Lex'),
      _q('Symbol table for?', ['Variables', 'Testing', 'I/O', 'None'], 'Variables'),
      _q('Syntax analysis name?', ['Scanning', 'Parsing', 'Lexing', 'Optimization'], 'Parsing'),
      _q('Grouping characters to sequences?', ['Parsing', 'Tokenizing', 'Linking', 'Loading'], 'Tokenizing'),
      _q('Missing semicolon catch phase?', ['Lexical', 'Syntax', 'Semantic', 'Optimization'], 'Syntax'),
      _q('Lexeme is?', ['Category', 'Character sequence matching pattern', 'Rule', 'None'], 'Character sequence matching pattern'),
      _q('Regex used in?', ['Lexical', 'Syntax', 'Optimization', 'Linker'], 'Lexical'),
    ],
    [
      _q('CFG used for?', ['Lexical', 'Syntax', 'Optimization', 'Semantic'], 'Syntax'),
      _q('Top-Down parser?', ['LR', 'LL', 'LALR', 'SLR'], 'LL'),
      _q('Bottom-Up parser?', ['LL', 'Recursive', 'LR', 'Predictive'], 'LR'),
      _q('Ambiguous grammar produces?', ['One tree', 'Multiple trees', 'No tree', 'Terminals'], 'Multiple trees'),
      _q('L in LL stands for?', ['Leftmost', 'Left-to-right scanning', 'Longest', 'Logical'], 'Left-to-right scanning'),
      _q('Handle pruning for?', ['Top-down', 'Bottom-up', 'Optimization', 'Lexing'], 'Bottom-up'),
      _q('Recursive descent is?', ['Bottom-up', 'Top-down', 'Semantic', 'Optimizer'], 'Top-down'),
      _q('Shift-reduce is?', ['Top-down', 'Bottom-up', 'Lexical', 'None'], 'Bottom-up'),
      _q('Yacc stands for?', ['Compiler Compiler', 'Code Correct', 'Code Class', 'None'], 'Yet Another Compiler Compiler'),
      _q('LALR stands for?', ['Look-Ahead LR', 'Left-Always', 'Long-Acting', 'None'], 'Look-Ahead LR'),
    ],
    [
      _q('Semantic analysis checks?', ['Syntax', 'Meaning/Consistency', 'Tokens', 'Fast code'], 'Meaning/Consistency'),
      _q('Intermediate representation is?', ['Machine dep', 'Machine indep', 'Assembly', 'Binary'], 'Machine indep'),
      _q('Three-address code example of?', ['High', 'Intermediate', 'Machine', 'Assembly'], 'Intermediate'),
      _q('Static checking done at?', ['Compile', 'Run', 'Link', 'Load'], 'Compile'),
      _q('AST used in?', ['Lexical', 'Intermediate', 'Physical', 'None'], 'Intermediate'),
      _q('Type checking ensures?', ['Memory', 'Compatible types', 'Small code', 'Syntax'], 'Compatible types'),
      _q('DAG can represent?', ['Rules', 'Expressions/Code', 'Memory', 'Tokens'], 'Expressions/Code'),
      _q('Backpatching for?', ['Boolean jumps', 'Memory', 'Lexing', 'Parsing'], 'Boolean jumps'),
      _q('SDT uses?', ['Grammar', 'Grammar + actions', 'C code', 'Tokens'], 'Grammar + actions'),
      _q('Inherited attributes pass?', ['Up', 'Down', 'Siblings', 'None'], 'Down'),
    ],
    [
      _q('Code optimization aims for?', ['Readability', 'Speed/Size', 'Features', 'Bugs'], 'Speed/Size'),
      _q('Dead code removal?', ['Loops', 'Unreachable code', 'Functions', 'Comments'], 'Unreachable code'),
      _q('Constant folding?', ['Variables', 'Evaluate at compile time', 'Paper', 'None'], 'Evaluate at compile time'),
      _q('Loop unrolling for?', ['Lexing', 'Optimization', 'Parsing', 'Linking'], 'Optimization'),
      _q('Final phase?', ['Optimization', 'Generation', 'Linking', 'Loading'], 'Code Generation'),
      _q('Peephole looks at?', ['Whole', 'Small window', 'Variables', 'Comments'], 'Small window'),
      _q('Register allocation task of?', ['Lexer', 'Parser', 'Generator', 'Linker'], 'Code Generator'),
      _q('Cross-compiler runs on one, produces for?', ['Same', 'Different', 'Web', 'Cloud'], 'Different'),
      _q('JIT happens?', ['Before', 'During', 'After', 'Never'], 'During execution'),
      _q('Compiler-construction tool?', ['Debugger', 'Lex', 'IDE', 'Editor'], 'Lex'),
    ],
  ];

  static final List<List<QuizQuestionModel>> _generalMath = [
    [
      _q('(a+b)² এর সঠিক সূত্র কোনটি?', ['a²+b²', 'a²+2ab+b²', 'a²-2ab+b²', 'a²-b²'], 'a²+2ab+b²'),
      _q('a²-b² = কত?', ['(a+b)(a+b)', '(a-b)(a-b)', '(a+b)(a-b)', 'a²+b²'], '(a+b)(a-b)'),
      _q('x² + 5x + 6 এর উৎপাদক কোনটি?', ['(x+2)(x+3)', '(x-2)(x-3)', '(x+1)(x+6)', '(x-1)(x-6)'], '(x+2)(x+3)'),
      _q('কোন সংখ্যার ৫% যদি ২০ হয়, তবে সংখ্যাটি কত?', ['১০০', '২০০', '৪০০', '৫০০'], '৪০০'),
      _q('বৃত্তের ক্ষেত্রফলের সূত্র কি?', ['2πr', 'πr²', 'πd', '2πr²'], 'πr²'),
      _q('সমকোণী ত্রিভুজের অতিভুজ ৫ এবং এক বাহু ৩ হলে অন্য বাহু কত?', ['২', '৪', '১', '৭'], '৪'),
      _q('log₁₀ 100 এর মান কত?', ['১', '২', '১০', '১০০'], '২'),
      _q('প্রথম ১০টি স্বাভাবিক সংখ্যার সমষ্টি কত?', ['৪৫', '৫০', '৫৫', '৬০'], '৫৫'),
      _q('বর্গের ক্ষেত্রফল ১৬ বর্গ সেমি হলে এর এক বাহুর দৈর্ঘ্য কত?', ['২', '৪', '৮', '১৬'], '৪'),
      _q('সরল মুনাফার সূত্র কোনটি?', ['I=Pnr', 'I=P/nr', 'I=n/Pr', 'None'], 'I=Pnr'),
    ],
    [
      _q('ত্রিভুজের তিন কোণের সমষ্টি কত?', ['৯০°', '১০০°', '১৮০°', '৩৬০°'], '১৮০°'),
      _q('একটি সমবাহু ত্রিভুজের প্রতিটি কোণ কত?', ['৩০°', '৪৫°', '৬০°', '৯০°'], '৬০°'),
      _q('বৃত্তের ব্যাস ব্যাসার্ধের কত গুণ?', ['অর্ধেক', 'সমান', 'দ্বিগুণ', 'তিন গুণ'], 'দ্বিগুণ'),
      _q('বর্গের পরিসীমার সূত্র কি?', ['a²', '4a', '2a', 'a/4'], '4a'),
      _q('আয়তক্ষেত্রের ক্ষেত্রফল =', ['দৈর্ঘ্য + প্রস্থ', 'দৈর্ঘ্য × প্রস্থ', '২(দৈর্ঘ্য + প্রস্থ)', 'দৈর্ঘ্য / প্রস্থ'], 'দৈর্ঘ্য × প্রস্থ'),
      _q('১ থেকে ২০ এর মধ্যে মৌলিক সংখ্যা কয়টি?', ['৭টি', '৮টি', '৯টি', '১০টি'], '৮টি'),
      _q('ঘনকের তলের সংখ্যা কয়টি?', ['৪টি', '৫টি', '৬টি', '৮টি'], '৬টি'),
      _q('সমান্তর ধারার n-তম পদের সূত্র কি?', ['a+(n-1)d', 'a+nd', 'a-(n-1)d', 'None'], 'a+(n-1)d'),
      _q('বৃত্তের পরিধির সূত্র কি?', ['πr²', '2πr', 'πd²', 'None'], '2πr'),
      _q('যদি x+y=5 এবং x-y=1 হয়, তবে x এর মান কত?', ['২', '৩', '৪', '৫'], '৩'),
    ],
    [
      _q('sin 30° এর মান কত?', ['0', '1/2', '√3/2', '1'], '1/2'),
      _q('cos 0° এর মান কত?', ['0', '1/2', '1', 'অসংজ্ঞায়িত'], '1'),
      _q('tan 45° এর মান কত?', ['0', '1', '√3', '1/√3'], '1'),
      _q('sin²θ + cos²θ = ?', ['0', '1', '2', 'sin 2θ'], '1'),
      _q('বৃত্তের কেন্দ্রে উৎপন্ন কোণ কত?', ['৯০°', '১৮০°', '২৭০°', '৩৬০°'], '৩৬০°'),
      _q('অর্ধবৃত্তস্থ কোণ কত?', ['৩০°', '৪৫°', '৬০°', '৯০°'], '৯০°'),
      _q('সেকেন্ডের কাটার কম্পাঙ্ক কত?', ['১ Hz', '১/৬০ Hz', '৬০ Hz', 'None'], '১/৬০ Hz'),
      _q('পরিসংখ্যানের উপাত্তের প্রকারভেদ কয়টি?', ['১টি', '২টি', '৩টি', '৪টি'], '২টি'),
      _q('মধ্যক নির্ণয়ের সূত্র কোনটি দিয়ে শুরু হয়?', ['L+', 'A+', '∑', 'None'], 'L+'),
      _q('প্রচুরক বলতে কি বুঝায়?', ['সবচেয়ে বড়', 'সবচেয়ে ছোট', 'সর্বাধিক বার আসা', 'গড়'], 'সর্বাধিক বার আসা'),
    ],
    [
      _q('২, ৪, ৬, ৮ এর গড় কত?', ['৪', '৫', '৬', '৮'], '৫'),
      _q('নিচের কোনটি মূলদ সংখ্যা?', ['√২', '√৩', '√৪', '√৫'], '√৪'),
      _q('সেট প্রকাশের পদ্ধতি কয়টি?', ['১টি', '২টি', '৩টি', '৪টি'], '২টি'),
      _q('ফাঁকা সেটের চিহ্ন কোনটি?', ['{0}', '∅', '{ }', '∅ এবং { } উভয়ই'], '∅ এবং { } উভয়ই'),
      _q('A={1,2}, B={2,3} হলে A∪B = ?', ['{2}', '{1,2,3}', '{1,3}', '∅'], '{1,2,3}'),
      _q('A∩B বলতে কি বুঝায়?', ['সংযোগ', 'ছেদ', 'বিয়োগ', 'গুণ'], 'ছেদ'),
      _q('বর্গের প্রতিটি কোণ কত?', ['৪৫°', '৬০°', '৯০°', '১৮০°'], '৯০°'),
      _q('একটি সুষম পঞ্চভুজের অভ্যন্তরীণ কোণগুলির সমষ্টি কত?', ['৩৬০°', '৫৪০°', '৭২০°', '৯০০°'], '৫৪০°'),
      _q('গাণিতিক গড় বের করার মূল সূত্র কোনটি?', ['Σx/n', 'Σf/n', 'Σfx/n', 'None'], 'Σx/n'),
      _q('আয়তলেখ আঁকার জন্য শ্রেণিসীমা কেমন হওয়া প্রয়োজন?', ['বিচ্ছিন্ন', 'অবিচ্ছিন্ন', 'বড়', 'ছোট'], 'অবিচ্ছিন্ন'),
    ],
  ];

  static final List<List<QuizQuestionModel>> _higherMath = [
    [
      _q('যদি f(x) = x²+1 হয়, তবে f(2) = ?', ['3', '4', '5', '6'], '5'),
      _q('অভেদ কোনটি?', ['(a+b)²=a²+2ab+b²', 'x+1=2', 'sin=1', 'None'], '(a+b)²=a²+2ab+b²'),
      _q('n(A)=3 হলে P(A) এর উপাদান সংখ্যা কত?', ['3', '6', '8', '9'], '8'),
      _q('দ্বিতীয় মাত্রার বহুপদী কোনটি?', ['x+1', 'x²+x+1', 'x³+1', '5'], 'x²+x+1'),
      _q('আংশিক ভগ্নাংশ প্রকাশের জন্য হরকে কি করতে হয়?', ['যোগ', 'উৎপাদকে বিশ্লেষণ', 'বিয়োগ', 'বর্গ'], 'উৎপাদকে বিশ্লেষণ'),
      _q('(1+x)^n এর বিস্তৃতিতে পদের সংখ্যা কত?', ['n', 'n-1', 'n+1', '2n'], 'n+1'),
      _q('5! এর মান কত?', ['10', '25', '120', '240'], '120'),
      _q("একটি ছক্কা নিক্ষেপ করলে '৩' পাওয়ার সম্ভাবনা কত?", ['১/২', '১/৩', '১/৬', '১'], '১/৬'),
      _q('অসীম ধারার সমষ্টি থাকার শর্ত কোনটি?', ['|r|<1', '|r|>1', 'r=1', 'r=0'], '|r|<1'),
      _q('সূচকীয় ফাংশন কোনটি?', ['x²', '2^x', 'log x', 'sin x'], '2^x'),
    ],
    [
      _q('বিন্দু (3,4) থেকে মূল বিন্দুর দূরত্ব কত?', ['3', '4', '5', '7'], '5'),
      _q('সরলরেখার ঢাল m এর সূত্র কোনটি?', ['(y2-y1)/(x2-x1)', 'dx/dy', 'y1/x1', 'None'], '(y2-y1)/(x2-x1)'),
      _q('A = 3i+4j হলে ভেক্টরটির মান কত?', ['3', '4', '5', '25'], '5'),
      _q('দুইটি ভেক্টর লম্ব হওয়ার শর্ত তাদের ডট গুণফল কত?', ['0', '1', '-1', 'অসংজ্ঞায়িত'], '0'),
      _q('ভেক্টর যোগের ত্রিভুজ বিধি কোনটি?', ['AB+BC=AC', 'AB+AC=BC', 'AC+BC=AB', 'None'], 'AB+BC=AC'),
      _q('গোলকের আয়তনের সূত্র কোনটি?', ['πr²', '2πr', '4/3 πr³', '4πr²'], '4/3 πr³'),
      _q('কোণকের আয়তন সিলিন্ডারের কত অংশ?', ['অর্ধেক', 'এক-তৃতীয়াংশ', 'সমান', 'দ্বিগুণ'], 'এক-তৃতীয়াংশ'),
      _q('সিলিন্ডারের বক্রতলের ক্ষেত্রফল কি?', ['2πrh', 'πr²h', '2πr(r+h)', 'None'], '2πrh'),
      _q('মূলবিন্দুগামী সরলরেখার সমীকরণ কি?', ['y=mx+c', 'y=mx', 'x=a', 'y=b'], 'y=mx'),
      _q('মধ্যবিন্দু নির্ণয়ের সূত্র কোনটি?', ['যোগ', 'যোগ/২', 'বিয়োগ', 'None'], '((x1+x2)/2, (y1+y2)/2)'),
    ],
    [
      _q('১ রেডিয়ান সমান কত ডিগ্রি (প্রায়)?', ['৪৫', '৫৭.৩', '৬০', '৯০'], '৫৭.৩'),
      _q('s=rθ সূত্রে θ এর একক কি?', ['ডিগ্রি', 'রেডিয়ান', 'মিনিট', 'সেকেন্ড'], 'রেডিয়ান'),
      _q('cos(-θ) সমান কত?', ['sin', '-cos', 'cos', '-sin'], 'cos'),
      _q('tan(90-θ) সমান কত?', ['tan', 'cot', '-tan', 'sin'], 'cot'),
      _q('sin 3θ এর সূত্র কোনটি?', ['3sin θ - 4sin³θ', '4sin³θ - 3sin θ', 'sin', 'None'], '3sin θ - 4sin³θ'),
      _q('নিশ্চায়ক D এর মান কোনটি?', ['b²-4ac', 'b²-ac', '4ac-b²', 'sqrt'], 'b²-4ac'),
      _q('D > 0 হলে মূলগুলো কেমন হবে?', ['সমান', 'জটিল', 'বাস্তব ও অসমান', 'শূন্য'], 'বাস্তব ও অসমান'),
      _q('একটি মুদ্রাকে দুইবার নিক্ষেপ করলে নমুনা বিন্দু কয়টি?', ['২', '৪', '৬', '৮'], '৪'),
      _q('সম্ভাবনার সর্বোচ্চ মান কত?', ['0', '0.5', '1', '100'], '1'),
      _q('বর্জনশীল ঘটনার ক্ষেত্রে P(A∪B) = ?', ['P(A)+P(B)', 'P(A)*P(B)', 'P(A)-P(B)', 'P(A∩B)'], 'P(A)+P(B)'),
    ],
    [
      _q('log e এর মান কত?', ['0', '1', '10', 'e'], '1'),
      _q('ln এর ভিত্তি কোনটি?', ['10', '2', 'e', '1'], 'e'),
      _q('log(mn) সমান কত?', ['যোগ', 'বিয়োগ', 'গুণ', 'None'], 'log m + log n'),
      _q('|x| < a বলতে কি বুঝায়?', ['x<a', '-a<x<a', 'x>-a', 'None'], '-a < x < a'),
      _q('স্থানাঙ্ক জ্যামিতিতে ত্রিভুজের ক্ষেত্রফল নির্ণয় পদ্ধতি কোনটি?', ['পিথাগোরাস', 'নির্ণায়ক', 'লগ', 'সম্ভাবনা'], 'নির্ণায়ক'),
      _q('i² এর মান কত?', ['1', '-1', '0', 'sqrt'], '-1'),
      _q('কোনটি ভেক্টর রাশি?', ['ভর', 'দ্রুতি', 'বেগ', 'সময়'], 'বেগ'),
      _q('একক ভেক্টরের মান কত?', ['0', '1', '-1', 'যেকোনো'], '1'),
      _q('নিচের কোনটি অমূলদ সংখ্যা?', ['0.5', '2/3', 'π', 'sqrt 9'], 'π'),
      _q('2^x = 8 হলে x কত?', ['2', '3', '4', '8'], '3'),
    ],
  ];

  static final List<List<QuizQuestionModel>> _physics = [
    [
      _q('বেগের পরিবর্তনের হারকে কি বলে?', ['দ্রুতি', 'সরণ', 'ত্বরণ', 'কাজ'], 'ত্বরণ'),
      _q('বলের একক কি?', ['ওয়াট', 'জুল', 'নিউটন', 'প্যাসকেল'], 'নিউটন'),
      _q('নিউটনের গতির ২য় সূত্র কোনটি?', ['F=ma', 'v=u+at', 'E=mc²', 'P=mv'], 'F=ma'),
      _q('ক্রিয়া ও প্রতিক্রিয়ার মধ্যবর্তী কোণ কত?', ['0', '90', '180', '360'], '180'),
      _q('পরন্ত বস্তুর সূত্র কে দিয়েছেন?', ['নিউটন', 'গ্যালিলিও', 'আইনস্টাইন', 'পাসকাল'], 'গ্যালিলিও'),
      _q('g এর মান কত?', ['8.9', '9.8', '10', '9.6'], '9.8'),
      _q('ভরবেগ কি ধরণের রাশি?', ['স্কেলার', 'ভেক্টর', 'মৌলিক', 'None'], 'ভেক্টর'),
      _q('ঘর্ষণ বল গতির কোন দিকে কাজ করে?', ['একই', 'বিপরীত', 'লম্ব', 'কোণাকুণি'], 'বিপরীত'),
      _q('অবস্থা বজায় রাখার ধর্মকে কি বলে?', ['ত্বরণ', 'জড়তা', 'বেগ', 'বল'], 'জড়তা'),
      _q('১ কেজি বস্তুতে ১ নিউটন বল দিলে ত্বরণ কত?', ['0', '1 m/s²', '9.8 m/s²', 'None'], '1 m/s²'),
    ],
    [
      _q('কাজের একক কি?', ['নিউটন', 'ওয়াট', 'জুল', 'প্যাসকেল'], 'জুল'),
      _q('ক্ষমতার একক কি?', ['জুল', 'নিউটন', 'ওয়াট', 'ভোল্ট'], 'ওয়াট'),
      _q('বিভব শক্তির সূত্র কোনটি?', ['1/2mv²', 'mgh', 'Fs', 'Pt'], 'mgh'),
      _q('গতিশক্তির সূত্র কোনটি?', ['mgh', '1/2mv²', 'mv', 'ma'], '1/2mv²'),
      _q('শক্তি কি হতে পারে?', ['তৈরি', 'ধ্বংস', 'রূপান্তর', 'None'], 'রূপান্তর'),
      _q('১ অশ্বক্ষমতা সমান কত ওয়াট?', ['500', '746', '1000', '60'], '746'),
      _q('চাপের একক কি?', ['জুল', 'নিউটন', 'প্যাসকেল', 'ওয়াট'], 'প্যাসকেল'),
      _q('গভীরতা বাড়লে চাপ কেমন হয়?', ['কমে', 'বাড়ে', 'একই', 'শূন্য'], 'বাড়ে'),
      _q('আর্কিমিডিসের সূত্র কিসের সাথে সম্পর্কিত?', ['আলো', 'শব্দ', 'প্লবতা', 'বিদ্যুৎ'], 'প্লবতা'),
      _q('পদার্থের ৪র্থ অবস্থার নাম কি?', ['কঠিন', 'তরল', 'বায়বীয়', 'প্লাজমা'], 'প্লাজমা'),
    ],
    [
      _q('শব্দ এক প্রকার কি?', ['বল', 'শক্তি', 'চাপ', 'None'], 'শক্তি'),
      _q('শব্দ চলাচলের জন্য কি প্রয়োজন?', ['মাধ্যম', 'আলো', 'বিদ্যুৎ', 'শূন্যস্থান'], 'মাধ্যম'),
      _q('বায়ুতে শব্দের বেগ কত (প্রায়)?', ['300', '330', '3*10^8', '1500'], '330'),
      _q('প্রতিধ্বনি শোনার ন্যূনতম দূরত্ব কত?', ['10.6', '16.6', '20', '100'], '16.6'),
      _q('তাপমাত্রা বাড়লে শব্দের বেগ কি হয়?', ['কমে', 'বাড়ে', 'একই', 'বন্ধ'], 'বাড়ে'),
      _q('পানির স্ফুটনাঙ্ক ফারেনহাইটে কত?', ['100', '180', '212', '312'], '212'),
      _q('সুপ্ততাপ বস্তুর কি পরিবর্তন করে?', ['তাপমাত্রা', 'অবস্থা', 'ভর', 'রঙ'], 'অবস্থা'),
      _q('তাপ সঞ্চালনের দ্রুততম পদ্ধতি কোনটি?', ['পরিবহন', 'পরিচলন', 'বিকিরণ', 'সব সমান'], 'বিকিরণ'),
      _q('গাড়ির লুকিং গ্লাস কোনটি?', ['সমতল', 'অবতল', 'উত্তল', 'None'], 'উত্তল'),
      _q('আলোর প্রতিসরণের সূত্র কয়টি?', ['1', '2', '3', '4'], '2'),
    ],
    [
      _q('বিদ্যুৎ প্রবাহের একক কি?', ['ভোল্ট', 'ওহম', 'অ্যাম্পিয়ার', 'ওয়াট'], 'অ্যাম্পিয়ার'),
      _q('রোধের একক কি?', ['অ্যাম্পিয়ার', 'ওহম', 'ভোল্ট', 'কুলম্ব'], 'ওহম'),
      _q('ওহমের সূত্র কোনটি?', ['V=IR', 'I=VR', 'R=VI', 'None'], 'V=IR'),
      _q('বিভব পার্থক্যের একক কি?', ['অ্যাম্পিয়ার', 'ওয়াট', 'ভোল্ট', 'জুল'], 'ভোল্ট'),
      _q('কোনটি পরিবাহী?', ['কাঁচ', 'প্লাস্টিক', 'তামা', 'কাঠ'], 'তামা'),
      _q('ফিউজ তার কেন ব্যবহার করা হয়?', ['আলোর জন্য', 'সাশ্রয়', 'নিরাপত্তা', 'ভোল্টেজ'], 'নিরাপত্তা'),
      _q('ট্রান্সফরমার কোন নীতিতে কাজ করে?', ['আবেশ', 'ঘর্ষণ', 'তাপ', 'আলো'], 'আবেশ'),
      _q('চার্জের একক কি?', ['অ্যাম্পিয়ার', 'কুলম্ব', 'ফ্যারাডে', 'ওহম'], 'কুলম্ব'),
      _q('ইলেকট্রনের চার্জ কেমন?', ['ধনাত্মক', 'ঋণাত্মক', 'নিরপেক্ষ', 'None'], 'ঋণাত্মক'),
      _q('সূর্য থেকে তাপ কোন পদ্ধতিতে আসে?', ['পরিবহন', 'পরিচলন', 'বিকিরণ', 'None'], 'বিকিরণ'),
    ],
  ];

  static final List<List<QuizQuestionModel>> _economics = [
    [
      _q('অর্থনীতির জনক কে?', ['অ্যাডাম স্মিথ', 'মার্শাল', 'কেইনস', 'স্যামুয়েলসন'], 'অ্যাডাম স্মিথ'),
      _q('মানুষের অভাব কেমন?', ['সীমিত', 'অসীম', 'শূন্য', 'None'], 'অসীম'),
      _q('দাম বাড়লে চাহিদা কি হয়?', ['বাড়ে', 'কমে', 'একই থাকে', 'দ্বিগুণ'], 'কমে'),
      _q('দাম বাড়লে যোগান কি হয়?', ['বাড়ে', 'কমে', 'একই থাকে', 'অর্ধেক'], 'বাড়ে'),
      _q('উৎপাদনের উপকরণ কয়টি?', ['২', '৩', '৪', '৫'], '৪'),
      _q('কোনটি মৌলিক উপকরণ নয়?', ['ভূমি', 'শ্রম', 'মূলধন', 'টাকা'], 'টাকা'),
      _q('ভূমি বলতে কি বুঝায়?', ['মাটি', 'প্রাকৃতিক সম্পদ', 'বাড়ি', 'রাস্তা'], 'প্রাকৃতিক সম্পদ'),
      _q('শ্রমের বিনিময়ে কি পাওয়া যায়?', ['মুনাফা', 'মজুরি', 'খাজনা', 'সুদ'], 'মজুরি'),
      _q('উদ্যোক্তার পুরস্কার কি?', ['মজুরি', 'সুদ', 'মুনাফা', 'খাজনা'], 'মুনাফা'),
      _q('সম্পদের দুষ্প্রাপ্যতা কি?', ['মৌলিক সমস্যা', 'কোনো সমস্যা না', 'ছোট বিষয়', 'বড় বিষয়'], 'মৌলিক সমস্যা'),
    ],
    [
      _q('বাজারের ভারসাম্য কোথায় হয়?', ['চাহিদা>যোগান', 'যোগান>চাহিদা', 'চাহিদা=যোগান', 'None'], 'চাহিদা=যোগান'),
      _q('একচেটিয়া বাজারে বিক্রেতা কয়জন?', ['১', '২', 'অনেক', 'কেউ না'], '১'),
      _q('পূর্ণ প্রতিযোগিতায় দাম কেমন থাকে?', ['পরিবর্তনশীল', 'ইচ্ছাধীন', 'একই', 'খুব বেশি'], 'একই'),
      _q('মুদ্রাস্ফীতি কি?', ['দাম বৃদ্ধি', 'টাকার মান বৃদ্ধি', 'বেকারত্ব কমা', 'উৎপাদন'], 'দাম বৃদ্ধি'),
      _q('GDP এর পূর্ণরূপ কি?', ['Gross Domestic Product', 'General Data', 'Grand', 'None'], 'Gross Domestic Product'),
      _q('মাথাপিছু আয় সূত্র কোনটি?', ['আয়/জনসংখ্যা', 'আয়*জনসংখ্যা', 'জনসংখ্যা/আয়', 'None'], 'আয়/জনসংখ্যা'),
      _q('বাংলাদেশের অর্থনীতি কিসের ওপর নির্ভরশীল?', ['শিল্প', 'কৃষি', 'সেবা', 'খনিজ'], 'কৃষি'),
      _q('জাতীয় আয় গণনার পদ্ধতি কয়টি?', ['১', '২', '৩', '৪'], '৩'),
      _q('সরকারের আয়ের প্রধান উৎস কি?', ['ঋণ', 'কর (Tax)', 'অনুদান', 'জরিমানা'], 'কর (Tax)'),
      _q('ভ্যাট (VAT) কি ধরণের কর?', ['প্রত্যক্ষ', 'পরোক্ষ', 'সম্পদ', 'None'], 'পরোক্ষ'),
    ],
    [
      _q('উপযোগ বলতে কি বুঝায়?', ['কেনা', 'অভাব পূরণের ক্ষমতা', 'বিক্রি', 'সঞ্চয়'], 'অভাব পূরণের ক্ষমতা'),
      _q('প্রান্তিক উপযোগ শূন্য হলে মোট উপযোগ কি হয়?', ['শূন্য', 'সর্বনিম্ন', 'সর্বোচ্চ', 'অসীম'], 'সর্বোচ্চ'),
      _q('মৌলিক অর্থনৈতিক সমস্যা কয়টি?', ['১', '২', '৩', '৪'], '৩'),
      _q('সুযোগ ব্যয় কি?', ['অতিরিক্ত', 'ত্যাগ বা বিসর্জন', 'বাজার দর', 'সঞ্চয়'], 'ত্যাগ বা বিসর্জন'),
      _q('ব্যষ্টিক অর্থনীতি আলোচনা করে কাকে নিয়ে?', ['দেশ', 'ব্যক্তি/একক প্রতিষ্ঠান', 'বিশ্ব', 'None'], 'ব্যক্তি/একক প্রতিষ্ঠান'),
      _q('সমষ্টি অর্থনীতি আলোচনা করে কি নিয়ে?', ['ব্যক্তি', 'সামগ্রিক অবস্থা', 'ছোট দোকান', 'None'], 'সামগ্রিক অবস্থা'),
      _q('পণ্য বিনিময়কে কি বলে?', ['টাকা', 'চেক', 'বার্টার', 'None'], 'বার্টার'),
      _q('মুদ্রার প্রধান কাজ কি?', ['সঞ্চয়', 'বিনিময়ের মাধ্যম', 'অপচয়', 'None'], 'বিনিময়ের মাধ্যম'),
      _q('কেন্দ্রীয় ব্যাংকের কাজ কি?', ['ঋণ', 'মুদ্রা প্রচলন', 'ব্যবসা', 'None'], 'মুদ্রা প্রচলন'),
      _q('বাণিজ্যিক ব্যাংকের লক্ষ্য কি?', ['সেবা', 'মুনাফা', 'টাকা ছাপানো', 'None'], 'মুনাফা'),
    ],
    [
      _q('বাংলাদেশের কেন্দ্রীয় ব্যাংক কোনটি?', ['সোনালী', 'বাংলাদেশ ব্যাংক', 'রূপালী', 'পুবালী'], 'বাংলাদেশ ব্যাংক'),
      _q('উন্নয়নশীল দেশের বৈশিষ্ট্য কোনটি?', ['উচ্চ আয়', 'নিম্ন মাথাপিছু আয়', 'উচ্চ প্রযুক্তি', 'None'], 'নিম্ন মাথাপিছু আয়'),
      _q('রপ্তানি আয় কি?', ['বিদেশ থেকে কেনা', 'বিদেশে বিক্রি', 'ভেতরে বিক্রি', 'None'], 'বিদেশে বিক্রি'),
      _q('আমদানি বলতে কি বুঝায়?', ['পাঠানো', 'বিদেশ থেকে কেনা', 'জমানো', 'None'], 'বিদেশ থেকে কেনা'),
      _q('বাজেট কি?', ['আয়-ব্যয়ের হিসাব', 'খরচ', 'আয়', 'None'], 'আয়-ব্যয়ের হিসাব'),
      _q('ঘাটতি বাজেট কখন হয়?', ['আয়>ব্যয়', 'আয়=ব্যয়', 'আয়<ব্যয়', 'None'], 'আয়<ব্যয়'),
      _q('অপরিহার্য অভাব কোনটি?', ['গাড়ি', 'খাদ্য', 'গয়না', 'সিনেমা'], 'খাদ্য'),
      _q('সঞ্চয় = কি?', ['আয়+ভোগ', 'আয়-ভোগ', 'আয়*ভোগ', 'None'], 'আয়-ভোগ'),
      _q('মূলধন কি?', ['মানুষের তৈরি উপকরণ', 'প্রাকৃতিক', 'শুধু টাকা', 'None'], 'মানুষের তৈরি উপকরণ'),
      _q('আয়কর কি ধরণের কর?', ['পরোক্ষ', 'প্রত্যক্ষ', 'ভ্যাট', 'None'], 'প্রত্যক্ষ'),
    ],
  ];
}
