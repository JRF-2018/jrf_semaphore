//
// pseudo_dynamicaudio.js
//
// Pseudo code of Ben Firshman's original dynamicaudio.js for JSNES.
//
var VERSION_pseudo_dynamicaudio = "0.03"; // Time-stamp: <2014-02-24T17:36:50Z>

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
// Author's Link:
//
//   http://jrf.cocolog-nifty.com/software/
//   (The page is written in Japanese.)
//

//'use utf8'; // Japanese
//

if (! window["bind"]) {
  window["bind"] = function (f, o) {
    return function() {return f.apply(o, arguments)};
  };
}

function DynamicAudio(args) {
    if (this instanceof arguments.callee) {
        if (typeof this.init === "function") {
            this.init.apply(this, (args && args.callee) ? args : arguments);
        }
    }
    else {
        return new arguments.callee(arguments);
    }
}

DynamicAudio.prototype = {
  audioElement: null,
  sampleRate: null,
  bufferSize: 8192,
  
  init: function(opts) {
    var self = this;
    var ctx;
    if (typeof AudioContext !== 'undefined') {
      ctx = new AudioContext();
    } else if (typeof webkitAudioContext !== 'undefined') {
      ctx = new webkitAudioContext();
    }
    if (ctx) {
      self.audioElement = ctx;
      self.sampleRate = 44100;
//      self.sampleRate = ctx.sampleRate;
    }
  },

  writeInt: function (samples) {
    if (this.audioElement !== null)  {
      var ctx = this.audioElement;
      var node = ctx.createBufferSource();
      var buf = ctx.createBuffer(2, this.bufferSize, this.sampleRate);
      var sb = samples;
      var b0 = buf.getChannelData(0);
      var b1 = buf.getChannelData(1);
      var i;
      for (i = 0; i < b0.length && i * 2 < sb.length; i++) {
	b0[i] = sb[i * 2] / 0x7fff; // Need to divide by 0x7fff, maybe.
	b1[i] = sb[i * 2 + 1] / 0x7fff;
      }
      for (;i < b0.length; i++) {
	b0[i] = b1[i] = 0;
      }
      node.buffer = buf; 
      node.connect(ctx.destination);
      node.start(0);
    }
  },
}

