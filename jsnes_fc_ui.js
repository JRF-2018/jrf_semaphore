//
// jsnes_fc_ui.js
//
// JSNES UI in an hommage of FamiCon. JSNES is copyright-ed by Ben
// Firshman 2010 under GPLv3, which is based on Jamie Sanders' vNES.
//
var VERSION_jsnes_fc_ui = "0.07"; // Time-stamp: <2014-06-05T22:57:47Z>

//
// License:
//
//   I in a provincial state made this program intended to be public-domain. 
//   But it might be better for you like me to treat this program as such 
//   under the (new) BSD-License or under the Artistic License.
//
//   Within three months after the release of this program, I
//   especially admit responsibility of effort for rational request of
//   correction to this program.
//
//   ...But, Ben ...umm... Mr. Firshman was subject to GPLv3, and I am
//   not.  I must present an excuse about it.  I hesitate to inherit
//   functions (methods) of the UI-object or its prototype before new,
//   because they are capsulated by Functor-like technique with
//   'jQuery' and my base Dom design much differs from Mr. Firshman's.
//   I thought difficulty to apply a casual way of JavaScript to its
//   reuse.  And its temporal instantiation is also restricted by its
//   listening of key events globally over 'document'.  So, it may be
//   inadequate, but I made some efforts to implement codes based on
//   the original ones more functionally or neatly, in order to regist
//   such 'Technological Burden' under GPLv3.
//
//
// Author's Link:
//
//   http://jrf.cocolog-nifty.com/software/
//   (The page is written in Japanese.)
//

//'use utf8'; // Japanese


if (! window["bind"]) {
  window["bind"] = function (f, o) {
    return function() {return f.apply(o, arguments);};
  };
}

if (! JSNES.Mappers[3]) {
  JSNES.Mappers[3] = function(nes) {
    this.nes = nes;
    this.PAGE_MASK = 0xF;
  };
  JSNES.Mappers[3].prototype = new JSNES.Mappers[0]();
  JSNES.Mappers[3].prototype.write = function (address, value) {
    if (address < 0x8000) {
      JSNES.Mappers[0].prototype.write.apply(this, arguments);
      return;
    }
    var mask = this.PAGE_MASK;
    while (mask > 0) {
      value = value & mask;
      if (value * 2 < this.nes.rom.vromCount) {
	break;
      }
      mask = mask >> 1;
    }
    if (mask == 0) {
      return;
    }
    this.load8kVromBank(value * 2, 0x0000);
  };
}

var JSNES_FC_UI_TEMPLATE_COUNT = 0;
var JSNES_FC_UI_CSS = '\
#jsnes-table {\
  margin-top: 30px;\
  margin-bottom: 30px;\
/*\
  margin-left: auto;\
  margin-right: auto;\
*/\
  box-shadow: 0px -10px 10px 10px Firebrick;\
  padding: 30px;\
  border: 0px solid white;\
  border-radius: 20px;\
}\
#jsnes-place {\
  width: 100%;\
  text-align: center;\
}\
#jsnes-place-holder {\
  display: inline-block;\
  line-height: 0;\
  background: transparent;\
  border: 8px solid transparent;\
}\
#jsnes-place-holder:hover {\
  border-color: Firebrick;\
}\
#absolute-top-left {\
  position: absolute;\
  top: 0px;\
  left: 0px;\
  width: 0;\
  height: 0;\
}\
#jsnes-nes-controller-name td {\
  text-align: center;\
}\
#jsnes-nes-controller-name .number-holder {\
  font-family: serif;\
  font-weight: bold;\
  border: 1px solid black;\
  color: white;\
  background: black;\
  padding-left: 0.5em;\
  padding-right: 0.5em;\
}\
td.rom-select {\
  text-align: center;\
}\
td.emu-control {\
  text-align: center;\
  line-height: 2em;\
}\
span.status-holder {\
  width: 100%;\
}\
#status-text {\
  width: 80%;\
  height: 2em;\
  overflow-y: scroll;\
}\
td.buttons {\
  margin-left: 0;\
  padding-left: 0;\
  margin-right: 0;\
  padding-right: 0;\
}\
table.controller {\
  margin-right: auto;\
  margin-left: auto;\
  border: 8px solid Firebrick;\
  border-radius: 10px;\
  background: Firebrick;\
  border-spacing: 0;\
}\
table.controller td {\
  vertical-align: bottom;\
}\
.command-buttons {\
  background: Khaki;\
  padding-bottom: 3px; \
  padding-top: 3px; \
}\
.command-buttons tr {\
  background: Khaki;\
  padding-bottom: 10px; \
  padding-top: 10px; \
}\
.direction-buttons {\
  background: Khaki;\
}\
.direction-n, .direction-e, .direction-c, .direction-w, .direction-s  {\
  background: DarkSlateGray;\
}\
\
.a-button .checkbox-holder, .b-button .checkbox-holder {\
  padding: 3px;\
  margin-right: 5px;\
  border: 1px solid DarkSlateGray;\
  border-radius: 10px;\
  background: DarkSlateGray;\
}\
.select-button .checkbox-holder, .start-button .checkbox-holder {\
  vertical-align: top;\
  padding: 1px;\
  margin-right: 2px;\
  border: 2px solid DarkSlateGray;\
  border-radius: 5px;\
  background: Firebrick;\
}\
#jsnes-1p-table td.start-button {\
  padding-bottom: 5px;\
}\
/*\
.command-button {\
  text-align: right;\
}\
*/\
\
.select-button .text-holder, .start-button .text-holder{\
  vertical-align: top;\
  font-size: x-small;\
}\
\
.a-button .text-holder, .b-button .text-holder{\
  padding: 1px;\
  border: 1px solid black;\
  border-radius: 8px;\
  background: black;\
  color: Khaki;\
}\
td.nes-semaphore {\
  text-align: center;\
  line-height: 2em;\
}\
td.save-control, td.flag-button-control {\
  line-height: 2em;\
}\
td.save-area, td.flag-text-control {\
  padding: 1em;\
}\
.save-address-note {\
  text-align: right;\
}\
\
input#flag-text {\
  width: 100%;\
}\
textarea#save-text {\
  width: 100%;\
  overflow-y: scroll;\
}\
#download-save-button {\
  display: none;\
}\
#whole-button {\
  display: none;\
}\
#hook {\
  display: none;\
}\
#jsnes-ad-area {\
  width: 100%;\
  text-align: center;\
}\
#jsnes-ad-area .ad-holder {\
  display: inline-block;\
  width: 120px;\
  height: 120px;\
/*  border: thin dashed gray;\
*/\
}';

var JSNES_FC_UI_TEMPLATE = '\
<div id="jsnes-fc-ui" class="jsnes-fc-ui">\
<table id="jsnes-table" class="jsnes-table" cols="3">\
<tr id="jsnes-rom-control">\
<td id="jsnes-place-td" colspan="2">\
<div id="jsnes-place">\
<span id="jsnes-place-holder"><canvas id="jsnes-console" width="256" height="240"></canvas></span>\
</div>\
</td>\
<td>\
<div  id="jsnes-ad-area" class="ad-area">\
<span id="jsnes-ad-holder" class="ad-holder">\
<input type="hidden" id="use-rom-dnd" value="false" />\
</span>\
</div>\
</td>\
</tr>\
\
<tr id="jsnes-rom-select">\
<td class="rom-select" colspan="2">\
<select id="rom-select" class="emu-control rom-select"></select>\
</td>\
</tr>\
<tr id="jsnes-emu-control">\
<td class="emu-control" colspan="2">\
<input type="button" id="pause-button"\
       class="emu-control pause-button"  value="Pause" disabled="disabled"/>\
<input type="button" id="restart-button"\
       class="emu-control restart-button"  value="Restart" disabled="disabled" />\
<input type="checkbox" id="sound-button"\
       class="emu-control sound-button" /><label for="sound-button">Enable Sound\
</label>\
<input type="checkbox" id="zoom-button"\
       class="emu-control zoom-button" /><label for="zoom-button">Zoom in</label>. \
<label for="x-glasses-text">X Glasses:</label><input type="text" id="x-glasses-text"\
       class="emu-control x-glasses-text" size="6" />\
<br/>\
<textarea rows="1" readonly="readonly" class="emu-control status-text" id="status-text">\
JSNES: Booting...\
</textarea>\
</td>\
<td>\
</td>\
</tr>\
\
<tr id="jsnes-nes-controllers">\
<td>\
<table id="jsnes-1p-table" class="1p controller" cols="2">\
<tr>\
<td class="1p buttons">\
<table class="1p direction-buttons" cols="3" rows="3">\
<tr>\
<td class="1p direction direction-nw"><input type="radio" name="1p-direction"\
	   class="1p direction direction-nw" value="nw" /></td>\
<td class="1p direction direction-n"><input type="radio" name="1p-direction"\
	   class="1p direction direction-n" value="n" /></td>\
<td class="1p direction direction-ne"><input type="radio" name="1p-direction"\
	   class="1p direction direction-nw" value="ne" /></td>\
</tr>\
<tr>\
<td class="1p direction direction-w"><input type="radio" name="1p-direction"\
	   class="1p direction direction-w" value="w" /></td>\
<td class="1p direction direction-c"><input type="radio" name="1p-direction"\
	   class="1p direction direction-c" value="c" checked="checked" /></td>\
<td class="1p direction direction-e"><input type="radio" name="1p-direction"\
	   class="1p direction direction-e" value="e" /></td>\
</tr>\
<tr>\
<td class="1p direction direction-sw"><input type="radio" name="1p-direction"\
	   class="1p direction direction-sw" value="sw" /></td>\
<td class="1p direction direction-s"><input type="radio" name="1p-direction"\
	   class="1p direction direction-s" value="s" /></td>\
<td class="1p direction direction-se"><input type="radio" name="1p-direction"\
	   class="1p direction direction-se" value="se" /></td>\
</tr>\
</table>\
</td>\
<td class="1p buttons">\
<table class="1p command-buttons" cols="1" rows="2">\
<tr>\
<td class="1p command-button select-button start-button">\
  <label for="1p-select"><span class="text-holder">SELECT</span></label>\
  <span class="checkbox-holder"><input type="checkbox" id="1p-select"\
     class="1p command-button select-button" value="SELECT" /></span>\
  <label for="1p-start"><span class="text-holder">START</span></label>\
  <span class="space-holder"> </span>\
  <span class="checkbox-holder"><input type="checkbox" id="1p-start"\
     class="1p command-button start-button" value="START" /></span>\
</td>\
</tr>\
<tr>\
<td class="1p command-button a-button b-button">\
  <label for"1p-b"><span class="text-holder">B</span>\
  <span class="checkbox-holder"><input type="checkbox" id="1p-b"\
	class="1p command-button b-button" value="B" /></span></label>\
  <span class="space-holder"> </span>\
  <label for="1p-a"><span class="text-holder">A</span>\
  <span class="checkbox-holder"><input type="checkbox" id="1p-a"\
	class="1p command-button a-button" value="A" /></span></label>\
</td>\
</tr>\
</table>\
</td>\
</tr>\
</table>\
</td>\
\
<td>\
<table class="2p controller" cols="2">\
<tr>\
<td class="2p buttons">\
<table class="2p direction-buttons" cols="3" rows="3">\
<tr>\
<td class="2p direction direction-nw"><input type="radio" name="2p-direction"\
	   class="2p direction direction-nw" value="nw" /></td>\
<td class="2p direction direction-n"><input type="radio" name="2p-direction"\
	   class="2p direction direction-n" value="n" /></td>\
<td class="2p direction direction-ne"><input type="radio" name="2p-direction"\
	   class="2p direction direction-ne" value="ne" /></td>\
</tr>\
<tr>\
<td class="2p direction direction-w"><input type="radio" name="2p-direction"\
	   class="2p direction direction-w" value="w" /></td>\
<td class="2p direction direction-c"><input type="radio" name="2p-direction"\
	   class="2p direction direction-c" value="c" checked="checked" /></td>\
<td class="2p direction direction-e"><input type="radio" name="2p-direction"\
	   class="2p direction direction-e" value="e" /></td>\
</tr>\
<tr>\
<td class="2p direction direction-sw"><input type="radio" name="2p-direction"\
	   class="2p direction direction-sw" value="sw" /></td>\
<td class="2p direction direction-s"><input type="radio" name="2p-direction"\
	   class="2p direction direction-s" value="s" /></td>\
<td class="2p direction direction-se"><input type="radio" name="2p-direction"\
	   class="2p direction direction-se" value="se" /></td>\
</tr>\
</table>\
</td>\
\
<td class="2p buttons">\
<table class="2p command-buttons" cols="1" rows="2">\
<tr>\
<td class="2p command-button select-button start-button"></td>\
</tr>\
<tr>\
<td class="2p command-button a-button b-button">\
  <label for="2p-b"><span class="text-holder">B</span>\
  <span class="checkbox-holder"><input type="checkbox" id="2p-b"\
	class="2p command-button b-button" value="B" /></span></label>\
  <span class="spce-holder"> </span>\
  <label for="2p-a"><span class="text-holder">A</span>\
  <span class="checkbox-holder"><input type="checkbox" id="2p-a"\
	class="2p command-button a-button" value="A" /></span></label>\
</td>\
</tr>\
</table>\
</td>\
</tr>\
</table>\
</td>\
<td>\
<table class="press-control">\
<tr>\
<td>\
<input type="checkbox" id="immediate-button"\
       class="press-control immediate" /><label for="immediate-button">Immediate</label>\
</td>\
</tr>\
<tr>\
<td>\
<input type="button" id="hold-them-button"\
       class="press-control hold-them-button"  value="Hold" />\
<input type="button" id="release-button"\
       class="press-control release-button"  value="Release" />\
</td>\
</tr>\
<tr>\
<td>\
<input type="button" id="push-them-button"\
       class="press-control push-them-button"  value="Push:" />\
<input type="text" id="push-length"\
       class="press-control push-length" size="2"value="60" />\
frames\
</td>\
</tr>\
</table>\
</td>\
</tr>\
\
<tr id="jsnes-nes-controller-name">\
<td><span class="number-holder">I</span> コントローラー</td>\
<td><span class="number-holder">II</span> コントローラー</td>\
<td></td>\
</tr>\
\
<tr id="jsnes-flag-control">\
<td class="flag-text-control" colspan="2">\
<input type="text" id="flag-text"\
       class="flag-text-control flag-text"  value="" /><br />\
<select id="flag-font" class="flag-text-control flag-font">\
<option value="current" selected="selected">(Current Font)</option>\
<option value="normal upright sans-serif">Normal</option>\
<option value="normal upright italic">Blur Italic</option>\
<option value="bold upright sans-serif">Bold</option>\
<option value="bold upright italic">Bold Blur Italic</option>\
<option value="normal slant sans-serif">Slant</option>\
<option value="normal slant italic">Italic</option>\
<option value="bold slant sans-serif">Bold Slant</option>\
<option value="bold slant italic">Italic Bold</option>\
</select>\
<select id="flag-color" class="flag-text-control flag-color">\
<option value="current" selected="selected">(Current Color)</option>\
<option value="grey">Grey</option>\
<option value="sky">Sky</option>\
<option value="khaki">Khaki</option>\
<option value="violet">Violet</option>\
<option value="sand">Sand</option>\
<option value="red">Red</option>\
<option value="forest">Forest</option>\
<option value="sakura">Sakura</option>\
</select>\
<input type="button" id="chr-dot-button"\
       class="flag-text-control chr-dot-button"\
       value="Dot" />\
<input type="button" id="chr-dash-button"\
       class="flag-text-control chr-dash-button"\
       value="Dash" />\
<input type="button" id="chr-null2-button"\
       class="flag-text-control chr-null2-button"\
       value="Delim" />\
<input type="button" id="chr-raw-button"\
       class="flag-text-control chr-raw-button"\
       value="Raw" />\
<br />\
</td>\
<td class="flag-button-control">\
<input type="button" id="flag-semaphore-button"\
       class="flag-button-control flag-semaphore-button"\
       value="Flag Semaphore" /><br/>\
<span class="text-holder">Wait:</span>\
<input type="text" id="flag-length"\
       class="flag-button-control flag-length" size="2" value="60" />\
<span class="text-holder">frames</span><br\
/><input type="button" id="whole-button"\
       class="flag-button-control whole-button"\
       value="Flag with Floats" /><br/>\
</td>\
</tr>\
\
<tr id="jsnes-nes-semaphore">\
<td class="nes-semaphore" colspan="2">\
<input type="checkbox" id="stop-load-count"\
       class="nes-semaphore stop-load" /><label for="stop-load-count">Stop when changing LoadCount</label>.  \
<input type="checkbox" id="stop-rand-seed"\
       class="nes-semaphore stop-rand-seed" /><label for="stop-rand-seed">Stop when storing RandSeed</label>.\
<br />\
<input type="checkbox" id="rand-magic"\
       class="nes-semaphore rand-magic" /><label for="rand-magic">Changel loading RandSeed by <a href="http://jrf.cocolog-nifty.com/archive/summoner.js">allot_magic</a>-ed value</label>.\
<br />\
<span class="address-note">(Memory address: LoadCount = $6011, RandSeed = $6012.)</span><br/>\
</td>\
<td>\
</td>\
</tr>\
\
<tr id="jsnes-save-control">\
<td class="save-area" colspan="2">\
<div>"Battery Backup" Save (Base64 or DataURI):</div>\
<textarea id="save-text" rows="4">\
</textarea>\
<div class="save-address-note">($6000-$7FFF: The last $00-s can be truncated.)</div>\
</td>\
<td class="save-control">\
<input type="button" id="inject-save-button"\
       class="emu-control save-control inject-save-button"  value="Inject" /><br/>\
<input type="button" id="capture-save-button"\
       class="emu-control save-control capture-save-button"  value="Capture" /><br/>\
<a id="download-save-button" target="_blank"\
       class="emu-control save-control download-save-button"\
       href="">Download</a>\
</td>\
</tr>\
\
</table>\
</div>';

if (typeof jQuery !== 'undefined') {
  (function ($) {
    $.fn.JSNES_FC_UI = function (opts) {
      var parent = this;
      var cvar = {
	DEFAULT_OPTS: {
	  defaultRom: null,
	  roms: null,
	  useJRFSemaphore: false,
	  useNESSemaphore: true,
	  useSaveDnD: true,
	  useRomDnD: false,
	  semaphoreAsm: "jrf_semaphore.asm",
	  errorBeep: "error_beep.wav"
	},

	LOAD_COUNT_ADDR: 0x6011,
	RAND_SEED_ADDR: 0x6012,

	FLAG_COLOR_TO_DIRECTION: {
	  "grey":	"s",
	  "sky":	"se",
	  "khaki":	"e",
	  "violet":	"ne",
	  "sand":	"n",
	  "red":	"nw",
	  "forest":	"w",
	  "sakura":	"sw"
	},

	FLAG_FONT_TO_DIRECTION: {
	  "normal upright sans-serif":	"s",
	  "normal upright italic":	"se",
	  "normal slant sans-serif":	"e",
	  "normal slant italic":	"nE",
	  "bold upright sans-serif":	"n",
	  "bold upright italic":	"nw",
	  "bold slant sans-serif":	"w",
	  "bold slant italic":		"sw"
	},

	FLAG_NUM_TO_DIRECTION_1P: ["s", "sw", "w", "nw", "n", "ne", "e", "se"],
	FLAG_NUM_TO_DIRECTION_2P: ["s", "se", "e", "ne", "n", "nw", "w", "sw"],

	SPECIAL_CHARACTER: {
	  "Dot": "\uFF65",
	  "Dash": "\uFF0D",
	  "Delim": "\uFF03",
	  "Raw": "\uFF04"
	},

	KEY_CODE_MAP: {
	  '1p-a':	88,
	  '1p-b':	89,
	  '1p-select':	17,
	  '1p-start':	13,
	  '1p-n':	38,
	  '1p-s':	40,
	  '1p-e':	39,
	  '1p-w':	37,
	  '2p-a':	103,
	  '2p-b':	105,
	  '2p-select':	99,
	  '2p-start':	97,
	  '2p-n':	104,
	  '2p-s':	98,
	  '2p-e':	102,
	  '2p-w':	100
	},
	KEY_ON_VALUE: 0x41,
	KEY_OFF_VALUE: 0x40
      };

      var UI = function (nes) {
	var self = this;
	self.container = parent;
	self.nes = nes;
	self.cvar = cvar;
	self.opts = opts || {};
	for (var k in cvar.DEFAULT_OPTS) {
	  if (typeof self.opts[k] === "undefined") {
	    self.opts[k] = cvar.DEFAULT_OPTS[k];
	  }
	}
	self.UI_ID = "JSNES-FC-UI-" + (JSNES_FC_UI_TEMPLATE_COUNT++).toString();
	self.init();
      };

      UI.prototype = {
	container: null,
	cvar: null,
	opts: null,
	UI_ID: null,

	nes: null,
	origMMapLoad: null,
	origMMapWrite: null,
	origNesFrame: null,
	canvasContext: null,
	canvasImageData: null,
	errorBeepBuf: null,
	dynamicaudio: null,
	magic: null,
	uiStatus: null,
	jsnesStatus: null,
	frameEvents: [],
	inputQueue: null,
	inputLastPause: false,
	forceRedraw: false,
	flagCode: null,
	flagInv: null,
	flagMode: null,
	romName: null,
	xGlasses: {},
	reqs: [],

	getDom: function (s) {
	  return document.getElementById(this.UI_ID + "_" + s);
	},
	getDoms: function (s) {
	  return document.getElementsByName(this.UI_ID + "_" + s);
	},

	init: function () {
	  var self = this;
	  self.loadBeep();
	  if (self.opts.useJRFSemaphore) {
	    self.loadSemaphoreAsm();
	  }
	  self.initDom();
	  self.initNes();
	  if (self.reqs.length > 0) {
	    var browser = navigator.userAgent || navigator.appName;
	    var r = [];
	    var q = {};
	    for (var i = 0; i < self.reqs.length; i++) {
	      var c = self.reqs[i];
	      if (! q[c]) {
		q[c] = true;
		r.push(c);
	      }
	    }
	    self.updateStatusUI("I think no one can't be rejected before assignment, except for the one who don't implement '" + r.join("' or '") + "'.  That is YOU, the browser '"  + browser + "'.  Get out NOW!  ...Or, forgive our glitches.  Sorry!");
	  }
	},

	loadBeep: function () {
	  var self = this;
	  var nes = self.nes;
	  var fname = self.opts.errorBeep;
	  if (! fname) {
	    return;
	  }
	  var ctx;
	  if (window["AudioContext"]) {
	    ctx = new AudioContext();
	  } else if (window["webkitAudioContext"]) {
	    ctx = new webkitAudioContext();
	  } else {
	    self.reqs.push("AudioContext");
	    return;
	  }

	  if (! window["ArrayBuffer"]) {
	    self.reqs.push("ArrayBuffer");
	    return;
	  }
	  var req = new XMLHttpRequest();
	  req.open("GET", fname, true);
	  req.responseType = "arraybuffer";
	  req.onload = bind(function () {
	    this.ctx.decodeAudioData(this.req.response, bind(function (buf) {
	      this.ui.errorBeepBuf = buf;
	    }, this), function () {});
	  }, {ui: self, ctx: ctx, req: req});
	  req.send();
	},

	loadSemaphoreAsm: function () {
	  var self = this;
	  var fname = self.opts.semaphoreAsm;
	  if (! fname) {
	    return;
	  }
	  var req = new XMLHttpRequest();
//	  if (typeof req.withCredentials === "undefined") {
//	    self.reqs.push("XHR2");
//	    return;
//	  }
	  req.open("GET", fname, true);
	  req.responseType = "text";
	  if (req["overrideMimeType"]) {
	    req.overrideMimeType('text/plain;charset=UTF-8');
	  }
	  req.onload = bind(function () {
	    this.ui.parseSemaphoreAsm(this.req.response);
	  }, {ui: self, req: req});
	  req.onerror = bind(function () {
	    this.ui.errorBeep("SemaphoreAsm: Load Failure.");
	  }, {ui: self, req: req});
	  req.send();
	},

	parseSemaphoreAsm: function (s) {
	  var self = this;
	  if (! s.match(/\nFlagCode:[^\n]*\n/)) {
	    self.errorBeep("SemaphoreAsm: Parse Error.");
	    return;
	  }
	  s = RegExp.rightContext;
	  if (! s.match(/\n[A-Za-z01-9\.]/)) {
	    self.errorBeep("SemaphoreAsm: Parse Error.");
	    return;
	  }
	  s = RegExp.leftContext;
	  s = s.replace(/\;[^\n]*\n/g, "\n");
	  var tbl = new Array(8 * 8);
	  self.flagCode = tbl;
	  var inv = {};
	  self.flagInv = inv;

	  var c = 0;
	  while (s.match(/\.db\s+([^\n]+)\n/)) {
	    s = RegExp.rightContext;
	    var l = RegExp.$1.split(/\s*,\s*/);
	    for (var i = 0; i < l.length && c < 8 * 8; i++, c++) {
	      var v = null;
	      if (l[i].match(/^\$/)) {
		v = parseInt(RegExp.rightContext, 16);
	      } else if (l[i].match(/\'(.)\'/)) {
		if (RegExp.$1 != "?") {
		  v = RegExp.$1.charCodeAt(0);
		}
	      }
	      tbl[c] = v;
	      if (v !== null) {
		var x = String.fromCharCode(v);

		// Swap "W" and "w" of Wikipedia.
		if (x == "w") {
		  x = "W";
		  v = x.charCodeAt(0);
		} else if (x == "W") {
		  x = "w";
		  v = x.charCodeAt(0);
		}
		  
		// When x == 0x03, c can take two values, but this
		// program don't use them via inv[].
		if (x.toLowerCase() == x) {
		  inv[v] = c;
		}
	      }
	    }
	  }
	  if (c != 8 * 8) {
	    self.errorBeep("SemaphoreAsm: Parse Error.");
	    return;
	  }
	},

	loadStorage: function () {
	  var self = this;
	  if (! window["localStorage"]) {
	    self.reqs.push("localStorage");
	    return;
	  }
	  var sav = localStorage.getItem(self.UI_ID + ":SAV");
	  if (sav) {
	    if (sav.match(/\;/)) {
	      sav = RegExp.rightContext;
	      var name = decodeURIComponent(RegExp.leftContext);
	      if (self.romName != name) {
		return;
	      }
	    }
	    self.getDom('save-text').value = sav;
	  }
	},

	saveStorage: function (s) {
	  var self = this;
	  if (! window["localStorage"]) {
	    self.reqs.push("localStorage");
	    return;
	  }
	  var name = self.romName || "";
	  name = encodeURIComponent(name);
	  localStorage.setItem(self.UI_ID + ":SAV", name + ";" + s);
	},

	initDom: function () {
	  var self = this;
	  var s, d, l;

	  s = JSNES_FC_UI_TEMPLATE;
	  s = s.replace(/(<[^>]+\s(?:name|id)=[\"\'])([^\"\']+[\"\'])/g,
			"$1" + self.UI_ID + "_$2");
	  self.container.html(s);


	  s = JSNES_FC_UI_CSS;
	  l = "";
	  while (s.match(/\/\*/)) {
	    l += RegExp.leftContext;
	    s = RegExp.rightContext;
	    if (s.match(/\*\//)) {
	      s = RegExp.rightContext;
	    } else {
	      s = "";
	    }
	  }
	  s = l + s;
	  l = "";
	  while (s.match(/^\s*([^\{]*)(\{[^\}]*\})/)) {
	    var sel = RegExp.$1;
	    var st = RegExp.$2;
	    s = RegExp.rightContext;
	    var sels = sel.split(/\s*,\s*/);
	    var r = [];
	    for (var i = 0; i < sels.length; i++) {
	      var c = sels[i];
	      if (! c.match(/#/)) {
		c = ["#" + self.UI_ID + "_" + "jsnes-fc-ui", c].join(" ");
	      } else {
		c = c.replace(/#/g, "#" + self.UI_ID + "_");
	      }
	      r.push(c);
	    }
	    l += r.join(", ") + st;
	  }
	  s = l;
	  d = document.createElement('style');
	  d.innerHTML = s;
	  document.getElementsByTagName('head')[0].appendChild(d);

	  d = self.getDom('jsnes-console');
	  if (! d["getContext"]) {
	    self.reqs.push("Canvas");
	    return;
	  }
	  self.canvasContext = d.getContext('2d');
	  self.canvasImageData
	    = self.canvasContext.getImageData(0, 0, 256, 240);

	  l = self.getDoms("1p-direction");
	  for (var i = 0; i < l.length; i++) {
	    d = l[i];
	    d.addEventListener('click', bind(self.clickDirection, self), false);
	  }
	  l = self.getDoms("2p-direction");
	  for (var i = 0; i < l.length; i++) {
	    d = l[i];
	    d.addEventListener('click', bind(self.clickDirection, self), false);
	  }
	  l = ["1p-start", "1p-select", "1p-a", "1p-b", "2p-a", "2p-b"];
	  for (var i = 0; i < l.length; i++) {
	    d = self.getDom(l[i]);
	    d.addEventListener('click', bind(self.clickButton, self), false);
	  }

	  l = [["pause-button", self.clickPause],
	       ["restart-button", self.clickRestart],
	       ["sound-button", self.clickSound],
	       ["zoom-button", self.clickZoom],
	       ["immediate-button", self.clickImmediate],
	       ["hold-them-button", self.clickHold],
	       ["release-button", self.clickRelease],
	       ["push-them-button", self.clickPush],
	       ["chr-dot-button", self.clickChr],
	       ["chr-dash-button", self.clickChr],
	       ["chr-null2-button", self.clickChr],
	       ["chr-raw-button", self.clickChr],
	       ["flag-semaphore-button", self.clickFlag],
	       ["whole-button", self.clickFloats],
	       ["inject-save-button", self.clickInject],
	       ["capture-save-button", self.clickCapture]
	      ];
	  for (var i = 0; i < l.length; i++) {
	    d = self.getDom(l[i][0]);
	    d.addEventListener('click', bind(l[i][1], self), false);
	  }
	  d = self.getDom('x-glasses-text');
	  d.addEventListener('change', bind(self.changeXGlasses, self), false);

	  d = self.getDom('jsnes-console');
	  d.addEventListener('mousedown', bind(self.gunOn, self), false);
	  d.addEventListener('mouseup', bind(self.gunOff, self), false);

	  d = self.getDom('jsnes-place-holder');
	  d.draggable = true;
	  d.addEventListener('dragstart', bind(self.consoleDrag, self), false);
	  d = self.getDom('jsnes-fc-ui');
	  d.addEventListener('drop', bind(self.consoleDrop, self), false);
	  d.addEventListener("dragover",
			     bind(self.handleDragOver, self), false);

	  if (window["File"] && window["FileList"]
	      && window["FileReader"] && window["Blob"]) {
	    d = self.getDom("jsnes-rom-control");
	    var d2 = self.getDom("jsnes-save-control");
	    d.addEventListener("dragover",
			       bind(self.handleDragOver, self), false);
	    d2.addEventListener("dragover",
			       bind(self.handleDragOver, self), false);
	    d.addEventListener("drop",
			       bind(self.handleRomSelect, self), false);
	    d2.addEventListener("drop",
			       bind(self.handleSavSelect, self), false);
	  } else {
	    self.reqs.push("FileReader API");
	  }
	  if ((! window["URL"] || ! URL["createObjectURL"])
	      && (! window["webkitURL"] || ! webkitURL["createObjectURL"])) {
	    self.reqs.push("URL.createObjectURL");
	  }

	  if (! self.opts.roms) {
	    self.getDom('jsnes-rom-select').style.display = 'none';
	  } else {
	    d = self.getDom('rom-select');
	    d.addEventListener('change', bind(self.selectRom, self), false);
	    var roms = self.opts.roms;
	    for (var i = 0; i < roms.length; i++) {
	      var v = roms[i];
	      if (typeof v == "string") {
		var d2 = document.createElement('option');
		d2.text = v;
		d2.value = v;
		d.appendChild(d2);
		continue;
	      }
	      var k = v[0];
	      v = v[1];
	      if (typeof v == "string") {
		var d2 = document.createElement('option');
		d2.text = k;
		d2.value = v;
		d.appendChild(d2);
		continue;
	      }
	      var l = v;
	      var g = document.createElement('optgroup');
	      g.label = k;
	      d.appendChild(g);
	      for (var j = 0; j < l.length; j++) {
		v = l[j];
		if (typeof v == "string") {
		  var d2 = document.createElement('option');
		  d2.text = v;
		  d2.value = v;
		  g.appendChild(d2);
		  continue;
		}
		k = v[0];
		v = v[1];
		var d2 = document.createElement('option');
		d2.text = k;
		d2.value = v;
		g.appendChild(d2);
	      }
	    }
	    if (self.opts.defaultRom) {
	      for (var i = 0; i < d.options.length; i++) {
		if (d.options[i].value == self.opts.defaultRom) {
		  d.options[i].selected = true;
		}
	      }
	    }
	  }

	  if (! self.opts.useNESSemaphore) {
	    self.getDom('jsnes-nes-semaphore').style.display = 'none';
	  }
	  if (! self.opts.useJRFSemaphore) {
	    self.getDom('jsnes-flag-control').style.display = 'none';
	  }
	  if (self.opts.useRomDnD) {
	    d = self.getDom('use-rom-dnd');
	    if (d) {
	      d.value = "true";
	    }
	  }
	},

	cleanPPU: function () {
	  var self = this;
	  var l = self.nes.ppu.nameTable;
	  for (var i = 0; i < l.length; i++) {
	    var nt = l[i];
	    for (var j = 0; j < nt.tile.length; j++) {
	      nt.tile[j] = 0;
	    }
	    for (var j = 0; j < nt.attrib.length; j++) {
	      nt.attrib[j] = 0;
	    }
	  }
	},

	initHook: function () {
	  var self = this;
	  var nes = self.nes;

	  if (self._nesFrame != nes.frame) {
	    self.origNesFrame = nes.frame;
	    nes.frame = self._nesFrame;
	  }
	  if (nes["mmap"]) {
	    if (self._mmapWrite != nes.mmap.write) {
	      self.origMMapLoad = nes.mmap.load;
	      if (window["allot_magic"]) {
		nes.mmap.load = self._mmapLoad;
	      }
	      self.origMMapWrite = nes.mmap.write;
	      nes.mmap.write = self._mmapWrite;
	    }
	  }
	},

	initNes: function () {
	  var self = this;
	  var d, l;

          self.resetCanvas();

          self.dynamicaudio = new DynamicAudio({
            swf: self.nes.opts.swfPath + 'dynamicaudio.swf'
          });

	  l = [["sound-button", self.clickSound],
	       ["zoom-button", self.clickZoom]
	      ];
	  for (var i = 0; i < l.length; i++) {
	    d = self.getDom(l[i][0]);
	    l[i][1].apply(self, [{target: d}]);
	  }

	  if (self.opts.defaultRom) {
	    self.loadRomURL(self.opts.defaultRom);
	  }
	  
	  if (self.checkImmediate()) {
	    d = self.getDom('hold-them-button');
	    self.clickHold({target: d});
	  }
	},

	_nesFrame: function () {
	  var self = this.ui;
	  var res = self.origNesFrame.apply(self.nes, []);
	  var l = self.frameEvents;
	  if (l.length == 0) {
	    return res;
	  }
	  var r = [];
	  var ev = [];
	  for (var i = 0; i < l.length; i++) {
	    var c = l[i];
	    if (--c[0] <= 0) {
	      ev.push(c[1]);
	    } else {
	      r.push(c);
	    }
	  }
	  self.frameEvents = r;
	  for (var i = 0; i < ev.length; i++) {
	    (ev[i])();
	  }
	  return res;
	},

	_mmapLoad: function (addr) {
	  var self = this.nes.ui;
	  if (addr != self.cvar.RAND_SEED_ADDR
	      || ! self.getDom('rand-magic').checked) {
	    return self.origMMapLoad.apply(self.nes.mmap, [addr]);
	  }
	  if (self.magic != null) {
	    var c = self.magic & 0xFF;
	    self.magic = null;
	    return c;
	  }
	  var mem = self.nes.cpu.mem;
	  var c = self.getDom('jsnes-console').toDataURL("image/png");
	  var d = new Array(16);
	  for (var i = 0; i < 8; i++) {
	    d[i] = self.nes.keyboard.state1[i];
	    d[i + 8] = self.nes.keyboard.state2[i];
	  }
	  d = String.fromCharCode.apply(null, d);
	  c = parseInt(allot_magic(c), 10) * 8 + parseInt(allot_magic(d), 10);
	  self.magic = c >> 8;
	  return c & 0xFF;
	},

	_mmapWrite: function (addr, value) {
	  var self = this.nes.ui;
	  var res = self.origMMapWrite.apply(self.nes.mmap, [addr, value]);
	  if (addr == self.cvar.LOAD_COUNT_ADDR
	      && self.getDom('stop-load-count').checked) {
	    self.nes.stop();
	    self.updateStatusUI("Stopped");
	    self.getDom('pause-button').value = "Resume";
	    self.clickCapture();
	  } else if (addr == self.cvar.RAND_SEED_ADDR
		  && self.getDom('stop-rand-seed').checked) {
	    self.nes.stop();
	    self.updateStatusUI("Stopped");
	    self.getDom('pause-button').value = "Resume";
	    self.clickCapture();
	  }
	  return res;
	},

	errorBeep: function (s) {
	  var self = this;
	  if (s) {
	    self.updateStatusUI(s);
	  }
	  if (! self.errorBeepBuf) {
	    return;
	  }
	  var ctx;
	  if (window["AudioContext"]) {
	    ctx = new AudioContext();
	  } else if (window["webkitAudioContext"]) {
	    ctx = new webkitAudioContext();
	  } else {
	    return;
	  }
	  var s = ctx.createBufferSource();
	  s.buffer = self.errorBeepBuf;
	  s.connect(ctx.destination);
	  s.start(0);
	},

	checkImmediate: function () {
	  var self = this;
	  return self.getDom('immediate-button').checked;
	},

	clickImmediate: function (e) {
	  var self = this;
	  if (e.target.checked) {
	    self.clickHold(e);
	  }
	},

	clickPause: function (e) {
	  var self = this;
	  if (self.nes.isRunning) {
	    self.nes.stop();
	    self.updateStatusUI("Paused");
	    self.getDom('pause-button').value = "Resume";
	  } else {
	    self.nes.start();
	    self.getDom('pause-button').value = "Pause";
	  }
	},

	clickRestart: function (e) {
	  var self = this;
	  self.nes.reloadRom();
	  self.initHook();
	  self.cleanPPU();
	  self.injectIfAvailable();
	  self.getDom('pause-button').value = "Pause";
	  self.nes.start();
	},

        clickSound: function (e) {
	  var self = this;
	  self.nes.opts.emulateSound = e.target.checked;
	},

	clickZoom: function (e) {
	  var self = this;
	  var d = self.getDom('jsnes-console');
	  if (e.target.checked) {
	    d.style.width = "512px";
	    d.style.height = "480px";
	  } else {
	    d.style.width = "256px";
	    d.style.height = "240px";
	  }
	},

	changeXGlasses: function (e) {
	  var self = this;
	  var pal = self.nes.ppu.imgPalette;
	  var l = e.target.value.split(/\s*,\s*/);
	  var r = {};
	  for (var i = 0; i < l.length; i++) {
	    var q = l[i].split(":");
	    var c = parseInt(q[0], 10);
	    if (! q[0].match(/^[01-9]+/) || ! (c >= 0 && c <= 15)) {
	      self.updateStatusUI("The format of X Glasses: [color-num(0-15)]:[alpha-value(0-255)]");
	      return;
	    }
	    var d = (q.length > 1)? parseInt(q[1], 10) : 0;
	    d = d & 0xFF;
	    r[pal[c]] = d;
	  }
	  self.xGlasses = r;
	  self.forceRedraw = true;
	},

	clickButton: function (e) {
	  var self = this;
	  if (! self.checkImmediate()) {
	    return;
	  }
	  var c = e.target.id;
	  c = c.replace(/^.*_/, "");
	  c = self.cvar.KEY_CODE_MAP[c];
	  v = (e.target.checked)? self.cvar.KEY_ON_VALUE
	    : self.cvar.KEY_OFF_VALUE;
	  self.nes.keyboard.setKey(c, v);
	},

	clickDirection: function (e) {
	  var self = this;
	  if (! self.checkImmediate()) {
	    return;
	  }
	  var c = e.target.value;
	  e.target.name.match(/^.*_([12]p-)/);
	  var p = RegExp.$1;
	  var k, v, l;
	  l = ["n", "s", "e", "w"];
	  for (i = 0; i < l.length; i++) {
	    k = self.cvar.KEY_CODE_MAP[p + l[i]];
	    v = (c.indexOf(l[i]) != -1)? self.cvar.KEY_ON_VALUE
	      : self.cvar.KEY_OFF_VALUE;
	    self.nes.keyboard.setKey(k, v);
	  }
	},

	clickHold: function (e) {
	  var self = this;
	  var k, v, l;
	  for (var j = 0; j < 2; j++) {
	    var p = (j == 0)? "1p-" : "2p-";
	    l = ["start", "select", "a", "b"];
	    for (var i = 0; i < l.length; i++) {
	      var d = self.getDom(p + l[i]);
	      if (! d) {
		continue;
	      }
	      k = self.cvar.KEY_CODE_MAP[p + l[i]];
	      v = (d.checked)? self.cvar.KEY_ON_VALUE
		: self.cvar.KEY_OFF_VALUE;
	      self.nes.keyboard.setKey(k, v);
	    }
	    l = self.getDoms(p + 'direction');
	    var c = 'c';
	    for (var i = 0; i < l.length; i++) {
	      if (l[i].checked) {
		c = l[i].value;
	      }
	    }
	    l = ["n", "s", "e", "w"];
	    for (i = 0; i < l.length; i++) {
	      k = self.cvar.KEY_CODE_MAP[p + l[i]];
	      v = (c.indexOf(l[i]) != -1)? self.cvar.KEY_ON_VALUE
		: self.cvar.KEY_OFF_VALUE;
	      self.nes.keyboard.setKey(k, v);
	    }
	  }
	},

	clickRelease: function (e) {
	  var self = this;
	  var l;
	  self.frameEvents = [];
	  for (var j = 0; j < 2; j++) {
	    var p = (j == 0)? "1p-" : "2p-";
	    l = ["start", "select", "a", "b"];
	    for (var i = 0; i < l.length; i++) {
	      var d = self.getDom(p + l[i]);
	      if (! d) {
		continue;
	      }
	      d.checked = false;
	    }
	    l = self.getDoms(p + 'direction');
	    for (var i = 0; i < l.length; i++) {
	      if (l[i].value == "c") {
		l[i].checked = true;
	      } else {
		l[i].checked = false;
	      }
	    }
	  }
	  self.clickHold(e);
	},

	clickPush: function (e) {
	  var self = this;
	  self.clickHold(e);
	  var w = parseInt(self.getDom('push-length').value, 10);
	  if (self.nes.isRunning) {
	    self.frameEvents = [[w, bind(self.clickRelease, self)]];
	  } else {
	    self.clickPause();
	    self.frameEvents = [[w, bind(self.clickPause, self)]];
	  }
	},

	clickChr: function (e) {
	  var self = this;
	  var c = e.target.value;
	  c = self.cvar.SPECIAL_CHARACTER[c];
	  var d = self.getDom('flag-text');
	  if (typeof d.selectionStart !== "undefined") {
	    var b = d.selectionStart;
	    var e = d.selectionEnd;
	    var s = d.value;
	    d.value = s.substr(0, b) + c + s.substr(e);
	    d.selectionStart = b + c.length;
	    d.selectionEnd = b + c.length;
	  } else {
	    d.value += c;
	  }
	},

	clickFlag: function (e) {
	  var self = this;
	  // self.getDom('immediate-button').checked = false;
	  var q = [];
	  var d;
	  var s;
	  d = self.getDom('flag-font');
	  d = d.options[d.selectedIndex];
	  if (d.value != "current") {
	    var c = self.cvar.FLAG_FONT_TO_DIRECTION[d.value];
	    q.push(["2p-b", "2p-direction-" + c]);
	  }
	  d = self.getDom('flag-color');
	  d = d.options[d.selectedIndex];
	  if (d.value != "current") {
	    var c = self.cvar.FLAG_COLOR_TO_DIRECTION[d.value];
	    q.push(["2p-a", "2p-direction-" + c]);
	  }
	  q.push([]);
	  q.push(["1p-direction-s", "2p-direction-sw"]);
	  self.flagMode = "letter";
	  d = self.getDom('flag-text');
	  s = d.value;
	  s = s.replace(/\s+$/, "");
	  if (s.length > 0) {
	    for (var i = 0; i < s.length; i++) {
	      var c = s.charCodeAt(i);
	      var nc = (i + 1 < s.length)? s.charCodeAt(i + 1) : null;
	      q = self.concatDirections(q, self.charCodeToDirections(c, nc));
	    }
	  }
	  q.push([]);
	  self.inputQueue = q;
	  if (! self.nes.isRunning) {
	    self.inputLastPause = true;
	    self.clickPause();
	  } else {
	    self.inputLastPause = false;
	  }
	  self.inputNext();
	},

	clickFloats: function (e) {
	  var self = this;
	  self.UI_ID.match(/[01-9]+$/);
	  var pre = RegExp.leftContext;
	  var n = parseInt(RegExp.lastMatch, 10);
	  if (JSNES_FC_UI_TEMPLATE_COUNT > n) n = JSNES_FC_UI_TEMPLATE_COUNT;
	  for (var i = 0; i < n; i++) {
	    var d = document.getElementById(pre + i.toString()
					    + "_hook");
	    if (d) {
	      d.value = "Flag";
	      d.click();
	    }
	  }
	},

	clickHook: function (e) {
	  var self = this;
	  if (e.target.value == "Flag") {
	    self.clickFlag(e);
	  }
	  e.target.value = "none";
	},

	concatDirections: function (a, b) {
	  var self = this;
	  if (a.length == 0) {
	    return b;
	  }
	  if (b.length == 0) {
	    return a;
	  }
	  var al = a[a.length - 1];
	  var bb = b[0];
	  if (al.join(" ") == bb.join(" ")
	      && al.join(" ") != "1p-direction-s 2p-direction-s") {
	    return a.concat([["1p-direction-s", "2p-direction-s"]]).concat(b);
	  } else {
	    return a.concat(b);
	  }
	},

	charCodeToRawDirection: function (c) {
	  var self = this;
	  if (c == 0x30) {
	    c = 0x6b;
	  } else if (c >= 0x31 && c <= 0x39) {
	    c = c - 0x31 + 0x61;
	  }
	  if (typeof self.flagInv[c] === "undefined") {
	    return null;
	  }
	  c = self.flagInv[c];
	  return [["1p-direction-" + self.cvar.FLAG_NUM_TO_DIRECTION_1P[c >> 3],
		   "2p-direction-" + self.cvar.FLAG_NUM_TO_DIRECTION_2P[c & 7]]];
	},

	charCodeToDirections: function (c, next_c) {
	  var self = this;
	  var C = function (s) {return s.charCodeAt(0);};
	  var r;
	  var mode;
	  var sc = "";
	  for (var k in self.cvar.SPECIAL_CHARACTER) {
	    var v = self.cvar.SPECIAL_CHARACTER[k];
	    if (c == C(v)) {
	      sc = k;
	      break;
	    }
	  }
	  c = c & 0xFF;
	  if (sc) {
	    if (sc == "Dot") {
	      r = [["2p-direction-n"], ["2p-direction-s"]];
	      mode = "morse";
	    } else if (sc == "Dash") {
	      r = [["2p-direction-n"], ["2p-direction-w"]];
	      mode = "morse";
	    } else if (sc == "Delim") {
	      r = [["2p-direction-sw"]];
	      mode = self.flagMode;
	    } else if (sc == "Raw") {
	      r = [];
	      mode = "raw";
	    }
	  } else if (c >= C("a") && c <= C("z")) {
	    r = self.charCodeToRawDirection(c);
	    mode = "letter";
	  } else if (c >= C("A") && c <= C("Z")) {
	    c += C("a") - C("A");
	    r = self.concatDirections(self.charCodeToRawDirection(C("_")),
				      self.charCodeToRawDirection(c));
	    mode = "letter";
	  } else if (c >= C("0") && c <= C("9")) {
	    if (self.flagMode == "raw") {
	      r = self.charCodeToRawDirection(c);
	      mode = "raw";
	    } else {
	      r = self.concatDirections(self.charCodeToRawDirection(C("_")),
					self.charCodeToRawDirection(c));
	      mode = "number";
	    }
	  } else if (c == C(" ")) {
	    r = self.charCodeToRawDirection(C(" "));
	    mode = self.flagMode;
	  } else if (c == C(".")) {
	    r = self.concatDirections(self.charCodeToRawDirection(C("_")),
				      self.charCodeToRawDirection(C(".")));

	    mode = self.flagMode;
	  } else if (c == C(",")) {
	    r = self.concatDirections(self.charCodeToRawDirection(C("_")),
				      self.charCodeToRawDirection(C(" ")));

	    mode = self.flagMode;
	  } else {
	    var l = c & 7;
	    var m = (c >> 3) & 7;
	    var h = (c >> 6) & 7;
	    r = self.charCodeToRawDirection(l + C("0"));
	    if (h == 0 && m >= 4) {
	      r = self.concatDirections(self.charCodeToRawDirection(m+C("0")),
					r);
	    } else if ((h == 1 && m == 0 && l == 0)
		       || (h == 1 && m == 3 && l != 0)) {
	      r = self.concatDirections(self.charCodeToRawDirection(C("8")),
					r);
	      
	    } else if ((h == 1 && m == 4 && l == 0)
		       || (h == 1 && m == 7 && l != 0)) {
	      r = self.concatDirections(self.charCodeToRawDirection(C("9")),
					r);
	    } else {
	      r = self.concatDirections(self.charCodeToRawDirection(m+C("0")),
					r);
	      r = self.concatDirections(self.charCodeToRawDirection(h+C("0")),
					r);
	    }
	    if (self.flagMode == "letter"
		&& next_c != null
		&& ((next_c >= C("a") && next_c <= C("z"))
		    || (next_c >= C("A") && next_c <= C("Z")))) {
	      r = self.concatDirections(self.charCodeToRawDirection(C("&")),
					r);
	      mode = "letter";
	    } else {
	      mode = "number";
	    }
	  }
	  if (mode != self.flagMode) {
	    if (mode == "letter"
		&& (self.flagMode == "raw" || self.flagMode == "number")) {
	      r = self.concatDirections(self.charCodeToRawDirection(C("j")),
					r);
	    } else if ((mode == "raw" || mode == "number")
		       && ! (self.flagMode == "raw"
			     || self.flagMode == "number")) {
	      r = self.concatDirections(self.charCodeToRawDirection(C("$")),
					r);
	    }
	    self.flagMode = mode;
	  }
	  return r;
	},

	inputNext: function () {
	  var self = this;
	  if (self.inputQueue.length <= 0) {
	    var m = "Input: Done.";
	    if (self.nes.isRunning && self.inputLastPause) {
	      self.clickPause();
	      m = "Input: pause -> Done.";
	    }
	    self.updateStatusUI(m);
	    return;
	  }
	  var with_release = false;
	  var s = self.inputQueue.shift();
	  while (s.length == 0) {
	    with_release = true;
	    if (self.inputQueue.length <= 0) {
	      var m = "Input: release -> Done.";
	      self.clickRelease();
	      if (self.nes.isRunning && self.inputLastPause) {
		self.clickPause();
		m = "Input: release -> pause -> Done.";
	      }
	      self.updateStatusUI(m);
	      return;
	    }
	    s = self.inputQueue.shift();
	  }
	  self.updateStatusUI("Input: "
			      + (with_release? "release -> " : "")
			      + s.join(" "));
	  var s = " " + s.join(" ") + " ";

	  var p1d = "";
	  var p2d = "";
	  if (s.match(/ 1p-direction-(\S+) /)) {
	    p1d = RegExp.$1;
	    s = RegExp.leftContext + " " + RegExp.rightContext;
	  }
	  if (s.match(/ 2p-direction-(\S+) /)) {
	    p2d = RegExp.$1;
	    s = RegExp.leftContext + " " + RegExp.rightContext;
	  }
	  for (var j = 0; j < 2; j++) {
	    var p = (j == 0)? "1p-" : "2p-";
	    var pd = (j == 0)? p1d : p2d;
	    var k, v, d;
	    if (with_release || ! s.match(/^\s+/)) {
	      var l = ["start", "select", "a", "b"];
	      for (var i = 0; i < l.length; i++) {
		d = self.getDom(p + l[i]);
		if (d) {
		  if (s.indexOf(p + l[i]) != -1) {
		    d.checked = true;
		  } else {
		    d.checked = false;
		  }
		}
	      }
	    }
	    if (with_release || p1d != "" || p2d != "") {
	      pd = pd || "c";
	      var l = self.getDoms(p + "direction");
	      for (var i = 0; i < l.length; i++) {
		d = l[i];
		if (d.value == pd) {
		  d.checked = true;
		} else {
		  d.checked = false;
		}
	      }
	    }
	  }
	  self.clickHold();
	  
	  self.frameEvents = [[parseInt(self.getDom('flag-length').value, 10),
			       bind(self.inputNext, self)]];
	},

	getAbsoluteTopLeft: function (e) {
	  var self = this;
	  var p = self.getDom('absolute-top-left');
	  if (! p) {
	    p = document.createElement('div');
	    p.id = self.UI_ID + '_' + 'absolute-top-left';
	    p.innerHTML = '<input id="' + self.UI_ID
	      + '_hook" type="button" value="none" />';
	    (document.documentElement || document.body).appendChild(p);
	    var tc = self.getDom('hook');
	    tc.addEventListener('click', bind(self.clickHook, self), false);
	  }
	  return p;
	},

	consoleDrag: function (e) {
	  var self = this;
	  self.getDom('whole-button').style.display = "inline";
	  self.getAbsoluteTopLeft();
	  e.stopPropagation();
//	  e.preventDefault();
	  e.dataTransfer.setData("text",
				 [e.target.id, e.clientX, e.clientY].join(","));
	},

	consoleDrop: function (e) {
	  var self = this;
	  e.stopPropagation();
	  e.preventDefault();
	  var s = e.dataTransfer.getData("text");
	  if (s && s.match(/^JSNES-FC-UI-[01-9]+/)) {
	    var q = RegExp.lastMatch;
	    var l = s.split(",");
	    var d = document.getElementById(l[0]);
	    self.floatDom(d, e.pageX, e.pageY);
	  }
	  return;
	},

	floatDom: function (d, pageX, pageY) {
	  var self = this;
	  var p = d.parentNode;
	  if (! p.id.match(/absolute-top-left/)) {
	    p.removeChild(d);
	    p = self.getAbsoluteTopLeft();
	    p.appendChild(d);
	  }
	  d.style.position = 'absolute';
	  d.style.top = pageY + 'px';
	  d.style.left = pageX + 'px';
	},

	gunOn: function (e) {
	  var self = this;
	  var mmap = self.nes.mmap;
	  var mag = (self.getDom('zoom-button').checked)? 2 : 1;
	  if (mmap && e["clientX"]) {
	    mmap.mousePressed = true;
            mmap.mouseX = e.clientX / mag;
            mmap.mouseY = e.clientY / mag;
	  }
	  e.stopPropagation();
	  e.preventDefault();
	},

	gunOff: function (e) {
	  var self = this;
	  var mmap = self.nes.mmap;
	  if (mmap && e["clientX"]) {
	    mmap.mousePressed = false;
            mmap.mouseX = 0;
            mmap.mouseY = 0;
	  }
	  e.stopPropagation();
	  e.preventDefault();
	},

	handleDragOver: function (e) {
	  e.stopPropagation();
	  e.preventDefault();
	  if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
	    e.dataTransfer.dropEffect = "copy";
	  } else {
	    e.dataTransfer.dropEffect = "move";
	  }
	},

	handleSavSelect: function (e) {
	  var self = this;
	  var txt = e.dataTransfer.getData("text");
	  if (! e.dataTransfer.files || e.dataTransfer.files.length == 0) {
	    if (txt && txt.match(/^JSNES-FC-UI-[01-9]+/)) {
	      return;
	    }
	  }
	  e.stopPropagation();
	  e.preventDefault();

	  if (! self.opts.useSaveDnD) {
	    self.errorBeep();
	    return;
	  }
	  if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
	    var file = e.dataTransfer.files[0];
	    var reader = new FileReader();
	    reader.onload = bind(function (e) {
	      var self = this;
	      self.getDom('save-text').value = e.target.result;
	    }, self);
	    reader.readAsDataURL(file);
	  } else if (txt) {
	    self.getDom('save-text').value = txt;
	  } else {
	    self.errorBeep();
	    return;
	  }
	},

	handleRomSelect: function (e) {
	  var self = this;
	  e.stopPropagation();
	  e.preventDefault();

	  if (! e.dataTransfer.files || e.dataTransfer.files.length == 0) {
	    var s = e.dataTransfer.getData("text");
	    if (s && s.match(/^JSNES-FC-UI-[01-9]+/)) {
	      var q = RegExp.lastMatch;
	      var l = s.split(",");
	      var d = document.getElementById(l[0]);
	      if (q  == self.UI_ID) {
		var p = d.parentNode;
		if (p.id.match(/absolute-top-left/)) {
		  p.removeChild(d);
		  p = self.getDom('jsnes-place');
		  p.appendChild(d);
		}
		d.style.position = "static";
		d.style.left = null;
		d.style.top = null;
	      } else {
		var scrollLeft =  document.documentElement.scrollLeft
                  || document.body.scrollLeft;
		var scrollTop = document.documentElement.scrollTop
                  || document.body.scrollTop;
		var bb = self.getDom('jsnes-place-holder')
		  .getBoundingClientRect();
		self.floatDom(d, bb.left + scrollLeft, bb.top + scrollTop);
	      }
	    }
	    return;
	  }

	  if (! self.opts.useRomDnD) {
	    self.errorBeep();
	    return;
	  }

	  var d = self.getDom("use-rom-dnd");
	  if (d && (d.value == "false" || ! d.value)) {
	    self.errorBeep();    
	    return;
	  }

	  // var done = true;
	  // while (d) {
	  //   done = false;
	  //   if (d.style.display == "none") {
	  //     done = true;
	  //     break;
	  //   }
	  //   d = d.parentNode;
	  // }
	  // if (! done) {
	  //   self.errorBeep();
	  //   return;
	  // }

	  if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
	    var file = e.dataTransfer.files[0];
	    var reader = new FileReader();
	    reader.onload = bind(function (e) {
	      var self = this.ui;
	      self.changeRom(this.fname, e.target.result);
	    }, {ui: self, fname: file.name});
	    reader.readAsBinaryString(file);
	  } else {
	    self.errorBeep();    
	    return;
	  }
	},

	clickInject: function (e) {
          var self = this;
	  var s = self.getDom('save-text').value;
	  if (! s.match(/\S/)) {
	    self.errorBeep();
	    return;
	  }
	  s = s.replace(/\s+/g, "");
	  if (s.match(/^data\:/)) {
	    if (! s.match(/\;base64,/)) {
	      self.errorBeep("DataURI must be encoded by base64.");
	      return;
	    }
	    s = RegExp.rightContext;
	  }
	  s = atob(s);
	  self.saveStorage(btoa(s));
	  
	  self.updateStatusUI("Injecting the saved ram.");
	  var i = 0;
	  var mem = self.nes.cpu.mem;
	  for (var i = 0; i < 0x2000; i++) {
	    if (i < s.length) {
	      mem[0x6000 + i] = s.charCodeAt(i) & 0xFF;
	    } else {
	      mem[0x6000 + i] = 0;
	    }
	  }
	},

	clickCapture: function (e) {
          var self = this;
	  var d;
	  var i = 0;
	  var a = new Array(0x2000);
	  var mem = self.nes.cpu.mem;
	  var z = 0;
	  for (var i = 0; i < 0x2000; i++) {
	    a[i] = mem[0x6000 + i];
	    if (a[i] != 0) {
	      z = 0;
	    } else {
	      z++;
	    }
	  }
	  
	  var blob = new Blob([String.fromCharCode.apply(null, a)],
			      {type: 'application/x-nes-sav'});
	  a = a.slice(0, 0x2000 - z);
	  var s = String.fromCharCode.apply(null, a);
	  s = btoa(s);
	  self.saveStorage(s);
	  s = "data:application/x-nes-sav;base64," + s;
	  self.getDom('save-text').value = s;
	  d = self.getDom('download-save-button');
	  d.href = (URL.createObjectURL || webkitURL.createObjectURL)(blob);
	  d.download = self.romName.replace(/\.[^\.]+/, ".sav");
	  d.style.display = 'inline';
	},

	selectRom: function (e) {
	  var self = this;
	  var sel = e.target.options[e.target.selectedIndex];
	  if (sel.value) {
	    self.loadRomURL(sel.value);
	  }
	},

        injectIfAvailable: function () {
          var self = this;
	  if (self.nes.rom.batteryRam) {
	    if (! self.getDom('save-text').value.match(/\S/)) {
	      self.loadStorage();
	    }
	    self.getDom('download-save-button').style.display = "none";
	    if (self.getDom('save-text').value.match(/\S/)) {
	      var d = self.getDom('inject-save-button');
	      self.clickInject({target: d});
	    }
	  }
	},

        changeRom: function (name, binstr) {
          var self = this;
	  self.romName = name.replace(/^.*\//, "");

	  if (binstr.length <= 3 || binstr.substr(0, 3) != "NES") {
	    self.errorBeep("The ROM isn't a NES ROM.");
	    return;
	  }
          self.nes.loadRom(binstr);
	  self.initHook();
	  self.cleanPPU();
	  self.injectIfAvailable();
          self.nes.start();
          self.enable();
        },

	loadRomURL: function (fname) {
	  var self = this;

	  if (! window["ArrayBuffer"]) {
	    self.reqs.push("ArrayBuffer");
	    return;
	  }
	  var req = new XMLHttpRequest();
	  req.open("GET", fname, true);
	  req.responseType = "arraybuffer";
	  req.onload = bind(function () {
	    var self = this.ui;
	    var a = new Uint8Array(this.req.response);
	    var b = String.fromCharCode.apply(null, a);
	    self.changeRom(this.fname, b);
	  }, {ui: self, req: req, fname: fname});
	  req.onerror = bind(function () {
	    var self = this.ui;
	    self.updateStatusUI("Load Error.");
	  }, {ui: self, req: req, fname: fname});
	  req.send();
	},

        resetCanvas: function () {
	  var self = this;

          self.canvasContext.fillStyle = 'black';

          // set alpha to opaque
          self.canvasContext.fillRect(0, 0, 256, 240);

          // Set alpha
	  var idat = self.canvasImageData.data;
          for (var i = 0; i < 256 * 240; i++) {
            idat[i * 4 + 3] = 0xFF;
          }
        },
        
        // nes.ui.screenshot() --> return <img> element.
        screenshot: function () {
	  var self = this;
          var img = new Image();
	  img.src = self.getDom('jsnes-console').toDataURL("image/png");
          return img;
        },
        
        // Enable and reset UI elements.
        enable: function () {
	  var self = this;
	  var nes = self.nes;
	  var d;
	  d = self.getDom('pause-button');
	  d.disabled = null;
	  d.value = (nes.isRunning)? "Pause" : "Resume";
	  d = self.getDom('restart-button');
	  d.disabled = null;
	  d = self.getDom('sound-button');
          if (nes.opts.emulateSound) {
	    d.checked = true;
          } else {
	    d.checked = false;
	  }
        },
        
        updateStatus: function (s) {
	  var self = this;
	  self.jsnesStatus = s;
	  var l = "";
	  if (self.uiStatus) {
	    l += "FC_UI: " + self.uiStatus + "\n";
	  }
	  if (self.jsnesStatus) {
	    l += "JSNES: " + self.jsnesStatus + "";
	  }
	  self.getDom('status-text').value = l;
        },
        
        updateStatusUI: function (s) {
	  var self = this;
	  self.uiStatus = s;
	  var l = "";
	  if (self.jsnesStatus) {
	    l += "JSNES: " + self.jsnesStatus + "\n";
	  }
	  if (self.uiStatus) {
	    l += "FC_UI: " + self.uiStatus + "";
	  }
	  self.getDom('status-text').value = l;
        },
        
        writeAudio: function (samples) {
	  var self = this;
          return self.dynamicaudio.writeInt(samples);
        },
        
        writeFrame: function (buffer, prevBuffer) {
	  var self = this;
	  var xg = self.xGlasses;
          var idat = self.canvasImageData.data;

	  var j = 0;
	  if (self.forceRedraw) {
	    self.forceRedraw = false;
	    for (var i = 0; i < 256 * 240; i++, j += 4) {
	      var p = buffer[i];
	      idat[j] = p & 0xFF;
	      idat[j + 1] = (p >> 8) & 0xFF;
	      idat[j + 2] = (p >> 16) & 0xFF;
	      if (typeof xg[p] !== "undefined") {
		idat[j + 3] = xg[p];
	      } else {
		idat[j + 3] = 0xFF;
	      }
	    }
	    for (var i = 0; i < 256 * 240; i++, j += 4) {
	      prevBuffer[i] = buffer[i];
	    }
	  } else {
	    for (var i = 0; i < 256 * 240; i++, j += 4) {
	      var p = buffer[i];
	      if (p != prevBuffer[i]) {
		idat[j] = p & 0xFF;
		idat[j + 1] = (p >> 8) & 0xFF;
		idat[j + 2] = (p >> 16) & 0xFF;
		if (typeof xg[p] !== "undefined") {
		  idat[j + 3] = xg[p];
		} else {
		  idat[j + 3] = 0xFF;
		}
		prevBuffer[i] = p;
	      }
	    }
	  }

          self.canvasContext.putImageData(self.canvasImageData, 0, 0);
        }
      };
      
      return UI;
    };
  })(jQuery);
}
