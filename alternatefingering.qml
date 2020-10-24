import QtQuick 2.0
import QtQuick.Controls 1.4
import MuseScore 3.0
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1

MuseScore {
	menuPath : "Plugins.Alternate Fingering"
	description : "Add and edit alternate fingering"
	version : "1.0"
	pluginType : "dialog"
	requiresScore : true

	width : 300
	height : 300

	/** category of instrument :"flute","clarinet", ... */
	property string __category : ""
	/** alias to the various keys schemas for a the current category. */
	property var __instruments : categories[__category]["instruments"];
	/** the notes to which the fingering must be made. */
	property var __notes : [];

	// config
	readonly property int debugLevel : level_DEBUG;
	readonly property bool atFingeringLevel : true;

	// constants
	readonly property string mode_OPEN : "open";
	readonly property string mode_CLOSED : "closed";
	readonly property string mode_HALF_LEFT : "halfleft";
	readonly property string mode_HALF_RIGHT : "halfright";

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
					invalidSelectionDialog.open();
					return;
				}
			}

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
		var model = Object.keys(__instruments);
		for (var i = 0; i < model.length; i++) {
			debugV(level_TRACE, "model", "-->", model[i]);
		}
		lstInstru.model = model;
		// Basé sur la sélection, on récupère le doigté déjà saisi
		var sFingering;
		var instrument_type;
		if (fingering) {
			instrument_type = extractInstrument(fingering.text);
		}
		if (instrument_type) {
			// We got an identification based on the fingering found in the selection
			sFingering = fingering.text;
		} else {
			// We have no fingering in the selection or we wre not able to identifiy it
			sFingering = "";
			instrument_type = categories[category]["default"];
			if (fingering) {
				warnings[warnings.length] = "Impossible to recognize instrument type based from the selected fingering. Using default one.";
			}
		}
		debugV(level_INFO, "analyse", 'type', instrument_type);
		debugV(level_INFO, "analyse", 'fingering', sFingering);

		var kk = __instruments[instrument_type]["keys"];

		// TODO: Vérifier si nécessaire
		for (var i = 0; i < kk.length; i++) {
			//console.log("K-->"+ kk[i].name);
			kk[i].visible = true;
		}

		// La sélection dans l'accord en cours
		for (var i = 0; i < kk.length; i++) {
			var modes = kk[i].modes;
			var m;
			for (m in modes) {
				if (sFingering.search(modes[m]) >  - 1) {
					kk[i].currentMode = m;
				}
			}
		}

		// On sélectionne le bon instrument
		if (instrument_type !== null) {
			lstInstru.currentIndex = model.indexOf(instrument_type);
			//console.log("selecting" + instrument_type + "(" + lstInstru.currentIndex + ")");
		} else {
			lstInstru.currentIndex = 0;
			//console.log("selecting (" + lstInstru.currentIndex + ")");
		}
		// On force un refresh
		lstInstru.currentIndexChanged();

	}
	// -----------------------------------------------------------------------
	// --- Write the score ----------------------------------------------------
	// -----------------------------------------------------------------------
	function writeFingering() {
		var instru = lstInstru.currentText;
		var sFingering = __instruments[instru].base.join('');
		var kk = __instruments[instru].keys;
		debugV(level_DEBUG, "**Writing", "Instrument", instru);
		debugV(level_DEBUG, "**Writing", "Notes count", __notes.length);

		for (var i = 0; i < kk.length; i++) {
			var k = kk[i];
			if (k.isSelected()) {
				sFingering += k.getCurrentRepresentation();
			}
			debugV(level_TRACE, k.name, "selected", k.isSelected());
		}
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

			if (instru.startsWith('wind.flutes')) {
				cat = "flute";
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
	function extractInstrument(sKeys) {
		var splt = sKeys.split('');
		var found;
		// on trie pour avoir les plus grand clés en 1er
		var sorted = Object.keys(__instruments);
		sorted = sorted.sort(function (a, b) {
				var res = __instruments[b]['base'].length - __instruments[a]['base'].length;
				return res;
			});
		for (var i = 0; i < sorted.length; i++) {
			var instru = sorted[i];
			var root = __instruments[instru]['base'];
			debug(level_DEBUG, instru + ":" + root);
			if (find(root, splt)) {
				debug(level_DEBUG, ">> found");
				found = instru;
				break;
			}
		}
		return found;
	}

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

	// -----------------------------------------------------------------------
	// --- Screen design -----------------------------------------------------
	// -----------------------------------------------------------------------
	GridLayout {
		anchors.fill : parent
		anchors.margins : 10
		columns : 1
		rowSpacing : 20

		RowLayout {
			Layout.alignment : Qt.AlignTop

			Label {
				text : "Instrument :"
			}
			ComboBox {
				id : lstInstru
				Layout.fillWidth : true
				// Pas de model. Il est construit sur la liste des __instruments gérés
				model : [""]// init
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
					debug(level_DEBUG, __instruments[lstInstru.model[lstInstru.currentIndex]]["keys"])
				}

			}
		}
		Item {
			id : panKeys
			Layout.fillWidth : true
			Layout.fillHeight : true
			Layout.alignment : Qt.AlignHCenter | Qt.AlignVCenter
			implicitHeight : spanKeys.implicitHeight
			implicitWidth : spanKeys.implicitWidth
			Layout.margins : 0

			Repeater {
				id : spanKeys
				model : __instruments[lstInstru.model[lstInstru.currentIndex]]["keys"].length
				delegate : CheckBox {
					readonly property var __key : __instruments[lstInstru.model[lstInstru.currentIndex]]["keys"][model.index];
					//text : __key.name
					checked : __key.isSelected()

					x : __key.column * 20;
					y : __key.row * 20;
					onClicked : {
						debug(level_DEBUG, __key.name + "clicked to" + checked);
						__key.setSelected(checked);
					}

					// Tooltip requires QtQuick.Controls 2.15 which is not available in MuseScore 3
					/**hoverEnabled : true
					ToolTip.delay : 1000
					ToolTip.timeout : 5000
					ToolTip.visible : hovered
					ToolTip.text : __key.name
					 */
					style : CheckBoxStyle {
						indicator : Rectangle {
							implicitWidth : 16 * __key.size
							implicitHeight : 16 * __key.size
							radius : 5
							border.color : control.activeFocus ? "darkblue" : "gray"
							border.width : 1
							Rectangle {
								visible : control.checked
								color : "#555"
								border.color : "#333"
								radius : 3
								anchors.margins : 4
								anchors.fill : parent
							}
						}
					}

				}

			}
		}
		RowLayout {
			Layout.alignment : Qt.AlignRight

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

	// -----------------------------------------------------------------------
	// --- Instruments -------------------------------------------------------
	// -----------------------------------------------------------------------

	property var flbflat : new noteClass("L Bb", '\uE006', 3, 1.5);
	property var flb : new noteClass("L B", '\uE007', 3, 2.5);
	property var fl1 : new noteClass("L1", '\uE008', 2, 1);
	property var fl2 : new noteClass("L2", '\uE009', 2, 2);
	property var fl3 : new noteClass("L3", '\uE00A', 2, 3);
	property var fgsharp : new noteClass("G #", '\uE00B', 1, 3.5);
	property var fcsharptrill : new noteClass("C # trill", '\uE00C', 1, 4.5);
	property var frbflat : new noteClass2("Bb trill", '\uE00D', 3, 4.5, 0.8);
	property var fr1 : new noteClass("R1", '\uE00E', 2, 5);
	property var fdtrill : new noteClass2("D trill", '\uE00F', 3, 5.5, 0.8);
	property var fr2 : new noteClass("D2", '\uE010', 2, 6);
	property var fdsharptrill : new noteClass2("D # trill", '\uE011', 3, 6.5, 0.8);
	property var fr3 : new noteClass("R3", '\uE012', 2, 7);
	property var fe : new noteClass("Low E", '\uE013', 3, 8);
	property var fcsharp : new noteClass("Low C #", '\uE014', 3, 9);
	property var fc : new noteClass("Low C", '\uE015', 2, 9);
	property var fbflat : new noteClass("Low Bb", '\uE016', 1, 9);
	property var fgizmo : new noteClass2("Gizmo", '\uE017', 1, 10, 0.8);
	property var categories : {
		"" : {
			"default" : "",
			"instruments" : {
				"" : {
					"base" : [],
					"keys" : []
				}
			}
		},
		"flute" : {
			"default" : "Flute in C",
			"instruments" : {
				"flute with B tail and C # thrill" : {
					"base" : ['\uE000', '\uE001', '\uE002', '\uE003'], // B + C thrill,
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, fcsharptrill, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fbflat]
				},
				"flute with B tail" : {
					"base" : ['\uE000', '\uE001', '\uE002'], // B
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fbflat]
				},
				"Flute with C # thrill" : {
					"base" : ['\uE000', '\uE001', '\uE003'], // C + C thrill
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, fcsharptrill, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc]
				}, // C + C thrill
				"Flute" : {
					"base" : ['\uE000', '\uE001'], // C
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc]
				}
			}
		},
		"clarinet" : {
			"default" : "clarinet",
			"instruments" : {
				"clarinet" : {
					"base" : ['\uE000', '\uE001', '\uE002', '\uE003'], // B + C thrill,
					"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, fcsharptrill, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fbflat]
				}
			}
		}

	};
	function noteClass(name, representation, row, column) {
		noteClass2.call(this, name, representation, row, column, 1);
	}

	function noteClass2(name, representation, row, column, size) {
		noteClass4.call(this, name, {
			mode_CLOSED : representation
		}, row, column, size);
		this.representation = representation;
	}

	function noteClass4(name, modes, row, column, size) {
		this.name = name;
		this.modes = modes;
		this.currentMode = mode_OPEN;
		this.visible = false;
		this.row = row;
		this.column = column;
		this.size = size;

		this.getCurrentRepresentation = function () {
			var r = this.modes[this.currentMode];
			// bug que je ne comprends pas => je prends le 1er mode
			if (!r) {
				var kys = Object.keys(this.modes);
				r = this.modes[kys[0]];
			}

			//console.log(this.name + " getting representation for : "+this.currentMode+" => "+r);
			return (this.currentMode != mode_OPEN) ? r : "";
		}

		// compatibility only
		this.setSelected = function (sel) {
			this.currentMode = (sel) ? mode_CLOSED : mode_OPEN;
		};
		this.isSelected = function () {
			return (this.currentMode !== mode_OPEN);
		}

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
