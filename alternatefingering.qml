import QtQuick 2.9
import QtQuick.Controls 2.2 
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import FileIO 3.0

MuseScore {
	menuPath : "Plugins.Alternate Fingering"
	description : "Add and edit alternate fingering"
	version : "1.3.0"
	pluginType : "dialog"
	requiresScore : true
	width: 600
	height: 600
	
	id: mainWindow
        
	/** category of instrument :"flute","clarinet", ... */
	property string __category : ""
	/** alias to the different keys schemas for a the current category. */
	property var __instruments : categories[__category]["instruments"]
	property var __modelInstruments : {{Object.keys(__instruments)}}

	/** alias to the different config options in the current category. */
	property var __config : categories[__category]["config"];
	/** alias to the different library  in the current category. */
	property var __library : categories[__category]["library"];
	/** alias to the different notes in the activated configs in the current category. */
	property var __confignotes : []

	// hack
	property bool refreshed : true;
	property bool presetsRefreshed: true
	property var ready : false;

	/** the notes to which the fingering must be made. */
	property var __notes : [];

	// config
	readonly property int debugLevel : level_TRACE;
	readonly property bool atFingeringLevel : true;

	// work variables
	property var lastoptions;
        property string currentInstrument: ""
        property var __asAPreset : new presetClass()

	// constants
	/* All the supported states. */
	readonly property var basestates : ["open", "closed"];
	readonly property var halfstates : ["right", "left"];
	readonly property var quarterstates : ["halfright", "halfleft"];
	readonly property var thrillstates : ["thrill"];
	readonly property var ringstates : ["ring"];

	/* All the playing techniques (aka "states") used by default. */
	// *User instructions*: Modify the default states by concatenating any of states arrays found above
	//property var usedstates : basestates;
	property var usedstates : basestates.concat(thrillstates);

	readonly property int titlePointSize: 12
	readonly property int tooltipShow: 500
	readonly property int tooltipHide: 5000
	
	readonly property int level_NONE : 0;
	readonly property int level_INFO : 10;
	readonly property int level_DEBUG : 20;
	readonly property int level_TRACE : 30;
	readonly property int level_ALL : 999;


	// -----------------------------------------------------------------------
	// --- Read the score ----------------------------------------------------
	// -----------------------------------------------------------------------
	onRun : {

		if (Qt.fontFamilies().indexOf('Fiati') < 0) {
			fontMissingDialog.open();
			return;
		}

                // lecture des options
                readOptions();
                readLibrary();
                
		// preliminary check of the usedstates
                displayUsedStates();

		var instrument;
		var category;
		var fingering;
		var notes;
		var errors = [];
		var warnings = [];
		var warnMultipleInstruments = false;
		var warnMultipleFingerings = false;
		if (atFingeringLevel) {
			// Managing fingering in the Fingering element (note.elements)
			notes = getNotesFromCursor(true);
			if (notes && (notes.length > 0)) {
				debug(level_DEBUG, "NOTES FOUND FROM CURSOR");
			} else {
				notes = getNotesFromSelection();
				if (notes && (notes.length > 0)) {
					debug(level_DEBUG, "NOTES FOUND FROM SELECTION");
				} else {
					debug(level_DEBUG, "NO NOTES FOUND");
					var fingerings = getFingeringsFromSelection();
					if (fingerings && (fingerings.length > 0)) {
						debug(level_DEBUG, "FINGERINGS FOUND FROM SELECTION");
						notes = [];
						for (var i = 0; i < fingerings.length; i++) {
							var f = fingerings[i];
							var n = f.parent;
							if (notes.indexOf(n) == -1)
								notes.push(n);
						}
						fingering = fingerings[0];
					} else {
						debug(level_DEBUG, "NO NOTES FOUND");
						invalidSelectionDialog.open();
						return;
					}
				}
			}

			if (notes) {

				var prevNote;
				var prevInstru;
				for (var i = 0; i < notes.length; i++) {
					var note = notes[i];
					var isValidNote = true;
					// Read the instrument and its category
					var instru = getInstrument(note);
					if (!instru || !instru.category) {
						// error : non valid instrument
						isValidNote = false;
						// log only if not already logged
						if ((prevInstru && instru && prevInstru != instru.instrument) ||
							!prevInstru) {
							errors[errors.length] = "Unsupported instrument (" + instru.instrument + ")";
						} else if (prevInstru && (prevInstru == "unknown") && !instru) {
							errors[errors.length] = "Unsupported instrument (unknow)";
						}
					} else if (instrument && instrument !== instru.instrument) {
						// warning : different instrument
						// log only if not already logged
						if (!warnMultipleInstruments) {
							warnings[warnings.length] = "All instruments should be the same";
							warnMultipleInstruments = true;
						}
					} else {
						instrument = instru.instrument;
						category = instru.category;
					}

					prevInstru = (instru) ? instru.instrument : "unknown";
					// Read the first fingering
					if (isValidNote) {
						var fingerings = getFingerings(note);
						enrichNote(note); // add note name, accidental name, ...

						if (fingerings && fingerings.length > 0) {
							fingerings = fingerings.filter(function (f) {
									return (f.fontFace === 'Fiati');
								});
						}
						if (fingerings && fingerings.length > 0) {
							if ((fingering && fingering !== fingerings[0]) || (fingerings.length > 1)) {
								if (!warnMultipleFingerings) {
									warnings[warnings.length] = "The selection contains different fingerings. Only taking one.";
									warnMultipleFingerings = true;
								}
							}
							if (!fingering) {
								fingering = fingerings[0];
							}
						}
					}

					prevNote = note;
				}

			}

		}

		// On peut arriver ici avec un ensemble de notes dont on déduit des fingerings
		// Ou juste un fingering
		debugV(level_INFO, ">>", "notes", notes);
		debugV(level_INFO, ">>", "instrument", instrument);
		debugV(level_INFO, ">>", "category", category);
		debugV(level_INFO, ">>", "fingering", ((fingering) ? fingering.text : fingering));
		debugV(level_INFO, ">>", "errors", errors);
		debugV(level_INFO, ">>", "warnings", warnings);
		// INVALID INSTRUMENT
		if (!instrument && !category) {
			// TODO: Pass the error message
			unkownInstrumentDialog.open();
			return;
		}

		// CORRECT INSTRUMENT
		__notes = notes;
		__category = category;

		// On fabrique le modèle pour le ComboBox
		pushFingering(fingering?fingering.text:undefined)
		
		ready=true;
		}
                
           
      function pushFingering(ff) {                
                ready=false;

		// Basé sur la sélection, on récupère le doigté déjà saisi
		var sFingering;
		var instrument_type;
		if (ff) {
			instrument_type = extractInstrument(__category, ff);
		}
		if (instrument_type) {
			// We got an identification based on the fingering found in the selection
			sFingering = ff;
		} else {
			// We have no fingering in the selection or we wre not able to identifiy it
			sFingering = "";
			if ((categories[__category]["default"]) && (__modelInstruments.indexOf(categories[__category]["default"]) > -1)) {
				// we have a default and valid instrument, we take it
				instrument_type = categories[__category]["default"];
			} else if (__modelInstruments.length > 0) {
				// we haven't a default instrument, we take the first one
				instrument_type = __modelInstruments[0];
			} else {
				// this category has no instruments. It should not occur. Anyway. We take an empty instrument.
				instrument_type = "";
			}

			if (ff) {
				warnings[warnings.length] = "Impossible to recognize instrument type based from the selected fingering. Using default one.";
			}
		}
		debugV(level_INFO, "analyse", 'type', instrument_type);
		debugV(level_INFO, "analyse", 'fingering', sFingering);

		// Sélection parmi les clés standards
		var keys = __instruments[instrument_type]["keys"];
		for (var i = 0; i < keys.length; i++) {
			var note = keys[i];
			var states = Object.keys(note.modes);
			for (var j = 0; j < states.length; j++) {
				var state = states[j];
				var rep = note.modes[state];
				if (sFingering.search(rep) >  - 1) {
					note.currentMode = state;
					break;
				}
			}
			debugP(level_TRACE, "note " + note.name, note, "currentMode");
		}

		// Sélection parmi les configuration de l'instrument
		for (var i = 0; i < __config.length; i++) {
			var config = __config[i];

			// a) la note
			for (var k = 0; k < config.notes.length; k++) {

				var note = config.notes[k];
				note.currentMode = "open"; // re-init
				var states = Object.keys(note.modes);
				for (var j = 0; j < states.length; j++) {
					var state = states[j];
					var rep = note.modes[state];
					if (sFingering.search(rep) >  - 1) {
						note.currentMode = state;
						break;
					}
				}
			}

			// b) la config (only if we start from an existing fingering. Otherwise we keep
			// the default values
			if (sFingering) {
				var rep = config.representation;
				config.activated = (sFingering.search(rep) >  - 1);
			}
		}

		// On sélectionne le bon instrument
		currentInstrument=instrument_type;
		refreshed = false; // awful trick to force the refresh
		refreshed = true;



		// On consruit la liste des notes dépendants des configurations actuellement sélectionnées.
		// Je voudrais faire ça par binding mais le javascript de QML ne supporte pas flatMap() => je dois le faire manuellement
		buildConfigNotes();

		ready = true;
	}
	// -----------------------------------------------------------------------
	// --- Modify the score ----------------------------------------------------
	// -----------------------------------------------------------------------
	function writeFingering() {

		var sFingering = buildFingeringRepresentation();
		
		debugV(level_INFO, "Fingering", "as string", sFingering);
		curScore.startCmd();
		if (atFingeringLevel) {
			// Managing fingering in the Fingering element (note.elements)
			var prevNote;
			var firstNote;
			for (var i = 0; i < __notes.length; i++) {
				var note = __notes[i];
				if ((i == 0) || (prevNote && !prevNote.parent.is(note.parent))) {
					// first note of chord. Going to treat the chord as once
					debug(level_TRACE, "dealing with first note");
					var chordnotes = note.parent.notes;
					debug(level_TRACE, "with" + chordnotes.length + "notes in the chord");
					var f = undefined;
					// We keep the first fingering found and we delete the others
					for (var j = 0; j < chordnotes.length; j++) {
						var nt = chordnotes[j];
						var fgs = getFingerings(nt);
						if (fgs && fgs.length > 0) {
							for (var k = (f ? 0 : 1); k < fgs.length; k++) {
								nt.remove(fgs[k]);
								debug(level_TRACE, "removing unneeded fingering");
							}
							// we keep the first found
							if (!f) {
								debug(level_DEBUG, "keeping first fingering");
								f = fgs[0];
							}
						}
					}

					// If no fingering found, create a new one
					if (!f) {
						debug(level_DEBUG, "adding a new fingering");
						f = newElement(Element.FINGERING);
						f.text = sFingering;
						f.fontFace = 'Fiati';
						f.fontSize = 42;
						// LEFT = 0, RIGHT = 1, HCENTER = 2, TOP = 0, BOTTOM = 4, VCENTER = 8, BASELINE = 16
						f.align = 2; // HCenter and top
						// Set text to below the staff
						f.placement = Placement.BELOW;
						// Turn on note relative placement
						f.autoplace = true;
						note.add(f);
					} else {
						f.text = sFingering;
						debug(level_DEBUG, "exsiting fingering modified");
					}
				} else {
					// We don't treat the other notes of the same chord
					debug(level_DEBUG, "skipping one note");
				}
				prevNote = note;
			}

		}

		curScore.endCmd(false);
	}

	function buildFingeringRepresentation() {
		var instru = currentInstrument;
		var sFingering = __instruments[instru].base.join('');
		var kk = __instruments[instru].keys;

		var mm = __config;

		debugV(level_DEBUG, "**Writing", "Instrument", instru);
		debugV(level_DEBUG, "**Writing", "Notes count", __notes.length);

		for (var i = 0; i < kk.length; i++) {
			var k = kk[i];
			if (k.selected) {
				sFingering += k.currentRepresentation;
			}
			debugV(level_TRACE, k.name, "selected", k.selected);
		}

		for (var i = 0; i < mm.length; i++) {
			var config = mm[i];
			if (config.activated) {
				sFingering += config.representation;
				for (var k = 0; k < config.notes.length; k++) {
					var note = config.notes[k];
					if (note.selected) {
						sFingering += note.currentRepresentation;
					}
				}
			}

		}

		return sFingering;

	}

	function removeAllFingerings() {

		var nbNotes=__notes.length;
		var nbFing=0
		
		curScore.startCmd();
		if (atFingeringLevel) {
			// Managing fingering in the Fingering element (note.elements)
			for (var i = 0; i < __notes.length; i++) {
				var note = __notes[i];
				// first note of chord. Going to treat the chord as once
				debug(level_TRACE, "dealing with first note");
				var chordnotes = note.parent.notes;
				debug(level_TRACE, "with" + chordnotes.length + "notes in the chord");
				var f = undefined;
				// We delete all the fingering found and 
				for (var j = 0; j < chordnotes.length; j++) {
					var nt = chordnotes[j];
					var fgs = getFingerings(nt);
					if (fgs && fgs.length > 0) {
						for (var k =  0 ; k < fgs.length; k++) {
							nbFing++;
							nt.remove(fgs[k]);
							debug(level_TRACE, "removing unneeded fingering");
						}
					}
				}
			}
		}

		curScore.endCmd(false);
		return {'nbnotes': nbNotes, 'nbdeleted': nbFing};
	}

	// -----------------------------------------------------------------------
	// --- Selection helper --------------------------------------------------
	// -----------------------------------------------------------------------
	/**
	 * Get all the selected notes from the selection
	 * @return Note[] : each returned {@link Note} has
	 *      - element.type==Element.NOTE
	 */
	function getNotesFromSelection() {
		var selection = curScore.selection;
		var el = selection.elements;
		var notes = [];
		var n = 0;
		for (var i = 0; i < el.length; i++) {
			var element = el[i];
			if (element.type == Element.NOTE) {
				notes[n++] = element;
			}
		}
		return notes;
	}

	/**
	 * Get all the selected chords from the selection
	 * @return Chord[] : each returned {@link Chord} has
	 *      - element.type==Element.CHORD
	 */
	function getChordsFromSelection() {
		var notes = getNotesFromSelection();
		var chords = [];
		var c = 0;
		var prevChord;
		for (var i = 0; i < notes.length; i++) {
			var element = notes[i];
			var chord = element.parent;
			if (prevChord && !prevChord.is(chord)) {
				chords[c++] = chord;
			}
			prevChord = chord;
		}
		return chords;
	}

	/**
	 * Get all the selected segments from the selection
	 * @return Segment[] : each returned {@link Segment} has
	 *      - element.type==Element.SEGMENT
	 */
	function getSegmentsFromSelection() {
		var chords = getChordsFromSelection();
		var segments = [];
		var s = 0;
		var prevSeg;
		for (var i = 0; i < chords.length; i++) {
			var element = chords[i];
			var seg = element.parent;
			if (prevSeg && !prevSeg.is(seg)) {
				segments[s++] = seg;
			}
			prevChord = seg;
		}
		return segments;
	}

	/**
	 * Reourne les fingerings sélectionnés
	 */
	function getFingeringsFromSelection() {
		var selection = curScore.selection;
		var el = selection.elements;
		var fingerings = [];
		var n = 0;
		for (var i = 0; i < el.length; i++) {
			var element = el[i];
			if (element.type == Element.FINGERING) {
				fingerings[n++] = element;
			}
		}
		return fingerings;
	}

	/**
	 * Get all the selected notes based on the cursor.
	 * Rem: This does not any result in case of the notes are selected inidvidually.
	 * @param oneNoteBySegment : boolean. If true, only one note by segment will be returned.
	 * @return Note[] : each returned {@link Note} has
	 *      - element.type==Element.NOTE
	 *
	 */
	function getNotesFromCursor(oneNoteBySegment) {
		var chords = getChordsFromCursor();
		var notes = [];
		for (var c = 0; c < chords.length; c++) {
			var chord = chords[c];
			var nn = chord.notes;
			for (var i = 0; i < nn.length; i++) {
				var note = nn[i];
				notes[notes.length] = note;
				if (oneNoteBySegment)
					break;
			}
		}
		return notes;
	}

	/**
	 * Get all the selected chords based on the cursor.
	 * Rem: This does not any result in case of the notes are selected inidvidually.
	 * @return Chord[] : each returned {@link Note} has
	 *      - element.type==Element.CHORD
	 *
	 */
	function getChordsFromCursor() {
		var score = curScore;
		var cursor = curScore.newCursor()
			var firstTick,
		firstStaff,
		lastTick,
		lastStaff;
		// start
		cursor.rewind(Cursor.SELECTION_START);
		firstTick = cursor.tick;
		firstStaff = cursor.track;
		// end
		cursor.rewind(Cursor.SELECTION_END);
		lastTick = cursor.tick;
		if (lastTick == 0) { // dealing with some bug when selecting to end.
			lastTick = curScore.lastSegment.tick + 1;
		}
		lastStaff = cursor.track;
		debugV(level_DEBUG, "> first", "tick", firstTick);
		debugV(level_DEBUG, "> first", "track", firstStaff);
		debugV(level_DEBUG, "> last", "tick", lastTick);
		debugV(level_DEBUG, "> last", "track", lastStaff);
		var chords = [];
		for (var track = firstStaff; track <= lastStaff; track++) {

			cursor.rewind(Cursor.SELECTION_START);
			var segment = cursor.segment;
			while (segment && (segment.tick < lastTick)) {
				var element;
				element = segment.elementAt(track);
				if (element && element.type == Element.CHORD) {
					debugV(level_TRACE, "- segment -", "tick", segment.tick);
					debugV(level_TRACE, "- segment -", "segmentType", segment.segmentType);
					debugV(level_TRACE, "--element", "label", (element) ? element.name : "null");
					chords[chords.length] = element;
				}

				cursor.next();
				segment = cursor.segment;
			}
		}

		return chords;
	}

	/**
	 * Get all the selected segments based on the cursor.
	 * Rem: This does not any result in case of the notes are selected inidvidually.
	 * @return Segment[] : each returned {@link Note} has
	 *      - element.type==Element.SEGMENT
	 *
	 */
	function getSegmentsFromCursor() {
		var score = curScore;
		var cursor = curScore.newCursor()
			cursor.rewind(Cursor.SELECTION_END);
		var lastTick = cursor.tick;
		cursor.rewind(Cursor.SELECTION_START);
		var firstTick = cursor.tick;
		debugV(level_DEBUG, "> first", "tick", firstTick);
		debugV(level_DEBUG, "> last", "tick", lastTick);
		var segment = cursor.segment;
		debugV(level_DEBUG, "> starting at", "tick", (segment) ? segment.tick : "NO SEGMENT");
		var segments = [];
		var s = 0;
		while (segment && (segment.tick < lastTick)) {
			segments[s++] = segment;
			cursor.next();
			segment = cursor.segment;
		}

		return segments;
	}

	// -----------------------------------------------------------------------
	// --- Score manipulation ------------------------------------------------
	// -----------------------------------------------------------------------
	/**
	 * Return the fingerings of this note
	 * @param note : the note for which the fingering has to be returned.
	 *   any {@link Element} has element.type==Element.NOTE
	 * @return Element[], each returned {@link Element} has element.type==Element.FINGERING .
	 */
	function getFingerings(note) {
		if (note.type != Element.NOTE) {
			return [];
		} else {
			var ff = [];
			var el = note.elements;
			//debugP(level_DEBUG,"getFingering", note,"type");
			for (var j = 0; j < el.length; j++) {
				var e = el[j];
				if (e.type == Element.FINGERING) {
					ff[ff.length] = e;
				}
			}
			return ff;
		}
	}
	/**
	 * Return the instrument playing that note
	 */
	function getInstrument(note) {
		if (note.type != Element.NOTE) {
			return undefined;
		} else {
			var nstaff = Math.ceil(note.track / 4);
			var part = note.staff.part;
			//debugO(level_DEBUG,"part", part);
			var instru = part.instrumentId;
			debug(level_DEBUG, instru);
			var cat;
			if (part && !instru && part.midiProgram) {
				switch (part.midiProgram) {
				case 73:
					instru = 'wind.flutes.flute';
					break;
				default:
					instru = 'unkown';
				}
			}

			for (var c in categories) {
				for (var i = 0; i < categories[c].support.length; i++) {
					var support = categories[c].support[i];
					if (instru.startsWith(support)) {
						cat = c;
						break;
					}
				}
			}

			return {
				"instrument" : instru,
				"category" : cat
			};
		}

	}

	function enrichNote(note) {
		// accidental
		var id = note.accidentalType;
		note.accidentalData = {name: "UNKOWN", image: "NONE.png"};
		for (var i = 0; i < accidentals.length; i++) {
			var acc = accidentals[i];
			if (id == eval("Accidental." + acc.name)) {
				note.accidentalData = acc;
				break;
			}
		}
		
		// note name and octave
		var tpc={'tpc' : 0, 'name' : '?', 'raw' : '?'};
		var pitch=note.pitch;
		var pitchnote=pitchnotes[pitch % 12];
		var noteOctave=Math.floor(pitch/12)-1;

		for (var i = 0; i < tpcs.length; i++) {
			var t = tpcs[i];
			if (note.tpc==t.tpc) {
				tpc=t;
				break;
			}
		}			

		if (pitchnote == "B" && tpc.raw == "C") {
			noteOctave++;
		} else if (pitchnote == "C" && tpc.raw == "B") {
			noteOctave--;
		}
		
		note.extname={"fullname": tpc.name+noteOctave, "name": tpc.raw+noteOctave, "raw": tpc.raw, "octave": noteOctave};
		
		// head
		var grp = note.headGroup?note.headGroup:0;
		note.headData = {name: "UNKOWN", image: "NONE.png"};
		for (var i = 0; i < heads.length; i++) {
			var head = heads[i];
                        console.log("----> "+grp+"--"+head.name+"--"+eval("NoteHeadGroup." + head.name));
			if (grp == eval("NoteHeadGroup." + head.name)) {
console.log("found "+head);
				note.headData = head;
				break;
			}
		}
		
		
		return;

	}
	// -----------------------------------------------------------------------
	// --- String extractors -------------------------------------------------
	// -----------------------------------------------------------------------
	function extractInstrument(category, sKeys) {
		var splt = sKeys.split('');
		var found;
		var instruments=categories[category]["instruments"];
		// on trie pour avoir les plus grand clés en 1er
		var sorted = Object.keys(instruments);
		sorted = sorted.sort(function (a, b) {
				var res = instruments[b]['base'].length - instruments[a]['base'].length;
				return res;
			});
		for (var i = 0; i < sorted.length; i++) {
			var instru = sorted[i];
			var root = instruments[instru]['base'];
			debug(level_DEBUG, instru + ":" + root);
			if (find(root, splt)) {
				debug(level_DEBUG, ">> found");
				found = instru;
				break;
			}
		}
		return found;
	}

	/**
	 * Verify if "what" is enterily contained in "within"
	 */
	function find(what, within) {
		var t,
		t2;
		//    if (b.length > a.length)
		//        t = b, b = a, a = t; // indexOf to loop over shorter
		// Je ne garde que ceux qui sont en commun dans les 2 arrays
		t = what.filter(function (e) {
				return within.indexOf(e) >  - 1;
			});
		// Je supprime de la chaîne à retrouver ce qu'il ya dans l'interection
		// Il ne devrait rien manquer, donc le résultat devrait être vide.
		t2 = what.filter(function (e) {
				return t.indexOf(e) ===  - 1;
			});
		return (t2.length === 0);
	}

	function doesIntersect(array1, array2) {
		var intersect = array1.filter(function (n) {
				return array2.indexOf(n) !== -1;
			});
		return intersect.length > 0;
	}

	// -----------------------------------------------------------------------
	// --- Screen design -----------------------------------------------------
	// -----------------------------------------------------------------------
	GridLayout {
		id : panMain
		rows : 7
		columns : 2

		anchors.fill : parent
		columnSpacing : 5
		rowSpacing : 5
		anchors.topMargin : 10
		anchors.rightMargin : 10
		anchors.leftMargin : 10
		anchors.bottomMargin : 5

		Item {
			Layout.row : 1
			Layout.column : 1
			Layout.columnSpan : 2
			Layout.rowSpan : 1

			id : panInstrument

			Layout.preferredHeight : lpc.implicitHeight + 4 // 4 pour les marges
			Layout.fillWidth : true
			RowLayout {
				id : lpc
				anchors.fill : parent
				anchors.margins : 2
				spacing : 2

				Label {
					text : "Instrument :"
					font.pointSize: titlePointSize
					leftPadding: 10
					rightPadding: 10
				}

				Loader {
					id: loadInstru
						Layout.fillWidth : true
						sourceComponent: (__modelInstruments.length<=1)?txtInstruCompo:lstInstruCompo
					}
				
				Text {
					text : "Config"
					horizontalAlignment : Qt.AlignRight
					rightPadding: 10
				}

				Loader {
					id : configOpenBtn
					Binding {
						target : configOpenBtn.item
						property : "panel"
						value : panConfig // should be a valid id
					}
					Binding {
						target : configOpenBtn.item
						property : "visible"
						value : (__config && __config.length > 0)
					}
					sourceComponent : openPanelComponent
				}
			}
		} //panInstrument


		ColumnLayout { // hack because the GridLayout doesn't manage well the invisible elements
			Layout.row : 2
			Layout.column : 2
			Layout.columnSpan : 1
			Layout.rowSpan : 4
			Layout.fillHeight : true
			Layout.fillWidth : true

			Rectangle {

				id : panConfig
				visible : false
				color : "#F0F0F0"
				//Layout.preferredWidth : layConfig.implicitWidth + 10
				Layout.fillWidth : true
				Layout.preferredHeight : layConfig.implicitHeight + 10
				anchors.margins : 20
				Grid {
					id : layConfig

					columns : 3
					columnSpacing : 5
					rowSpacing : 5

					Repeater {
						model : ready ? __config : []
						delegate : CheckBox {
							id : chkConfig
							property var __mode : __config[model.index]
							Layout.alignment : Qt.AlignLeft | Qt.QtAlignBottom
							text : __mode.name
							checked : __mode.activated // init only
							onClicked : {
								debug(level_TRACE, "onClik " + __mode.name);
								var before = __mode.activated;
								__mode.activated = !__mode.activated;
								buildConfigNotes();
								refreshed = false; // awful trick to force the refresh
								refreshed = true;
							}
						}

					}
				}
			} //panConfig


			Rectangle { 
				id : panKeys

				Layout.fillHeight : true
				Layout.fillWidth : true

				color : "#F0F0F0"
				clip: true

				Item { // un small element within the fullWidth/fullHeight where we paint the repeater
					anchors.horizontalCenter : parent.horizontalCenter
					anchors.verticalCenter : parent.verticalCenter
					width : 100 //repNotes.implicitHeight // 4 columns
					height : 240 // repNotes.implicitWidth // 12 rows


					// Repeater pour les notes de base
					Repeater {
						id : repNotes
						model : ready ? getNormalNotes(refreshed) : []; //awful hack. Just return the raw __config array
						//delegate : holeComponent - via Loader, pour passer la note à gérer
						Loader {
							id : loaderNotes
							Binding {
								target : loaderNotes.item
								property : "note"
								value : __instruments[currentInstrument]["keys"][model.index]
							}
							sourceComponent : holeComponent
						}
					}

					// Repeater pour les notes des __config
					Repeater {
						id : repModes
						model : ready ? getConfigNotes(refreshed) : []; //awful hack. Just return the raw __config array
						//delegate : holeComponent - via Loader, pour passer la note à gérer depuis le mode
						Loader {
							id : loaderModes
							Binding {
								target : loaderModes.item
								property : "note"
								value : __confignotes[model.index]// should be a note
							}
							sourceComponent : holeComponent
						}
					}
				}
			} //panKeys
			
		} // right column

		Item { // buttons row // DEBUG was Item
			Layout.row : 6
			Layout.column : 1
			Layout.columnSpan : 2
			Layout.rowSpan : 1
			Layout.fillWidth : true
			Layout.preferredHeight : panButtons.implicitHeight

			RowLayout {
				id : panButtons

				//Layout.alignment : Qt.AlignRight
				//Layout.fillWidth : true
				//anchors { left: parent.left; right: parent.right }
				anchors.fill: parent
				
				Button {
					implicitHeight : buttonBox.contentItem.height
					implicitWidth : buttonBox.contentItem.height

					indicator :
					Image {
						source : "alternatefingering/save.svg"
						width : 23
						fillMode : Image.PreserveAspectFit // ensure it fits
						mipmap : true // smoothing
						anchors.centerIn : parent
					}
					onClicked : saveOptions()
					
					
					ToolTip.text : "Save the options"
					hoverEnabled: true
					ToolTip.delay: tooltipShow
					ToolTip.timeout: tooltipHide
					ToolTip.visible: hovered				
				}

				Button {
					implicitHeight : buttonBox.contentItem.height
					implicitWidth : buttonBox.contentItem.height

					indicator :
					Image {
						source : "alternatefingering/settings.svg"
						mipmap : true // smoothing
						width : 23
						fillMode : Image.PreserveAspectFit // ensure it fits
						anchors.centerIn : parent
					}
					onClicked : optionsWindow.show()
					ToolTip.text : "Settings..."
					hoverEnabled: true
					ToolTip.delay: tooltipShow
					ToolTip.timeout: tooltipHide
					ToolTip.visible: hovered
				}

				Item { // spacer // DEBUG Item/Rectangle
					id: spacer
					implicitHeight : 10
					Layout.fillWidth : true
				}

				Button {
					text: "Remove fingerings..."
					implicitHeight : buttonBox.contentItem.height
					//implicitWidth : buttonBox.contentChildren[0].width
					onClicked: 
						confirmRemoveMissingDialog.open()
				}

				DialogButtonBox {
					standardButtons : DialogButtonBox.Close
					id : buttonBox

					background.opacity: 0 // hide default white background

					Button {
						text: "Add"
						DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
						}

					onAccepted : {
						writeFingering();
						Qt.quit();
						}
					onRejected : Qt.quit()

				}
			}
		} // button rows 
		
		Item { // status bar
			Layout.row : 7
			Layout.column : 1
			Layout.columnSpan : 2
			Layout.rowSpan : 1
			Layout.fillWidth : true
			Layout.preferredHeight : 15 //txtStatus.implicitHeight

			id : panStatusBar

			Text {
				id : txtStatus
				text : ""
				wrapMode : Text.NoWrap
				elide : Text.ElideRight
				maximumLineCount : 1
				anchors.left: parent.left
				anchors.right: txtNote.left
			}

			Text {
				id : txtNote
				text : (__notes.length>0)?__notes[0].extname.name:"--"
				anchors.right: txtNoteAcc.left
				leftPadding: 5
				rightPadding: 0
			}

			Image {
				id : txtNoteAcc
				source: "./alternatefingering/"+((__notes.length>0)?__notes[0].accidentalData.image:"NONE.png")
				fillMode : Image.PreserveAspectFit
				height : 20
				width : 20
				anchors.right: txtNoteHead.left
			}

			Image {
				id : txtNoteHead
				source: "./alternatefingering/"+((__notes.length>0)?__notes[0].headData.image:"NONE.png")
				fillMode : Image.PreserveAspectFit
				height : 20
				width : 20
				anchors.right: parent.right
			}

		} // status bar

		GroupBox {  
			title: "Favorites"+(chkFilterPreset.checkState  === Qt.Checked ? " (strict)" : chkFilterPreset.checkState  === Qt.PartiallyChecked ? " (similar)" : "")
			Layout.row : 2
			Layout.column : 1
			Layout.columnSpan : 1
			Layout.rowSpan : 4

			Layout.fillHeight : true
			
			anchors.rightMargin: 5
			anchors.topMargin: 10
			anchors.bottomMargin: 10
			//topPadding: 10

			ColumnLayout { // left column
				anchors.fill: parent
				spacing:10

				ListView { // Presets
					Layout.fillHeight : true
					//Layout.fillWidth : true
					width : 100

					id : lstPresets

					model : getPresetsLibrary(presetsRefreshed) //__library
					delegate : presetComponent
					clip : true
					focus : true

					// scrollbar
					flickableDirection : Flickable.VerticalFlick
					boundsBehavior : Flickable.StopAtBounds

					highlight : Rectangle {
						color : "lightsteelblue"
						width : lstPresets.width
					}
				} // presets

				Item { // preset buttons // DEBUG Item/Rectangle
					Layout.preferredHeight : panPresetActions.implicitHeight
					Layout.preferredWidth : panPresetActions.implicitWidth
					Layout.alignment : Qt.AlignVCenter | Qt.AlignHCenter

					// color : "violet"
					clip : true

					RowLayout {
						id : panPresetActions
						spacing : 2

						CheckBox {

							id : chkFilterPreset
							
							tristate: true

							padding : 0
							spacing : 0

							indicator : Rectangle {
								implicitHeight : buttonBox.contentItem.height * 0.6 //btnOk.height
								implicitWidth : buttonBox.contentItem.height * 0.6 //btnOk.height
								color : chkFilterPreset.pressed ? "#C0C0C0" : 
									chkFilterPreset.checkState  === Qt.Checked ? "#C0C0C0" : chkFilterPreset.checkState  === Qt.PartiallyChecked ? "#D0D0D0" : "#E0E0E0"
								anchors.centerIn : parent
								Image {
									id : imgFilter
									mipmap : true // smoothing
									width : 21  // 23, a little bit smaller
									source : "alternatefingering/filter.svg"
									fillMode : Image.PreserveAspectFit // ensure it fits
									anchors.centerIn : parent
								}
							}
							onClicked : {
								presetsRefreshed = false; // awfull hack
								presetsRefreshed = true;
							}

							ToolTip.text : "Show only the current note's favorites"
							hoverEnabled: true
							ToolTip.delay: tooltipShow
							ToolTip.timeout: tooltipHide
							ToolTip.visible: hovered				
							
						}

						Button {
							implicitHeight : buttonBox.contentItem.height * 0.6 //btnOk.height
							implicitWidth : buttonBox.contentItem.height * 0.6 //btnOk.height

							indicator :
							Image {
								source : "alternatefingering/add.svg"
								mipmap : true // smoothing
								width : 23
								fillMode : Image.PreserveAspectFit // ensure it fits
								anchors.centerIn : parent
							}
							onClicked : {
								var note = __notes[0];
								__asAPreset = new presetClass(__category, "", note.extname.name, note.accidentalData.name, buildFingeringRepresentation());
								debug(level_DEBUG, JSON.stringify(__asAPreset));
								addPresetWindow.state = "add"
								addPresetWindow.show()
							}
							ToolTip.text : "Add current keys combination as new favorite"
							hoverEnabled: true
							ToolTip.delay: tooltipShow
							ToolTip.timeout: tooltipHide
							ToolTip.visible: hovered				
						}

						Button {
							implicitHeight : buttonBox.contentItem.height * 0.6 //btnOk.height
							implicitWidth : buttonBox.contentItem.height * 0.6 //btnOk.height

                                                         enabled: (lstPresets.currentIndex>=0)
							
							indicator : 
							Image {
								source : "alternatefingering/delete.svg"
								mipmap : true // smoothing
								width : 23
								fillMode : Image.PreserveAspectFit // ensure it fits
								anchors.centerIn : parent
							}
							onClicked : {
								__asAPreset = lstPresets.model[lstPresets.currentIndex]
                                                                
									debug(level_DEBUG, JSON.stringify(__asAPreset));
								addPresetWindow.state = "remove"
									addPresetWindow.show()
							}
						ToolTip.text : "Remove the selected favorite"
						hoverEnabled: true
						ToolTip.delay: tooltipShow
						ToolTip.timeout: tooltipHide
						ToolTip.visible: hovered				
						}
					}
				} 
			} // left column
		}
	}
	// ----------------------------------------------------------------------
	// --- Screen support ---------------------------------------------------
	// ----------------------------------------------------------------------

	Component {
		id : openPanelComponent

		Image {
			id : btn
			property var panel
			source : "./alternatefingering/openpanel.svg"
			states : [
				State {
					when : panel.visible;
					PropertyChanges {
						target : btn;
						source : "./alternatefingering/closepanel.svg"
					}
				},
				State {
					when : !panel.visible;
					PropertyChanges {
						target : btn;
						source : "./alternatefingering/openpanel.svg"
					}
				}
			]

			MouseArea {
				anchors.fill : parent
				onClicked : {
					panel.visible = !panel.visible
				}
			}
		}

	}

	Component {
		id : holeComponent

		Image {
			id : img

			property var note

			x : note ? note.column * 20 : 0;
			y : note ? note.row * 20 : 0;
			scale : note ? note.size : 1;

			source : "./alternatefingering/open.svg"

			states : [
				State {
					name : "open"
					PropertyChanges {
						target : img;
						source : "./alternatefingering/open.svg"
					}
				},
				State {
					name : "closed"
					PropertyChanges {
						target : img;
						source : "./alternatefingering/closed.svg"
					}
				},
				State {
					name : "left"
					PropertyChanges {
						target : img;
						source : "./alternatefingering/left.svg"
					}
				},
				State {
					name : "right"
					PropertyChanges {
						target : img;
						source : "./alternatefingering/right.svg"
					}
				},
				State {
					name : "halfleft"
					PropertyChanges {
						target : img;
						source : "./alternatefingering/quarterleft.svg"
					}
				},
				State {
					name : "halfright"
					PropertyChanges {
						target : img;
						source : "./alternatefingering/quarterright.svg"
					}
				},
				State {
					name : "ring"
					PropertyChanges {
						target : img;
						source : "./alternatefingering/ring.svg"
					}
				},
				State {
					name : "thrill"
					PropertyChanges {
						target : img;
						source : "./alternatefingering/thrill.svg"
					}
				},
				State {
					name : "deactivated"
					PropertyChanges { 
						target : img;
						source : "./alternatefingering/deactivated.svg"
					}
				}
			]

			state : note ? (note.deactivated ? "deactivated" : note.currentMode) : "deactivated" // initial state

			MouseArea {
				anchors.fill : parent
				onClicked : {
					if (note.deactivated) { // temp. On devrait résoudre ça via mode.activated seulement
						parent.state = "deactivated"; // temp en attendant de résoudre le problème de binding
						return;
					}
					var keystates = Object.keys(note.modes);
					// Object.keys ne préserve pas l'ordre, donc je repars de la array des états.
					var states = usedstates.filter(function (e) {
							return keystates.indexOf(e) >  - 1;
						});

					var nextIndex = (states.indexOf(parent.state) + 1) % states.length;
					note.currentMode = states[nextIndex];
					// l'instruction au-dessus devrait suffire, mais le binding ne va s'en doute pas aussi loin
					parent.state = states[nextIndex];
					debugV(level_TRACE, "note", "current state", note.currentMode);
					debugV(level_TRACE, "note", "current state", parent.state);

				}

				ToolTip.text : note.name
				hoverEnabled: true
				ToolTip.delay: tooltipShow
				ToolTip.timeout: tooltipHide
				ToolTip.visible: containsMouse // "hovered" does not work for MouseArea
			}
		}
	}

	Component {
		id : presetComponent

		Item {
			width : parent.width
			height : 100 //prsRep.implictHeight+prsLab.implictHeight+prsNote.implictHeight
			clip : true

			readonly property ListView __lv : ListView.view

			property var __preset : __lv.model[model.index]//__library[model.index]


			Text {
				id : prsRep
				text : __preset.representation

				anchors {
					top : parent.top
					left : parent.left
					rightMargin : 5
					leftMargin : 10
				}

				font.family : "fiati"
				font.pixelSize : 60
				renderType : Text.NativeRendering
				font.hintingPreference : Font.PreferVerticalHinting

				onLineLaidOut : { // hack for correct display of Fiati font
					line.y = line.y * 0.8
					line.height = line.height * 0.8
				}

			}

			Text {
				id : prsLab
				text : __preset.label
				visible : (__preset.label && __preset.label !== "")
				height : (visible) ? parent.height / 2 : 0
				width : (parent.width - 35) //prsRep.width)
				horizontalAlignment : Text.AlignHCenter
				verticalAlignment : Text.AlignBottom
				elide : Text.ElideRight
				wrapMode : Text.Wrap
				anchors {
					right : parent.right
					bottom : parent.verticalCenter
					margins : 2
				}
			}

			Text {
				id : prsNote
				text : __preset.note
				//width:(parent.width-prsRep.width)/2
				width : (parent.width - 35) / 2
				horizontalAlignment : Text.AlignRight
				anchors {
					left : prsLab.left
					top : prsLab.bottom
				}
			}

			Image {
				id : prsAcc
				source : "./alternatefingering/" + getAccidentalImage(__preset.accidental)
				fillMode : Image.PreserveAspectFit
				height : 20
				width : 20
				anchors {
					left : prsNote.right
					top : prsLab.bottom
				}
			}

			MouseArea {
				anchors.fill : parent;
				acceptedButtons : Qt.LeftButton

				onDoubleClicked : {
					pushFingering(__preset.representation);
				}

				onClicked : {
					__lv.currentIndex = index;
				}

							ToolTip.text : __preset.label
							hoverEnabled: true
							ToolTip.delay: tooltipShow
							ToolTip.timeout: tooltipHide
							ToolTip.visible: containsMouse && __preset.label && __preset.label !== ""// "hovered" does not work for MouseArea

			}
		}

	}

	Component {
		id : lstInstruCompo
		ComboBox {
			id : lstInstru
			model : __modelInstruments 
			currentIndex : { { __modelInstruments.indexOf(currentInstrument) } } 
			clip : true
			focus : true
			width : parent.width
			height : 20
			//color :"lightgrey"
			anchors {
				top : parent.top
				fill : parent
			}
			contentItem : Text {
				text: (__modelInstruments[currentIndex])?__modelInstruments[currentIndex]:"--"
				font.pointSize: titlePointSize
				verticalAlignment: Qt.AlignVCenter
			}

			onCurrentIndexChanged : {
				debug(level_DEBUG, "Now current index is :" + model[currentIndex])
				currentInstrument = model[currentIndex];
			}

		}

	}

	Component {
		id : txtInstruCompo
		Text {
			id : txtInstru
			text : __modelInstruments[0]
			font.pointSize: titlePointSize
			anchors {
				//top : parent.top
				fill : parent
			}
			verticalAlignment : Text.AlignVCenter
			horizontalAlignment : Text.AlignLeft

		}

	}
	MessageDialog {
		id : unkownInstrumentDialog
		icon : StandardIcon.Warning
		standardButtons : StandardButton.Ok
		title : 'Unknown Instrument!'
		text : 'The staff instrument is not a valid intrument'
		detailedText : 'Alternate Fingering only manages \'wind.flutes.flute\''
		onAccepted : {
			Qt.quit()
		}
	}
	MessageDialog {
		id : invalidSelectionDialog
		icon : StandardIcon.Warning
		standardButtons : StandardButton.Ok
		title : 'Invalid Selection!'
		text : 'The selection is not valid'
		detailedText : 'At least one note must be selected, and all the notes must of the same instrument.'
		onAccepted : {
			Qt.quit()
		}
	}

	MessageDialog {
		id : fontMissingDialog
		icon : StandardIcon.Question
		standardButtons : StandardButton.Ok
		title : 'Missing Fiati music font!'
		text : 'The Fiati music font is not installed on your device.'
		detailedText : 'You can download the font from here:\n' +
		'https://github.com/eduardomourar/fiati/releases\n\n' +
		'The Zip file contains the font file you need to install on your device.\n' +
		'You will also need to restart MuseScore for it to recognize the new font.'
		onAccepted : {
			Qt.quit()
		}
	}

	MessageDialog {
		id : confirmRemoveMissingDialog
		icon : StandardIcon.Warning
		standardButtons : StandardButton.Yes | StandardButton.No
		title : 'Confirm '
		text : 'Do you confirm the deletion of the fingerings of the '+__notes.length+' selected note'+(__notes.length>1?'s':'')+' ?'
		onYes : {
			var res=removeAllFingerings();
			if (res.nbdeleted>0) txtStatus.text=res.nbnotes+" note"+(res.nbnotes>1?"s":"")+" treated; "+res.nbdeleted+" fingering"+(res.deleted>1?"s":"")+" deleted";
			else txtStatus.text="No fingerings deleted";
			confirmRemoveMissingDialog.close();
			
		}
		onNo: confirmRemoveMissingDialog.close();
	}

	Window {
		id : optionsWindow
		title : "Options..."
		width : 400
		height : 400
		modality : Qt.WindowModal
		flags : Qt.Dialog | Qt.WindowSystemMenuHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
		//color: "#E3E3E3"

		ColumnLayout {

			anchors.fill : parent
			spacing : 5
			anchors.margins : 5

			Text {
				Layout.fillWidth: true
				verticalAlignment : Text.AlignVCenter
				horizontalAlignment : Text.AlignHCenter
				font.pointSize: 12
				text : 'Alternate Fingerings'
			}

			Text {
				Layout.fillWidth: true
				verticalAlignment : Text.AlignVCenter
				horizontalAlignment : Text.AlignHCenter
				font.pointSize: 9
				topPadding: -5
				bottomPadding: 15
				text : 'by <a href="https://www.laurentvanroy.be/" title="Laurent van Roy">Laurent van Roy</a>'
				onLinkActivated: Qt.openUrlExternally(link)
			}
			
			
			Rectangle {
				Layout.preferredHeight : txtOptFing.implicitHeight + 4 // 4 pour les marges
				Layout.fillWidth : true
				color: "#C0C0C0"
				
				Text {
					id : txtOptFing
					text : "Fingering optionss"
					Layout.fillWidth : true
					rightPadding: 5
					leftPadding: 5
					horizontalAlignment : Qt.AlignLeft
				}
				
			}
			Rectangle { 
				color : "#F0F0F0"
				Layout.fillWidth : true
				Layout.fillHeight: true
				anchors.margins : 20
				Flow {
					anchors.fill: parent

					CheckBox {
						id : chkTechnicHalf
						Layout.alignment : Qt.AlignLeft | Qt.QtAlignBottom
						text : "Include playing half holes"
						onClicked : onTechnicOptionClicked()
						checked : false;
					}
					CheckBox {
						id : chkTechnicQuarter
						Layout.alignment : Qt.AlignLeft | Qt.QtAlignBottom
						text : "Include playing quarter holes"
						onClicked : onTechnicOptionClicked()
						checked : false;
					}
					CheckBox {
						id : chkTechnicRing
						Layout.alignment : Qt.AlignLeft | Qt.QtAlignBottom
						text : "Include playing ring"
						onClicked : onTechnicOptionClicked()
						checked : false;
					}
					CheckBox {
						id : chkTechnicThrill
						Layout.alignment : Qt.AlignLeft | Qt.QtAlignBottom
						text : "Include thrill keys"
						onClicked : onTechnicOptionClicked()
						checked : true;
					}
				}
			} 
	
			Rectangle {
				Layout.preferredHeight : txtOptMisc.implicitHeight + 4 // 4 pour les marges
				Layout.fillWidth : true
				color: "#C0C0C0"
				
				Text {
					id : txtOptMisc
					text : "Misc. optionss"
					Layout.fillWidth : true
					horizontalAlignment : Qt.AlignLeft
					rightPadding: 5
					leftPadding: 5
				}
				
			}
			Rectangle { 
				color : "#F0F0F0"
				Layout.fillWidth : true
				Layout.fillHeight: true
				anchors.margins : 20
				Flow {
					anchors.fill: parent
					CheckBox {
						id : chkEquivAccidental
						Layout.alignment : Qt.AlignLeft | Qt.QtAlignBottom
						text : "Accidental equivalence in presets "
						onClicked : { presetsRefreshed=false; presetsRefreshed=true; } // awfull hack 
						checked : true;
					}
				}
			} 
	

			DialogButtonBox {
				id: opionsButtonBox
				Layout.alignment : Qt.AlignHCenter
				Layout.fillWidth : true
				background.opacity : 0 // hide default white background
				standardButtons : DialogButtonBox.Close //| DialogButtonBox.Save
				onRejected : optionsWindow.hide()
				onAccepted: { saveOptions(); optionsWindow.hide() }
			}
			
			Text {
				Layout.fillWidth: true
				verticalAlignment : Text.AlignVCenter
				horizontalAlignment : Text.AlignHCenter
				font.pointSize: 10

				text : 'Icons made by <a href="https://www.flaticon.com/authors/hirschwolf" title="hirschwolf">hirschwolf</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a>'
				
				wrapMode: Text.Wrap
				
				onLinkActivated: Qt.openUrlExternally(link)

			}
			

		}
	}
      
	Window {
		id : addPresetWindow
		title : "Manage Library..."
		width : 250
		height : 350
		modality : Qt.WindowModal
		flags : Qt.Dialog | Qt.WindowSystemMenuHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
		
		property string state: "remove"

		Item {
			anchors.fill: parent

                        state: addPresetWindow.state
			
			states : [
				State {
					name : "remove";
					PropertyChanges { target : btnEpAdd; text : "Remove" }
					PropertyChanges { target : labEpCat; text : "Delete the following " + __asAPreset.category + " preset ?" }
					PropertyChanges { target : labEpLabVal; readOnly : true }
					PropertyChanges { target : labEpNoteVal; readOnly : true }
					PropertyChanges { target : lstEpAcc; enabled : false }
					
				},
				State {
					name : "add";
					PropertyChanges { target : btnEpAdd; text : "Add" }
					PropertyChanges { target : labEpCat; text : "Add the new " + __asAPreset.category + " preset : " }
					PropertyChanges { target : labEpLabVal; readOnly : false }
					PropertyChanges { target : labEpNoteVal; readOnly : false }
					PropertyChanges { target : lstEpAcc; enabled : true }
					
				}
			]
			
			GridLayout {
				columns: 2
				rows : 5

				anchors.fill : parent
				columnSpacing : 5
				rowSpacing : 5
				anchors.margins : 10

				Text {
					Layout.row: 1
					Layout.column: 1
					Layout.columnSpan: 2
					Layout.rowSpan: 1

					id : labEpCat

					Layout.preferredWidth : parent.width
					Layout.preferredHeight : 20

					text : "--"

					font.weight : Font.DemiBold
					verticalAlignment : Text.AlignVCenter
					horizontalAlignment : Text.AlignLeft
					font.pointSize: 11

				}

				Rectangle { // se passer du rectangle ???
					Layout.row: 2
					Layout.column: 1
					Layout.columnSpan: 2
					Layout.rowSpan: 1

					Layout.fillWidth : true
					Layout.fillHeight : true

					Text {
						anchors.fill: parent            
						id : labEpRep

						text : __asAPreset.representation

						font.family : "fiati"
											font.pixelSize : 100

						renderType : Text.NativeRendering
						font.hintingPreference : Font.PreferVerticalHinting
						verticalAlignment : Text.AlignTop
						horizontalAlignment : Text.AlignHCenter

						onLineLaidOut: { // hack for correct display of Fiati font
							line.y = line.y * 0.8
							line.height = line.height * 0.8
							line.x = line.x - 7
							line.width = line.width - 7
						}
					}
				}


				Label {
					Layout.row: 3
					Layout.column: 1
					Layout.columnSpan: 1
					Layout.rowSpan: 1

					id : labEpLab

					text : "Label:"

					Layout.preferredHeight : 20

				}

				TextField {
					Layout.row: 3
					Layout.column: 2
					Layout.columnSpan: 1
					Layout.rowSpan: 1

					id : labEpLabVal

					text : __asAPreset.label

					Layout.preferredHeight : 30
										Layout.fillWidth: true  
										placeholderText : "label text (optional)" 
										maximumLength : 255 

				}


				Label {
					Layout.row: 4
					Layout.column: 1
					Layout.columnSpan: 1
					Layout.rowSpan: 1

					id : labEpKey

					text : "For key:"

					Layout.preferredHeight : 20


				}
			
				RowLayout {
					Layout.row : 4
					Layout.column : 2
					Layout.columnSpan : 1
					Layout.rowSpan : 1

//					Layout.preferredHeight : 20
					Layout.fillWidth : false

					TextField {

						id : labEpNoteVal

						text : __asAPreset.note

						//inputMask: "A9"
						validator : RegExpValidator {regExp : /^[A-G][0-9]$/}
						maximumLength : 2
						placeholderText : "e.g. \"C4\""
						Layout.preferredHeight: 30
						Layout.preferredWidth: 40

					}

					ComboBox {
						id : lstEpAcc
						//Layout.fillWidth : true
						model : accidentals
						currentIndex : visible?getAccidentalModelIndex(__asAPreset.accidental):0 

						clip : true
						focus : true
						Layout.preferredHeight: 30
						Layout.preferredWidth: 80

						delegate : ItemDelegate { // requiert QuickControls 2.2
							contentItem : Image {
								height : 25
								width : 25
								source : "./alternatefingering/" + accidentals[index].image
								fillMode : Image.Pad
								verticalAlignment : Text.AlignVCenter
							}
							highlighted : lstEpAcc.highlightedIndex === index

						}

						contentItem : Image {
							id : img
							height : 25
							width : 25
							fillMode : Image.Pad
							source : "./alternatefingering/" + accidentals[lstEpAcc.currentIndex].image
						}
					}

				}
				DialogButtonBox {
					Layout.row : 5
					Layout.column : 1
					Layout.columnSpan : 2
					Layout.rowSpan : 1
					Layout.alignment: Qt.AlignRight

					background.opacity: 0 // hide default white background

					standardButtons: DialogButtonBox.Cancel
					Button {
						id: btnEpAdd
						text: "--"
						DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
					}

					onAccepted: {
						if ("remove"===addPresetWindow.state) {
							// remove
							for (var i = 0; i < __library.length; i++) {
								var p = __library[i];
								if ((p.category === __asAPreset.category) &&
									(p.label === __asAPreset.label) &&
									(p.note === __asAPreset.note) &&
									(p.accidental === __asAPreset.accidental) &&
									(p.representation === __asAPreset.representation)) {
									__library.splice(i, 1);
									break;
								}
							}
							addPresetWindow.hide();
							}
							else {
							// add
							var preset=new presetClass(__asAPreset.category, labEpLabVal.text, labEpNoteVal.text, lstEpAcc.model[lstEpAcc.currentIndex].name, __asAPreset.representation);
							__library.push(preset);
							addPresetWindow.hide();
						}
					  presetsRefreshed=false; // awfull hack
					  presetsRefreshed=true;
					  saveLibrary();
					}
					onRejected: addPresetWindow.hide()

				}
			}
		}
	}
	// ----------------------------------------------------------------------
	// --- Screen support ---------------------------------------------------
	// ----------------------------------------------------------------------

	function onTechnicOptionClicked() {
		usedstates = [].concat(
			basestates,
			chkTechnicHalf.checked ? halfstates : [],
			chkTechnicQuarter.checked ? quarterstates : [
			],
			chkTechnicRing.checked ? ringstates : [],
			chkTechnicThrill.checked ? thrillstates : []);
	}

	/**
	 * @return the raw notes array of the current instrument.
	 */
	function getNormalNotes(refresh) { // refresh is just meant for the "awful hack" ;-)
		return (__instruments[currentInstrument]) ? __instruments[currentInstrument]["keys"] : [];
	}

	/**
	 * @return the raw __confignotes array *without* any treatment. This way, in the repeater, we can
	 * acces the right mode by just writing __confignotes[model.index].
	 */
	function getConfigNotes(refresh) { // refresh is just meant for the "awful hack" ;-)
		for (var k = 0; k < __confignotes.length; k++) {
			var n = __confignotes[k];
			debug(level_TRACE, "getConfigNotes: " + n.name + " " + n.currentMode);
		}
		debug(level_TRACE, "getConfigNotes: " + __confignotes.length);
		return __confignotes;
	}

	function buildConfigNotes() {
		var notes = [];
		for (var i = 0; i < __config.length; i++) {
			var config = __config[i];
			if (config.activated) {
				for (var k = 0; k < config.notes.length; k++) {
					var note = config.notes[k];
					notes[notes.length++] = note;
					debug(level_TRACE, "buildConfigNotes: " + note.name + " " + note.currentMode);
				}
			}
		}
		debug(level_TRACE, "buildConfigNotes: " + notes.length);
		__confignotes = notes;
	}

        function getPresetsLibrary(refresh) { // refresh is just meant for the "awful hack" ;-)
            var note=__notes[0];
            if (chkFilterPreset.checkState === Qt.Unchecked) {
				// everything
                  return __library;
            } else if (chkFilterPreset.checkState === Qt.Checked) {
				// strong filter (on note and accidental)
				  var useEquiv=chkEquivAccidental.checked;
                  var lib=[];
                  for(var i=0;i<__library.length;i++) {
                        var preset=__library[i];
                        debug(level_TRACE, preset.label+note.extname.name+";"+preset.note+";"+note.accidentalData.name+";"+preset.accidental);
                        if ((note.extname.name===preset.note && (note.accidentalData.name===preset.accidental || (useEquiv && isEquivAccidental(note.accidentalData.name,preset.accidental))))
                        || (""===preset.note && "NONE"===preset.accidental)) {
                              lib.push(preset);
                        } 
                  }
                  return lib;
            } else  {
				// loose filter (on note only)
                  var lib=[];
                  for(var i=0;i<__library.length;i++) {
                        var preset=__library[i];
                        debug(level_TRACE, preset.label+note.extname.name+";"+preset.note+";"+note.accidentalData.name+";"+preset.accidental);
                        if ((note.extname.name===preset.note)
                        || (""===preset.note && "NONE"===preset.accidental)) {
                              lib.push(preset);
                        } 
                  }
                  return lib;
            }
        
	}
	function getAccidentalModelIndex(accidentalName) {
		for(var i=0;i<accidentals.length;i++) {
			if (accidentalName===accidentals[i].name) {
				return i;
				}
			}
		return 0;
	}

      function getAccidentalImage(accidentalName) {
		for(var i=0;i<accidentals.length;i++) {
			if (accidentalName===accidentals[i].name) {
				return accidentals[i].image;
				}
			}
		return "NONE.png";
	}

	// -----------------------------------------------------------------------
	// --- Property File -----------------------------------------------------
	// -----------------------------------------------------------------------
    FileIO {
        id: settingsFile
        source: homePath() + "/alternatefingering.properties"
        //source: rootPath() + "/alternatefingering.properties"
        //source: Qt.resolvedUrl("alternatefingering.properties")
        //source: "./alternatefingering.properties"
            
        onError: {
			//statusBar.text=msg;
        }
    }
    FileIO {
        id: libraryFile
        source: homePath() + "/alternatefingering.library"
        //source: rootPath() + "/alternatefingering.properties"
        //source: Qt.resolvedUrl("alternatefingering.properties")
        //source: "./alternatefingering.properties"
            
        onError: {
			//statusBar.text=msg;
        }
    }
      
	function saveOptions() {

		if (typeof lastoptions === 'undefined') {
			lastoptions = {};
		}

		// used states
		lastoptions['states'] = usedstates;
		
		// preset filter
		if (chkFilterPreset.checkState === Qt.Unchecked) {
			// everything
			lastoptions['filter'] = "false";
		} else if (chkFilterPreset.checkState === Qt.Checked) {
			// strong filter
			lastoptions['filter'] = "true";
		} else {
			// loose filter
			lastoptions['filter'] = "partial";
		}

		// accidental equivalence
		lastoptions['equivalence'] = chkEquivAccidental.checked		
		
		
		// instruments config
		if (typeof lastoptions['categories'] === 'undefined') {
			lastoptions['categories'] = {};
		}

		lastoptions['categories'][__category] = {
			'default' : currentInstrument
		};

		var cfgs = [];
		for (var i = 0; i < __config.length; i++) {
			var config = __config[i];
			cfgs[i] = {
				name : config.name,
				activated : config.activated
			};
		}
		lastoptions['categories'][__category]['config'] = cfgs;
		
		var t = JSON.stringify(lastoptions) + "\n";
		debug(level_DEBUG, t);

		if (settingsFile.write(t)){
			txtStatus.text="Settings saved to " + settingsFile.source;
		}
		else {
			txtStatus.text="Error while saving the settings";
		}
				
		
	}

	function saveLibrary() {

                var allpresets={};
                
                var cats=Object.keys(categories);
                
                for(var c=0;c<cats.length;c++) {
                  var cat=cats[c];
                  allpresets[cat]=categories[cat]['library'];
                  }

		var t = JSON.stringify(allpresets) + "\n";
		debug(level_DEBUG, t);

		if (libraryFile.write(t)){
			//txtStatus.text="Library saved to " + libraryFile.source;
			txtStatus.text="";
		}
		else {
			txtStatus.text="Error while saving the library";
		}
				
		
	}

	function readOptions() {
	
		/*try {
                        console.log("Current "+currentPath());
                        } catch (e) {
                        console.log("Current "+e.message);
                        }
		try {
		console.log("Root "+rootPath());
                        } catch (e) {
                        console.log("Root "+e.message);
                        }
		try {
		console.log("Home "+homePath());
                        } catch (e) {
                        console.log("Home "+e.message);
                        }
		try {
		console.log("Temp "+tempPath());
                        } catch (e) {
                        console.log("Temp "+e.message);
                        }

                try {
		console.log("Settings "+settingsFile.source);
                        } catch (e) {
                        console.log("Settings "+e.message);
                        }*/
	
		if (!settingsFile.exists()) return;
		
		var json = settingsFile.read();

		
		try {
			lastoptions = JSON.parse(json);
		} catch (e) {
				console.error('while reading the option file', e.message);		
		}
		
		// used states
		usedstates = lastoptions['states'];
		displayUsedStates();

		// preset filter
		var filter = lastoptions['filter'];
		if (filter === "false") {
			// everything
			chkFilterPreset.checkState = Qt.Unchecked;
		} else if (filter === "true") {
			// strong filter
			chkFilterPreset.checkState = Qt.Checked;
		} else {
			// loose filter
			chkFilterPreset.checkState = Qt.PartiallyChecked
		}

		// accidental equivalence
		chkEquivAccidental.checked=(lastoptions['equivalence']==="true");	
		

		// instruments config
		var cats = Object.keys(lastoptions['categories']);
		for (var j = 0; j < cats.length; j++) {
			var cat = cats[j];
			var desc = lastoptions['categories'][cat];
			
			// default instrument
			categories[cat].default = desc.default;
			debug(level_DEBUG, "readOptions: " + cat + " -- " + desc.default);

			// config options
			var cfgs = desc['config'];
			for (var k = 0; k < cfgs.length; k++) {
				var cfg = cfgs[k];
				debug(level_DEBUG, "readOptions: " + cfg.name + " --> " + cfg.activated);

				for (var l = 0; l < categories[cat]['config'].length; l++) {
					var c = categories[cat]['config'][l];
					if (c.name == cfg.name) {
						c.activated = cfg.activated;
						debug(level_DEBUG, "readOptions: setting " + c.name + " --> " + c.activated);
					}
				}
			}
		}
                
	}
	
	function readLibrary() {
	
		if (!libraryFile.exists()) return;
		
		var json = libraryFile.read();

		var allpresets={};      
		
		try {
			allpresets = JSON.parse(json);
		} catch (e) {
				console.error('while reading the library file', e.message);		
		}
		
		var cats=Object.keys(categories);
		
		for(var c=0;c<cats.length;c++) {
		  var cat=cats[c];
		  categories[cat]['library']=allpresets[cat];
		  }

	}
	
	

	function displayUsedStates() {
		chkTechnicHalf.checked = doesIntersect(usedstates, halfstates);
		chkTechnicQuarter.checked = doesIntersect(usedstates, quarterstates);
		chkTechnicRing.checked = doesIntersect(usedstates, ringstates);
		chkTechnicThrill.checked = doesIntersect(usedstates, thrillstates);
		if (usedstates.indexOf("open") == -1)
			usedstates.push("open");
		if (usedstates.indexOf("closed") == -1)
			usedstates.push("closed");

	}
	// -----------------------------------------------------------------------
	// --- Instruments -------------------------------------------------------
	// -----------------------------------------------------------------------

	property double cA: 2
	property double cB: 3
	property double cC: 2.1
	property double cD: 4
	property double cE: 3.8
	property double cF: 1.2
	property double cG: 4.5
	property double cH: 1
	
	property var flbflat : new noteClass4("L Bb", {
		'closed' : '\uE006',
		'thrill' : '\uE03C'
	}, cA, 1.5);
	property var flb : new noteClass4("L B", {
		'closed' : '\uE007',
		'thrill' : '\uE03D'
	}, cA, 2.5);
	property var fl1 : new noteClass4("L1", {
		'closed' : '\uE008',
		'left' : '\uE024',
		'right' : '\uE02A',
		'halfleft' : '\uE030',
		'halfright' : '\uE036',
		'thrill' : '\uE03E'
	}, cB, 1);
	property var fl2 : new noteClass4("L2", {
		'closed' : '\uE009',
		'ring' : '\uE01F',
		'left' : '\uE025',
		'right' : '\uE02B',
		'halfleft' : '\uE031',
		'halfright' : '\uE037',
		'thrill' : '\uE03F'
	}, cB, 2, 1);
	property var fl3 : new noteClass4("L3", {
		'closed' : '\uE00A',
		'ring' : '\uE020',
		'left' : '\uE026',
		'right' : '\uE02C',
		'halfleft' : '\uE032',
		'halfright' : '\uE038',
		'thrill' : '\uE040'
	}, cB, 3);
	property var fgsharp : new noteClass4("G #", {
		'closed' : '\uE00B',
		'thrill' : '\uE041'
	}, cD, 3.5);
	property var fcsharptrill : new noteClass4("C # trill", {
		'closed' : '\uE00C',
		'thrill' : '\uE042'
	}, cB, 4.2, 0.8);
	property var frbflat : new noteClass4("Bb trill", {
		'closed' : '\uE00D',
		'thrill' : '\uE043'
	}, cC, 4.5, 0.8);
	property var fr1 : new noteClass4("R1", {
		'closed' : '\uE00E',
		'ring' : '\uE021',
		'left' : '\uE027',
		'right' : '\uE02D',
		'halfleft' : '\uE033',
		'halfright' : '\uE039',
		'thrill' : '\uE044'
	}, cB, 5);
	property var fdtrill : new noteClass4("D trill", {
		'closed' : '\uE00F',
		'thrill' : '\uE045'
	}, cC, 5.5, 0.8);
	property var fr2 : new noteClass4("R2", {
		'closed' : '\uE010',
		'ring' : '\uE022',
		'left' : '\uE028',
		'right' : '\uE02E',
		'halfleft' : '\uE034',
		'halfright' : '\uE03A',
		'thrill' : '\uE046'
	}, cB, 6);
	property var fdsharptrill : new noteClass4("D # trill", {
		'closed' : '\uE011',
		'thrill' : '\uE047'
	}, cC, 6.5, 0.8);
	property var fr3 : new noteClass4("R3", {
		'closed' : '\uE012',
		'ring' : '\uE023',
		'left' : '\uE029',
		'right' : '\uE02F',
		'halfleft' : '\uE035',
		'halfright' : '\uE03B',
		'thrill' : '\uE048'
	}, cB, 7);
	property var fe : new noteClass4("Low E", {
		'closed' : '\uE013',
		'thrill' : '\uE049'
	}, cA, 8);
	property var fcsharp : new noteClass4("Low C #", {
		'closed' : '\uE014',
		'thrill' : '\uE04A'
	}, cA, 9);
	property var fc : new noteClass4("Low C", {
		'closed' : '\uE015',
		'thrill' : '\uE04B'
	}, cB, 9);
	property var fbflat : new noteClass4("Low Bb", {
		'closed' : '\uE016',
		'thrill' : '\uE04C'
	}, cD, 9);
	property var fgizmo : new noteClass4("Gizmo", {
		"closed" : "\uE017",
		"thrill" : "\uE04D"
	}, cD, 10, 0.8);

	property var fKCUpLever : new noteClass4("fKCUpLever", {
		'closed' : '\uE018',
		'thrill' : '\uE04E'
	}, cE, 1.5, 0.8);
	property var fKAuxCSharpTrill : new noteClass4("fKAuxCSharpTrill", {
		'closed' : '\uE019',
		'thrill' : '\uE04F'
	}, cE, 2.5, 0.8);
	property var fKBbUpLever : new noteClass4("fKBbUpLever", {
		'closed' : '\uE01A',
		'thrill' : '\uE050'
	}, cF, 1, 0.8);
	property var fKBUpLever : new noteClass4("fKBUpLever", {
		'closed' : '\uE01B',
		'thrill' : '\uE051'
	}, cF, 2, 0.8);
	property var fKGUpLever : new noteClass4("fKGUpLever", {
		'closed' : '\uE01C',
		'thrill' : '\uE052'
	}, cG, 4.5, 0.8);
	property var fKFSharpBar : new noteClass4("fKFSharpBar", {
		'closed' : '\uE01D',
		'thrill' : '\uE053'
	}, cH, 5, 0.8);
	property var fKDUpLever : new noteClass4("fKDUpLever", {
		'closed' : '\uE01E',
		'thrill' : '\uE054'
	}, cA, 10, 0.8);

	property var categories : {
		"flute" : {
			// *User instructions*: Modify the default instrument here. Use any of the instruments listed below.
			"default" : "flute",
			"config" : [
				// *User instructions*: Modify the last false/true parameter in the
				// instrumentConfig class to control the default activation of this configuration
				new instrumentConfigClass("B tail", '\uE002', fbflat, false),
				new instrumentConfigClass("C# thrill", '\uE003', fcsharptrill, false),
				new instrumentConfigClass("OpenHole", '\uE004', [], false) // no associated notes with the OpenHole config
				//,new instrumentConfigClass("Kingma System", '\uE005', [fKCUpLever,fKAuxCSharpTrill,fKBbUpLever,fKBUpLever,fKGUpLever,fKFSharpBar,fKDUpLever],false),  // errors at the glypths level

			],
			"support" : [
				'wind.flutes'
			],
			"instruments" : {
/*				"flute with B tail" : {
					"base" : ['\uE000', '\uE001', '\uE002'], // B
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fbflat, fgizmo]
				},*/
				"Flute" : {
					"base" : ['\uE000', '\uE001'], // C
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fgizmo]
				}
			},
			"library": []
		},
		// unused - in progress
		"clarinet" : {
			"default" : "clarinet",
			"config" : [],
			"support" : [],
			"instruments" : {
				"clarinet" : {
					"base" : ['\uE000', '\uE001', '\uE002', '\uE003'], // B + C thrill,
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, fcsharptrill, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fbflat]
				}
			},
			"library": []
		},
		// default and empty category
		"" : {
			"default" : "",
			"config" : [],
			"support" : [],
			"instruments" : {
				"" : {
					"base" : [],
					"keys" : []
				}
			},
			"library": []
		}

	};

	/**
	 * A class representating an instrument key, that can be open/closed.
	 * With default size (=1).
	 * @param name The name of the key (e.g. for the tooltip)
	 * @param representation The glypth used in the Fiati font to display this key as closed
	 * @ param row, colum where to put that key in the diagram
	 * @return a note/key object
	 */
	function noteClass(name, representation, column, row) {
		noteClass2.call(this, name, representation, column, row, 1);
	}

	/**
	 * A class representating an instrument key, that can be open/closed.
	 * @param name The name of the key (e.g. for the tooltip)
	 * @param representation The glypth used in the Fiati font to display this key as closed
	 * @param row, colum Where to put that key in the diagram
	 * @param size The size of the key on the diagram
	 * @return a note/key object
	 */
	function noteClass2(name, representation, column, row, size) {
		noteClass4.call(this, name, {
			"closed" : representation
		}, column, row, size);
		this.representation = representation;
	}

	/**
	 * A class representating an instrument key, that can be open/closed/hal-fclosed/...
	 * @param name The name of the key (e.g. for the tooltip)
	 * @param modes An array of all the availble closure modes for that key with they corresponding glypth in the Fiati font.
	 * E.g. {"closed" : '\uE012', "thrill": '\uE013'}
	 * If not present, the "open" mode will be added with an empty representation
	 * @param row, colum Where to put that key in the diagram
	 * @param size The size of the key on the diagram
	 * @return a note/key object
	 */
	function noteClass4(name, xmodes, column, row, size) {
		this.name = name;
		this.modes = xmodes;
		if (!this.modes.open) {
			// ajoute un mode "open" s'il n'y en a pas
			this.modes.open = '';
		}

		this.currentMode = "open";
		this.deactivated = false; // temp
		this.row = row;
		this.column = column;
		this.size = ((typeof size !== 'undefined')) ? size : 1;

		Object.defineProperty(this, "currentRepresentation", {
			get : function () {
				var r = this.modes[this.currentMode];
				// bug que je ne comprends pas => je prends le 1er mode
				if (!r) {
					var kys = Object.keys(this.modes);
					r = this.modes[kys[0]];
				}

				return (this.currentMode !== "open") ? r : "";
			},
			enumerable : true
		});

		Object.defineProperty(this, "selected", {
			get : function () {
				return (this.currentMode !== "open");
			},
			set : function (sel) {
				this.currentMode = (sel) ? "closed" : "open";
			},
			enumerable : true
		});

	}

	/**
	 * An object for representation an instrument config option. Such as optional extra key found on some instruments (E.g. "C# thrill" key found on sme flute.)
	 * @param name The name of the key (e.g. for the tooltip)
	 * @param representation The glypth used in the Fiati font to display this key as *open*
	 * @param note A valid note object representing the usage of that key of an array of Notes
	 */
	function instrumentConfigClass(name, representation, notes, defaultActive) {
		var active = (defaultActive !== undefined) ? defaultActive : false;
		this.name = name;
		this.representation = representation;
		this.notes = (Array.isArray(notes) ? notes : [notes]);

		Object.defineProperty(this, "activated", {
			get : function () {
				return active;
			},
			set : function (newActive) {
				active = newActive;
				for (var i = 0; i < this.notes.length; i++) {
					if (!active)
						this.notes[i].currentMode = "open";
				}
			},
			enumerable : true
		});

	}

	  // -----------------------------------------------------------------------
	  // --- Library -------------------------------------------------------
	  // -----------------------------------------------------------------------
	  /**
	  * Class representing a preset.
	  * @param category A category of instrument. Must match any of the categories defined in the categories arrays
	  * @param label A label. Optional. If non proivded then replaced by an empty string
	  * @param accidental The accidental of the note. A *string* corresponding to an element of  Musescore Accidental enumeration. Optional. If non proivded then replaced by "--", meaining "suitable to all notes". 
	  * @param representation The textual representation of the key combination. Is expected to be a valid unicode combination ,ut no verification is made. Optional. If non proivded then replaced by an empty string.
	  * @param head The head of the note. A *string* corresponding to an element of  Musescore HeadGroup enumeration. Optional. If non proivded then replaced by "--", meaining "suitable to all notes". 
	  */
	  
	  function presetClass(category, label, note, accidental,representation, head) {
			this.category=(category!==undefined)?String(category):"??";
			this.label = (label!==undefined)?String(label):"";
			this.note= (note!==undefined)?String(note):"";
			
			this.accidental=ALL;
			if (accidental!==undefined && accidental!=="") {
				var acc=String(accidental);
				var accid=eval("Accidental." + acc);
				if (accid===undefined || accid==0) acc="NONE";
				this.accidental=acc;
			}
			
			this.head=ALL;
			if (head!==undefined && head!=="") {
				var hd=String(head);
				var accid=eval("NoteHeadgroup." + hd);
				if (accid===undefined || accid==0) hd="HEAD_NORMAL";
				this.head=hd;
			}
			
			this.representation=(representation!==undefined)?String(representation):"";
	  }
	  
	  readonly property string ALL: "--" 
	  
	  // -----------------------------------------------------------------------
	  // --- Accidentals -------------------------------------------------------
	  // -----------------------------------------------------------------------
			
	readonly property var pitchnotes : [ 'C', 'C', 'D', 'D', 'E', 'F', 'F', 'G', 'G', 'A', 'A', 'B']

	readonly property var tpcs : [{
			'tpc' : -1,
			'name' : 'F??',
			'raw' : 'F'
		}, {
			'tpc' : 0,
			'name' : 'C??',
			'raw' : 'C'
		}, {
			'tpc' : 1,
			'name' : 'G??',
			'raw' : 'G'
		}, {
			'tpc' : 2,
			'name' : 'D??',
			'raw' : 'D'
		}, {
			'tpc' : 3,
			'name' : 'A??',
			'raw' : 'A'
		}, {
			'tpc' : 4,
			'name' : 'E??',
			'raw' : 'E'
		}, {
			'tpc' : 5,
			'name' : 'B??',
			'raw' : 'B'
		}, {
			'tpc' : 6,
			'name' : 'F?',
			'raw' : 'F'
		}, {
			'tpc' : 7,
			'name' : 'C?',
			'raw' : 'C'
		}, {
			'tpc' : 8,
			'name' : 'G?',
			'raw' : 'G'
		}, {
			'tpc' : 9,
			'name' : 'D?',
			'raw' : 'D'
		}, {
			'tpc' : 10,
			'name' : 'A?',
			'raw' : 'A'
		}, {
			'tpc' : 11,
			'name' : 'E?',
			'raw' : 'E'
		}, {
			'tpc' : 12,
			'name' : 'B?',
			'raw' : 'B'
		}, {
			'tpc' : 13,
			'name' : 'F',
			'raw' : 'F'
		}, {
			'tpc' : 14,
			'name' : 'C',
			'raw' : 'C'
		}, {
			'tpc' : 15,
			'name' : 'G',
			'raw' : 'G'
		}, {
			'tpc' : 16,
			'name' : 'D',
			'raw' : 'D'
		}, {
			'tpc' : 17,
			'name' : 'A',
			'raw' : 'A'
		}, {
			'tpc' : 18,
			'name' : 'E',
			'raw' : 'E'
		}, {
			'tpc' : 19,
			'name' : 'B',
			'raw' : 'B'
		}, {
			'tpc' : 20,
			'name' : 'F?',
			'raw' : 'F'
		}, {
			'tpc' : 21,
			'name' : 'C?',
			'raw' : 'C'
		}, {
			'tpc' : 22,
			'name' : 'G?',
			'raw' : 'G'
		}, {
			'tpc' : 23,
			'name' : 'D?',
			'raw' : 'D'
		}, {
			'tpc' : 24,
			'name' : 'A?',
			'raw' : 'A'
		}, {
			'tpc' : 25,
			'name' : 'E?',
			'raw' : 'E'
		}, {
			'tpc' : 26,
			'name' : 'B?',
			'raw' : 'B'
		}, {
			'tpc' : 27,
			'name' : 'F??',
			'raw' : 'F'
		}, {
			'tpc' : 28,
			'name' : 'C??',
			'raw' : 'C'
		}, {
			'tpc' : 29,
			'name' : 'G??',
			'raw' : 'G'
		}, {
			'tpc' : 30,
			'name' : 'D??',
			'raw' : 'D'
		}, {
			'tpc' : 31,
			'name' : 'A??',
			'raw' : 'A'
		}, {
			'tpc' : 32,
			'name' : 'E??',
			'raw' : 'E'
		}, {
			'tpc' : 33,
			'name' : 'B??',
			'raw' : 'B'
		}
	]

	readonly property var accidentals : [
		{ 'name': 'NONE', 'image': 'NONE.png' },
		{ 'name': 'FLAT', 'image': 'FLAT.png' },
		{ 'name': 'NATURAL', 'image': 'NATURAL.png' },
		{ 'name': 'SHARP', 'image': 'SHARP.png' },
		{ 'name': 'SHARP2', 'image': 'SHARP2.png' },
		{ 'name': 'FLAT2', 'image': 'FLAT2.png' },
		{ 'name': 'NATURAL_FLAT', 'image': 'NATURAL_FLAT.png' },
		{ 'name': 'NATURAL_SHARP', 'image': 'NATURAL_SHARP.png' },
		{ 'name': 'SHARP_SHARP', 'image': 'SHARP_SHARP.png' },
		{ 'name': 'FLAT_ARROW_UP', 'image': 'FLAT_ARROW_UP.png' },
		{ 'name': 'FLAT_ARROW_DOWN', 'image': 'FLAT_ARROW_DOWN.png' },
		{ 'name': 'NATURAL_ARROW_UP', 'image': 'NATURAL_ARROW_UP.png' },
		{ 'name': 'NATURAL_ARROW_DOWN', 'image': 'NATURAL_ARROW_DOWN.png' },
		{ 'name': 'SHARP_ARROW_UP', 'image': 'SHARP_ARROW_UP.png' },
		{ 'name': 'SHARP_ARROW_DOWN', 'image': 'SHARP_ARROW_DOWN.png' },
		{ 'name': 'SHARP2_ARROW_UP', 'image': 'SHARP2_ARROW_UP.png' },
		{ 'name': 'SHARP2_ARROW_DOWN', 'image': 'SHARP2_ARROW_DOWN.png' },
		{ 'name': 'FLAT2_ARROW_UP', 'image': 'FLAT2_ARROW_UP.png' },
		{ 'name': 'FLAT2_ARROW_DOWN', 'image': 'FLAT2_ARROW_DOWN.png' },
		{ 'name': 'MIRRORED_FLAT', 'image': 'MIRRORED_FLAT.png' },
		{ 'name': 'MIRRORED_FLAT2', 'image': 'MIRRORED_FLAT2.png' },
		{ 'name': 'SHARP_SLASH', 'image': 'SHARP_SLASH.png' },
		{ 'name': 'SHARP_SLASH4', 'image': 'SHARP_SLASH4.png' },
		{ 'name': 'FLAT_SLASH2', 'image': 'FLAT_SLASH2.png' },
		{ 'name': 'FLAT_SLASH', 'image': 'FLAT_SLASH.png' },
		{ 'name': 'SHARP_SLASH3', 'image': 'SHARP_SLASH3.png' },
		{ 'name': 'SHARP_SLASH2', 'image': 'SHARP_SLASH2.png' },
		{ 'name': 'DOUBLE_FLAT_ONE_ARROW_DOWN', 'image': 'DOUBLE_FLAT_ONE_ARROW_DOWN.png' },
		{ 'name': 'FLAT_ONE_ARROW_DOWN', 'image': 'FLAT_ONE_ARROW_DOWN.png' },
		{ 'name': 'NATURAL_ONE_ARROW_DOWN', 'image': 'NATURAL_ONE_ARROW_DOWN.png' },
		{ 'name': 'SHARP_ONE_ARROW_DOWN', 'image': 'SHARP_ONE_ARROW_DOWN.png' },
		{ 'name': 'DOUBLE_SHARP_ONE_ARROW_DOWN', 'image': 'DOUBLE_SHARP_ONE_ARROW_DOWN.png' },
		{ 'name': 'DOUBLE_FLAT_ONE_ARROW_UP', 'image': 'DOUBLE_FLAT_ONE_ARROW_UP.png' },
		{ 'name': 'FLAT_ONE_ARROW_UP', 'image': 'FLAT_ONE_ARROW_UP.png' },
		{ 'name': 'NATURAL_ONE_ARROW_UP', 'image': 'NATURAL_ONE_ARROW_UP.png' },
		{ 'name': 'SHARP_ONE_ARROW_UP', 'image': 'SHARP_ONE_ARROW_UP.png' },
		{ 'name': 'DOUBLE_SHARP_ONE_ARROW_UP', 'image': 'DOUBLE_SHARP_ONE_ARROW_UP.png' },
		{ 'name': 'DOUBLE_FLAT_TWO_ARROWS_DOWN', 'image': 'DOUBLE_FLAT_TWO_ARROWS_DOWN.png' },
		{ 'name': 'FLAT_TWO_ARROWS_DOWN', 'image': 'FLAT_TWO_ARROWS_DOWN.png' },
		{ 'name': 'NATURAL_TWO_ARROWS_DOWN', 'image': 'NATURAL_TWO_ARROWS_DOWN.png' },
		{ 'name': 'SHARP_TWO_ARROWS_DOWN', 'image': 'SHARP_TWO_ARROWS_DOWN.png' },
		{ 'name': 'DOUBLE_SHARP_TWO_ARROWS_DOWN', 'image': 'DOUBLE_SHARP_TWO_ARROWS_DOWN.png' },
		{ 'name': 'DOUBLE_FLAT_TWO_ARROWS_UP', 'image': 'DOUBLE_FLAT_TWO_ARROWS_UP.png' },
		{ 'name': 'FLAT_TWO_ARROWS_UP', 'image': 'FLAT_TWO_ARROWS_UP.png' },
		{ 'name': 'NATURAL_TWO_ARROWS_UP', 'image': 'NATURAL_TWO_ARROWS_UP.png' },
		{ 'name': 'SHARP_TWO_ARROWS_UP', 'image': 'SHARP_TWO_ARROWS_UP.png' },
		{ 'name': 'DOUBLE_SHARP_TWO_ARROWS_UP', 'image': 'DOUBLE_SHARP_TWO_ARROWS_UP.png' },
		{ 'name': 'DOUBLE_FLAT_THREE_ARROWS_DOWN', 'image': 'DOUBLE_FLAT_THREE_ARROWS_DOWN.png' },
		{ 'name': 'FLAT_THREE_ARROWS_DOWN', 'image': 'FLAT_THREE_ARROWS_DOWN.png' },
		{ 'name': 'NATURAL_THREE_ARROWS_DOWN', 'image': 'NATURAL_THREE_ARROWS_DOWN.png' },
		{ 'name': 'SHARP_THREE_ARROWS_DOWN', 'image': 'SHARP_THREE_ARROWS_DOWN.png' },
		{ 'name': 'DOUBLE_SHARP_THREE_ARROWS_DOWN', 'image': 'DOUBLE_SHARP_THREE_ARROWS_DOWN.png' },
		{ 'name': 'DOUBLE_FLAT_THREE_ARROWS_UP', 'image': 'DOUBLE_FLAT_THREE_ARROWS_UP.png' },
		{ 'name': 'FLAT_THREE_ARROWS_UP', 'image': 'FLAT_THREE_ARROWS_UP.png' },
		{ 'name': 'NATURAL_THREE_ARROWS_UP', 'image': 'NATURAL_THREE_ARROWS_UP.png' },
		{ 'name': 'SHARP_THREE_ARROWS_UP', 'image': 'SHARP_THREE_ARROWS_UP.png' },
		{ 'name': 'DOUBLE_SHARP_THREE_ARROWS_UP', 'image': 'DOUBLE_SHARP_THREE_ARROWS_UP.png' },
		{ 'name': 'LOWER_ONE_SEPTIMAL_COMMA', 'image': 'LOWER_ONE_SEPTIMAL_COMMA.png' },
		{ 'name': 'RAISE_ONE_SEPTIMAL_COMMA', 'image': 'RAISE_ONE_SEPTIMAL_COMMA.png' },
		{ 'name': 'LOWER_TWO_SEPTIMAL_COMMAS', 'image': 'LOWER_TWO_SEPTIMAL_COMMAS.png' },
		{ 'name': 'RAISE_TWO_SEPTIMAL_COMMAS', 'image': 'RAISE_TWO_SEPTIMAL_COMMAS.png' },
		{ 'name': 'LOWER_ONE_UNDECIMAL_QUARTERTONE', 'image': 'LOWER_ONE_UNDECIMAL_QUARTERTONE.png' },
		{ 'name': 'RAISE_ONE_UNDECIMAL_QUARTERTONE', 'image': 'RAISE_ONE_UNDECIMAL_QUARTERTONE.png' },
		{ 'name': 'LOWER_ONE_TRIDECIMAL_QUARTERTONE', 'image': 'LOWER_ONE_TRIDECIMAL_QUARTERTONE.png' },
		{ 'name': 'RAISE_ONE_TRIDECIMAL_QUARTERTONE', 'image': 'RAISE_ONE_TRIDECIMAL_QUARTERTONE.png' },
		{ 'name': 'DOUBLE_FLAT_EQUAL_TEMPERED', 'image': 'DOUBLE_FLAT_EQUAL_TEMPERED.png' },
		{ 'name': 'FLAT_EQUAL_TEMPERED', 'image': 'FLAT_EQUAL_TEMPERED.png' },
		{ 'name': 'NATURAL_EQUAL_TEMPERED', 'image': 'NATURAL_EQUAL_TEMPERED.png' },
		{ 'name': 'SHARP_EQUAL_TEMPERED', 'image': 'SHARP_EQUAL_TEMPERED.png' },
		{ 'name': 'DOUBLE_SHARP_EQUAL_TEMPERED', 'image': 'DOUBLE_SHARP_EQUAL_TEMPERED.png' },
		{ 'name': 'QUARTER_FLAT_EQUAL_TEMPERED', 'image': 'QUARTER_FLAT_EQUAL_TEMPERED.png' },
		{ 'name': 'QUARTER_SHARP_EQUAL_TEMPERED', 'image': 'QUARTER_SHARP_EQUAL_TEMPERED.png' },
		{ 'name': 'SORI', 'image': 'SORI.png' },
		{ 'name': 'KORON', 'image': 'KORON.png' }
		//,{ 'name': 'UNKNOWN', 'image': 'UNKNOWN.png' }
	];
	readonly property var equivalences : [
		['SHARP','NATURAL_SHARP'],
		['FLAT','NATURAL_FLAT'],
		['NONE','NATURAL'],
		['SHARP2','SHARP_SHARP']
	];
	
	readonly property var heads : [
		{ 'name': 'HEAD_NORMAL ', 'image': 'HEAD_NORMAL.png' },
		{ 'name': 'HEAD_CROSS ', 'image': 'HEAD_CROSS.png' },
		{ 'name': 'HEAD_PLUS ', 'image': 'HEAD_PLUS.png' },
		{ 'name': 'HEAD_XCIRCLE ', 'image': 'HEAD_XCIRCLE.png' },
		{ 'name': 'HEAD_WITHX ', 'image': 'HEAD_WITHX.png' },
		{ 'name': 'HEAD_TRIANGLE_UP ', 'image': 'HEAD_TRIANGLE_UP.png' },
		{ 'name': 'HEAD_TRIANGLE_DOWN ', 'image': 'HEAD_TRIANGLE_DOWN.png' },
		{ 'name': 'HEAD_SLASHED1 ', 'image': 'HEAD_SLASHED1.png' },
		{ 'name': 'HEAD_SLASHED2 ', 'image': 'HEAD_SLASHED2.png' },
		{ 'name': 'HEAD_DIAMOND ', 'image': 'HEAD_DIAMOND.png' },
		{ 'name': 'HEAD_DIAMOND_OLD ', 'image': 'HEAD_DIAMOND_OLD.png' },
		{ 'name': 'HEAD_CIRCLED ', 'image': 'HEAD_CIRCLED.png' },
		{ 'name': 'HEAD_CIRCLED_LARGE ', 'image': 'HEAD_CIRCLED_LARGE.png' },
		{ 'name': 'HEAD_LARGE_ARROW ', 'image': 'HEAD_LARGE_ARROW.png' },
		{ 'name': 'HEAD_BREVIS_ALT ', 'image': 'HEAD_BREVIS_ALT.png' },
		{ 'name': 'HEAD_SLASH ', 'image': 'HEAD_SLASH.png' },
		{ 'name': 'HEAD_SOL ', 'image': 'HEAD_SOL.png' },
		{ 'name': 'HEAD_LA ', 'image': 'HEAD_LA.png' },
		{ 'name': 'HEAD_FA ', 'image': 'HEAD_FA.png' },
		{ 'name': 'HEAD_MI ', 'image': 'HEAD_MI.png' },
		{ 'name': 'HEAD_DO ', 'image': 'HEAD_DO.png' },
		{ 'name': 'HEAD_RE ', 'image': 'HEAD_RE.png' },
		{ 'name': 'HEAD_TI ', 'image': 'HEAD_TI.png' },
		{ 'name': 'HEAD_DO_WALKER ', 'image': 'HEAD_DO_WALKER.png' },
		{ 'name': 'HEAD_RE_WALKER ', 'image': 'HEAD_RE_WALKER.png' },
		{ 'name': 'HEAD_TI_WALKER ', 'image': 'HEAD_TI_WALKER.png' },
		{ 'name': 'HEAD_DO_FUNK ', 'image': 'HEAD_DO_FUNK.png' },
		{ 'name': 'HEAD_RE_FUNK ', 'image': 'HEAD_RE_FUNK.png' },
		{ 'name': 'HEAD_TI_FUNK ', 'image': 'HEAD_TI_FUNK.png' },
		{ 'name': 'HEAD_DO_NAME ', 'image': 'HEAD_DO_NAME.png' },
		{ 'name': 'HEAD_RE_NAME ', 'image': 'HEAD_RE_NAME.png' },
		{ 'name': 'HEAD_MI_NAME ', 'image': 'HEAD_MI_NAME.png' },
		{ 'name': 'HEAD_FA_NAME ', 'image': 'HEAD_FA_NAME.png' },
		{ 'name': 'HEAD_SOL_NAME ', 'image': 'HEAD_SOL_NAME.png' },
		{ 'name': 'HEAD_LA_NAME ', 'image': 'HEAD_LA_NAME.png' },
		{ 'name': 'HEAD_TI_NAME ', 'image': 'HEAD_TI_NAME.png' },
		{ 'name': 'HEAD_SI_NAME ', 'image': 'HEAD_SI_NAME.png' },
		{ 'name': 'HEAD_A_SHARP ', 'image': 'HEAD_A_SHARP.png' },
		{ 'name': 'HEAD_A ', 'image': 'HEAD_A.png' },
		{ 'name': 'HEAD_A_FLAT ', 'image': 'HEAD_A_FLAT.png' },
		{ 'name': 'HEAD_B_SHARP ', 'image': 'HEAD_B_SHARP.png' },
		{ 'name': 'HEAD_B ', 'image': 'HEAD_B.png' },
		{ 'name': 'HEAD_B_FLAT ', 'image': 'HEAD_B_FLAT.png' },
		{ 'name': 'HEAD_C_SHARP ', 'image': 'HEAD_C_SHARP.png' },
		{ 'name': 'HEAD_C ', 'image': 'HEAD_C.png' },
		{ 'name': 'HEAD_C_FLAT ', 'image': 'HEAD_C_FLAT.png' },
		{ 'name': 'HEAD_D_SHARP ', 'image': 'HEAD_D_SHARP.png' },
		{ 'name': 'HEAD_D ', 'image': 'HEAD_D.png' },
		{ 'name': 'HEAD_D_FLAT ', 'image': 'HEAD_D_FLAT.png' },
		{ 'name': 'HEAD_E_SHARP ', 'image': 'HEAD_E_SHARP.png' },
		{ 'name': 'HEAD_E ', 'image': 'HEAD_E.png' },
		{ 'name': 'HEAD_E_FLAT ', 'image': 'HEAD_E_FLAT.png' },
		{ 'name': 'HEAD_F_SHARP ', 'image': 'HEAD_F_SHARP.png' },
		{ 'name': 'HEAD_F ', 'image': 'HEAD_F.png' },
		{ 'name': 'HEAD_F_FLAT ', 'image': 'HEAD_F_FLAT.png' },
		{ 'name': 'HEAD_G_SHARP ', 'image': 'HEAD_G_SHARP.png' },
		{ 'name': 'HEAD_G ', 'image': 'HEAD_G.png' },
		{ 'name': 'HEAD_G_FLAT ', 'image': 'HEAD_G_FLAT.png' },
		{ 'name': 'HEAD_H ', 'image': 'HEAD_H.png' },
		{ 'name': 'HEAD_H_SHARP ', 'image': 'HEAD_H_SHARP.png' },
		{ 'name': 'HEAD_CUSTOM ', 'image': 'HEAD_CUSTOM.png' },
		{ 'name': 'HEAD_GROUPS ', 'image': 'HEAD_GROUPS.png' },
		{ 'name': 'HEAD_INVALID ', 'image': 'HEAD_INVALID.png' }
	];


	function isEquivAccidental(a1, a2) {
		for (var i = 0; i < equivalences.length; i++) {
			if ((equivalences[i][0] === a1 && equivalences[i][1] === a2) ||
				(equivalences[i][0] === a2 && equivalences[i][1] === a1))
				return true;
		}
		return false;
	}

	  // -----------------------------------------------------------------------
	// --- Debug -------------------------------------------------------
	// -----------------------------------------------------------------------
	function debug(level, label) {
		if (level > debugLevel)
			return;

		console.log(label);
	}

	function debugV(level, label, prop, value) {
		if (level > debugLevel)
			return;

		console.log(label + " " + prop + ":" + value);
	}

	function debugP(level, label, element, prop) {
		if (level > debugLevel)
			return;

		console.log(label + " " + prop + ":" + element[prop]);
	}

	function debugO(level, label, element) {
		if (level > debugLevel)
			return;

		var kys = Object.keys(element);
		for (var i = 0; i < kys.length; i++) {
			debugV(level, label, kys[i], element[kys[i]]);
		}
	}

}
