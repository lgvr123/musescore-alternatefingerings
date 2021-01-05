import QtQuick 2.0
import QtQuick.Controls 1.4
import MuseScore 3.0
import QtQuick.Dialogs 1.1
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1

MuseScore {
	menuPath : "Plugins.Alternate Fingering"
	description : "Add and edit alternate fingering"
	version : "1.2.0"
	pluginType : "dialog"
	requiresScore : true

	width : 400
	height : 300

	/** category of instrument :"flute","clarinet", ... */
	property string __category : ""
	/** alias to the different keys schemas for a the current category. */
	property var __instruments : categories[__category]["instruments"];
	/** alias to the different config options in the current category. */
	property var __config : categories[__category]["config"];
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

        property var lastoptions;

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
		var model = Object.keys(categories[category]["instruments"]);
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
		if (instrument_type !== null) {
			lstInstru.currentIndex = model.indexOf(instrument_type);
			//console.log("selecting" + instrument_type + "(" + lstInstru.currentIndex + ")");
		} else {
			lstInstru.currentIndex = 0;
			//console.log("selecting (" + lstInstru.currentIndex + ")");
		}
		// On force un refresh
		lstInstru.currentIndexChanged();
		// On consruit la liste des notes dépendants des configurations actuellement sélectionnées.
		// Je voudrais faire ça par binding mais le javascript de QML ne supporte pas flatMap() => je dois le faire manuellement
		buildConfigNotes();

		ready = true;
	}
	// -----------------------------------------------------------------------
	// --- Write the score ----------------------------------------------------
	// -----------------------------------------------------------------------
	function writeFingering() {
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
	ColumnLayout {
		anchors.fill : parent
		spacing : 5
		anchors.margins : 10

		Item {
			id : panInstrument
			Layout.preferredHeight : lpc.implicitHeight + 4 // 4 pour les marges
			//Layout.fillHeight : false
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
					// Pas de model. Il est construit sur la liste des __instruments gérés
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
		}
		Item {
			id : panConfig
			visible : false
			//color : "yellow"
			//border.color: "grey"
			//border.width: 2
			Layout.preferredWidth : parent.width
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
		}

		Item {

			Layout.alignment : Qt.AlignHCenter | Qt.AlignmentTop

			Layout.preferredWidth : 240 //repNotes.implicitHeight // 12 columns
			Layout.preferredHeight : 100 // repNotes.implicitWidth // 4 rows
			//Layout.fillHeight : true
			//Layout.fillWidth : true

			//color : "#ffaaaa"

			// Repeater pour les notes de base
			Repeater {
				id : repNotes
				model : (__instruments[lstInstru.model[lstInstru.currentIndex]]) ? __instruments[lstInstru.model[lstInstru.currentIndex]]["keys"] : []
				//delegate : holeComponent - via Loader, pour passer la note à gérer
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
		Item {
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
		}
		Item {
			id : panOptions
			//color : "yellow"
			visible : false
			//border.color: "grey"
			//border.width: 2
			Layout.preferredWidth : parent.width
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
		}

		RowLayout {
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

		var cfgs = []
		for (var i = 0; i < __config.length; i++) {
			var config = __config[i];
			cfgs[i] = {};
			cfgs[i][config.name] = config.activated;
		}
		lastoptions['categories'][__category]['config'] = cfgs;

		var t = JSON.stringify(lastoptions) + "\n";
		console.log(t);

		var obj = JSON.parse(t);
	}

	function readOptions() {
		var json = '{"states":["open","closed","ring","thrill"],"categories":{"flute":{"default":"flute with B tail","config":[{"C# thrill":false},{"OpenHole":true}]}}}';
		lastoptions = JSON.parse(json);

		usedstates = lastoptions['states'];
		displayUsedStates();

		var cats = Object.keys(lastoptions['categories']);
		for (var j = 0; j < cats.length; j++) {
			var cat = cats[j];
			var desc = lastoptions['categories'][cat];
			categories[cat].default = desc.default;
			console.log(cat + " -- " + desc.default);
			// TBC: gérer l'activation par défaut des configs
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
			}
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
			}
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
			}
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
