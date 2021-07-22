var level_NONE = 0;
var level_INFO = 10;
var level_DEBUG = 20;
var level_TRACE = 30;
var level_ALL = 999;

// config
var debugLevel = level_DEBUG;


// -----------------------------------------------------------------------
// --- Accidentals -------------------------------------------------------
// -----------------------------------------------------------------------

var generic_preset = "--";

var accidentals = [{
		'name' : generic_preset,
		'tuning' : 0,
		'image' : 'generic.png'
	}, {
		'name' : 'NONE',
		'tuning' : 0,
		'image' : 'NONE.png'
	}, {
		'name' : 'FLAT',
		'tuning' : 0,
		'image' : 'FLAT.png'
	}, {
		'name' : 'NATURAL',
		'tuning' : 0,
		'image' : 'NATURAL.png'
	}, {
		'name' : 'SHARP',
		'tuning' : 0,
		'image' : 'SHARP.png'
	}, {
		'name' : 'SHARP2',
		'tuning' : 0,
		'image' : 'SHARP2.png'
	}, {
		'name' : 'FLAT2',
		'tuning' : 0,
		'image' : 'FLAT2.png'
	}, {
		'name' : 'NATURAL_FLAT',
		'tuning' : 0,
		'image' : 'NATURAL_FLAT.png'
	}, {
		'name' : 'NATURAL_SHARP',
		'tuning' : 0,
		'image' : 'NATURAL_SHARP.png'
	}, {
		'name' : 'SHARP_SHARP',
		'tuning' : 0,
		'image' : 'SHARP_SHARP.png'
	}, {
		'name' : 'FLAT_ARROW_UP',
		'tuning' : 0,
		'image' : 'FLAT_ARROW_UP.png'
	}, {
		'name' : 'FLAT_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'FLAT_ARROW_DOWN.png'
	}, {
		'name' : 'NATURAL_ARROW_UP',
		'tuning' : 0,
		'image' : 'NATURAL_ARROW_UP.png'
	}, {
		'name' : 'NATURAL_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'NATURAL_ARROW_DOWN.png'
	}, {
		'name' : 'SHARP_ARROW_UP',
		'tuning' : 0,
		'image' : 'SHARP_ARROW_UP.png'
	}, {
		'name' : 'SHARP_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'SHARP_ARROW_DOWN.png'
	}, {
		'name' : 'SHARP2_ARROW_UP',
		'tuning' : 0,
		'image' : 'SHARP2_ARROW_UP.png'
	}, {
		'name' : 'SHARP2_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'SHARP2_ARROW_DOWN.png'
	}, {
		'name' : 'FLAT2_ARROW_UP',
		'tuning' : 0,
		'image' : 'FLAT2_ARROW_UP.png'
	}, {
		'name' : 'FLAT2_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'FLAT2_ARROW_DOWN.png'
	}, {
		'name' : 'MIRRORED_FLAT',
		'tuning' : 0,
		'image' : 'MIRRORED_FLAT.png'
	}, {
		'name' : 'MIRRORED_FLAT2',
		'tuning' : 0,
		'image' : 'MIRRORED_FLAT2.png'
	}, {
		'name' : 'SHARP_SLASH',
		'tuning' : 0,
		'image' : 'SHARP_SLASH.png'
	}, {
		'name' : 'SHARP_SLASH4',
		'tuning' : 0,
		'image' : 'SHARP_SLASH4.png'
	}, {
		'name' : 'FLAT_SLASH2',
		'tuning' : 0,
		'image' : 'FLAT_SLASH2.png'
	}, {
		'name' : 'FLAT_SLASH',
		'tuning' : 0,
		'image' : 'FLAT_SLASH.png'
	}, {
		'name' : 'SHARP_SLASH3',
		'tuning' : 0,
		'image' : 'SHARP_SLASH3.png'
	}, {
		'name' : 'SHARP_SLASH2',
		'tuning' : 0,
		'image' : 'SHARP_SLASH2.png'
	}, {
		'name' : 'DOUBLE_FLAT_ONE_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'DOUBLE_FLAT_ONE_ARROW_DOWN.png'
	}, {
		'name' : 'FLAT_ONE_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'FLAT_ONE_ARROW_DOWN.png'
	}, {
		'name' : 'NATURAL_ONE_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'NATURAL_ONE_ARROW_DOWN.png'
	}, {
		'name' : 'SHARP_ONE_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'SHARP_ONE_ARROW_DOWN.png'
	}, {
		'name' : 'DOUBLE_SHARP_ONE_ARROW_DOWN',
		'tuning' : 0,
		'image' : 'DOUBLE_SHARP_ONE_ARROW_DOWN.png'
	}, {
		'name' : 'DOUBLE_FLAT_ONE_ARROW_UP',
		'tuning' : 0,
		'image' : 'DOUBLE_FLAT_ONE_ARROW_UP.png'
	}, {
		'name' : 'FLAT_ONE_ARROW_UP',
		'tuning' : 0,
		'image' : 'FLAT_ONE_ARROW_UP.png'
	}, {
		'name' : 'NATURAL_ONE_ARROW_UP',
		'tuning' : 0,
		'image' : 'NATURAL_ONE_ARROW_UP.png'
	}, {
		'name' : 'SHARP_ONE_ARROW_UP',
		'tuning' : 0,
		'image' : 'SHARP_ONE_ARROW_UP.png'
	}, {
		'name' : 'DOUBLE_SHARP_ONE_ARROW_UP',
		'tuning' : 0,
		'image' : 'DOUBLE_SHARP_ONE_ARROW_UP.png'
	}, {
		'name' : 'DOUBLE_FLAT_TWO_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'DOUBLE_FLAT_TWO_ARROWS_DOWN.png'
	}, {
		'name' : 'FLAT_TWO_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'FLAT_TWO_ARROWS_DOWN.png'
	}, {
		'name' : 'NATURAL_TWO_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'NATURAL_TWO_ARROWS_DOWN.png'
	}, {
		'name' : 'SHARP_TWO_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'SHARP_TWO_ARROWS_DOWN.png'
	}, {
		'name' : 'DOUBLE_SHARP_TWO_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'DOUBLE_SHARP_TWO_ARROWS_DOWN.png'
	}, {
		'name' : 'DOUBLE_FLAT_TWO_ARROWS_UP',
		'tuning' : 0,
		'image' : 'DOUBLE_FLAT_TWO_ARROWS_UP.png'
	}, {
		'name' : 'FLAT_TWO_ARROWS_UP',
		'tuning' : 0,
		'image' : 'FLAT_TWO_ARROWS_UP.png'
	}, {
		'name' : 'NATURAL_TWO_ARROWS_UP',
		'tuning' : 0,
		'image' : 'NATURAL_TWO_ARROWS_UP.png'
	}, {
		'name' : 'SHARP_TWO_ARROWS_UP',
		'tuning' : 0,
		'image' : 'SHARP_TWO_ARROWS_UP.png'
	}, {
		'name' : 'DOUBLE_SHARP_TWO_ARROWS_UP',
		'tuning' : 0,
		'image' : 'DOUBLE_SHARP_TWO_ARROWS_UP.png'
	}, {
		'name' : 'DOUBLE_FLAT_THREE_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'DOUBLE_FLAT_THREE_ARROWS_DOWN.png'
	}, {
		'name' : 'FLAT_THREE_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'FLAT_THREE_ARROWS_DOWN.png'
	}, {
		'name' : 'NATURAL_THREE_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'NATURAL_THREE_ARROWS_DOWN.png'
	}, {
		'name' : 'SHARP_THREE_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'SHARP_THREE_ARROWS_DOWN.png'
	}, {
		'name' : 'DOUBLE_SHARP_THREE_ARROWS_DOWN',
		'tuning' : 0,
		'image' : 'DOUBLE_SHARP_THREE_ARROWS_DOWN.png'
	}, {
		'name' : 'DOUBLE_FLAT_THREE_ARROWS_UP',
		'tuning' : 0,
		'image' : 'DOUBLE_FLAT_THREE_ARROWS_UP.png'
	}, {
		'name' : 'FLAT_THREE_ARROWS_UP',
		'tuning' : 0,
		'image' : 'FLAT_THREE_ARROWS_UP.png'
	}, {
		'name' : 'NATURAL_THREE_ARROWS_UP',
		'tuning' : 0,
		'image' : 'NATURAL_THREE_ARROWS_UP.png'
	}, {
		'name' : 'SHARP_THREE_ARROWS_UP',
		'tuning' : 0,
		'image' : 'SHARP_THREE_ARROWS_UP.png'
	}, {
		'name' : 'DOUBLE_SHARP_THREE_ARROWS_UP',
		'tuning' : 0,
		'image' : 'DOUBLE_SHARP_THREE_ARROWS_UP.png'
	}, {
		'name' : 'LOWER_ONE_SEPTIMAL_COMMA',
		'tuning' : 0,
		'image' : 'LOWER_ONE_SEPTIMAL_COMMA.png'
	}, {
		'name' : 'RAISE_ONE_SEPTIMAL_COMMA',
		'tuning' : 0,
		'image' : 'RAISE_ONE_SEPTIMAL_COMMA.png'
	}, {
		'name' : 'LOWER_TWO_SEPTIMAL_COMMAS',
		'tuning' : 0,
		'image' : 'LOWER_TWO_SEPTIMAL_COMMAS.png'
	}, {
		'name' : 'RAISE_TWO_SEPTIMAL_COMMAS',
		'tuning' : 0,
		'image' : 'RAISE_TWO_SEPTIMAL_COMMAS.png'
	}, {
		'name' : 'LOWER_ONE_UNDECIMAL_QUARTERTONE',
		'tuning' : 0,
		'image' : 'LOWER_ONE_UNDECIMAL_QUARTERTONE.png'
	}, {
		'name' : 'RAISE_ONE_UNDECIMAL_QUARTERTONE',
		'tuning' : 0,
		'image' : 'RAISE_ONE_UNDECIMAL_QUARTERTONE.png'
	}, {
		'name' : 'LOWER_ONE_TRIDECIMAL_QUARTERTONE',
		'tuning' : 0,
		'image' : 'LOWER_ONE_TRIDECIMAL_QUARTERTONE.png'
	}, {
		'name' : 'RAISE_ONE_TRIDECIMAL_QUARTERTONE',
		'tuning' : 0,
		'image' : 'RAISE_ONE_TRIDECIMAL_QUARTERTONE.png'
	}, {
		'name' : 'DOUBLE_FLAT_EQUAL_TEMPERED',
		'tuning' : 0,
		'image' : 'DOUBLE_FLAT_EQUAL_TEMPERED.png'
	}, {
		'name' : 'FLAT_EQUAL_TEMPERED',
		'tuning' : 0,
		'image' : 'FLAT_EQUAL_TEMPERED.png'
	}, {
		'name' : 'NATURAL_EQUAL_TEMPERED',
		'tuning' : 0,
		'image' : 'NATURAL_EQUAL_TEMPERED.png'
	}, {
		'name' : 'SHARP_EQUAL_TEMPERED',
		'tuning' : 0,
		'image' : 'SHARP_EQUAL_TEMPERED.png'
	}, {
		'name' : 'DOUBLE_SHARP_EQUAL_TEMPERED',
		'tuning' : 0,
		'image' : 'DOUBLE_SHARP_EQUAL_TEMPERED.png'
	}, {
		'name' : 'QUARTER_FLAT_EQUAL_TEMPERED',
		'tuning' : 0,
		'image' : 'QUARTER_FLAT_EQUAL_TEMPERED.png'
	}, {
		'name' : 'QUARTER_SHARP_EQUAL_TEMPERED',
		'tuning' : 0,
		'image' : 'QUARTER_SHARP_EQUAL_TEMPERED.png'
	}, {
		'name' : 'SORI',
		'tuning' : 0,
		'image' : 'SORI.png'
	}, {
		'name' : 'KORON',
		'tuning' : 0,
		'image' : 'KORON.png'
	}
	//,{ 'name': 'UNKNOWN', 'tuning': 0, 'image': 'UNKNOWN.png' }
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

// -----------------------------------------------------------------------
// --- Heads -------------------------------------------------------
// -----------------------------------------------------------------------

var heads = [{
		'name' : generic_preset,
		'image' : 'generic.png'
	}, {
		'name' : 'HEAD_NORMAL',
		'image' : 'HEAD_NORMAL.png'
	}, {
		'name' : 'HEAD_CROSS',
		'image' : 'HEAD_CROSS.png'
	}, {
		'name' : 'HEAD_PLUS',
		'image' : 'HEAD_PLUS.png'
	}, {
		'name' : 'HEAD_XCIRCLE',
		'image' : 'HEAD_XCIRCLE.png'
	}, {
		'name' : 'HEAD_WITHX',
		'image' : 'HEAD_WITHX.png'
	}, {
		'name' : 'HEAD_TRIANGLE_UP',
		'image' : 'HEAD_TRIANGLE_UP.png'
	}, {
		'name' : 'HEAD_TRIANGLE_DOWN',
		'image' : 'HEAD_TRIANGLE_DOWN.png'
	}, {
		'name' : 'HEAD_SLASHED1',
		'image' : 'HEAD_SLASHED1.png'
	}, {
		'name' : 'HEAD_SLASHED2',
		'image' : 'HEAD_SLASHED2.png'
	}, {
		'name' : 'HEAD_DIAMOND',
		'image' : 'HEAD_DIAMOND.png'
	}, {
		'name' : 'HEAD_DIAMOND_OLD',
		'image' : 'HEAD_DIAMOND_OLD.png'
	}, {
		'name' : 'HEAD_CIRCLED',
		'image' : 'HEAD_CIRCLED.png'
	}, {
		'name' : 'HEAD_CIRCLED_LARGE',
		'image' : 'HEAD_CIRCLED_LARGE.png'
	}, {
		'name' : 'HEAD_LARGE_ARROW',
		'image' : 'HEAD_LARGE_ARROW.png'
	}, {
		'name' : 'HEAD_BREVIS_ALT',
		'image' : 'HEAD_BREVIS_ALT.png'
	}, {
		'name' : 'HEAD_SLASH',
		'image' : 'HEAD_SLASH.png'
	}, {
		'name' : 'HEAD_SOL',
		'image' : 'HEAD_SOL.png'
	}, {
		'name' : 'HEAD_LA',
		'image' : 'HEAD_LA.png'
	}, {
		'name' : 'HEAD_FA',
		'image' : 'HEAD_FA.png'
	}, {
		'name' : 'HEAD_MI',
		'image' : 'HEAD_MI.png'
	}, {
		'name' : 'HEAD_DO',
		'image' : 'HEAD_DO.png'
	}, {
		'name' : 'HEAD_RE',
		'image' : 'HEAD_RE.png'
	}, {
		'name' : 'HEAD_TI',
		'image' : 'HEAD_TI.png'
	}, {
		'name' : 'HEAD_DO_WALKER',
		'image' : 'HEAD_DO_WALKER.png'
	}, {
		'name' : 'HEAD_RE_WALKER',
		'image' : 'HEAD_RE_WALKER.png'
	}, {
		'name' : 'HEAD_TI_WALKER',
		'image' : 'HEAD_TI_WALKER.png'
	}, {
		'name' : 'HEAD_DO_FUNK',
		'image' : 'HEAD_DO_FUNK.png'
	}, {
		'name' : 'HEAD_RE_FUNK',
		'image' : 'HEAD_RE_FUNK.png'
	}, {
		'name' : 'HEAD_TI_FUNK',
		'image' : 'HEAD_TI_FUNK.png'
	}, {
		'name' : 'HEAD_DO_NAME',
		'image' : 'HEAD_DO_NAME.png'
	}, {
		'name' : 'HEAD_RE_NAME',
		'image' : 'HEAD_RE_NAME.png'
	}, {
		'name' : 'HEAD_MI_NAME',
		'image' : 'HEAD_MI_NAME.png'
	}, {
		'name' : 'HEAD_FA_NAME',
		'image' : 'HEAD_FA_NAME.png'
	}, {
		'name' : 'HEAD_SOL_NAME',
		'image' : 'HEAD_SOL_NAME.png'
	}, {
		'name' : 'HEAD_LA_NAME',
		'image' : 'HEAD_LA_NAME.png'
	}, {
		'name' : 'HEAD_TI_NAME',
		'image' : 'HEAD_TI_NAME.png'
	}, {
		'name' : 'HEAD_SI_NAME',
		'image' : 'HEAD_SI_NAME.png'
	}, {
		'name' : 'HEAD_A_SHARP',
		'image' : 'HEAD_A_SHARP.png'
	}, {
		'name' : 'HEAD_A',
		'image' : 'HEAD_A.png'
	}, {
		'name' : 'HEAD_A_FLAT',
		'image' : 'HEAD_A_FLAT.png'
	}, {
		'name' : 'HEAD_B_SHARP',
		'image' : 'HEAD_B_SHARP.png'
	}, {
		'name' : 'HEAD_B',
		'image' : 'HEAD_B.png'
	}, {
		'name' : 'HEAD_B_FLAT',
		'image' : 'HEAD_B_FLAT.png'
	}, {
		'name' : 'HEAD_C_SHARP',
		'image' : 'HEAD_C_SHARP.png'
	}, {
		'name' : 'HEAD_C',
		'image' : 'HEAD_C.png'
	}, {
		'name' : 'HEAD_C_FLAT',
		'image' : 'HEAD_C_FLAT.png'
	}, {
		'name' : 'HEAD_D_SHARP',
		'image' : 'HEAD_D_SHARP.png'
	}, {
		'name' : 'HEAD_D',
		'image' : 'HEAD_D.png'
	}, {
		'name' : 'HEAD_D_FLAT',
		'image' : 'HEAD_D_FLAT.png'
	}, {
		'name' : 'HEAD_E_SHARP',
		'image' : 'HEAD_E_SHARP.png'
	}, {
		'name' : 'HEAD_E',
		'image' : 'HEAD_E.png'
	}, {
		'name' : 'HEAD_E_FLAT',
		'image' : 'HEAD_E_FLAT.png'
	}, {
		'name' : 'HEAD_F_SHARP',
		'image' : 'HEAD_F_SHARP.png'
	}, {
		'name' : 'HEAD_F',
		'image' : 'HEAD_F.png'
	}, {
		'name' : 'HEAD_F_FLAT',
		'image' : 'HEAD_F_FLAT.png'
	}, {
		'name' : 'HEAD_G_SHARP',
		'image' : 'HEAD_G_SHARP.png'
	}, {
		'name' : 'HEAD_G',
		'image' : 'HEAD_G.png'
	}, {
		'name' : 'HEAD_G_FLAT',
		'image' : 'HEAD_G_FLAT.png'
	}, {
		'name' : 'HEAD_H',
		'image' : 'HEAD_H.png'
	}, {
		'name' : 'HEAD_H_SHARP',
		'image' : 'HEAD_H_SHARP.png'
	}, {
		'name' : 'HEAD_CUSTOM',
		'image' : 'HEAD_CUSTOM.png'
	}, {
		'name' : 'HEAD_GROUPS',
		'image' : 'HEAD_GROUPS.png'
	}, {
		'name' : 'HEAD_INVALID',
		'image' : 'HEAD_INVALID.png'
	}
];

// -----------------------------------------------------------------------
// --- Instruments -------------------------------------------------------
// -----------------------------------------------------------------------

var cA = 2
var cB = 3
var cC = 2.1
var cD = 4
var cE = 3.8
var cF = 1.2
var cG = 4.5
var cH = 1

var flbflat = new noteClass4("L Bb", {
	'closed' : '\uE006',
	'thrill' : '\uE03C'
}, cA, 1.5);
var flb = new noteClass4("L B", {
		'closed' : '\uE007',
		'thrill' : '\uE03D'
	}, cA, 2.5);
var fl1 = new noteClass4("L1", {
		'closed' : '\uE008',
		'left' : '\uE024',
		'right' : '\uE02A',
		'halfleft' : '\uE030',
		'halfright' : '\uE036',
		'thrill' : '\uE03E'
	}, cB, 1);
var fl2 = new noteClass4("L2", {
		'closed' : '\uE009',
		'ring' : '\uE01F',
		'left' : '\uE025',
		'right' : '\uE02B',
		'halfleft' : '\uE031',
		'halfright' : '\uE037',
		'thrill' : '\uE03F'
	}, cB, 2, 1);
var fl3 = new noteClass4("L3", {
		'closed' : '\uE00A',
		'ring' : '\uE020',
		'left' : '\uE026',
		'right' : '\uE02C',
		'halfleft' : '\uE032',
		'halfright' : '\uE038',
		'thrill' : '\uE040'
	}, cB, 3);
var fgsharp = new noteClass4("G #", {
		'closed' : '\uE00B',
		'thrill' : '\uE041'
	}, cD, 3.5);
var fcsharptrill = new noteClass4("C # trill", {
		'closed' : '\uE00C',
		'thrill' : '\uE042'
	}, cB, 4.2, 0.8);
var frbflat = new noteClass4("Bb trill", {
		'closed' : '\uE00D',
		'thrill' : '\uE043'
	}, cC, 4.5, 0.8);
var fr1 = new noteClass4("R1", {
		'closed' : '\uE00E',
		'ring' : '\uE021',
		'left' : '\uE027',
		'right' : '\uE02D',
		'halfleft' : '\uE033',
		'halfright' : '\uE039',
		'thrill' : '\uE044'
	}, cB, 5);
var fdtrill = new noteClass4("D trill", {
		'closed' : '\uE00F',
		'thrill' : '\uE045'
	}, cC, 5.5, 0.8);
var fr2 = new noteClass4("R2", {
		'closed' : '\uE010',
		'ring' : '\uE022',
		'left' : '\uE028',
		'right' : '\uE02E',
		'halfleft' : '\uE034',
		'halfright' : '\uE03A',
		'thrill' : '\uE046'
	}, cB, 6);
var fdsharptrill = new noteClass4("D # trill", {
		'closed' : '\uE011',
		'thrill' : '\uE047'
	}, cC, 6.5, 0.8);
var fr3 = new noteClass4("R3", {
		'closed' : '\uE012',
		'ring' : '\uE023',
		'left' : '\uE029',
		'right' : '\uE02F',
		'halfleft' : '\uE035',
		'halfright' : '\uE03B',
		'thrill' : '\uE048'
	}, cB, 7);
var fe = new noteClass4("Low E", {
		'closed' : '\uE013',
		'thrill' : '\uE049'
	}, cA, 8);
var fcsharp = new noteClass4("Low C #", {
		'closed' : '\uE014',
		'thrill' : '\uE04A'
	}, cA, 9);
var fc = new noteClass4("Low C", {
		'closed' : '\uE015',
		'thrill' : '\uE04B'
	}, cB, 9);
var fbflat = new noteClass4("Low Bb", {
		'closed' : '\uE016',
		'thrill' : '\uE04C'
	}, cD, 9);
var fgizmo = new noteClass4("Gizmo", {
		"closed" : "\uE017",
		"thrill" : "\uE04D"
	}, cD, 10, 0.8);

var fKCUpLever = new noteClass4("fKCUpLever", {
		'closed' : '\uE018',
		'thrill' : '\uE04E'
	}, cE, 1.5, 0.8);
var fKAuxCSharpTrill = new noteClass4("fKAuxCSharpTrill", {
		'closed' : '\uE019',
		'thrill' : '\uE04F'
	}, cE, 2.5, 0.8);
var fKBbUpLever = new noteClass4("fKBbUpLever", {
		'closed' : '\uE01A',
		'thrill' : '\uE050'
	}, cF, 1, 0.8);
var fKBUpLever = new noteClass4("fKBUpLever", {
		'closed' : '\uE01B',
		'thrill' : '\uE051'
	}, cF, 2, 0.8);
var fKGUpLever = new noteClass4("fKGUpLever", {
		'closed' : '\uE01C',
		'thrill' : '\uE052'
	}, cG, 4.5, 0.8);
var fKFSharpBar = new noteClass4("fKFSharpBar", {
		'closed' : '\uE01D',
		'thrill' : '\uE053'
	}, cH, 5, 0.8);
var fKDUpLever = new noteClass4("fKDUpLever", {
		'closed' : '\uE01E',
		'thrill' : '\uE054'
	}, cA, 10, 0.8);

var categories = {
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
				"id" : "flute", // instrument Id from https://github.com/musescore/MuseScore/blob/3.x/share/instruments/instruments.xml
				"label" : "Flute", // nice name
				"base" : ['\uE000', '\uE001'], // C
				"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fgizmo]
			}
		},
		"library" : []
	},
	// unused - in progress
	"clarinet" : {
		"default" : "clarinet",
		"config" : [],
		"support" : [],
		"instruments" : {
			"clarinet" : {
				"id" : "clarinet", // instrument Id from https://github.com/musescore/MuseScore/blob/3.x/share/instruments/instruments.xml
				"label" : "Clarinet", // nice name
				"base" : ['\uE000', '\uE001', '\uE002', '\uE003'], // B + C thrill,
				"keys" : [flbflat, flb, fl1, fl2, fl3, fgsharp, fcsharptrill, frbflat, fr1, fdtrill, fr2, fdsharptrill, fr3, fe, fcsharp, fc, fbflat]
			}
		},
		"library" : []
	},
	// default and empty category
	"" : {
		"default" : "",
		"config" : [],
		"support" : [],
		"instruments" : {
			"" : {
				"id" : "piano",
				"label" : "default",
				"base" : [],
				"keys" : []
			}
		},
		"library" : []
	}

};

// -----------------------------------------------------------------------
// --- Classes -------------------------------------------------------
// -----------------------------------------------------------------------

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

/**
 * Class representing a preset.
 * @param category A category of instrument. Must match any of the categories defined in the categories arrays
 * @param label A label. Optional. If non proivded then replaced by an empty string
 * @param accidental The accidental of the note. A *string* corresponding to an element of  Musescore Accidental enumeration. Optional. If non proivded then replaced by "--", meaining "suitable to all notes".
 * @param representation The textual representation of the key combination. Is expected to be a valid unicode combination ,ut no verification is made. Optional. If non proivded then replaced by an empty string.
 * @param head The head of the note. A *string* corresponding to an element of  Musescore HeadGroup enumeration. Optional. If non proivded then replaced by "--", meaining "suitable to all notes".
 */

function presetClass(category, label, note, accidental, representation, head) {
	this.category = (category !== undefined) ? String(category) : "??";

	this.label = (label !== undefined) ? String(label) : "";

	var _note = (note !== undefined) ? String(note) : "";

	var _acc = generic_preset;
	if (accidental !== undefined && accidental !== "" && accidental !== generic_preset) {
		_acc = String(accidental);
		var accid = eval("Accidental." + _acc);
		if (accid === undefined || accid == 0)
			_acc = "NONE";
		0
	}

	this.head = generic_preset;
	if (head !== undefined && head !== "" && head !== generic_preset) {
		var hd = String(head);
		var accid = eval("NoteHeadGroup." + hd);
		if (accid === undefined || accid == 0)
			hd = "HEAD_NORMAL";
		this.head = hd;
	}

	this.representation = (representation !== undefined) ? String(representation) : "";

	var _pitch = NoteHelper.buildPitchedNote(_note, _acc).pitch;

	Object.defineProperty(this, "accidental", {
		get : function () {
			return _acc;
		},
		enumerable : true
	});

	Object.defineProperty(this, "note", {
		get : function () {
			return _note;
		},
		enumerable : true
	});

	Object.defineProperty(this, "pitch", {
		get : function () {
			return _pitch;
		},
		//enumerable : false
		enumerable : true // should be false, because it is transient. but if we keep at false then the selectPreset function is no able to access it.
	});

}

/**
 * Creation of a preset from a preset object containing the *enumerable* fields (ie. the non transient fields)
 */
function presetClassRaw(raw) {
	presetClass.call(this, raw.category, raw.label, raw.note, raw.accidental, raw.representation, raw.head);
}

// -----------------------------------------------------------------------
// --- Codes -------------------------------------------------------
// -----------------------------------------------------------------------


/** category of instrument :"flute","clarinet", ... */
var __category = ""
/** alias to the different keys schemas for a the current category. */
var __instruments = categories[__category]["instruments"]
var __modelInstruments = Object.keys(__instruments);

/** alias to the different config options in the current category. */
var __config = categories[__category]["config"];
/** alias to the different library  in the current category. */
var __library = categories[__category]["library"];
/** alias to the different notes in the activated configs in the current category. */
var __confignotes = []

// hack
var refreshed = true;
var presetsRefreshed = true
	var ready = false;

/** the notes to which the fingering must be made. */
var __notes = []; // TODO 2.0 moved as QML property

// config
var atFingeringLevel = true;

// work variables
var lastoptions;
var currentInstrument = ""
	var currentPreset = undefined
	var __asAPreset = new presetClass()

	// constants
	/* All the supported states. */
	var basestates = ["open", "closed"];
var halfstates = ["right", "left"];
var quarterstates = ["halfright", "halfleft"];
var thrillstates = ["thrill"];
var ringstates = ["ring"];

/* All the playing techniques (aka "states") used by default. */
// *User instructions*= Modify the default states by concatenating any of states arrays found above
//var usedstates = basestates;
var usedstates = basestates.concat(thrillstates);

var titlePointSize = 12
var tooltipShow = 500
var tooltipHide = 5000

var similarpitch = 2

// -----------------------------------------------------------------------
// --- Read the score ----------------------------------------------------
// -----------------------------------------------------------------------
function init() {

	if (Qt.fontFamilies().indexOf('Fiati') < 0) {
		return false;
	}

	// lecture des options
	readOptions();
	readLibrary();
	if (tuningSettingsFile.exists()) {
		console.log("AccidentalTuning settings file found.")
		loadTuningSettings();
	} else {
		console.log("AccidentalTuning settings file not found.")
	}

	return true;
}

function analyseSelection() {
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
		notes = SelHelper.getNotesRestsFromCursor(true);
		if (notes && (notes.length > 0)) {
			debug(level_DEBUG, "NOTES FOUND FROM CURSOR");
		} else {
			notes = SelHelper.getNotesRestsFromSelection();
			if (notes && (notes.length > 0)) {
				debug(level_DEBUG, "NOTES FOUND FROM SELECTION");
			} else {
				debug(level_DEBUG, "NO NOTES FOUND");
				var fingerings = SelHelper.getFingeringsFromSelection();
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
					notes = [];
					//invalidSelectionDialog.open(); // v2 Autorisé
					//return;
				}
			}
		}

		if (notes && (notes.length > 0)) {
			// Notes and Rests
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
				if (isValidNote) { // On enrichit tout: Note comme Rest.
					var fingerings = getFingerings(note);
					enrichNoteHead(note); // add note name, accidental name, ...

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
	debugV(level_INFO, ">>", "notes", notes.length);
	debugV(level_INFO, ">>", "instrument", instrument);
	debugV(level_INFO, ">>", "category", category);
	debugV(level_INFO, ">>", "fingering", ((fingering) ? fingering.text : fingering));
	debugV(level_INFO, ">>", "errors", errors);
	debugV(level_INFO, ">>", "warnings", warnings);
	// INVALID INSTRUMENT
	if (!instrument && !category) {
		//unkownInstrumentDialog.open(); // v2: autorisé
		//return;
		notes = [];
		category = "";
		instrument = "";
	}

	// CORRECT INSTRUMENT
	/*Properties.*/__notes = notes;
	__category = category;

	// On fabrique le modèle pour le ComboBox
	// TODO 2.0 A remettre 
	/*
	pushFingering(fingering ? fingering.text : undefined)

	// on sélectionne la 1ère note dans la liste des presets
	if (notes.length > 0) {
		var note1 = undefined;
		for (var i = 0; i < notes.length; i++) {
			if (notes[i].type === Element.NOTE) {
				note1 = notes[i];
				break;
			}
		}

		if (note1) {
			selectPreset(
				new presetClass(__category, "", note1.extname.name, note1.accidentalData.name, fingering ? fingering.text : undefined, note1.headData.name), false);
			if (lstPresets.currentIndex >= 0) {
				currentPreset = lstPresets.model[lstPresets.currentIndex];
				debugO(level_DEBUG, "Matching startup preset", currentPreset);
			} else {
				currentPreset = undefined;
				debug(level_DEBUG, "Matching startup preset - none");
			}
		}
	}*/ 
	ready = true;
}

function pushFingering(ff) {
	ready = false;

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
	currentInstrument = instrument_type;
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
function writeFingering(sFingering) {

	debugV(level_INFO, "Fingering", "as string", sFingering);

	curScore.startCmd();
	debug(level_TRACE, ">>>>>START CMD [write fingering]");
	if (atFingeringLevel) {
		// Managing fingering in the Fingering element (note.elements)
		var prevNote = undefined;
		var firstNote;
		for (var i = 0; i < __notes.length; i++) {
			var note = __notes[i];
			if (note.type != Element.NOTE) {
				debugV(level_DEBUG, "Skipping fingering for non note", "index", i);
				prevNote = undefined;
				continue;
			}
			debugV(level_DEBUG, "Going for fingering of element", "index", i);

			if ((prevNote === undefined) || (prevNote && !prevNote.parent.is(note.parent))) {
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

				addFingeringTextToNote(note, sFingering, f);

			} else {
				// We don't treat the other notes of the same chord
				debug(level_DEBUG, "skipping next note of same chord");
			}
			prevNote = note;
		}

	}

	debug(level_TRACE, "<<<<<END CMD [write fingering]");
	curScore.endCmd(false);
}

function addFingeringTextToNote(note, representation, textobj) {
	// If no fingering found, create a new one
	if (!textobj) {
		debug(level_DEBUG, "adding a new fingering");
		var f = newElement(Element.FINGERING);
		f.text = representation;
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
		textobj.text = representation;
		debug(level_DEBUG, "exsiting fingering modified");
	}

}

/**
 * Analyze the alignement needs (accidental and/or heads). If the alignement strategy is "Ask each time" and
 * if there is a need in alignement, then ask what to do. Otherwise (depending on the strategy), either align
 * without further questions or leave.
 */
function alignToPreset(forceAcc, forceHead, doTuning) {

	// no preset ? no alignement needed
	if (currentPreset === undefined) {
		// console.log("--No preset => no alignement");
		alignToPreset_after();
		return;
	}

	//console.log("--Default forceAcc="+forceAcc);
	//console.log("--Default forceHead="+forceHead);

	// both default behaviours set to "Never Align" ? no alignement needed
	if (!forceAcc && !forceHead && !doTuning) {
		//console.log("-- => no alignement");
		alignToPreset_after();
		return;
	}

	curScore.startCmd();
	debug(level_TRACE, ">>>>>START CMD [align to preset]");

	if (atFingeringLevel) {
		// Managing fingering in the Fingering element (note.elements)
		var prevNote = undefined;
		var firstNote;
		for (var i = 0; i < __notes.length; i++) {
			var note = __notes[i];
			if (note.type == Element.REST) {
				note = alignToPreset_do(note, currentPreset, forceAcc, forceHead, doTuning);
				__notes[i] = note;
			} else if ((prevNote === undefined) || (prevNote && !prevNote.parent.is(note.parent))) {
				// first note of chord. Going to treat the chord as once
				debug(level_TRACE, "dealing with first note");
				var chordnotes = note.parent.notes;

				for (var j = 0; j < chordnotes.length; j++) {
					var nt = enrichNoteHead(chordnotes[j]);
					alignToPreset_do(nt, currentPreset, forceAcc, forceHead, doTuning);
				}
			}
			prevNote = note;
		}
	}

	// console.log("-- => alignement required");

	debug(level_TRACE, "<<<<<END CMD [align to preset]");
	curScore.endCmd(false);
	alignToPreset_after();
}

/**
 * Execute the alignement.
 */
function alignToPreset_do(nt, preset, forceAcc, forceHead, doTuning) {

	if (preset === undefined)
		return;

	var t = {
		'note' : preset.note,
		'accidental' : ((preset.accidental !== generic_preset) ? preset.accidental : "NONE")
	};
	var target = NoteHelper.buildPitchedNote(t.note, t.accidental);

	debugO(level_DEBUG, "Target note: ", t);
	debugO(level_DEBUG, "Target note: ", target);

	// note and accidental
	if (forceAcc) {
		debug(level_DEBUG, "** aligning note **");
		if (nt.type == Element.REST) {
			var note = restToNote(nt, target);
			nt = note;
			enrichNoteHead(nt);
		}

		// we must align the accidental too
		if (preset.accidental !== generic_preset && preset.accidental !== nt.accidentalData.name) {
			debug(level_DEBUG, "** aligning accidental **");
			nt.accidentalType = eval("Accidental." + preset.accidental);
		}
		// To do **after** the set of accidentalType because this (kinda) resets the pitch
		changeNote(nt, target);

	}

	// we must align the head
	if (forceHead && (nt.type == Element.NOTE)) {
		if (preset.head !== generic_preset && preset.head !== nt.headData.name) {
			debug(level_DEBUG, "** aligning head **");
			nt.headGroup = eval("NoteHeadGroup." + preset.head);
		}
	}
	// tuning
	debug(level_TRACE, "Tuning before:" + nt.tuning);
	if (doTuning && (nt.type == Element.NOTE)) {
		debug(level_DEBUG, "** aligning tuning **");
		nt.tuning = getAccidentalTuning(preset.accidental);
	}
	debug(level_TRACE, "Tuning after:" + nt.tuning);

	return nt;
}

function alignToPreset_after() {
	//console.log("===AFTER ALIGNEMENT TO PRESET==");
}

function removeAllFingerings() {

	var nbNotes = __notes.length;
	var nbFing = 0

		curScore.startCmd();
	debug(level_TRACE, ">>>>>START CMD [remove fingering]");
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
					for (var k = 0; k < fgs.length; k++) {
						nbFing++;
						nt.remove(fgs[k]);
						debug(level_TRACE, "removing unneeded fingering");
					}
				}
			}
		}
	}

	debug(level_TRACE, "<<<<<END CMD [remove fingering]");
	curScore.endCmd(false);
	return {
		'nbnotes' : nbNotes,
		'nbdeleted' : nbFing
	};
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
	if ((note.type != Element.NOTE) && (note.type != Element.REST)) {
		return undefined;
	} else {
		// var nstaff = Math.ceil(note.track / 4); // 14/2/21 pas utile ?
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

function changeNote(note, toNote) {
	if (note.type != Element.NOTE) {
		debug(level_INFO, "! Changing Note of a non-Note element");
		return;
	}

	var debugTpc = note.tpc;

	debugPitch(level_TRACE, "Before correction", note);
	note.tpc1 = toNote.tpc1;
	note.tpc2 = toNote.tpc2;
	note.pitch = toNote.pitch;
	debugPitch(level_TRACE, "After correction", note);

	return note;

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
	oCursor.setDuration(duration.numerator, duration.denominator);
	//oCursor.addNote(toNote.pitch); // We can add whatever note here, we'll rectify it afterwards
	oCursor.addNote(0); // We can add whatever note here, we'll rectify it afterwards
	oCursor.rewindToTick(cur_time);
	var chord = oCursor.element;
	var note = chord.notes[0];

	debugPitch(level_DEBUG, "Added note", note);

	changeNote(note, toNote);

	debugPitch(level_DEBUG, "Corrected note", note);

	return note;
}
/**
 * Enrichit Note et Rest d'une même manière (point de vue propriété de l'objet)
 */
function enrichNoteHead(note) {

	// Par défaut:
	note.headData = {
		name : "UNKOWN",
		image : "NONE.png"
	};

	note.accidentalData = {
		name : "UNKOWN",
		image : "NONE.png"
	};

	note.extname = {
		"fullname" : "",
		"name" : "",
		"raw" : "",
		"octave" : ""
	};

	if (note.type === Element.NOTE) {
		// accidental
		var id = note.accidentalType;
		for (var i = 1; i < accidentals.length; i++) { // starting at 1 because 0 is the generic one ("--")
			var acc = accidentals[i];
			if (id == eval("Accidental." + acc.name)) {
				note.accidentalData = acc;
				break;
			}
		}

		// note name and octave
		var tpc = {
			'tpc' : 0,
			'name' : '?',
			'raw' : '?'
		};
		var pitch = note.pitch;
		var pitchnote = NoteHelper.pitchnotes[pitch % 12];
		var noteOctave = Math.floor(pitch / 12) - 1;

		for (var i = 0; i < NoteHelper.tpcs.length; i++) {
			var t = NoteHelper.tpcs[i];
			if (note.tpc == t.tpc) {
				tpc = t;
				break;
			}
		}

		if (pitchnote == "B" && tpc.raw == "C") {
			noteOctave++;
		} else if (pitchnote == "C" && tpc.raw == "B") {
			noteOctave--;
		}

		note.extname = {
			"fullname" : tpc.name + noteOctave,
			"name" : tpc.raw + noteOctave,
			"raw" : tpc.raw,
			"octave" : noteOctave
		};

		// head
		var grp = note.headGroup ? note.headGroup : 0;
		for (var i = 1; i < heads.length; i++) { // starting at 1 because 0 is the generic one ("--")
			var head = heads[i];
			if (grp == eval("NoteHeadGroup." + head.name)) {
				note.headData = head;
				break;
			}
		}

	} else if (note.type === Element.REST) {
		note.extname = {
			"fullname" : "Rest",
			"name" : "--",
			"raw" : "",
			"octave" : ""
		};

	}
	return note;
}
// -----------------------------------------------------------------------
// --- String extractors -------------------------------------------------
// -----------------------------------------------------------------------
function extractInstrument(category, sKeys) {
	var splt = sKeys.split('');
	var found;
	var instruments = categories[category]["instruments"];
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
	lastoptions['equivalence'] = (chkEquivAccidental.checkState === Qt.Checked) ? "true" : "false";

	// push to notes options
	lastoptions['pushacc'] = (chkForceAccidental.checkState === Qt.Checked) ? "true" : "false";
	lastoptions['pushhead'] = (chkForceHead.checkState === Qt.Checked) ? "true" : "false";
	lastoptions['pushtuning'] = (chkDoTuning.checkState === Qt.Checked) ? "true" : "false";

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

	if (settingsFile.write(t)) {
		txtStatus.text = "Settings saved to " + settingsFile.source;
	} else {
		txtStatus.text = "Error while saving the settings";
	}

}

function saveLibrary() {

	var allpresets = {};

	var cats = Object.keys(categories);

	for (var c = 0; c < cats.length; c++) {
		var cat = cats[c];
		allpresets[cat] = categories[cat]['library'];
	}

	var t = JSON.stringify(allpresets) + "\n";
	debug(level_DEBUG, t);

	if (libraryFile.write(t)) {
		//txtStatus.text="Library saved to " + libraryFile.source;
		txtStatus.text = "";
	} else {
		txtStatus.text = "Error while saving the library";
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

	if (!settingsFile.exists())
		return;

	var json = settingsFile.read();

	debug(level_DEBUG, json);

	try {
		lastoptions = JSON.parse(json);
	} catch (e) {
		console.error('while reading the option file', e.message);
	}

	// used states
	usedstates = lastoptions['states'];
	// displayUsedStates(); // 2.0 

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
	chkEquivAccidental.checkState = (lastoptions['equivalence'] === "true") ? Qt.Checked : Qt.Unchecked;

	// push to notes options
	chkForceAccidental.checkState = (lastoptions['pushacc'] === "true") ? Qt.Checked : Qt.Unchecked;
	debug(level_DEBUG, "readOptions: 'pushacc' --> " + chkForceAccidental.checked + " (" + lastoptions['pushacc'] + ")");
	chkForceHead.checkState = (lastoptions['pushhead'] === "true") ? Qt.Checked : Qt.Unchecked;
	debug(level_DEBUG, "readOptions: 'pushhead' --> " + chkForceHead.checked + " (" + lastoptions['pushhead'] + ")");
	chkDoTuning.checkState = (lastoptions['pushtuning'] === "true") ? Qt.Checked : Qt.Unchecked;
	debug(level_DEBUG, "readOptions: 'pushtuning' --> " + chkDoTuning.checked + " (" + lastoptions['pushtuning'] + ")");

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

	if (!libraryFile.exists())
		return;

	var json = libraryFile.read();

	var allpresets = {};

	try {
		allpresets = JSON.parse(json);
	} catch (e) {
		console.error('while reading the library file', e.message);
	}

	var cats = Object.keys(categories);

	for (var c = 0; c < cats.length; c++) {
		var cat = cats[c];
		var pp = [];
		for (var i = 0; i < allpresets[cat].length; i++) {
			var raw = allpresets[cat][i];
			if (raw.head == undefined) {
				raw.head = generic_preset;
			}
			var p = new presetClassRaw(raw); // getting a real presetClass with the transient fields set correclty
			debugO(level_DEBUG, "readLibrary: preset:", p);
			debugP(level_DEBUG, "readLibrary: preset:", p, "pitch"); // transient = non-enumerable
			pp.push(p);
		}

		categories[cat]['library'] = pp;

	}

}

// -----------------------------------------------------------------------
// --- Export library -----------------------------------------------------
// -----------------------------------------------------------------------
function printLibrary(category) {
	if (category === undefined) {
		console.warn("Library export: not category has been provided");
		return;
	}

	if (categories[category] === undefined) {
		console.warn("Library export: invalid category " + category);
		return;
	}
	debug(level_INFO, "Exporting " + category + " library");

	var def = categories[category]["default"];
	var instru = categories[category]["instruments"][def];

	var lib = categories[category]["library"];

	for (var i = 0; i < lib.length; i++) {
		var preset = lib[i];
		preset.tuning = getAccidentalTuning(preset.accidental);
		preset.orderkey = preset.pitch * 100 + preset.tuning;

	}

	// Sorting the library
	lib = lib.sort(function (a, b) {
			var res = a.orderkey - b.orderkey;
			if (res == 0)
				res = a.representation.localeCompare(b.representation);
			return res;
		});

	var score = newScore("library", instru.id, ((lib.length == 0) ? 1 : lib.length));
	//var score = newScore("library", instru.id, 99);
	var numerator = 4;
	var denominator = 4;

	score.addText("title", "Alternate " + instru.label + " diagrams");

	score.startCmd();

	var cursor = score.newCursor();
	cursor.track = 0;

	cursor.rewind(0);
	var ts = newElement(Element.TIMESIG);
	ts.timesig = fraction(numerator, denominator);
	cursor.add(ts);

	cursor.rewind(0);

	for (var i = 0; i < lib.length; i++) {
		if (i > 0)
			cursor.next();
		cursor.setDuration(0, 0); // quarter
		var rest = cursor.element;
		var preset = lib[i];
		debugO(level_DEBUG, "Exporting preset", preset);
		rest = alignToPreset_do(rest, preset, true, true, true);
		addFingeringTextToNote(rest, preset.representation);

		if (preset.label !== undefined && preset.label !== "") {

			//var f = newElement(Element.STAFF_TEXT);
			var f = newElement(Element.TEXT);
			//f.subStyle=Tid.EXPRESSION;
			f.fontSize = 8;
			f.text = preset.label.replace(" ", "\n");
			// LEFT = 0, RIGHT = 1, HCENTER = 2, TOP = 0, BOTTOM = 4, VCENTER = 8, BASELINE = 16
			f.align = 6; // HCenter and Bottom
			f.placement = Placement.ABOVE;
			// Turn on note relative placement
			f.autoplace = true;
			f.offsetY = -5;
			//rest.parent.add(f);  // STAFF_TEXT added at the level of the Segment (and not the note)
			rest.add(f); // STAFF_TEXT added at the level of the Segment (and not the note)

		}

	}

	score.endCmd();

}

// -----------------------------------------------------------------------
// --- AccindetalTuner support -------------------------------------------
// -----------------------------------------------------------------------
// Taken from AccidentalTuner.qml but adapted to feed our own accidentals model
function loadTuningSettings() {
	var textInFile = tuningSettingsFile.read();
	var lines = textInFile.split("\n");
	for (var i = 0; i < lines.length; i++) {
		if (lines[i][0] == '{') {
			try {
				var obj = JSON.parse(lines[i]);
				for (var j = 0; j < accidentals.length; j++) {
					if (obj.name == accidentals[j].name) {
						accidentals[j].tuning = obj.tuning;
						break;
					}
				}

			} catch (e) {}
		}
	}
}

// Taken from AccidentalTuner.qml but adapted to get the tuning from our own accidentals model
function getAccidentalTuning(accidental) {
	//if accidental not in the accidentalList, return 0

	for (var i = 0; i < accidentals.length; i++) {
		if (accidental == accidentals[i].name) {
			return accidentals[i].tuning;
		}
	}

	return 0;
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

function debugPitch(level, label, note) {
	debugP(level, label, note, 'pitch');
	debugP(level, label, note, 'tpc1');
	debugP(level, label, note, 'tpc2');
}
