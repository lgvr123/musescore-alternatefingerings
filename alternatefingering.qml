import QtQuick 2.9
import QtQuick.Controls 1.4
import MuseScore 3.0
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import FileIO 3.0

MuseScore {
	menuPath : "Plugins.Alternate Fingering"
	description : "Add and edit alternate fingering"
	version : "1.2.0"
	pluginType : "dialog"
	requiresScore : true
        width: 500
        height: 500
        
	/** category of instrument :"flute","clarinet", ... */
	property string __category : ""
	/** alias to the different keys schemas for a the current category. */
	property var __instruments : categories[__category]["instruments"];
	/** alias to the different config options in the current category. */
	property var __config : categories[__category]["config"];
	/** alias to the different library  in the current category. */
	property var __library : categories[__category]["library"];
	/** alias to the different notes in the activated configs in the current category. */
	property var __confignotes : []

	// hack
	property var refreshed : true;
	property var ready : false;

	/** the notes to which the fingering must be made. */
	property var __notes : [];

	// config
	readonly property int debugLevel : level_TRACE;
	readonly property bool atFingeringLevel : true;

	// work variables
	property var lastoptions;

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
//
enrichNote(note);
console.log('-->Accidental: '+ note.accidentalType + ' ('+note.accidentalName+')');
console.log('-->Note: '+ note.pitch + "/" + note.tpc + " ==> "+note.extname.fullname);



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

		// On peut arriver ici avec un ensemble de notes dont on d�duit des fingerings
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

		// On fabrique le mod�le pour le ComboBox
		var model = Object.keys(categories[category]["instruments"]);
		for (var i = 0; i < model.length; i++) {
			debugV(level_TRACE, "model", "-->", model[i]);
		}
		lstInstru.model = model;

		// Bas� sur la s�lection, on r�cup�re le doigt� d�j� saisi
		var sFingering;
		var instrument_type;
		if (fingering) {
			instrument_type = extractInstrument(__category, fingering.text);
		}
		if (instrument_type) {
			// We got an identification based on the fingering found in the selection
			sFingering = fingering.text;
		} else {
			// We have no fingering in the selection or we wre not able to identifiy it
			sFingering = "";
			if ((categories[category]["default"]) && (model.indexOf(categories[category]["default"]) > -1)) {
				// we have a default and valid instrument, we take it
				instrument_type = categories[category]["default"];
			} else if (model.length > 0) {
				// we haven't a default instrument, we take the first one
				instrument_type = model[0];
			} else {
				// this category has no instruments. It should not occur. Anyway. We take an empty instrument.
				instrument_type = "";
			}

			if (fingering) {
				warnings[warnings.length] = "Impossible to recognize instrument type based from the selected fingering. Using default one.";
			}
		}
		debugV(level_INFO, "analyse", 'type', instrument_type);
		debugV(level_INFO, "analyse", 'fingering', sFingering);

		// S�lection parmi les cl�s standards
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

		// S�lection parmi les configuration de l'instrument
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

		// On s�lectionne le bon instrument
		if (instrument_type !== null) {
			lstInstru.currentIndex = model.indexOf(instrument_type);
			//console.log("selecting" + instrument_type + "(" + lstInstru.currentIndex + ")");
		} else {
			lstInstru.currentIndex = 0;
			//console.log("selecting (" + lstInstru.currentIndex + ")");
		}
		// On force un refresh
		lstInstru.currentIndexChanged();
		// On consruit la liste des notes d�pendants des configurations actuellement s�lectionn�es.
		// Je voudrais faire �a par binding mais le javascript de QML ne supporte pas flatMap() => je dois le faire manuellement
		buildConfigNotes();

		ready = true;
	}
	// -----------------------------------------------------------------------
	// --- Write the score ----------------------------------------------------
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
		Qt.quit();
	}

	function buildFingeringRepresentation() {
		var instru = lstInstru.currentText;
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
	 * Reourne les fingerings s�lectionn�s
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

	// -----------------------------------------------------------------------
	// --- String extractors -------------------------------------------------
	// -----------------------------------------------------------------------
	function extractInstrument(category, sKeys) {
		var splt = sKeys.split('');
		var found;
		var instruments=categories[category]["instruments"];
		// on trie pour avoir les plus grand cl�s en 1er
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
		// Je supprime de la cha�ne � retrouver ce qu'il ya dans l'interection
		// Il ne devrait rien manquer, donc le r�sultat devrait �tre vide.
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
		id: panMain
		rows: 7
		columns: 2

		anchors.fill : parent
		columnSpacing  : 5
                rowSpacing : 5
		anchors.topMargin : 10
		anchors.rightMargin : 10
		anchors.leftMargin : 10
		anchors.bottomMargin : 0

		
		Item {
            Layout.row: 1
            Layout.column: 1			
            Layout.columnSpan: 2
            Layout.rowSpan: 1

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
		                }

				ComboBox {
					id : lstInstru
					Layout.fillWidth : true
					// Pas de model. Il est construit sur la liste des __instruments g�r�s
					model : [""]// init
					currentIndex : 0 //init
					clip : true
					focus : true
					width : parent.width
					height : 20
					//color :"lightgrey"
					anchors {
						top : parent.top
					}
					onCurrentIndexChanged : {
						debug(level_DEBUG, "Now current index is :" + model[currentIndex])
						//debug(level_DEBUG, __instruments[lstInstru.model[lstInstru.currentIndex]]["keys"])
					}

				}

				Loader {
					id : configOpenBtn
					Binding {
						target : configOpenBtn.item
						property : "panel"
						value : panConfig // should be a valid it
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
            Layout.row: 2
            Layout.column: 2			
            Layout.columnSpan: 1
            Layout.rowSpan: 4
	    Layout.fillHeight: true
            Layout.fillWidth: true
 
		Item { 
            //Layout.row: 2
            //Layout.column: 2			
            //Layout.columnSpan: 1
            //Layout.rowSpan: 1

			id : panConfig
			visible : false
			//color : "red"
			//border.color: "grey"
			//border.width: 2
			Layout.preferredWidth : layConfig.implicitWidth + 10
			Layout.preferredHeight : layConfig.implicitHeight + 10
			anchors.margins : 20
			Grid {
				id : layConfig

				columns : 2
				columnSpacing : 5
				rowSpacing : 5
				//horizontalItemAlignment : Grid.AlignLeft
				//verticalItemAlignment  : Grid.AlignTop

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
		}  //panConfig


		Rectangle { // debug was Item
            //Layout.row: 3
            //Layout.column: 2			
            //Layout.columnSpan: 1
            //Layout.rowSpan: 1
	    Layout.fillHeight: true 
            Layout.fillWidth: true 	

                        color: "blue"
			id: panKeys


Item { // un small element within the fullWidth/fullHeight where we paint the repeater
			anchors.horizontalCenter : parent.horizontalCenter 
			anchors.verticalCenter : parent.verticalCenter 
			width : 240 //repNotes.implicitHeight // 12 columns
			height : 100 // repNotes.implicitWidth // 4 rows
//color: "white"


			// Repeater pour les notes de base
			Repeater {
				id : repNotes
				model : (__instruments[lstInstru.model[lstInstru.currentIndex]]) ? __instruments[lstInstru.model[lstInstru.currentIndex]]["keys"] : []
				//delegate : holeComponent - via Loader, pour passer la note � g�rer
				Loader {
					id : loaderNotes
					Binding {
						target : loaderNotes.item
						property : "note"
						value : __instruments[lstInstru.model[lstInstru.currentIndex]]["keys"][model.index]
					}
					sourceComponent : holeComponent
				}
			}

			// Repeater pour les notes des __config
			Repeater {
				id : repModes
				model : ready ? getConfigNotes(refreshed) : []; //awful hack. Just return the raw __config array
				//delegate : holeComponent - via Loader, pour passer la note � g�rer depuis le mode
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
		}  //panKeys
		

		Item {
            //Layout.row: 4
            //Layout.column: 2			
            //Layout.columnSpan: 1
            //Layout.rowSpan: 1

			id : panOptionsOpen
			Layout.preferredHeight : lpoo.implicitHeight + 4 // 4 pour les marges
			//Layout.fillHeight : false
			Layout.fillWidth : true
			RowLayout {
				id : lpoo
				anchors.fill : parent
				anchors.margins : 2
				spacing : 2
				Text {
					text : "Options"
					Layout.fillWidth : true
				}
				Loader {
					id : optionsOpenBtn
					Binding {
						target : optionsOpenBtn.item
						property : "panel"
						value : panOptions // should be a valid it
					}
					sourceComponent : openPanelComponent
				}
			}
		} //panOptionsOpen
	Item { 
            //Layout.row: 5
            //Layout.column: 2			
            //Layout.columnSpan: 1
            //Layout.rowSpan: 1

			id : panOptions
			visible : false
			//color : "red"
			//border.color: "grey"
			//border.width: 2
			Layout.preferredWidth : layOptions.implicitWidth+10
			Layout.preferredHeight : layOptions.implicitHeight + 10
			anchors.margins : 20
			Grid {
				id : layOptions

				columns : 2
				columnSpacing : 5
				rowSpacing : 5
				//horizontalItemAlignment : Grid.AlignLeft
				//verticalItemAlignment  : Grid.AlignTop


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
		} //panOptions
}

		Item {
            Layout.row: 6
            Layout.column: 2			
            Layout.columnSpan: 1
            Layout.rowSpan: 1
            Layout.fillWidth: true
            Layout.preferredHeight: panButtons.implicitHeight
		
            RowLayout {
            			id: panButtons
		
			Layout.alignment : Qt.AlignRight

			Button {
				text : "Save"
				onClicked : {
					saveOptions()
				}
			}

			Button {
				text : "Read"
				onClicked : {
					readOptions()
				}
			}

			Button {
				text : "Ok"
				onClicked : {
					writeFingering()
				}
			}

			Button {
				text : "Cancel"
				onClicked : {
					Qt.quit()
				}
			}
                  }
		} // panButtons

		
		Item {
            Layout.row: 7
            Layout.column: 1	
            Layout.columnSpan: 2
            Layout.rowSpan: 1
            Layout.fillWidth: true 
            //color: "#aaaaaa"
            //border.color: "black"
            Layout.preferredHeight: 15 //txtStatus.implicitHeight
            
			id: panStatusBar
			
			
			Text {
				id: txtStatus
				text: ""
				wrapMode: Text.WrapAnywhere
				width: parent.width
				//padding: 3
			}
			
		} // panStatusBar
		
		ListView {
            Layout.row: 2
            Layout.column: 1	
            Layout.columnSpan: 1
            Layout.rowSpan: 5

            Layout.fillHeight: true 
			
	     //color: "blue"

                        

			Layout.preferredWidth : 100
			id: lstPresets

                        model: __library
                        delegate: presetComponent
                        clip: true
                        
		} // panPresets
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

			// Tooltip requires QtQuick.Controls 2.15 which is not available in MuseScore 3
			/**hoverEnabled : true
			ToolTip.delay : 1000
			ToolTip.timeout : 5000
			ToolTip.visible : hovered
			ToolTip.text : __key.name
			 */

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
					if (note.deactivated) { // temp. On devrait r�soudre �a via mode.activated seulement
						parent.state = "deactivated"; // temp en attendant de r�soudre le probl�me de binding
						return;
					}
					var keystates = Object.keys(note.modes);
					// Object.keys ne pr�serve pas l'ordre, donc je repars de la array des �tats.
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
			}
		}
	}

        Component {
            id: presetComponent
            
            Rectangle {
                  color: "white"
                  property var __preset: __library[model.index]
                  width: 80
                  height: 100 //prsRep.implictHeight+prsLab.implictHeight+prsNote.implictHeight
                  
                  Text {
                        id: prsRep
                        text: __preset.representation
                        font.family: "fiati"
                        font.pixelSize: 80
                        //font.preferShaping: true // from Qt5.10. MuseScore 3.5 supports to 5.9 => for MuseScore 4.x
                        renderType: Text.NativeRendering
                        font.hintingPreference: Font.PreferVerticalHinting
                        width:20//parent.width
                        height: 50
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter 
                        horizontalAlignment : Text.AlignHCenter
                        y: -20//verticalAlignment: Text.AlignBottom
                        }

                  Text {
                        id: prsLab
                        text: (__preset.label=="")?"--":__preset.label
                        width:parent.width
                        height: 20
                        anchors.top: prsRep.bottom
                        anchors.horizontalCenter: parent.horizontalCenter 
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        }

                  Text {
                        id: prsNote
                        text: __preset.note
                        width:parent.width/2
                        height: 20
                        anchors.top: prsLab.bottom
                        anchors.right: parent.horizontalCenter 
                        horizontalAlignment: Text.AlignRight
                        verticalAlignment: Text.AlignVCenter
                        }
                   

                   //Image {
                   Text {
                        id: prsAcc
                        text: "#" //__preset.accidental
                        width:parent.width/2
                        height: 20
                        anchors.top: prsLab.bottom
                        anchors.left: parent.horizontalCenter 
                        horizontalAlignment: Text.AlignLeft
                        verticalAlignment : Text.AlignVCenter
                        }
                   
            
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
		icon : StandardIcon.Warning
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
	 * @return the raw __confignotes array *without* any treatment. This way, in the repeater, we can
	 * acces the right mode by just writing __confignotes[model.index].
	 */
	function getConfigNotes(refresh) {
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

	// -----------------------------------------------------------------------
	// --- Property File -----------------------------------------------------
	// -----------------------------------------------------------------------
    FileIO {
        id: settingsFile
        source: homePath() + "/alternatefingering.properties"
            
        onError: {
			//statusBar.text=msg;
        }
    }
      
	function saveOptions() {

		if (typeof lastoptions === 'undefined') {
			lastoptions = {};
		}

		lastoptions['states'] = usedstates;

		if (typeof lastoptions['categories'] === 'undefined') {
			lastoptions['categories'] = {};
		}

		lastoptions['categories'][__category] = {
			'default' : lstInstru.currentText
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
		
		var presets = [];
// debug
__library.push(new presetClass(__category,"xyz","A","SHARP",buildFingeringRepresentation()));
// debug
		for (var i = 0; i < __library.length; i++) {
			var preset = __library[i];
			presets[i] = preset;
		}
		lastoptions['categories'][__category]['library'] = presets;

		var t = JSON.stringify(lastoptions) + "\n";
		console.log(t);

		if (settingsFile.write(t)){
			console.log("File written to " + settingsFile.source);
		
		}
		else {
			console.log("Could not save settings");
		}
				
		
	}

	function readOptions() {
		//var json = '{"states":["open","closed","ring","thrill"],"categories":{"flute":{"default":"flute with B tail","config":[{"name": "C# thrill", "activated" :true},{"name": "OpenHole", "activated" :false}],"library":[{"label":"Un b�mol", "note":"A", "accidental": "FLAT", "representation": "\uE000\uE001\uE007"}],[{"label":"Un nawak", "note":"B", "accidental": "XYZE", "representation": "\uE000\uE001\uE008"}]}}}';
		//var json = '{"states":["open","closed","ring","thrill"],"categories":{"flute":{"default":"flute with B tail","config":[{"name": "C# thrill", "activated" :true},{"name": "OpenHole", "activated" :false}],"library":[{"category":"flute","label":"From Save","note":"B","accidental":"FLAT","representation":"?????????"}]}}}';
	
		try {
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
                        }
	
		if (!settingsFile.exists()) return;
		
		var json = settingsFile.read();

		
		try {
			lastoptions = JSON.parse(json);
		} catch (e) {
				console.error('while reading the option file', e.message);		
		}
		
		
		usedstates = lastoptions['states'];
		displayUsedStates();

		var cats = Object.keys(lastoptions['categories']);
		for (var j = 0; j < cats.length; j++) {
			var cat = cats[j];
			var desc = lastoptions['categories'][cat];
			
			// default instrument
			categories[cat].default = desc.default;
			console.log("readOptions: " + cat + " -- " + desc.default);

			// config options
			var cfgs = desc['config'];
			for (var k = 0; k < cfgs.length; k++) {
				var cfg = cfgs[k];
				console.log("readOptions: " + cfg.name + " --> " + cfg.activated);

				for (var l = 0; l < categories[cat]['config'].length; l++) {
					var c = categories[cat]['config'][l];
					if (c.name == cfg.name) {
						c.activated = cfg.activated;
						console.log("readOptions: setting " + c.name + " --> " + c.activated);
					}
				}
			}
			
			// library
			var prsts = desc['library'];
			for (var k = 0; k < prsts.length; k++) {
				var prst = prsts[k];
				console.log("readOptions: " + prst.label + " --> " + prst.note + "/" + prst.accidental);

				if (prst.category == cat) {
					var preset = new presetClass(prst.category, prst.label, prst.note, prst.accidental, prst.representation);
					var instrument_type = extractInstrument(cat, preset.representation);
					if (instrument_type) {
						// We got an representation matching our category, we keep it
						console.log("readOptions:  matching preset: " + preset);
						categories[cat]["library"].push(preset);
					} else {
						console.log("readOptions: Non matching preset: " + preset);
					}
				}
			}
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

	property var flbflat : new noteClass4("L Bb", {
		'closed' : '\uE006',
		'thrill' : '\uE03C'
	}, 3, 1.5);
	property var flb : new noteClass4("L B", {
		'closed' : '\uE007',
		'thrill' : '\uE03D'
	}, 3, 2.5);
	property var fl1 : new noteClass4("L1", {
		'closed' : '\uE008',
		'left' : '\uE024',
		'right' : '\uE02A',
		'halfleft' : '\uE030',
		'halfright' : '\uE036',
		'thrill' : '\uE03E'
	}, 2, 1);
	property var fl2 : new noteClass4("L2", {
		'closed' : '\uE009',
		'ring' : '\uE01F',
		'left' : '\uE025',
		'right' : '\uE02B',
		'halfleft' : '\uE031',
		'halfright' : '\uE037',
		'thrill' : '\uE03F'
	}, 2, 2, 1);
	property var fl3 : new noteClass4("L3", {
		'closed' : '\uE00A',
		'ring' : '\uE020',
		'left' : '\uE026',
		'right' : '\uE02C',
		'halfleft' : '\uE032',
		'halfright' : '\uE038',
		'thrill' : '\uE040'
	}, 2, 3);
	property var fgsharp : new noteClass4("G #", {
		'closed' : '\uE00B',
		'thrill' : '\uE041'
	}, 1, 3.5);
	property var fcsharptrill : new noteClass4("C # trill", {
		'closed' : '\uE00C',
		'thrill' : '\uE042'
	}, 2, 4.2, 0.8);
	property var frbflat : new noteClass4("Bb trill", {
		'closed' : '\uE00D',
		'thrill' : '\uE043'
	}, 2.8, 4.5, 0.8);
	property var fr1 : new noteClass4("R1", {
		'closed' : '\uE00E',
		'ring' : '\uE021',
		'left' : '\uE027',
		'right' : '\uE02D',
		'halfleft' : '\uE033',
		'halfright' : '\uE039',
		'thrill' : '\uE044'
	}, 2, 5);
	property var fdtrill : new noteClass4("D trill", {
		'closed' : '\uE00F',
		'thrill' : '\uE045'
	}, 2.8, 5.5, 0.8);
	property var fr2 : new noteClass4("R2", {
		'closed' : '\uE010',
		'ring' : '\uE022',
		'left' : '\uE028',
		'right' : '\uE02E',
		'halfleft' : '\uE034',
		'halfright' : '\uE03A',
		'thrill' : '\uE046'
	}, 2, 6);
	property var fdsharptrill : new noteClass4("D # trill", {
		'closed' : '\uE011',
		'thrill' : '\uE047'
	}, 2.8, 6.5, 0.8);
	property var fr3 : new noteClass4("R3", {
		'closed' : '\uE012',
		'ring' : '\uE023',
		'left' : '\uE029',
		'right' : '\uE02F',
		'halfleft' : '\uE035',
		'halfright' : '\uE03B',
		'thrill' : '\uE048'
	}, 2, 7);
	property var fe : new noteClass4("Low E", {
		'closed' : '\uE013',
		'thrill' : '\uE049'
	}, 3, 8);
	property var fcsharp : new noteClass4("Low C #", {
		'closed' : '\uE014',
		'thrill' : '\uE04A'
	}, 3, 9);
	property var fc : new noteClass4("Low C", {
		'closed' : '\uE015',
		'thrill' : '\uE04B'
	}, 2, 9);
	property var fbflat : new noteClass4("Low Bb", {
		'closed' : '\uE016',
		'thrill' : '\uE04C'
	}, 1, 9);
	property var fgizmo : new noteClass4("Gizmo", {
		"closed" : "\uE017",
		"thrill" : "\uE04D"
	}, 1, 10, 0.8);

	property var fKCUpLever : new noteClass4("fKCUpLever", {
		'closed' : '\uE018',
		'thrill' : '\uE04E'
	}, 1.2, 1.5, 0.8);
	property var fKAuxCSharpTrill : new noteClass4("fKAuxCSharpTrill", {
		'closed' : '\uE019',
		'thrill' : '\uE04F'
	}, 1.2, 2.5, 0.8);
	property var fKBbUpLever : new noteClass4("fKBbUpLever", {
		'closed' : '\uE01A',
		'thrill' : '\uE050'
	}, 3.8, 1, 0.8);
	property var fKBUpLever : new noteClass4("fKBUpLever", {
		'closed' : '\uE01B',
		'thrill' : '\uE051'
	}, 3.8, 2, 0.8);
	property var fKGUpLever : new noteClass4("fKGUpLever", {
		'closed' : '\uE01C',
		'thrill' : '\uE052'
	}, 0.5, 4.5, 0.8);
	property var fKFSharpBar : new noteClass4("fKFSharpBar", {
		'closed' : '\uE01D',
		'thrill' : '\uE053'
	}, 4, 5, 0.8);
	property var fKDUpLever : new noteClass4("fKDUpLever", {
		'closed' : '\uE01E',
		'thrill' : '\uE054'
	}, 3, 10, 0.8);

	property var categories : {
		"flute" : {
			// *User instructions*: Modify the default instrument here. Use any of the instruments listed below.
			"default" : "flute",
			"config" : [
				// *User instructions*: Modify the last false/true parameter in the
				// instrumentConfig class to control the default activation of this configuration
				new instrumentConfigClass("C# thrill", '\uE003', fcsharptrill, false),
				new instrumentConfigClass("OpenHole", '\uE004', [], false) // no associated notes with the OpenHole config
				//,new instrumentConfigClass("Kingma System", '\uE005', [fKCUpLever,fKAuxCSharpTrill,fKBbUpLever,fKBUpLever,fKGUpLever,fKFSharpBar,fKDUpLever],false),  // errors at the glypths level

			],
			"support" : [
				'wind.flutes'
			],
			"instruments" : {
				"flute with B tail" : {
					"base" : ['\uE000', '\uE001', '\uE002'], // B
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fbflat, fgizmo]
				},
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
	function noteClass(name, representation, row, column) {
		noteClass2.call(this, name, representation, row, column, 1);
	}

	/**
	 * A class representating an instrument key, that can be open/closed.
	 * @param name The name of the key (e.g. for the tooltip)
	 * @param representation The glypth used in the Fiati font to display this key as closed
	 * @param row, colum Where to put that key in the diagram
	 * @param size The size of the key on the diagram
	 * @return a note/key object
	 */
	function noteClass2(name, representation, row, column, size) {
		noteClass4.call(this, name, {
			"closed" : representation
		}, row, column, size);
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
	function noteClass4(name, xmodes, row, column, size) {
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
	  * @param accidental The accidental of the note. A *string* corresponding to an element of  Musescore Accidental enumeration. Optional. If non proivded then replaced by "NONE".
	  * @param representation The textual representation of the key combination. Is expected to be a valid unicode combination ,ut no verification is made. Optional. If non proivded then replaced by an empty string.
	  */
	  
	  function presetClass(category, label, note, accidental,representation) {
			this.category=category;
			this.label = (label!==undefined)?String(label):"";
			this.note= (note!==undefined)?String(note):"";
			
			this.accidental="NONE";
			if (accidental!==undefined) {
				var acc=String(accidental);
				var accid=eval("Accidental." + acc);
				console.log("## acc = "+acc +" --> "+accid);
				if (accid===undefined || accid==0) acc="NONE";
				this.accidental=acc;
			}
			
			this.representation=(representation!==undefined)?String(representation):"";
	  }
	  
	  
	  // -----------------------------------------------------------------------
	  // --- Accidentals -------------------------------------------------------
	  // -----------------------------------------------------------------------

function enrichNote(note) {
	// accidental
	var id = note.accidentalType;
	note.accidentalName = "NONE";
	if (id != 0) {
		for (var i = 0; i < accidentals.length; i++) {
			var acc = accidentals[i];
			if (id == eval("Accidental." + acc.name)) {
				note.accidentalName = acc.name;
				break;
			}
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
	return;

}
		
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
	{ 'name': 'NONE' },
	{ 'name': 'FLAT' },
	{ 'name': 'NATURAL' },
	{ 'name': 'SHARP' },
	{ 'name': 'SHARP2' },
	{ 'name': 'FLAT2' },
	{ 'name': 'SHARP3' },
	{ 'name': 'FLAT3' },
	{ 'name': 'NATURAL_FLAT' },
	{ 'name': 'NATURAL_SHARP' },
	{ 'name': 'SHARP_SHARP' },
	{ 'name': 'FLAT_ARROW_UP' },
	{ 'name': 'FLAT_ARROW_DOWN' },
	{ 'name': 'NATURAL_ARROW_UP' },
	{ 'name': 'NATURAL_ARROW_DOWN' },
	{ 'name': 'SHARP_ARROW_UP' },
	{ 'name': 'SHARP_ARROW_DOWN' },
	{ 'name': 'SHARP2_ARROW_UP' },
	{ 'name': 'SHARP2_ARROW_DOWN' },
	{ 'name': 'FLAT2_ARROW_UP' },
	{ 'name': 'FLAT2_ARROW_DOWN' },
	{ 'name': 'ARROW_DOWN' },
	{ 'name': 'ARROW_UP' },
	{ 'name': 'MIRRORED_FLAT' },
	{ 'name': 'MIRRORED_FLAT2' },
	{ 'name': 'SHARP_SLASH' },
	{ 'name': 'SHARP_SLASH4' },
	{ 'name': 'FLAT_SLASH2' },
	{ 'name': 'FLAT_SLASH' },
	{ 'name': 'SHARP_SLASH3' },
	{ 'name': 'SHARP_SLASH2' },
	{ 'name': 'DOUBLE_FLAT_ONE_ARROW_DOWN' },
	{ 'name': 'FLAT_ONE_ARROW_DOWN' },
	{ 'name': 'NATURAL_ONE_ARROW_DOWN' },
	{ 'name': 'SHARP_ONE_ARROW_DOWN' },
	{ 'name': 'DOUBLE_SHARP_ONE_ARROW_DOWN' },
	{ 'name': 'DOUBLE_FLAT_ONE_ARROW_UP' },
	{ 'name': 'FLAT_ONE_ARROW_UP' },
	{ 'name': 'NATURAL_ONE_ARROW_UP' },
	{ 'name': 'SHARP_ONE_ARROW_UP' },
	{ 'name': 'DOUBLE_SHARP_ONE_ARROW_UP' },
	{ 'name': 'DOUBLE_FLAT_TWO_ARROWS_DOWN' },
	{ 'name': 'FLAT_TWO_ARROWS_DOWN' },
	{ 'name': 'NATURAL_TWO_ARROWS_DOWN' },
	{ 'name': 'SHARP_TWO_ARROWS_DOWN' },
	{ 'name': 'DOUBLE_SHARP_TWO_ARROWS_DOWN' },
	{ 'name': 'DOUBLE_FLAT_TWO_ARROWS_UP' },
	{ 'name': 'FLAT_TWO_ARROWS_UP' },
	{ 'name': 'NATURAL_TWO_ARROWS_UP' },
	{ 'name': 'SHARP_TWO_ARROWS_UP' },
	{ 'name': 'DOUBLE_SHARP_TWO_ARROWS_UP' },
	{ 'name': 'DOUBLE_FLAT_THREE_ARROWS_DOWN' },
	{ 'name': 'FLAT_THREE_ARROWS_DOWN' },
	{ 'name': 'NATURAL_THREE_ARROWS_DOWN' },
	{ 'name': 'SHARP_THREE_ARROWS_DOWN' },
	{ 'name': 'DOUBLE_SHARP_THREE_ARROWS_DOWN' },
	{ 'name': 'DOUBLE_FLAT_THREE_ARROWS_UP' },
	{ 'name': 'FLAT_THREE_ARROWS_UP' },
	{ 'name': 'NATURAL_THREE_ARROWS_UP' },
	{ 'name': 'SHARP_THREE_ARROWS_UP' },
	{ 'name': 'DOUBLE_SHARP_THREE_ARROWS_UP' },
	{ 'name': 'LOWER_ONE_SEPTIMAL_COMMA' },
	{ 'name': 'RAISE_ONE_SEPTIMAL_COMMA' },
	{ 'name': 'LOWER_TWO_SEPTIMAL_COMMAS' },
	{ 'name': 'RAISE_TWO_SEPTIMAL_COMMAS' },
	{ 'name': 'LOWER_ONE_UNDECIMAL_QUARTERTONE' },
	{ 'name': 'RAISE_ONE_UNDECIMAL_QUARTERTONE' },
	{ 'name': 'LOWER_ONE_TRIDECIMAL_QUARTERTONE' },
	{ 'name': 'RAISE_ONE_TRIDECIMAL_QUARTERTONE' },
	{ 'name': 'DOUBLE_FLAT_EQUAL_TEMPERED' },
	{ 'name': 'FLAT_EQUAL_TEMPERED' },
	{ 'name': 'NATURAL_EQUAL_TEMPERED' },
	{ 'name': 'SHARP_EQUAL_TEMPERED' },
	{ 'name': 'DOUBLE_SHARP_EQUAL_TEMPERED' },
	{ 'name': 'QUARTER_FLAT_EQUAL_TEMPERED' },
	{ 'name': 'QUARTER_SHARP_EQUAL_TEMPERED' },
	{ 'name': 'FLAT_17' },
	{ 'name': 'SHARP_17' },
	{ 'name': 'FLAT_19' },
	{ 'name': 'SHARP_19' },
	{ 'name': 'FLAT_23' },
	{ 'name': 'SHARP_23' },
	{ 'name': 'FLAT_31' },
	{ 'name': 'SHARP_31' },
	{ 'name': 'FLAT_53' },
	{ 'name': 'SHARP_53' },
	{ 'name': 'SORI' },
	{ 'name': 'KORON' }
];

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

