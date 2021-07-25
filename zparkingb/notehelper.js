/**********************
/* Parking B - MuseScore - Note helper
/* v1.0.1
/* ChangeLog: 
/* 	- 22/7/21: Added restToNote and changeNote function
/*  - 25/7/21: Managing of transposing instruments
/**********************************************/
/**
 * Add some propeprties to the note. Among others, the name of the note, in the format "C4" and "C#4", ...
 * The added properties:
 * - note.accidentalName : the name of the accidental
 * - note.extname.fullname : "C#4"
 * - note.extname.name : "C4"
 * - note.extname.raw : "C"
 * - note.extname.octave : "4"
 * @param note The note to be enriched
 * @return /
 */
function enrichNote(note) {
	// accidental
	var id = note.accidentalType;
	note.accidentalName = "UNKOWN";
	for (var i = 0; i < accidentals.length; i++) {
		var acc = accidentals[i];
		if (id == eval("Accidental." + acc.name)) {
			note.accidentalName = acc.name;
			break;
		}
	}

	// note name and octave
	var pitch = note.pitch;
	var tpitch= pitch+note.tpc2-note.tpc1; // note displayed as if it has that pitch
	note.extname = pitchToName(tpitch,note.tpc2);
	note.pitchname = pitchToName(pitch,note.tpc1);
	return;

}

function pitchToName(npitch, ntpc) {
	var tpc = {
		'tpc' : 0,
		'name' : '?',
		'raw' : '?'
	};

	var pitchnote = pitchnotes[npitch % 12];
	var noteOctave = Math.floor(npitch / 12) - 1;

	for (var i = 0; i < tpcs.length; i++) {
		var t = tpcs[i];
		if (ntpc == t.tpc) {
			tpc = t;
			break;
		}
	}

	if ((pitchnote == "A" || pitchnote == "B") && tpc.raw == "C") {
		noteOctave++;
	} else if (pitchnote == "C" && tpc.raw == "B") {
		noteOctave--;
	}

	return {
		"fullname" : tpc.name + noteOctave,
		"name" : tpc.raw + noteOctave,
		"raw" : tpc.raw,
		"octave" : noteOctave
	};

	
	
}

/**
 * Reconstructed a note pitch information based on the note name and its accidental
 * @param noteName the name of the note, without alteration. Eg "C4", and not "C#4"
 * @param accidental the <b>name</b> of the accidental to use. Eg "SHARP2"
 * @return a structure with pitch/tpc information
ret.pitch : the pitch of the note
ret.tpc: the value for the note tpc1 and tpc2
 */
function buildPitchedNote(noteName, accidental) {

	var name = noteName.substr(0, 1);
	var octave = parseInt(noteName.substr(1, 3));

	var a = accidental;
	for (var i = 0; i < equivalences.length; i++) {
		for (var j = 1; j < equivalences[i].length; j++) {
			if (accidental == equivalences[i][j]) {
				a = equivalences[i][0];
				break;
			}
		}
	}

	// tpc
	var tpc = {
		'tpc' : -1,
		'pitch' : 0
	};
	for (var i = 0; i < tpcs.length; i++) {
		var t = tpcs[i];
		if (name == t.raw && a == t.accidental) {
			//console.log("found with "+t.name);
			tpc = t;
			break;
		}
	}

	if (tpc.tpc == -1) {
		// not found. it means that we have an "exotic" accidental
		for (var i = 0; i < tpcs.length; i++) {
			var t = tpcs[i];
			if (name == t.raw && 'NONE' == t.accidental) {
				//console.log("found with "+t.name + ' NONE');
				tpc = t;
				break;
			}
		}
	}

	if (tpc.tpc == -1) {
		// not found. Shouldn't occur
		tpc.tpc = 0;
	}

	// pitch
	//console.log("--" + tpc.pitch + "--");
	var pitch = (octave + 1) * 12 + ((tpc.pitch !== undefined) ? tpc.pitch : 0);

	var recompose = {
		"pitch" : pitch,
		//"tpc1" : tpc.tpc,  // ==> undefined to forece the representation
		"tpc2" : tpc.tpc 
	};

	return recompose;
}

/**
 *
 * duration: {numerator, denominator} optional. If undefined, the rest duration will be used.
 */
function restToNote(rest, toNote) {
	if (rest.type != Element.REST)
		return;

	//console.log("==ON A REST==");
	var cur_time = rest.parent.tick; // getting rest's segment's tick
	var duration = rest.duration;
	var oCursor = curScore.newCursor()
		oCursor.rewindToTick(cur_time);
	// oCursor.setDuration(duration.numerator, duration.denominator); // 22/7/21 En commentaire, car efface la Duration mise en amont
	//oCursor.addNote(toNote.pitch); // We can add whatever note here, we'll rectify it afterwards
	oCursor.addNote(60); // We can add whatever note here, we'll rectify it afterwards
	oCursor.rewindToTick(cur_time);
	var chord = oCursor.element;
	var note = chord.notes[0];

	//debugPitch(level_DEBUG,"Added note",note);

	changeNote(note, toNote);

	//debugPitch(level_DEBUG,"Corrected note",note);


	return note;
}

/**
* Convention 
*   keep toNote.tpc1 undefined to force a representation. For transposing instruments, the pitch will be adapted (e.g. a note displayed at C, will be pitched as D)
*   keep toNote.tpc2 undefined to force a pitch. For transposing instruments, the representation will be adapted  (e.g. a note pitched at C, will be displayed as Bb)

*/
function changeNote(note, toNote) {
	if (note.type != Element.NOTE) {
		debug(level_INFO, "! Changing Note of a non-Note element");
		return;
	}

	var debugTpc = note.tpc;
	
	console.log("default is pitch: "+note.pitch+", tpc: "+note.tpc1+"/"+note.tpc2+"/"+note.tpc);
	console.log("requested is pitch: "+((toNote.pitch===undefined)?"undefined":toNote.pitch)+
		", tpc: "+((toNote.tpc1===undefined)?"undefined":toNote.tpc1)+"/"+((toNote.tpc2===undefined)?"undefined":toNote.tpc2));
	
	var transposing=note.tpc2-note.tpc1;
	
	var p=(toNote.tpc1===undefined)?toNote.pitch-transposing:toNote.pitch;
	var t1=(toNote.tpc1===undefined)?toNote.tpc2-transposing:toNote.tpc1;
	var t2=(toNote.tpc2===undefined)?toNote.tpc1+transposing:toNote.tpc2;

	console.log("Adapted as pitch: "+p+", tpc: "+t1+"/"+t2);


	note.tpc1 =t1;
	note.tpc2 = t2;
	note.pitch = p;

	console.log("After is pitch: "+note.pitch+", tpc: "+note.tpc1+"/"+note.tpc2+"/"+note.tpc);

	return note;

}

var pitchnotes = ['C', 'C', 'D', 'D', 'E', 'F', 'F', 'G', 'G', 'A', 'A', 'B'];

var tpcs = [{
		'tpc' : -1,
		'name' : 'F♭♭',
		'accidental' : 'FLAT2',
		'pitch' : 3,
		'raw' : 'F'
	}, {
		'tpc' : 0,
		'name' : 'C♭♭',
		'accidental' : 'FLAT2',
		'pitch' : -2,
		'raw' : 'C'
	}, {
		'tpc' : 1,
		'name' : 'G♭♭',
		'pitch' : 5,
		'accidental' : 'FLAT2',
		'raw' : 'G'
	}, {
		'tpc' : 2,
		'name' : 'D♭♭',
		'pitch' : 0,
		'accidental' : 'FLAT2',
		'raw' : 'D'
	}, {
		'tpc' : 3,
		'name' : 'A♭♭',
		'pitch' : 7,
		'accidental' : 'FLAT2',
		'raw' : 'A'
	}, {
		'tpc' : 4,
		'name' : 'E♭♭',
		'pitch' : 2,
		'accidental' : 'FLAT2',
		'raw' : 'E'
	}, {
		'tpc' : 5,
		'name' : 'B♭♭',
		'pitch' : 9,
		'accidental' : 'FLAT2',
		'raw' : 'B'
	}, {
		'tpc' : 6,
		'name' : 'F♭',
		'pitch' : 4,
		'accidental' : 'FLAT',
		'raw' : 'F'
	}, {
		'tpc' : 7,
		'name' : 'C♭',
		'pitch' : -1,
		'accidental' : 'FLAT',
		'raw' : 'C'
	}, {
		'tpc' : 8,
		'name' : 'G♭',
		'pitch' : 6,
		'accidental' : 'FLAT',
		'raw' : 'G'
	}, {
		'tpc' : 9,
		'name' : 'D♭',
		'pitch' : 1,
		'accidental' : 'FLAT',
		'raw' : 'D'
	}, {
		'tpc' : 10,
		'name' : 'A♭',
		'pitch' : 8,
		'accidental' : 'FLAT',
		'raw' : 'A'
	}, {
		'tpc' : 11,
		'name' : 'E♭',
		'pitch' : 3,
		'accidental' : 'FLAT',
		'raw' : 'E'
	}, {
		'tpc' : 12,
		'name' : 'B♭',
		'pitch' : 10,
		'accidental' : 'FLAT',
		'raw' : 'B'
	}, {
		'tpc' : 13,
		'name' : 'F',
		'pitch' : 5,
		'accidental' : 'NONE',
		'raw' : 'F'
	}, {
		'tpc' : 14,
		'name' : 'C',
		'pitch' : 0,
		'accidental' : 'NONE',
		'raw' : 'C'
	}, {
		'tpc' : 15,
		'name' : 'G',
		'pitch' : 7,
		'accidental' : 'NONE',
		'raw' : 'G'
	}, {
		'tpc' : 16,
		'name' : 'D',
		'pitch' : 2,
		'accidental' : 'NONE',
		'raw' : 'D'
	}, {
		'tpc' : 17,
		'name' : 'A',
		'pitch' : 9,
		'accidental' : 'NONE',
		'raw' : 'A'
	}, {
		'tpc' : 18,
		'name' : 'E',
		'pitch' : 4,
		'accidental' : 'NONE',
		'raw' : 'E'
	}, {
		'tpc' : 19,
		'name' : 'B',
		'pitch' : 11,
		'accidental' : 'NONE',
		'raw' : 'B'
	}, {
		'tpc' : 20,
		'name' : 'F♯',
		'pitch' : 6,
		'accidental' : 'SHARP',
		'raw' : 'F'
	}, {
		'tpc' : 21,
		'name' : 'C♯',
		'pitch' : 1,
		'accidental' : 'SHARP',
		'raw' : 'C'
	}, {
		'tpc' : 22,
		'name' : 'G♯',
		'pitch' : 8,
		'accidental' : 'SHARP',
		'raw' : 'G'
	}, {
		'tpc' : 23,
		'name' : 'D♯',
		'pitch' : 3,
		'accidental' : 'SHARP',
		'raw' : 'D'
	}, {
		'tpc' : 24,
		'name' : 'A♯',
		'pitch' : 10,
		'accidental' : 'SHARP',
		'raw' : 'A'
	}, {
		'tpc' : 25,
		'name' : 'E♯',
		'pitch' : 5,
		'pitch' : 5,
		'accidental' : 'SHARP',
		'raw' : 'E'
	}, {
		'tpc' : 26,
		'name' : 'B♯',
		'pitch' : 12,
		'accidental' : 'SHARP',
		'raw' : 'B'
	}, {
		'tpc' : 27,
		'name' : 'F♯♯',
		'pitch' : 7,
		'accidental' : 'SHARP2',
		'raw' : 'F'
	}, {
		'tpc' : 28,
		'name' : 'C♯♯',
		'pitch' : 2,
		'accidental' : 'SHARP2',
		'raw' : 'C'
	}, {
		'tpc' : 29,
		'name' : 'G♯♯',
		'pitch' : 9,
		'accidental' : 'SHARP2',
		'raw' : 'G'
	}, {
		'tpc' : 30,
		'name' : 'D♯♯',
		'pitch' : 3,
		'accidental' : 'SHARP2',
		'raw' : 'D'
	}, {
		'tpc' : 31,
		'name' : 'A♯♯',
		'pitch' : 11,
		'accidental' : 'SHARP2',
		'raw' : 'A'
	}, {
		'tpc' : 32,
		'name' : 'E♯♯',
		'pitch' : 6,
		'accidental' : 'SHARP2',
		'raw' : 'E'
	}, {
		'tpc' : 33,
		'name' : 'B♯♯',
		'pitch' : 13,
		'accidental' : 'SHARP2',
		'raw' : 'B'
	}
];

var accidentals = [{
		'name' : 'NONE',
	}, {
		'name' : 'FLAT',
	}, {
		'name' : 'NATURAL',
	}, {
		'name' : 'SHARP',
	}, {
		'name' : 'SHARP2',
	}, {
		'name' : 'FLAT2',
	}, {
		'name' : 'NATURAL_FLAT',
	}, {
		'name' : 'NATURAL_SHARP',
	}, {
		'name' : 'SHARP_SHARP',
	}, {
		'name' : 'FLAT_ARROW_UP',
	}, {
		'name' : 'FLAT_ARROW_DOWN',
	}, {
		'name' : 'NATURAL_ARROW_UP',
	}, {
		'name' : 'NATURAL_ARROW_DOWN',
	}, {
		'name' : 'SHARP_ARROW_UP',
	}, {
		'name' : 'SHARP_ARROW_DOWN',
	}, {
		'name' : 'SHARP2_ARROW_UP',
	}, {
		'name' : 'SHARP2_ARROW_DOWN',
	}, {
		'name' : 'FLAT2_ARROW_UP',
	}, {
		'name' : 'FLAT2_ARROW_DOWN',
	}, {
		'name' : 'MIRRORED_FLAT',
	}, {
		'name' : 'MIRRORED_FLAT2',
	}, {
		'name' : 'SHARP_SLASH',
	}, {
		'name' : 'SHARP_SLASH4',
	}, {
		'name' : 'FLAT_SLASH2',
	}, {
		'name' : 'FLAT_SLASH',
	}, {
		'name' : 'SHARP_SLASH3',
	}, {
		'name' : 'SHARP_SLASH2',
	}, {
		'name' : 'DOUBLE_FLAT_ONE_ARROW_DOWN',
	}, {
		'name' : 'FLAT_ONE_ARROW_DOWN',
	}, {
		'name' : 'NATURAL_ONE_ARROW_DOWN',
	}, {
		'name' : 'SHARP_ONE_ARROW_DOWN',
	}, {
		'name' : 'DOUBLE_SHARP_ONE_ARROW_DOWN',
	}, {
		'name' : 'DOUBLE_FLAT_ONE_ARROW_UP',
	}, {
		'name' : 'FLAT_ONE_ARROW_UP',
	}, {
		'name' : 'NATURAL_ONE_ARROW_UP',
	}, {
		'name' : 'SHARP_ONE_ARROW_UP',
	}, {
		'name' : 'DOUBLE_SHARP_ONE_ARROW_UP',
	}, {
		'name' : 'DOUBLE_FLAT_TWO_ARROWS_DOWN',
	}, {
		'name' : 'FLAT_TWO_ARROWS_DOWN',
	}, {
		'name' : 'NATURAL_TWO_ARROWS_DOWN',
	}, {
		'name' : 'SHARP_TWO_ARROWS_DOWN',
	}, {
		'name' : 'DOUBLE_SHARP_TWO_ARROWS_DOWN',
	}, {
		'name' : 'DOUBLE_FLAT_TWO_ARROWS_UP',
	}, {
		'name' : 'FLAT_TWO_ARROWS_UP',
	}, {
		'name' : 'NATURAL_TWO_ARROWS_UP',
	}, {
		'name' : 'SHARP_TWO_ARROWS_UP',
	}, {
		'name' : 'DOUBLE_SHARP_TWO_ARROWS_UP',
	}, {
		'name' : 'DOUBLE_FLAT_THREE_ARROWS_DOWN',
	}, {
		'name' : 'FLAT_THREE_ARROWS_DOWN',
	}, {
		'name' : 'NATURAL_THREE_ARROWS_DOWN',
	}, {
		'name' : 'SHARP_THREE_ARROWS_DOWN',
	}, {
		'name' : 'DOUBLE_SHARP_THREE_ARROWS_DOWN',
	}, {
		'name' : 'DOUBLE_FLAT_THREE_ARROWS_UP',
	}, {
		'name' : 'FLAT_THREE_ARROWS_UP',
	}, {
		'name' : 'NATURAL_THREE_ARROWS_UP',
	}, {
		'name' : 'SHARP_THREE_ARROWS_UP',
	}, {
		'name' : 'DOUBLE_SHARP_THREE_ARROWS_UP',
	}, {
		'name' : 'LOWER_ONE_SEPTIMAL_COMMA',
	}, {
		'name' : 'RAISE_ONE_SEPTIMAL_COMMA',
	}, {
		'name' : 'LOWER_TWO_SEPTIMAL_COMMAS',
	}, {
		'name' : 'RAISE_TWO_SEPTIMAL_COMMAS',
	}, {
		'name' : 'LOWER_ONE_UNDECIMAL_QUARTERTONE',
	}, {
		'name' : 'RAISE_ONE_UNDECIMAL_QUARTERTONE',
	}, {
		'name' : 'LOWER_ONE_TRIDECIMAL_QUARTERTONE',
	}, {
		'name' : 'RAISE_ONE_TRIDECIMAL_QUARTERTONE',
	}, {
		'name' : 'DOUBLE_FLAT_EQUAL_TEMPERED',
	}, {
		'name' : 'FLAT_EQUAL_TEMPERED',
	}, {
		'name' : 'NATURAL_EQUAL_TEMPERED',
	}, {
		'name' : 'SHARP_EQUAL_TEMPERED',
	}, {
		'name' : 'DOUBLE_SHARP_EQUAL_TEMPERED',
	}, {
		'name' : 'QUARTER_FLAT_EQUAL_TEMPERED',
	}, {
		'name' : 'QUARTER_SHARP_EQUAL_TEMPERED',
	}, {
		'name' : 'SORI',
	}, {
		'name' : 'KORON',
	}
	//,{ 'name': 'UNKNOWN',  }
];

var equivalences = [
	['SHARP', 'NATURAL_SHARP'],
	['FLAT', 'NATURAL_FLAT'],
	['NONE', 'NATURAL'],
	['SHARP2', 'SHARP_SHARP']
];

function isEquivAccidental(a1, a2) {
	for (var i = 0; i < equivalences.length; i++) {
		if ((equivalences[i][0] === a1 && equivalences[i][1] === a2) ||
			(equivalences[i][0] === a2 && equivalences[i][1] === a1))
			return true;
	}
	return false;
}
