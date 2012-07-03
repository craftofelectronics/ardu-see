
/**
 * Module dependencies.
 */

var express = require('express');
var routes = require('./routes');
var fs = require('fs');

var sys   = require('util'),
    exec  = require('child_process').exec,
    child;

var app = module.exports = express.createServer();

// For arduino programming
var FILENAME = "json.js";
var OCCFILE = "ardusee";
var ARDUINO_PORT = '/dev/ttyUSB0';
var BAUD = '57600';


// Configuration

app.configure(function(){
  app.set('views', __dirname + '/views');
  app.set('view engine', 'jade');
  app.use(express.bodyParser());
  app.use(express.methodOverride());
  app.use(express.errorHandler({ showStack: true, dumpExceptions: true }));
  app.use(app.router);
  app.use(express.static(__dirname + '/public'));
});

app.configure('development', function(){
  app.use(express.errorHandler({ dumpExceptions: true, showStack: true }));
});

app.configure('production', function(){
  app.use(express.errorHandler());
});

// Routes
app.get('/', routes.index);

app.get('/new'
  , function (req, rsp) {
    rsp.send("New");
  });

/*
 /Users/jadudm/Dropbox/IFTTT/ardu-see.occ
*/



/*
occbuild: Running command: /Users/jadudm/Downloads/Transterpreter/Transterpreter.app/Contents/Resources/bin/tce-dump.pl -C ardu-see.tce
occbuild: Running command: /Users/jadudm/Downloads/Transterpreter/Transterpreter.app/Contents/Resources/bin/plinker.pl -s -o ardu-see.tbc /Users/jadudm/Downloads/Transterpreter/Transterpreter.app/Contents/Resources/arduino/tvm/lib/forall.lib ardu-see.tce
*/
/*
AVRDUDE_FLAGS="$TVM_AVRDUDE_CODE_FLAGS -P $UPLOAD_PORT"
AVRDUDE_WRITE_OCCAM="-D -U flash:w:$HEX"
*/
/*
TVM_MCU=m328p
TVM_GCC_MCU=atmega328p
TVM_BYTECODE_ADDR=0x4F00
TVM_F_CPU=16000000
TVM_UPLOAD_RATE=57600
PLATFORM=arduino
     
# avrdude
TVM_AVRDUDE_FIRMWARE_FLAGS="-V -F -p $TVM_MCU"
TVM_AVRDUDE_CODE_FLAGS="-V -F -p $TVM_MCU -b $TVM_UPLOAD_RATE -c arduino"
TVM_ARDUINO_FIRMWARE=tvm-avr-atmega328p-16000000-arduino.hex

*/



var isearch = "";
function add_isearch (s) {
  isearch += ":" + s;
}

add_isearch("tvm/common/lib");
add_isearch("tvm/common/include");
add_isearch("tvm/common/include/arch/m328p");
add_isearch("tvm/common/include/arch/common");
add_isearch("tvm/common/include/platforms/arduino");
 
var compile = "occ21";
var compile_options = "-t2 -V -etc -w -y -znd -znec -udo -zncc -init -xin -mobiles -zrpe -zcxdiv -zcxrem";
compile_options += " -zep -b -tle -DEF F.CPU=16000000 -DEF OCCBUILD.TVM";

function extend_env (env, k, v) {
  env.k = v;
}

detect = function (callback) {
  console.log('attempting to find Arduino board');
  child = exec('ls /dev | grep usb', 
      function(err, stdout, stderr){
        var usb = stdout.slice(0, -1).split('\n'),
          found = false,
          err = null,
          possible, temp;

          while ( usb.length ) {
            possible = usb.pop();

            if (possible.slice(0, 2) !== 'cu') {
              console.log (possible);
            }
          }
          console.log ('PRESS RESET ON THE ARDUINO NOW');
          callback('/dev/tty.usbserial-A9007KRZ');
          //callback('/dev/tty.usbmodem1a21');
        });
}

function readarduino (port) {
  var E = process.env;
  E.PATH += ":tvm/osx/bin";
  
      child = exec(
              'read_arduino ' + '-b ' + BAUD + ' ' + port, 
              E,
              function (error, stdout, stderr) {
                if (error == null) {
                  console.log('avrduding success!');
                } else {
                  console.log('avrdude exec error: ' + error);
                }
              });
}

function avrdude (fname, PORT) {
  var E = process.env;
  var avrdude = 'avrdude'
              + ' '
              + '-C'
              + ' '
              + 'tvm/common/conf/avrdude.conf'
              + ' '
              + '-V -F -p ' + 'm328p' + ' -b ' + BAUD + ' -c arduino'
              + ' '
              + '-P ' + PORT
              + ' '
              + '-D -U flash:w:' + fname + '.hex';
              
      child = exec(
              avrdude, 
              E,
              function (error, stdout, stderr) {
                if (error == null) {
                  console.log('avrduding success!');
                } else {
                  console.log('avrdude exec error: ' + error);
                }
              });
}


function reset_arduino (fname, port) {
  var E = process.env;

  var reset = 'reset-arduino'
              + ' '
              + port;
  
  
      child = exec(
              reset, 
              E,
              function (error, stdout, stderr) {
                if (error == null) {
                  console.log('reset success!');
                  avrdude(fname, port);
                } else {
                  console.log('reset exec error: ' + error);
                }
              });
}

function binhex (fname) {
  var E = process.env;
  var bin2hex = 'binary-to-ihex'
              + ' '
              + '0x4F00'
              + ' '
              + fname + '.tbc' 
              + ' '
              + fname + '.hex';
  
  
      child = exec(
              bin2hex, 
              E,
              function (error, stdout, stderr) {
                if (error == null) {
                  console.log('binhex success!');
                  
                  detect(function (port) { reset_arduino(fname, port); });
                } else {
                  console.log('binhex exec error: ' + error);
                }
              });
}

function plink (fname) {
  var E = process.env;
  var plinker = 'plinker.pl'
              + ' '
              + '-s -o'
              + ' '
              + fname + '.tbc' 
              + ' '
              + 'tvm/common/lib/forall.lib'
              + ' '
              + fname + '.tce';
              
      child = exec(
              plinker, 
              E,
              function (error, stdout, stderr) {
                if (error == null) {
                  console.log('plinker success!');
                  binhex (fname);
                } else {
                  console.log('plinker exec error: ' + error);
                }
              });
}


function compile_occam (fname) {
  var E = process.env;
  E.ISEARCH = isearch;
  var compile_cmd = compile 
                  + " " 
                  + compile_options
                  + " "
                  
  compile_cmd += fname + ".occ";

    child = exec(
              compile_cmd, 
              E,
              function (error, stdout, stderr) {
                if (error == null) {
                  console.log('compilation success!');
                  plink (fname);
                } else {
                  console.log('compile exec error: ' + error);
                }
              });
}




function write_temp_scheme (fname, def) {
  var stream = fs.createWriteStream(fname);
  stream.once('open', function(fd) 
  {
    stream.write(def);
  });
}

function do_conversion (fname) {
  var cmd = './jsonconv ' + fname;
  child = exec(cmd, 
    function (error, stdout, stderr) {
      if (error == null) {
        console.log('JSON converted!');
        compile_occam(OCCFILE);
      } else {
        console.log('exec error: ' + error);
      }
    });
}
  
app.post('/run'
  , function(req, res) {
    
    var the = req.body;
    var seconds = new Date().getTime();
    var json = JSON.stringify(the.diagram);
    
    //json = json.replace(/"/g, "\\\"");
    //var definition = "(define p" + seconds + " \"" + json + "\")\n";
    var definition = json + "\n";
    //var convert_call = "(convert p" + seconds + ")\n";
    write_temp_scheme(FILENAME, definition);
    
    do_conversion(FILENAME)

    
    //console.log(definition);
    //console.log(req.body);
    
    res.contentType('json');
    res.send({ response : 42});
    
    });

app.listen(3000, function(){
  console.log("Express server listening on port %d in %s mode", app.address().port, app.settings.env);
});
