import QtQuick 2.9
import QtQuick.Controls 2.2
import MuseScore 3.0
import QtQuick.Window 2.2
import QtQuick.Dialogs 1.2
import QtQuick.Controls.Styles 1.4
import QtQuick.Layouts 1.1
import FileIO 3.0

import "zparkingb/selectionhelper.js" as SelHelper
import "zparkingb/notehelper.js" as NoteHelper

MuseScore {
	menuPath : "Plugins.Alternate Fingering"
	description : "Add and edit alternate fingering"
	version : "1.4.0"
	pluginType : "dialog"
	//dockArea: "right"
	requiresScore : true
	width : 600
	height : 600

	id : mainWindow

	// -----------------------------------------------------------------------
	// --- Read the score ----------------------------------------------------
	// -----------------------------------------------------------------------
	onRun : {

		if (!init()) {
			fontMissingDialog.open();
			return;
		}
		
		// preliminary check of the usedstates
		displayUsedStates();


		analyseSelection();
	}

	// -----------------------------------------------------------------------
	// --- Modify the score ----------------------------------------------------
	// -----------------------------------------------------------------------
	function writeFingering() {

		var sFingering = buildFingeringRepresentation();

		CORE.writeFingering(sFingering);

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

	/**
	 * Analyze the alignement needs (accidental and/or heads). If the alignement strategy is "Ask each time" and
	 * if there is a need in alignement, then ask what to do. Otherwise (depending on the strategy), either align
	 * without further questions or leave.
	 */
	function alignToPreset() {
		CORE.alignToPreset((chkForceAccidental.checkState === Qt.Checked), (chkForceHead.checkState === Qt.Checked), chkDoTuning.enabled && (chkDoTuning.checkState === Qt.Checked))
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
					font.pointSize : titlePointSize
					leftPadding : 10
					rightPadding : 10
				}

				Loader {
					id : loadInstru
					Layout.fillWidth : true
					sourceComponent : (__modelInstruments.length <= 1) ? txtInstruCompo : lstInstruCompo
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

			Rectangle { // panKeys
				id : panKeys

				Layout.fillHeight : true
				Layout.fillWidth : true

				color : "#F0F0F0"
				clip : true

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

			Rectangle {
				Layout.preferredHeight : txtOptAlign.implicitHeight + 4 // 4 pour les marges
				Layout.fillWidth : true
				color : "#C0C0C0"

				Text {
					id : txtOptAlign
					text : "Align slected notes on preset..."
					Layout.fillWidth : true
					rightPadding : 5
					leftPadding : 5
					horizontalAlignment : Qt.AlignLeft
				}
			}

			Rectangle {

				id : panOptions
				visible : true
				color : "#F0F0F0"
				Layout.preferredWidth : layOptions.implicitWidth + 10
				Layout.fillWidth : true
				Layout.preferredHeight : layOptions.implicitHeight + 10
				anchors.margins : 20

				Grid {
					id : layOptions

					columns : 1
					columnSpacing : 5
					rowSpacing : -2

					CheckBox {
						id : chkForceAccidental
						text : "Note/accidental"
						Layout.alignment : Qt.AlignVCenter | Qt.AlignLeft
						Layout.rightMargin : 5
						Layout.leftMargin : 5
						indicator : Rectangle {
							implicitWidth : 12
							implicitHeight : implicitWidth
							x : chkForceAccidental.leftPadding + 2
							y : parent.height / 2 - height / 2
							border.color : "grey"

							Rectangle {
								width : parent.implicitWidth / 2
								height : parent.implicitWidth / 2
								x : parent.implicitWidth / 4
								y : parent.implicitWidth / 4
								color : "grey"
								visible : chkForceAccidental.checked
							}
						}
					}

					CheckBox {
						id : chkDoTuning
						text : "+ tunings"
						Layout.alignment : Qt.AlignTop | Qt.AlignLeft
						Layout.rightMargin : 5
						Layout.leftMargin : 5
						indicator.width : 16
						indicator.height : 16
						enabled : tuningSettingsFile.exists() && chkForceAccidental.checked
					}

					CheckBox {
						id : chkForceHead
						text : "Notes heads"
						Layout.alignment : Qt.AlignVCenter | Qt.AlignLeft
						Layout.rightMargin : 5
						Layout.leftMargin : 5
						indicator.width : 16
						indicator.height : 16
					}

				}
			}

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
				anchors.fill : parent

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
					hoverEnabled : true
					ToolTip.delay : tooltipShow
					ToolTip.timeout : tooltipHide
					ToolTip.visible : hovered
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
					hoverEnabled : true
					ToolTip.delay : tooltipShow
					ToolTip.timeout : tooltipHide
					ToolTip.visible : hovered
				}

				Button {
					implicitHeight : buttonBox.contentItem.height
					implicitWidth : buttonBox.contentItem.height

					indicator :
					Image {
						source : "alternatefingering/export.svg"
						mipmap : true // smoothing
						width : 23
						fillMode : Image.PreserveAspectFit // ensure it fits
						anchors.centerIn : parent
					}
					onClicked : printLibrary(__category)
					ToolTip.text : "Print library"
					hoverEnabled : true
					ToolTip.delay : tooltipShow
					ToolTip.timeout : tooltipHide
					ToolTip.visible : hovered
				}

				Item { // spacer // DEBUG Item/Rectangle
					id : spacer
					implicitHeight : 10
					Layout.fillWidth : true
				}

				Button {
					text : "Remove fingerings..."
					implicitHeight : buttonBox.contentItem.height
					//implicitWidth : buttonBox.contentChildren[0].width
					onClicked :
					confirmRemoveMissingDialog.open()
				}

				DialogButtonBox {
					standardButtons : DialogButtonBox.Close
					id : buttonBox

					background.opacity : 0 // hide default white background

					Button {
						text : "Apply"
						DialogButtonBox.buttonRole : DialogButtonBox.AcceptRole
					}

					onAccepted : {
						alignToPreset(); // first aligning the notes if needed (and replacing the rests by notes if required)
						writeFingering(); // secondly adding the fingering
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
			Layout.preferredHeight : txtNote.implicitHeight
			//color: "#F0F0F0"

			id : panStatusBar

			Text {
				id : txtStatus
				text : ""
				wrapMode : Text.NoWrap
				elide : Text.ElideRight
				maximumLineCount : 1
				anchors.left : parent.left
				anchors.right : txtCurPNote.left
			}

			Item {
				id : txtCurPNote
				anchors.right : txtCurPAcc.left
				implicitHeight : txtNoteAcc.height
				implicitWidth : 24
				Text {
					text : (currentPreset) ? currentPreset.note : "--"
					leftPadding : 5
					rightPadding : 5
					anchors.centerIn : parent
				}
				// dummy left border
				Rectangle {
					width : 2
					x : 0
					color : "#929292"
					implicitHeight : 18
					anchors.verticalCenter : parent.verticalCenter
				}
			}

			Item {
				id : txtCurPAcc
				anchors.right : txtCurPHead.left
				anchors.leftMargin : 5
				implicitHeight : i_pna.height
				implicitWidth : i_pna.width
				Image {
					id : i_pna
					source : "./alternatefingering/" + ((currentPreset) ? getAccidentalImage(currentPreset.accidental) : "NONE.png")
					fillMode : Image.PreserveAspectFit
					anchors.centerIn : parent
					height : 20
					width : 20
				}

				// dummy left border
				Rectangle {
					width : 2
					x : 0
					color : "#929292"
					implicitHeight : 18
					anchors.verticalCenter : parent.verticalCenter
				}
			}

			Item {
				id : txtCurPHead
				anchors.right : txtNote.left
				anchors.leftMargin : 5
				implicitHeight : i_pnh.height
				implicitWidth : i_pnh.width

				Image {
					id : i_pnh
					source : "./alternatefingering/" + ((currentPreset) ? getHeadImage(currentPreset.head) : "NONE.png")
					fillMode : Image.PreserveAspectFit
					anchors.centerIn : parent
					height : 20
					width : 20
				}

				// dummy left border
				Rectangle {
					width : 2
					x : 0
					color : "#929292"
					implicitHeight : 18
					anchors.verticalCenter : parent.verticalCenter
				}
			}
			Rectangle {
				id : txtNote
				anchors.right : txtNoteAcc.left
				implicitHeight : txtNoteAcc.height
				implicitWidth : 24
				// anchors.leftMargin : 5

				color : (currentPreset && (__notes.length > 0) && (currentPreset.note != __notes[0].extname.name)) ? "lightpink" : "transparent"

				Text {
					id : i_tn
					text : (__notes.length > 0) ? __notes[0].extname.name : "--"
					anchors.centerIn : parent
					leftPadding : 5
					rightPadding : 5
				}

				// dummy left border
				Rectangle {
					width : 2
					x : 0
					color : "#929292"
					implicitHeight : 18
					anchors.verticalCenter : parent.verticalCenter
				}

			}

			Rectangle {
				id : txtNoteAcc
				anchors.right : txtNoteHead.left
				anchors.leftMargin : 5
				implicitHeight : i_tna.height
				implicitWidth : i_tna.width

				color : (currentPreset && (__notes.length > 0) && (currentPreset.accidental != generic_preset) && (currentPreset.accidental != __notes[0].accidentalData.name)) ? "lightpink" : "transparent"

				Image {
					id : i_tna
					source : "./alternatefingering/" + ((__notes.length > 0) ? __notes[0].accidentalData.image : "NONE.png")
					fillMode : Image.PreserveAspectFit
					anchors.centerIn : parent
					height : 20
					width : 20
				}
				// dummy left border
				Rectangle {
					width : 2
					x : 0
					color : "#929292"
					implicitHeight : 18
					anchors.verticalCenter : parent.verticalCenter
				}

			}
			Rectangle {
				id : txtNoteHead
				anchors.right : parent.right
				anchors.leftMargin : 5
				implicitHeight : i_tnh.height
				implicitWidth : i_tnh.width

				color : (currentPreset && (__notes.length > 0) && (currentPreset.head != generic_preset) && (currentPreset.head != __notes[0].headData.name)) ? "lightpink" : "transparent"

				Image {
					id : i_tnh
					source : "./alternatefingering/" + ((__notes.length > 0) ? __notes[0].headData.image : "NONE.png")
					fillMode : Image.PreserveAspectFit
					anchors.centerIn : parent
					height : 20
					width : 20
				}
				// dummy left border
				Rectangle {
					width : 2
					x : 0
					color : "#929292"
					implicitHeight : 18
					anchors.verticalCenter : parent.verticalCenter
				}

			}
		} // status bar
		GroupBox {
			title : "Presets" + (chkFilterPreset.checkState === Qt.Checked ? " (strict)" : chkFilterPreset.checkState === Qt.PartiallyChecked ? " (similar)" : "")
			Layout.row : 2
			Layout.column : 1
			Layout.columnSpan : 1
			Layout.rowSpan : 4

			Layout.fillHeight : true

			anchors.rightMargin : 5
			anchors.topMargin : 10
			anchors.bottomMargin : 10
			//topPadding: 10

			ColumnLayout { // left column
				anchors.fill : parent
				spacing : 10

				ListView { // Presets
					Layout.fillHeight : true
					//Layout.fillWidth : true
					width : 125

					id : lstPresets

					model : getPresetsLibrary(presetsRefreshed) //__library
					delegate : presetComponent
					clip : true
					focus : true

					highlightMoveDuration : 250 // 250 pour changer la sélection
					highlightMoveVelocity : 2000 // ou 2000px/sec


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

							tristate : true

							padding : 0
							spacing : 0

							indicator : Rectangle {
								implicitHeight : buttonBox.contentItem.height * 0.6 //btnOk.height
								implicitWidth : buttonBox.contentItem.height * 0.6 //btnOk.height
								color : chkFilterPreset.pressed ? "#C0C0C0" :
								chkFilterPreset.checkState === Qt.Checked ? "#C0C0C0" : chkFilterPreset.checkState === Qt.PartiallyChecked ? "#D0D0D0" : "#E0E0E0"
								anchors.centerIn : parent
								Image {
									id : imgFilter
									mipmap : true // smoothing
									width : 21 // 23, a little bit smaller
									source : "alternatefingering/filter.svg"
									fillMode : Image.PreserveAspectFit // ensure it fits
									anchors.centerIn : parent
								}
							}
							onClicked : {
								presetsRefreshed = false; // awfull hack
								presetsRefreshed = true;
							}

							ToolTip.text : "Show only the current note's presets"
							hoverEnabled : true
							ToolTip.delay : tooltipShow
							ToolTip.timeout : tooltipHide
							ToolTip.visible : hovered

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
								__asAPreset = new presetClass(__category, "", note.extname.name, note.accidentalData.name, buildFingeringRepresentation(), note.headData.name);
								debug(level_DEBUG, JSON.stringify(__asAPreset));
								addPresetWindow.state = "add"
									addPresetWindow.show()
							}
							ToolTip.text : "Add current keys combination as new preset"
							hoverEnabled : true
							ToolTip.delay : tooltipShow
							ToolTip.timeout : tooltipHide
							ToolTip.visible : hovered
						}

						Button {
							implicitHeight : buttonBox.contentItem.height * 0.6 //btnOk.height
							implicitWidth : buttonBox.contentItem.height * 0.6 //btnOk.height

							enabled : (lstPresets.currentIndex >= 0)

							indicator :
							Image {
								source : "alternatefingering/edit.svg"
								mipmap : true // smoothing
								width : 23
								fillMode : Image.PreserveAspectFit // ensure it fits
								anchors.centerIn : parent
							}
							onClicked : {
								__asAPreset = lstPresets.model[lstPresets.currentIndex]

									debug(level_DEBUG, JSON.stringify(__asAPreset));
								addPresetWindow.state = "edit"
									addPresetWindow.show()
							}
							ToolTip.text : "Edit the selected preset"
							hoverEnabled : true
							ToolTip.delay : tooltipShow
							ToolTip.timeout : tooltipHide
							ToolTip.visible : hovered
						}

						Button {
							implicitHeight : buttonBox.contentItem.height * 0.6 //btnOk.height
							implicitWidth : buttonBox.contentItem.height * 0.6 //btnOk.height

							enabled : (lstPresets.currentIndex >= 0)

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
							ToolTip.text : "Remove the selected preset"
							hoverEnabled : true
							ToolTip.delay : tooltipShow
							ToolTip.timeout : tooltipHide
							ToolTip.visible : hovered
						}

						Button {
							implicitHeight : buttonBox.contentItem.height * 0.6 //btnOk.height
							implicitWidth : buttonBox.contentItem.height * 0.6 //btnOk.height

							indicator :
							Image {
								source : "alternatefingering/select.svg"
								mipmap : true // smoothing
								width : 23
								fillMode : Image.PreserveAspectFit // ensure it fits
								anchors.centerIn : parent
							}
							onClicked : {
								var note = __notes[0];
								var p = new presetClass(__category, "", note.extname.name, note.accidentalData.name, buildFingeringRepresentation(), note.headData.name);
								debug(level_DEBUG, JSON.stringify(p));
								selectPreset(p, false); // select the closest match
								currentPreset = lstPresets.model[lstPresets.currentIndex]; // make it the current present to be pushed to the score
							}
							ToolTip.text : "Search fingering in presets"
							hoverEnabled : true
							ToolTip.delay : tooltipShow
							ToolTip.timeout : tooltipHide
							ToolTip.visible : hovered
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
					// On reset le "currentPreset"
					currentPreset = undefined;

				}

				ToolTip.text : note.name
				hoverEnabled : true
				ToolTip.delay : tooltipShow
				ToolTip.timeout : tooltipHide
				ToolTip.visible : containsMouse // "hovered" does not work for MouseArea
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

			Image {
				id : prsHead
				source : "./alternatefingering/" + getHeadImage(__preset.head)
				fillMode : Image.PreserveAspectFit
				height : 20
				width : 20
				anchors {
					left : prsAcc.right
					top : prsLab.bottom
				}
			}

			MouseArea {
				anchors.fill : parent;
				acceptedButtons : Qt.LeftButton

				onDoubleClicked : {
					currentPreset = __preset;
					pushFingering(__preset.representation);
				}

				onClicked : {
					__lv.currentIndex = index;
				}

				ToolTip.text : __preset.label
				hoverEnabled : true
				ToolTip.delay : tooltipShow
				ToolTip.timeout : tooltipHide
				ToolTip.visible : containsMouse && __preset.label && __preset.label !== "" // "hovered" does not work for MouseArea

			}
		}

	}

	Component {
		id : lstInstruCompo
		ComboBox {
			id : lstInstru
			model : __modelInstruments
			currentIndex : { {
					__modelInstruments.indexOf(currentInstrument)
				}
			}
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
				text : (__modelInstruments[currentIndex]) ? __instruments[__modelInstruments[currentIndex]].label : "--"
				font.pointSize : titlePointSize
				verticalAlignment : Qt.AlignVCenter
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
			text : (__category === "") ? "Non supported instrument" : __instruments[__modelInstruments[0]].label
			font.pointSize : (__category === "") ? 9 : titlePointSize
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
		text : 'Do you confirm the deletion of the fingerings of the ' + __notes.length + ' selected note' + (__notes.length > 1 ? 's' : '') + ' ?'
		onYes : {
			var res = removeAllFingerings();
			if (res.nbdeleted > 0)
				txtStatus.text = res.nbnotes + " note" + (res.nbnotes > 1 ? "s" : "") + " treated; " + res.nbdeleted + " fingering" + (res.deleted > 1 ? "s" : "") + " deleted";
			else
				txtStatus.text = "No fingerings deleted";
			confirmRemoveMissingDialog.close();

		}
		onNo : confirmRemoveMissingDialog.close();
	}

	MessageDialog {
		id : confirmPushToNoteDialog
		icon : StandardIcon.Question
		property var notes : []
		property int forceAcc : 0
		property int forceHead : 0

		standardButtons : StandardButton.Yes | StandardButton.No
		title : 'Align notes to preset'
		text : 'Some of the selected notes have a different accidental and/or head than the chosen preset.<br/>' +
		'Do want to align the notes ' +
		((forceAcc == -1) ? '<b>accidentals</b>' : '') +
		((forceAcc == -1 && forceHead == -1) ? ' and ' : '') +
		((forceHead == -1) ? '<b>heads</b>' : '') +
		' on the preset ?<br/>'

		informativeText : 'Your choice will apply to all the selected notes.<br/><br/>'
		detailedText :
		((forceAcc == 1) ? 'Accidentals will always be aligned if different.\n' :
			((forceAcc == 0) ? 'Accidentals will never be aligned.\n' :
				'Accidentals will be aligned depending on your choice.\n')) +
		((forceHead == 1) ? 'Heads will always be aligned if different.\n' :
			((forceHead == 0) ? 'Heads will never be aligned.\n' :
				'Heads will be aligned depending on your choice.\n')) +
		'\nThose behaviours can be changed in the options.'
		onYes : {
			if (forceAcc == -1)
				forceAcc = 1;
			if (forceHead == -1)
				forceHead = 1;
			confirmPushToNoteDialog.close();
			alignToPreset_do(notes, forceAcc, forceHead);
		}
		onNo : {
			if (forceAcc == -1)
				forceAcc = 0;
			if (forceHead == -1)
				forceHead = 0;
			confirmPushToNoteDialog.close();
			alignToPreset_do(notes, forceAcc, forceHead);
		}
	}

	Window {
		id : optionsWindow
		title : "Options..."
		width : 500
		height : 450
		modality : Qt.WindowModal
		flags : Qt.Dialog | Qt.WindowSystemMenuHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint
		//color: "#E3E3E3"

		ColumnLayout {

			anchors.fill : parent
			spacing : 5
			anchors.margins : 5

			Text {
				Layout.fillWidth : true
				verticalAlignment : Text.AlignVCenter
				horizontalAlignment : Text.AlignHCenter
				font.pointSize : 12
				text : 'Alternate Fingerings ' + version
			}

			Text {
				Layout.fillWidth : true
				verticalAlignment : Text.AlignVCenter
				horizontalAlignment : Text.AlignHCenter
				font.pointSize : 9
				topPadding : -5
				bottomPadding : 15
				text : 'by <a href="https://www.laurentvanroy.be/" title="Laurent van Roy">Laurent van Roy</a>'
				onLinkActivated : Qt.openUrlExternally(link)
			}

			Rectangle {
				Layout.preferredHeight : txtCfgInstr.implicitHeight + 4 // 4 pour les marges
				Layout.fillWidth : true
				visible : (__category !== "")
				color : "#C0C0C0"

				Text {
					id : txtCfgInstr
					text : "Instrument configuration (" + __modelInstruments[0] + ")"
					Layout.fillWidth : true
					rightPadding : 5
					leftPadding : 5
					horizontalAlignment : Qt.AlignLeft
				}
			}

			Rectangle { // panConfig

				visible : (__category !== "")

				id : panConfig
				color : "#F0F0F0"
				//Layout.preferredWidth : layConfig.implicitWidth + 10
				Layout.fillWidth : true
				Layout.preferredHeight : layConfig.implicitHeight + 10
				anchors.margins : 20
				Flow {
					id : layConfig

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
				Layout.preferredHeight : txtOptFing.implicitHeight + 4 // 4 pour les marges
				Layout.fillWidth : true
				color : "#C0C0C0"

				Text {
					id : txtOptFing
					text : "Fingering options"
					Layout.fillWidth : true
					rightPadding : 5
					leftPadding : 5
					horizontalAlignment : Qt.AlignLeft
				}
			}

			Rectangle {
				Layout.preferredHeight : layFO.height + anchors.margins * 2
				Layout.fillWidth : true
				//Layout.fillHeight: true

				//anchors.margins : 20
				color : "#F0F0F0"

				Flow {
					id : layFO
					//anchors.fill: parent
					anchors.left : parent.left;
					anchors.right : parent.right

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
				color : "#C0C0C0"

				Text {
					id : txtOptMisc
					text : "Misc. options"
					Layout.fillWidth : true
					horizontalAlignment : Qt.AlignLeft
					rightPadding : 5
					leftPadding : 5
				}

			}
			Rectangle {
				color : "#F0F0F0"
				//anchors.margins : 20
				Layout.preferredHeight : layMO.height + anchors.margins * 2 + 10
				Layout.fillWidth : true

				GridLayout {
					id : layMO

					//implicitHeight: childrenRect.height + anchors.margins*2 + 15
					implicitWidth : childrenRect.width + anchors.margins * 2

					rowSpacing : 5
					columnSpacing : 2

					columns : 2
					rows : 2
					CheckBox {
						id : chkEquivAccidental
						Layout.columnSpan : 2
						Layout.alignment : Qt.AlignLeft | Qt.QtAlignBottom
						text : "Accidental equivalence in presets "
						onClicked : {
							presetsRefreshed = false;
							presetsRefreshed = true;
						} // awfull hack
						checked : true;
					}

				}
			}

			Item {
				// spacer
				Layout.fillHeight : true;
				Layout.fillWidth : true;
				//Layout.columnSpan: 2
			}

			DialogButtonBox {
				id : opionsButtonBox
				Layout.alignment : Qt.AlignHCenter
				Layout.fillWidth : true
				background.opacity : 0 // hide default white background
				standardButtons : DialogButtonBox.Close //| DialogButtonBox.Save
				onRejected : optionsWindow.hide()
				onAccepted : {
					saveOptions();
					optionsWindow.hide()
				}
			}

			Text {
				Layout.fillWidth : true
				verticalAlignment : Text.AlignVCenter
				horizontalAlignment : Text.AlignHCenter
				font.pointSize : 10

				text : '<a href="https://musescore.org/en/project/accidental-tuner" title="Link to MuseScore plugin library">AccidntalTuner</a> by <a href="https://www.gilbertyammine.com/" title="gilbertyammine.com">https://www.gilbertyammine.com/</a>'

				wrapMode : Text.Wrap

				onLinkActivated : Qt.openUrlExternally(link)

			}
			Text {
				Layout.fillWidth : true
				verticalAlignment : Text.AlignVCenter
				horizontalAlignment : Text.AlignHCenter
				font.pointSize : 10

				text : 'Icons made by <a href="https://www.flaticon.com/authors/hirschwolf" title="hirschwolf">hirschwolf</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a>'

				wrapMode : Text.Wrap

				onLinkActivated : Qt.openUrlExternally(link)

			}

		}
	}

	Window {
		id : addPresetWindow
		title : "Manage Library..."
		width : 325
		height : 350
		modality : Qt.WindowModal
		flags : Qt.Dialog | Qt.WindowSystemMenuHint | Qt.WindowTitleHint | Qt.WindowCloseButtonHint

		property string state : "add"

		Item {
			anchors.fill : parent

			state : addPresetWindow.state

			states : [
				State {
					name : "remove";
					PropertyChanges {
						target : btnEpAdd;
						text : "Remove"
					}
					PropertyChanges {
						target : labEpCat;
						text : "Delete the following " + __asAPreset.category + " preset ?"
					}
					PropertyChanges {
						target : labEpLabVal;
						readOnly : true
					}
					PropertyChanges {
						target : labEpNoteVal;
						readOnly : true
					}
					PropertyChanges {
						target : lstEpAcc;
						enabled : false
					}

				},
				State {
					name : "add";
					PropertyChanges {
						target : btnEpAdd;
						text : "Add"
					}
					PropertyChanges {
						target : labEpCat;
						text : "Add the new " + __asAPreset.category + " preset : "
					}
					PropertyChanges {
						target : labEpLabVal;
						readOnly : false
					}
					PropertyChanges {
						target : labEpNoteVal;
						readOnly : false
					}
					PropertyChanges {
						target : lstEpAcc;
						enabled : true
					}
				},
				State {
					name : "edit";
					PropertyChanges {
						target : btnEpAdd;
						text : "Save"
					}
					PropertyChanges {
						target : labEpCat;
						text : "Edit the " + __asAPreset.category + " preset : "
					}
					PropertyChanges {
						target : labEpLabVal;
						readOnly : false
					}
					PropertyChanges {
						target : labEpNoteVal;
						readOnly : false
					}
					PropertyChanges {
						target : lstEpAcc;
						enabled : true
					}
				}
			]

			GridLayout {
				columns : 2
				rows : 5

				anchors.fill : parent
				columnSpacing : 5
				rowSpacing : 5
				anchors.margins : 10

				Text {
					Layout.row : 1
					Layout.column : 1
					Layout.columnSpan : 2
					Layout.rowSpan : 1

					id : labEpCat

					Layout.preferredWidth : parent.width
					Layout.preferredHeight : 20

					text : "--"

					font.weight : Font.DemiBold
					verticalAlignment : Text.AlignVCenter
					horizontalAlignment : Text.AlignLeft
					font.pointSize : 11

				}

				Rectangle { // se passer du rectangle ???
					Layout.row : 2
					Layout.column : 1
					Layout.columnSpan : 2
					Layout.rowSpan : 1

					Layout.fillWidth : true
					Layout.fillHeight : true

					Text {
						anchors.fill : parent
						id : labEpRep

						text : __asAPreset.representation

						font.family : "fiati"
						font.pixelSize : 100

						renderType : Text.NativeRendering
						font.hintingPreference : Font.PreferVerticalHinting
						verticalAlignment : Text.AlignTop
						horizontalAlignment : Text.AlignHCenter

						onLineLaidOut : { // hack for correct display of Fiati font
							line.y = line.y * 0.8
								line.height = line.height * 0.8
								line.x = line.x - 7
								line.width = line.width - 7
						}
					}
				}

				Label {
					Layout.row : 3
					Layout.column : 1
					Layout.columnSpan : 1
					Layout.rowSpan : 1

					id : labEpLab

					text : "Label:"

					Layout.preferredHeight : 20

				}

				TextField {
					Layout.row : 3
					Layout.column : 2
					Layout.columnSpan : 1
					Layout.rowSpan : 1

					id : labEpLabVal

					text : __asAPreset.label

					Layout.preferredHeight : 30
					Layout.fillWidth : true
					placeholderText : "label text (optional)"
					maximumLength : 255

				}

				Label {
					Layout.row : 4
					Layout.column : 1
					Layout.columnSpan : 1
					Layout.rowSpan : 1

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
						validator : RegExpValidator {
							regExp : /^[A-G][0-9]$/
						}
						maximumLength : 2
						placeholderText : "e.g. \"C4\""
						Layout.preferredHeight : 30
						Layout.preferredWidth : 40

					}

					ComboBox {
						id : lstEpAcc
						//Layout.fillWidth : true
						model : accidentals
						currentIndex : visible ? getAccidentalModelIndex(__asAPreset.accidental) : 0

						clip : true
						focus : true
						Layout.preferredHeight : 30
						Layout.preferredWidth : 80

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
							height : 25
							width : 25
							fillMode : Image.Pad
							source : "./alternatefingering/" + accidentals[lstEpAcc.currentIndex].image
						}
					}
					ComboBox {
						id : lstEpHead
						//Layout.fillWidth : true
						model : heads
						currentIndex : visible ? getHeadModelIndex(__asAPreset.head) : 0

						clip : true
						focus : true
						Layout.preferredHeight : 30
						Layout.preferredWidth : 80

						delegate : ItemDelegate { // requiert QuickControls 2.2
							contentItem : Image {
								height : 25
								width : 25
								source : "./alternatefingering/" + heads[index].image
								fillMode : Image.Pad
								verticalAlignment : Text.AlignVCenter
							}
							highlighted : lstEpHead.highlightedIndex === index

						}

						contentItem : Image {
							height : 25
							width : 25
							fillMode : Image.Pad
							source : "./alternatefingering/" + heads[lstEpHead.currentIndex].image
						}
					}
				}

				DialogButtonBox {
					Layout.row : 5
					Layout.column : 1
					Layout.columnSpan : 2
					Layout.rowSpan : 1
					Layout.alignment : Qt.AlignRight

					background.opacity : 0 // hide default white background

					standardButtons : DialogButtonBox.Cancel
					Button {
						id : btnEpAdd
						text : "--"
						DialogButtonBox.buttonRole : DialogButtonBox.AcceptRole
					}

					onAccepted : {
						if ("remove" === addPresetWindow.state) {
							// remove
							for (var i = 0; i < __library.length; i++) {
								var p = __library[i];
								if ((p.category === __asAPreset.category) &&
									(p.label === __asAPreset.label) &&
									(p.note === __asAPreset.note) &&
									(p.accidental === __asAPreset.accidental) &&
									(p.head === __asAPreset.head) &&
									(p.representation === __asAPreset.representation)) {
									__library.splice(i, 1);
									break;
								}
							}
							addPresetWindow.hide();
						} else if ("add" === addPresetWindow.state) {
							// add
							var preset = new presetClass(__asAPreset.category, labEpLabVal.text, labEpNoteVal.text, lstEpAcc.model[lstEpAcc.currentIndex].name, __asAPreset.representation, lstEpHead.model[lstEpHead.currentIndex].name);
							__library.push(preset);
							addPresetWindow.hide();

							// make added preset as current preset
							currentPreset = preset;

							// set added preset as working preset
							__asAPreset = preset;
						} else if ("edit" === addPresetWindow.state) {
							// edit
							var preset = new presetClass(__asAPreset.category, labEpLabVal.text, labEpNoteVal.text, lstEpAcc.model[lstEpAcc.currentIndex].name, __asAPreset.representation, lstEpHead.model[lstEpHead.currentIndex].name);

							for (var i = 0; i < __library.length; i++) {
								var p = __library[i];
								if ((p.category === __asAPreset.category) &&
									(p.label === __asAPreset.label) &&
									(p.note === __asAPreset.note) &&
									(p.accidental === __asAPreset.accidental) &&
									(p.head === __asAPreset.head) &&
									(p.representation === __asAPreset.representation)) {
									__library[i] = preset;
									break;
								}
							}

							addPresetWindow.hide();

							// set edited preset as working preset
							__asAPreset = preset;
						}

						presetsRefreshed = false; // awfull hack
						presetsRefreshed = true;

						// Select the added/edited preset in the list view
						if ("remove" !== addPresetWindow.state) {
							selectPreset(__asAPreset);
						}

						saveLibrary();
					}
					onRejected : addPresetWindow.hide()

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

	property var keysorder : ['B', 'A', 'G', 'F', 'E', 'D', 'C']

	function getPresetsLibrary(refresh) { // refresh is just meant for the "awful hack" ;-)
		var note = __notes[0];

		var sorted = __library.sort(function (a, b) {
				var kA = keysorder.indexOf(a.note.substr(0, 1));
				var kB = keysorder.indexOf(b.note.substr(0, 1));
				var nA = parseInt(a.note.substring(1, 2), 10);
				var nB = parseInt(b.note.substring(1, 2), 10);
				// console.log(a.note+" = ["+kA+","+nA+"] -- "+b.note+" = ["+kB+","+nB+"]");
				// console.log((nB - nA)+" / "+(kA - kB));
				var res = (nB - nA);
				if (res !== 0)
					return res;
				return kA - kB;
			});

		if (chkFilterPreset.checkState === Qt.Unchecked) {
			// everything
			return sorted;

		} else if (chkFilterPreset.checkState === Qt.Checked) {
			// strong filter (on note and accidental)
			var useEquiv = chkEquivAccidental.checked;
			var lib = [];
			for (var i = 0; i < sorted.length; i++) {
				var preset = sorted[i];
				debug(level_TRACE, preset.label + note.extname.name + ";" + preset.note + ";" + note.accidentalData.name + ";" + preset.accidental);
				if ((note.extname.name === preset.note && (note.accidentalData.name === preset.accidental || (useEquiv && isEquivAccidental(note.accidentalData.name, preset.accidental))))
					 || ("" === preset.note && "NONE" === preset.accidental)) {
					lib.push(preset);
				}
			}
			return lib;
		} else {
			// loose filter (on note only)
			var lib = [];
			var pitch = note.pitch; // generate a depends on non-NOTIFYable properties: Warning: Ms::PluginAPI::Note::pitch
			for (var i = 0; i < __library.length; i++) {
				var preset = __library[i];
				debug(level_TRACE, preset.label + note.extname.name + ";" + preset.note + ";" + note.accidentalData.name + ";" + preset.accidental + ";" + pitch + ";" + preset.pitch);
				//				if ((note.extname.name === preset.note) || ("" === preset.note && "NONE" === preset.accidental)) {
				if (((preset.pitch - similarpitch) <= pitch) && ((preset.pitch + similarpitch) >= pitch)) {
					lib.push(preset);
				}
			}
			return lib;
		}
	}

	function getAccidentalModelIndex(accidentalName) {
		for (var i = 0; i < accidentals.length; i++) {
			if (accidentalName === accidentals[i].name) {
				return i;
			}
		}
		return 0;
	}

	function getAccidentalImage(accidentalName) {
		if (accidentalName == generic_preset) {
			return "generic.png"
		}
		for (var i = 0; i < accidentals.length; i++) {
			if (accidentalName === accidentals[i].name) {
				return accidentals[i].image;
			}
		}
		return "NONE.png";
	}

	function getHeadModelIndex(headName) {
		for (var i = 0; i < heads.length; i++) {
			if (headName === heads[i].name) {
				return i;
			}
		}
		return 0;
	}

	function getHeadImage(headName) {
		if (headName == generic_preset) {
			return "generic.png"
		}
		for (var i = 0; i < heads.length; i++) {
			if (headName === heads[i].name) {
				return heads[i].image;
			}
		}
		return "NONE.png";
	}

	function selectPreset(preset, strict) {

		if (preset === undefined)
			return;

		if (strict === undefined)
			strict = true;

		var filtered = lstPresets.model.slice();

		console.log("Selecting (" + strict + ")");
		debugO(level_DEBUG, "preset", preset);
		console.log("Among " + filtered.length);

		for (var i = 0; i < filtered.length; i++) {
			filtered[i].index = i;
		}

		var stricts,
		weaks;

		if (strict) {
			stricts = ["category", "representation", "note", "accidental", "head", "label"];
			//weaks = [];
		} else {
			stricts = ["category", "representation"];
			//weaks = ["note", "accidental", "head", "label"];
		}

		var best = -1;
		for (var i = 0; i < stricts.length; i++) {
			var f = stricts[i];
			filtered = filtered.filter(function (p) {
					return (p[f] === preset[f]);
				});
			console.log("Preset selection: after '" + f + "': " + filtered.length);
			if (filtered.length === 0) {
				break;
			}
		}
		if (filtered.length > 0) { // les filtres stricts ont retenus au minimum 1 élément
			best = filtered[0].index;
			var pitch = preset.pitch;
			var delta = 99;
			console.log("looking for " + pitch + "; starting at " + delta);
			/*for (var i = 0; i < weaks.length; i++) {
			var f = weaks[i];
			filtered = filtered.filter(function (p1) {
			return (p1[f] === "--" || preset[f] === "--" || p1[f] === undefined || preset[f] === undefined || p1[f] === preset[f]);
			});
			if (filtered.length === 0)
			break;
			else
			best = filtered[0].index;
			}*/
			// looking for the preset with the best match at pitch level
			for (var i = 0; i < filtered.length; i++) {
				var p = filtered[i];
				//console.log("analyzing for "+p.pitch+"; target at "+delta);
				var d = Math.abs(p.pitch - pitch); // is only working if the pitch field of the presetClass is numerable=true. Don't know why. It should work even if at false
				if (d < delta) {
					best = p.index;
					delta = d;
				}
			}
		}

		console.log("best: " + best);
		lstPresets.currentIndex = best;
	}
	// -----------------------------------------------------------------------
	// --- Property File -----------------------------------------------------
	// -----------------------------------------------------------------------
	FileIO {
		id : settingsFile
		source : homePath() + "/alternatefingering.properties"
		//source: rootPath() + "/alternatefingering.properties"
		//source: Qt.resolvedUrl("alternatefingering.properties")
		//source: "./alternatefingering.properties"

		onError : {
			//statusBar.text=msg;
		}
	}
	FileIO {
		id : libraryFile
		source : homePath() + "/alternatefingering.library"
		//source: rootPath() + "/alternatefingering.properties"
		//source: Qt.resolvedUrl("alternatefingering.properties")
		//source: "./alternatefingering.properties"

		onError : {
			//statusBar.text=msg;
		}
	}

	FileIO {
		id : tuningSettingsFile
		source : homePath() + "/MuseScore_AT_Settings.dat"
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

}