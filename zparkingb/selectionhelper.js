/**********************
/* Parking B - MuseScore - Selection helper
/* v1.0.0
/**********************************************/
// -----------------------------------------------------------------------
// --- Selection helper --------------------------------------------------
// -----------------------------------------------------------------------
/**
 * Get all the selected notes from the selection
 * @return Note[] : each returned {@link Note}  has the following properties:
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
 * Get all the selected rest from the selection
 * @return Note[] : each returned {@link Rest}  has the following properties:
 *      - element.type==Element.REST
 */
function getRestsFromSelection() {
	var selection = curScore.selection;
	var el = selection.elements;
	var rests = [];
	for (var i = 0; i < el.length; i++) {
		var element = el[i];
		if (element.type == Element.REST) {
			rests.push(element);
		}

	}
	return rests;
}

/**
 * Get all the selected notes and rests from the selection
 * @return Note[] : each returned {@link Rest}  has the following properties:
 *      - element.type==Element.REST or Element.NOTE
 */
function getNotesRestsFromSelection() {
	var selection = curScore.selection;
	var el = selection.elements;
	var rests = [];
	for (var i = 0; i < el.length; i++) {
		var element = el[i];
		if ((element.type == Element.REST) || (element.type == Element.NOTE)) {
			rests.push(element);
		}

	}
	return rests;
}
/**
 * Get all the selected chords from the selection
 * @return Chord[] : each returned {@link Chord}  has the following properties:
 *      - element.type==Element.CHORD
 */
function getChordsFromSelection() {
	var notes = getNotesFromSelection();
	var chords = [];
	var prevChord;
	for (var i = 0; i < notes.length; i++) {
		var element = notes[i];
		var chord = element.parent;
		if (prevChord && !prevChord.is(chord)) {
			chords.push(chord);
		}
		prevChord = chord;
	}
	return chords;
}

/**
 * Get all the selected segments from the selection
 * @return Segment[] : each returned {@link Segment}  has the following properties:
 *      - element.type==Element.SEGMENT
 */
function getSegmentsFromSelection() {
	// Les segments sur base des notes et accords
	var chords = getChordsFromSelection();
	var segments = [];
	var prevSeg;
	for (var i = 0; i < chords.length; i++) {
		var element = chords[i];
		var seg = element.parent;
		if (prevSeg && !prevSeg.is(seg)) {
			segments.push(seg);
		}
		prevChord = seg;
	}

	// Les segments sur base des accords
	var rests = getRestsFromSelection();
	for (var i = 0; i < rests.length; i++) {
		var element = rests[i];
		var seg = element.parent;
		
		if (segments.indexOf(seg)===-1)  {
			segments.push(seg);
		}
	}

	return segments;
}

/**
 * Reourne les fingerings sélectionnés
 * @return Fingering[] : each returned {@link Fingering}  has the following properties:
 *      - element.type==Element.FINGERING
 */
function getFingeringsFromSelection() {
	var selection = curScore.selection;
	var el = selection.elements;
	var fingerings = [];
	for (var i = 0; i < el.length; i++) {
		var element = el[i];
		if (element.type == Element.FINGERING) {
			fingerings.push(element);
		}
	}
	return fingerings;
}

/**
 * Get all the selected notes based on the cursor.
 * Rem: This does not any result in case of the notes are selected inidvidually.
 * @param oneNoteBySegment : boolean. If true, only one note by segment will be returned.
 * @return Note[] : each returned {@link Note}  has the following properties:
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
 * @return Chord[] : each returned {@link Note} has the following properties:
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
 * Get all the selected rests based on the cursor.
 * Rem: This does not any result in case of the rests and notes are selected inidvidually.
 * @return Rest[] : each returned {@link Note} has the following properties:
 *      - element.type==Element.REST
 *
 */
function getRestsFromCursor() {
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
	var rests = [];
	for (var track = firstStaff; track <= lastStaff; track++) {

		cursor.rewind(Cursor.SELECTION_START);
		var segment = cursor.segment;
		while (segment && (segment.tick < lastTick)) {
			var element;
			element = segment.elementAt(track);
			if (element && element.type == Element.REST) {
				debugV(level_TRACE, "- segment -", "tick", segment.tick);
				debugV(level_TRACE, "- segment -", "segmentType", segment.segmentType);
				debugV(level_TRACE, "--element", "label", (element) ? element.name : "null");
				rests.push(element);
			}

			cursor.next();
			segment = cursor.segment;
		}
	}

	return rests;
}

/**
 * Get all the selected notes and rests based on the cursor.
 * Rem: This does not any result in case of the rests and notes are selected inidvidually.
 * @return Rest[] : each returned {@link Note} has the following properties:
 *      - element.type==Element.REST or Element.NOTE
 *
 */
function getNotesRestsFromCursor() {
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
	var rests = [];
	for (var track = firstStaff; track <= lastStaff; track++) {

		cursor.rewind(Cursor.SELECTION_START);
		var segment = cursor.segment;
		while (segment && (segment.tick < lastTick)) {
			var element;
			element = segment.elementAt(track);
			if (element && ((element.type == Element.REST) || (element.type == Element.NOTE))){
				debugV(level_TRACE, "- segment -", "tick", segment.tick);
				debugV(level_TRACE, "- segment -", "segmentType", segment.segmentType);
				debugV(level_TRACE, "--element", "label", (element) ? element.name : "null");
				rests.push(element);
			}

			cursor.next();
			segment = cursor.segment;
		}
	}

	return rests;
}

/**
 * Get all the selected segments based on the cursor.
 * Rem: This does not return any result in case of the notes are selected inidvidually.
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
