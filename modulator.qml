//=============================================================================
//  Modulator Plugin for MuseScore 4
//
//  Inspired by the plugin "Pivot-Chords" by Bill Hails, rewrote by Sunny090628.
//
//  Copyright (C) 2023 Jean-Yves Chasle (madjyc)
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import MuseScore 3.0
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

MuseScore {
    version: "1.1.0"
    pluginType: "dialog"
    description: "Choose a single note or a chord, then let the plugin find all the chords (triads or seventh chords) in all keys and scales that share at least 1 note with it."
    width: 640
    height: 480
    // MuseScore3 specific (uncomment the following line to in MuseScore3)
//    menuPath: "Plugins.Composing Tools.Modulator"
    // MuseScore4 specific (comment those 3 lines in MuseScore3)
    title: "Modulator"
    categoryCode: "composing-arranging-tools"
    thumbnailName: "modulator.png"

    function pivotChordFinder() {
        var note7Names = [
            "C",
            "D",
            "E",
            "F",
            "G",
            "A",
            "B",
        ];

        var note12NamesStd = [
            ["C"],
            ["C♯", "D♭"],
            ["D"],
            ["D♯", "E♭"],
            ["E"],
            ["F"],
            ["F♯", "G♭"],
            ["G"],
            ["G♯", "A♭"],
            ["A"],
            ["A♯", "B♭"],
            ["B"],
        ];

        var note12NamesExt = [
            ["C", "B♯", "D♭♭"],
            ["C♯", "D♭", "B♯♯"],
            ["D", "C♯♯", "E♭♭"],
            ["D♯", "E♭", "F♭♭"],
            ["E", "F♭", "D♯♯"],
            ["F", "E♯", "G♭♭"],
            ["F♯", "G♭", "E♯♯"],
            ["G", "F♯♯", "A♭♭"],
            ["G♯", "A♭", "F♯♯"],
            ["A", "G♯♯", "B♭♭"],
            ["A♯", "B♭", "C♭♭"],
            ["B", "C♭","A♯♯"],
        ];

        var chordTypeNames = [
            "m",
            "m7", // 7th implicitely minor
            "mM7",
            "°",
            "°7", // 7th implicitely diminished
            "ø7", // 7th implicitely minor
            "",   // implicitely major
            "7",  // 7th implicitely minor
            "M7", // 7th implicitely major
            "+",
            "+7", // 7th implicitely minor
            "+M7",
            " single note", // not a chord
            " dim 3rd", // dyad
            " min 3rd", // dyad
            " maj 3rd", // dyad
            " aug 3rd", // dyad
            " dim 5th", // dyad
            " perf 5th", // dyad
            " aug 5th", // dyad
            " dim 7th", // dyad
            " min 7th", // dyad
            " maj 7th", // dyad
        ];

        var chordTypeNotes12 = [
            [0, 3, 7],     // m
            [0, 3, 7, 10], // m7
            [0, 3, 7, 11], // mM7
            [0, 3, 6],     // °, m(♭5)
            [0, 3, 6, 9],  // °7
            [0, 3, 6, 10], // ø7, m7(♭5)
            [0, 4, 7],     // M
            [0, 4, 7, 10], // 7
            [0, 4, 7, 11], // M7
            [0, 4, 8],     // +
            [0, 4, 8, 10], // +7
            [0, 4, 8, 11], // +M7
            [0], // single (considered as the root node)
            [0, 2], // dim 3rd
            [0, 3], // min 3rd
            [0, 4], // maj 3rd
            [0, 5], // aug 3rd
            [0, 6], // dim 5th
            [0, 7], // perf 5th
            [0, 8], // aug 5th
            [0, 9], // dim 7th
            [0, 10], // min 7rd
            [0, 11], // maj 7rd
        ];

        var scaleModeNames = [
            "major",
            "natural minor",
            "harmonic minor",
            "melodic minor",
        ];

        var scaleModeNotes12 = [
            [0, 2, 4, 5, 7, 9, 11], // major
            [0, 2, 3, 5, 7, 8, 10], // natural minor
            [0, 2, 3, 5, 7, 8, 11], // harmonic minor
            [0, 2, 3, 5, 7, 9, 11], // melodic minor
        ];

        // Scale degrees for thirds
        // https://m.basicmusictheory.com/topic/scale-chord
        var scaleModeDegrees3 = [
            ["I", "ii", "iii", "IV", "V", "vi", "vii°"], // major
            ["i", "ii°", "III", "iv", "v", "VI", "VII"], // natural minor
            ["i", "ii°", "III+", "iv", "V", "VI", "vii°"], // harmonic minor
            ["i", "ii", "III+", "IV", "V", "vi°", "vii°"], // melodic minor
        ];

        // Scale degrees for seventh chords
        // https://m.basicmusictheory.com/topic/scale-chord
        var scaleModeDegrees4 = [
            ["I7", "ii7", "iii7", "IV7", "V7", "vi7", "viiø7"], // major
            ["i7", "iiø7", "III7", "iv7", "v7", "VI7", "VII7",], // natural minor
            ["i7", "iiø7", "III+7", "iv7", "V7", "VI7", "vii°7",], // harmonic minor
            ["i7", "ii7", "III+7", "IV7", "V7", "viø7", "viiø7",], // melodic minor
        ];
        
        // Each key is represented as major and minor.
        var circleOfFifths12 = [
            ["C"],
            ["C♯", "D♭"],
            ["D"],
            ["D♯", "E♭"],
            ["E"],
            ["F"],
            ["F♯", "G♭"],
            ["G"],
            ["G♯", "A♭"],
            ["A"],
            ["A♯", "B♭"],
            ["B", "C♭"],
        ];
        
        var textColors = {
            "normal_dark":    "#093756",
            "normal_medium":  "#457596",
            "normal_light":   "#87aeca",
            "hilight_dark":   "#db8100",
            "hilight_medium": "#e0962b",
            "hilight_light":  "#eab870",
        };

        // Displays the chord details based on the given root note and type.
        //   * chord_root_note12: index of the root note in note12NamesStd.
        //   * chord_type: index of the chord type in chordTypeNames and chordTypeNotes12.
        this.printChordRealNoteNames = function (chord_root_note12, chord_type) {
            // Determines whether the second note of the chord is a 3rd, a 5th or a 7th away from the root note.
            var chord_step = evaluateChordStep(chordTypeNotes12[chord_type]);
            
            // Determines the notes of the given chord as indexes of note12NamesStd.
            var chord_notes12 = offsetNotes12(chord_root_note12, chordTypeNotes12[chord_type]);
            
            // Gets all possible names for the root note of the chord (e.g. ["C♯", "D♭"]).
            var chord_root_note12_names = note12NamesStd[chord_root_note12];
            
            // Starting with each possible name for the root note, find and display the name of the other notes of the chord.
            var message = "Your chord: ";
            for (var n = 0; n < chord_root_note12_names.length; n++) {
                if (n > 0) {
                    message += " or ";
                }
                var chord_real_note_names = getChordRealNoteNames(chord_notes12, chord_root_note12_names[n], chord_step); // e.g. "C♯" then "D♭").
                message += "<b><span style='color:" + textColors["hilight_dark"] + ";'>" + chord_root_note12_names[n] + chordTypeNames[chord_type] + "</span></b> " + noteNamesToString(chord_real_note_names);
            }
            outputText.text = message;
        }

        // Finds and displays all the chords from any keys sharing at least one note with the given chord.
        //   * chord_root_note12: index of the root note in note12NamesStd.
        //   * chord_type: index of the chord type in chordTypeNames.
        //   * chord_size: number of notes of the chords to find.
        this.printChordInScales = function (chord_root_note12, chord_type, chord_size, strict) {
            // Determines the notes of the given chord as indexes of note12NamesStd.
            var chord_notes12 = offsetNotes12(chord_root_note12, chordTypeNotes12[chord_type]);
            
            // Considers each key from scaleModeNames.
            var message = "";
            var results_found = false;
            for (var scale_mode_index = 0; scale_mode_index < scaleModeNames.length; scale_mode_index++) {
                // Gets the mode name (e.g. "major") of the current scale.
                var scale_mode_name = scaleModeNames[scale_mode_index];
                
                // Gets the relative notes of the mode (e.g. [0, 2, 4, 5, 7, 9, 11]).
                var scale_mode_notes12 = scaleModeNotes12[scale_mode_index];
                
                // Considers each key from circleOfFifths12 (some have multiple names).
                for (var scale_key_index = 0; scale_key_index < circleOfFifths12.length; scale_key_index++) {
                    // Determines the note positions of the current scale mode in the current key (e.g. ["C♯", "D♭"] -> [1, 3, 5, 6, 8, 10, 0]).
                    var scale_notes12 = offsetNotes12(scale_key_index, scale_mode_notes12)
                    
                    // Gets all possible names of the current key from scale_key_index (e.g. ["C♯", "D♭"] in major mode).
                    var scale_key_names = circleOfFifths12[scale_key_index];
                    
                    // Finds the name of each note of the current scale depending on the name of its root note (e.g. ["C♯", "D♭"] -> "C♯" then "D♭").
                    var scale_real_note_names = [];
                    for (var key_name_index = 0; key_name_index < scale_key_names.length; key_name_index++) {
                        var scale_key_name = scale_key_names[key_name_index]; // e.g. ["C♯", "D♭"] -> "C♯" then "D♭"
                        scale_real_note_names[key_name_index] = getScaleRealNoteNames(scale_key_name, scale_notes12);
                    }
                    
                    // Starting with each note of the current scale...
                    var res = [];
                    var key_already_displayed = false;
                    for (var scale_note12_index = 0; scale_note12_index < scale_notes12.length; scale_note12_index++) {
                        // Finds the chord of the current scale (triad or 7th chord depending on desired chord_size) based on this note
                        // (e.g. ["C♯", "D♭"] 7th chord -> [1, 5, 8, 0]).
                        var scale_chord_notes12 = getChordNotes12FromScalePosition(scale_notes12, scale_note12_index, chord_size);
                        
                        // Counts the notes in common with the given chord.
                        var count = howManyNotesInCommon(chord_notes12, scale_chord_notes12);
                        
                        // Only chords that share at least on note are displayed.
                        if ((strict && count >= chord_notes12.length) || (!strict && count > 0)) {
                            results_found = true;
                            // Displays the key (e.g. "In C♯ or D♭ major:").
                            if (!key_already_displayed) {
                                message = "<p><br>In <b><span style='color:" + textColors["hilight_dark"] + ";'>" + scale_key_names[0] + " " + scale_mode_name + "</span></b> " + noteNamesToHtml(chord_notes12, scale_real_note_names[0]);
                                if (scale_key_names.length > 1) {
                                    message += "<br>or <b><span style='color:" + textColors["hilight_dark"] + ";'>" + scale_key_names[1] + " " + scale_mode_name + "</span></b> " + noteNamesToHtml(chord_notes12, scale_real_note_names[1]);
                                }
                                message += ":</p>";
                                outputText.text = outputText.text + message;
                                message = "";
                                key_already_displayed = true;
                            }
                            
                            // Gets the type name of the current chord from the current scale (e.g. "M7").
                            var scale_chord_type_name = getChordTypeName(scale_chord_notes12);
                            
                            // As the number of shared notes decreases, the color of the text fades.
                            var ref_chord_size = chordTypeNotes12[chord_type].length;
                            if (ref_chord_size >= 3 && count == 1) {
                                var textColorNormal = textColors["normal_light"];
                                var textColorHilight = textColors["hilight_light"];
                            } else if ((ref_chord_size >= 3 && count == 2) || (ref_chord_size == 2 && count == 1)) {
                                var textColorNormal = textColors["normal_medium"];
                                var textColorHilight = textColors["hilight_medium"];
                            } else {
                                var textColorNormal = textColors["normal_dark"];
                                var textColorHilight = textColors["hilight_dark"];
                            }
                            message = "<p style='color:" + textColorNormal + ";'>";
                            
                            // Converts each note of current chord from the current scale to its name depending on the current key,
                            // then displays the chord details (e.g. "1 note in common with IM7 (C♯,E♯,G♯,B♯) or (D♭,F,A♭,C)").
                            for (var srnn = 0; srnn < scale_real_note_names.length; srnn++) {
                                var scale_chord_real_note_names = notes12ToScaleNoteNames(scale_chord_notes12, scale_notes12, scale_real_note_names[srnn])
                                var scale_chord_degree = undefined;
                                switch (chord_size) {
                                    case 3:
                                        scale_chord_degree = scaleModeDegrees3[scale_mode_index][scale_note12_index];
                                        break;
                                    case 4:
                                        scale_chord_degree = scaleModeDegrees4[scale_mode_index][scale_note12_index];
                                        break;
                                    default:
                                        throw(chord_size + " is not allowed as a chord size.");
                                }
                                if (srnn == 0) {
                                    message += "    <b>" + count + (count > 1 ? " notes" : " note") + "</b> in common with <b>" + scale_chord_degree + "</b>: <b>";
                                } else {
                                    message += " or <b>";
                                }
                                message += "<span style='color:" + textColorHilight + ";'>" + scale_chord_real_note_names[0] + scale_chord_type_name + "</span></b> " + noteNamesToHtml(chord_notes12, scale_chord_real_note_names);
                            }
                            message += "</p>";
                            outputText.text = outputText.text + message;
                        }
                    }
                }
            }
            if (!results_found) {
                outputText.text = outputText.text + "<p><b>No results found.</b></p>";
            }
        }
        
        // Determines whether the second note of the chord is a 3rd, a 5th or a 7th away from the root note (which is always 0 here).
        function evaluateChordStep(rel_chord_notes12) {
            // A single note is not a real chord, step doesn't mean anything in that case.
            if (rel_chord_notes12.length <= 1) {
                return 0;
            }
            // Is it a 3rd?
            if (rel_chord_notes12[1] <= 5) {
                return 2;
            }
            // Is it a 5th (only valid for a dyad)?
            if (rel_chord_notes12[1] <= 8) {
                return 4;
            }
            // Is it a 7th (only valid for a dyad)?
            if (rel_chord_notes12[1] <= 11) {
                return 6;
            }
            throw("Invalid second note step " + rel_chord_notes12[1]);
            return undefined;
        }
       
        function offsetNotes12(offset, chord_notes12) {
            var res = [];
            for (var i = 0; i < chord_notes12.length; i++) {
                res[i] = (chord_notes12[i] + offset) % 12;
            }
            return res;
        }
        
        // One note index can have multiple names. We want to start with the name based off the first character of the root note.
        // e.g. chord_notes12 = [1,5,8] and root_note12_name = "D♭" -> the 1st note of the chord is D-something, so the next notes
        //      have to be one third apart: F-something, A-something, etc.
        function getChordRealNoteNames(chord_notes12, root_note12_name, chord_step) {
            // Looks for the index of the note without accidentals in note7Names (e.g. "B♭♭" -> index 6 ("B")).
            var note7 = note12NameToNote7(root_note12_name);
            // OK we have the starting index in note7Names (i.e. [C, D, E, F, G, A, B]).
            
            var res = [];
            for (var i = 0; i < chord_notes12.length; i++) {
                // Looks for the one and only note name in note12NamesExt[i] that starts with the current radical at note7 position.
                res[i] = getRealNote12Name(chord_notes12[i], note7);
                note7 = (note7 + chord_step) % 7; // i.e. every other index to ensure that notes are separated by a third.
            }
            
            return res;
        }
        
        // Again, one note index can have multiple names. We want to start with the name based on the first character of the key.
        // e.g. ["C♯", "D♭"] + "major" -> [1, 3, 5, 6, 8, 10, 0]
        //      Here, the index of the 1st note is 1, which can have different names depending on the key.
        //      -> If scale_key_name is "C♯", we want to translate [1, 3, 5, 6, 8, 10, 0] into [C♯, D♯, E♯, F♯, G♯, A♯, B♯],
        //         but if scale_key_name is "D♭", we want to translate [1, 3, 5, 6, 8, 10, 0] into [D♭, E♭, F, G♭, A♭, B♭, C].
        function getScaleRealNoteNames(scale_key_name, scale_notes12) {
            // Looks for the index of the note without accidentals in note7Names (e.g. "B♭♭" -> index 6 ("B")).
            var note7 = note12NameToNote7(scale_key_name);
            
            // OK we have the starting index in note7Names (i.e. [C, D, E, F, G, A, B]).
            var res = [];
            for (var i = 0; i < scale_notes12.length; i++) {
                // Looks for the one and only note name in note12NamesExt[i] that starts with the current radical at note7 position.
                res[i] = getRealNote12Name(scale_notes12[i], note7);
                if (res[i] == undefined) {
                    // Not found?! What kind of chord is this?
                    throw(note7Names[note7] + " cannot be found in " + real_note12_names);
                }
                note7 = (note7 + 1) % 7; // i.e. every index to ensure that notes are separated by a second.
            }
            return res;
        }
        
        // Returns the index of the note's radical in note7Names (e.g. "C♯" -> "C" in note7Names)
        function note12NameToNote7(note12_name) {
            for (var i = 0; i < note7Names.length; i++) { // Compare seulement le 1er caractère.
                if (note7Names[i] == note12_name[0]) {
                    return i;
                }
            }
            return undefined;
        }
        
        // Finds the name of note12 in note12NamesExt among all the possibilities, based on its note name in note7Names (1-character radical),
        // to ensure that the note names are all separated by a third (i.e. every other index).
        function getRealNote12Name(note12, note7) {
            // Get the radical to compare to.
            var note7Name = note7Names[note7];
            
            // Get all the possible names for that note (e.g. C♯ or D♭).
            var real_note12_names = note12NamesExt[note12];
            
            // Compare the 1st character of each note name to note7Name (1-character radical).
            for (var n = 0; n < real_note12_names.length; n++) {
                if(real_note12_names[n][0] == note7Name) {
                    return real_note12_names[n];
                }
            }
            return undefined;
        }
        
        function getChordNotes12FromScalePosition(scale, position, chord_size) {
            var chord_notes = [];
            for (var i = 0; i < chord_size; i++) {
                chord_notes.push(scale[(position + 2*i) % scale.length]);
            }
            return chord_notes;
        }

        function howManyNotesInCommon(chord_notes_A, chord_notes_B) {
            var count = 0;
            for (var n1 in chord_notes_A) {
                for (var n2 in chord_notes_B) {
                    if (chord_notes_A[n1] == chord_notes_B[n2]) {
                        count += 1;
                        break;
                    }
                }
            }
            return count;
        }

        // Returns the type name of the given chord from chordTypeNotes12 (e.g. [0, 3, 7, 10] -> "m7").  
        function getChordTypeName(chord_notes12) {
            // Offsets the chord notes so that its first index is 0.
            var chord_0based = offsetNotes12(12 - chord_notes12[0], chord_notes12);
            var chord_name = undefined
            
            for (var i = 0; i < chordTypeNotes12.length; i++) {
                if (areChordsEqual(chord_0based, chordTypeNotes12[i])) {
                    chord_name = chordTypeNames[i];
                    break;
                }
            }
            return chord_name;
        }

        function areChordsEqual(chord_notes_A, chord_notes_B) {
            if (chord_notes_A.length != chord_notes_B.length) {
                return false;
            }

            for (var i = 0; i < chord_notes_A.length; i++) {
                if (chord_notes_A[i] != chord_notes_B[i]) {
                    return false;
                }
            }
            return true;
        }

        // Converts the given chords notes from the given scale to their names as found in scale_note_names.
        function notes12ToScaleNoteNames(scale_chord_notes12, scale_notes12, scale_note_names) {
            var res = [];
            
            // Get the position of each chord note in scale_notes12, then find its name in scale_note_names (same index).
            for (var chord_note12_index = 0; chord_note12_index < scale_chord_notes12.length; chord_note12_index++) {
                for (var scale_note12_index = 0; scale_note12_index < scale_notes12.length; scale_note12_index++) {
                    if (scale_notes12[scale_note12_index] == scale_chord_notes12[chord_note12_index]) {
                        res[chord_note12_index] = scale_note_names[scale_note12_index];
                        break;
                    }
                }
            }
            return res;
        }
        
        function noteNamesToString(noteNames) {
            var str = "(";
            for (var i = 0; i < noteNames.length; i++) {
                if (i > 0) {
                    str += ", ";
                }
                str += noteNames[i];
            }
            str += ")";
            
            return str;
        }
        
        // Returns a string representing the note names of scale_chord_real_note_names to be displayed in bold when the note belongs to the original chord chord_notes12.
        function noteNamesToHtml(chord_notes12, scale_chord_real_note_names) {
            var str = "(";
            // Scans each note name from the final chord.
            for (var i = 0; i < scale_chord_real_note_names.length; i++) {
                if (i > 0) {
                    str += ", ";
                }
                var note_name = scale_chord_real_note_names[i];
                var found = false;
                // Scans each note position from the original chord.
                for (var j = 0; j < chord_notes12.length; j++) {
                    // Get all possible names for that note position.
                    var names = note12NamesExt[chord_notes12[j]];
                    // Match if the note name from the final chord is found in the current possible names.
                    for (var n = 0; n < names.length; n++) {
                        if (note_name == names[n]) {
                            found = true;
                            break;
                        }
                    }
                    if (found) {
                        str += "<b>";
                        break;
                    }
                }
                str += note_name;
                if (found) {
                    str += "</b>";
                }
            }
            str += ")";
            
            return str;
        }
    }

    // Searching for triads (3) or seventh chords (4).
    property int chord_size: 3
    property bool strict: true

    function displayChordNotes(chord_root_note12, chord_type) {
        var finder = new pivotChordFinder();
        finder.printChordRealNoteNames(chord_root_note12, chord_type);
    }

    function displayPivotChords(chord_root_note12, chord_type) {
        var finder = new pivotChordFinder();
        finder.printChordRealNoteNames(chord_root_note12, chord_type);
        finder.printChordInScales(chord_root_note12, chord_type, chord_size, strict);
    }

    Rectangle {
        color: "slategray"
        anchors.fill: parent

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            GridLayout {
                columns: 1
                anchors.fill: parent
                    
                Label {
                    text: "Root note"
                    font.bold: true
                    color: "white"
                }
                ComboBox {
                    id: chordRootNoteBox
                    model: ListModel {
                        id: rootNoteList
                        ListElement { text: "C";     root_note: 0 }
                        ListElement { text: "C♯/Db"; root_note: 1 }
                        ListElement { text: "D";     root_note: 2 }
                        ListElement { text: "D♯/Eb"; root_note: 3 }
                        ListElement { text: "E";     root_note: 4 }
                        ListElement { text: "F";     root_note: 5 }
                        ListElement { text: "F♯/Gb"; root_note: 6 }
                        ListElement { text: "G";     root_note: 7 }
                        ListElement { text: "G♯/Ab"; root_note: 8 }
                        ListElement { text: "A";     root_note: 9 }
                        ListElement { text: "A♯/Bb"; root_note: 10 }
                        ListElement { text: "B";     root_note: 11 }
                    }
                    currentIndex: 0
//                    style: ComboBoxStyle {
//                        font.family: 'MScore Text'
//                        font.pointSize: 14
//                    }
                    onActivated: {
                        displayChordNotes(model.get(index).root_note, chordTypeBox.model.get(chordTypeBox.currentIndex).chord_type)
                    }
                }
                Label {
                    text: "Chord type"
                    font.bold: true
                    color: "white"
                }
                ComboBox {
                    id: chordTypeBox
                    model: ListModel {
                        id: chordTypeList
                        ListElement { text: "[1] single note"; chord_type: 12 }
                        ListElement { text: "[2] dim 3rd"; chord_type: 13 }
                        ListElement { text: "[2] min 3rd"; chord_type: 14 }
                        ListElement { text: "[2] maj 3rd"; chord_type: 15 }
                        ListElement { text: "[2] aug 3rd"; chord_type: 16 }
                        ListElement { text: "[2] dim 5th"; chord_type: 17 }
                        ListElement { text: "[2] perf 5th"; chord_type: 18 }
                        ListElement { text: "[2] aug 5th"; chord_type: 19 }
                        ListElement { text: "[2] dim 7th"; chord_type: 20 }
                        ListElement { text: "[2] min 7th"; chord_type: 21 }
                        ListElement { text: "[2] maj 7th"; chord_type: 22 }
                        ListElement { text: "[3] °, dim, m(♭5)"; chord_type: 3 }
                        ListElement { text: "[3] m"; chord_type: 0 }
                        ListElement { text: "[3] M"; chord_type: 6 }
                        ListElement { text: "[3] +, aug"; chord_type: 9 }
                        ListElement { text: "[4] °7, dim7, m6(♭5)"; chord_type: 4 }
                        ListElement { text: "[4] ø7, m7(♭5)"; chord_type: 5 }
                        ListElement { text: "[4] m7"; chord_type: 1 }
                        ListElement { text: "[4] 7"; chord_type: 7 }
                        ListElement { text: "[4] mM7"; chord_type: 2 }
                        ListElement { text: "[4] M7"; chord_type: 8 }
                        ListElement { text: "[4] +7, aug7, 7(♯5)"; chord_type: 10 }
                        ListElement { text: "[4] +M7, augM7"; chord_type: 11 }
                    }
                    currentIndex: 0
//                    style: ComboBoxStyle {
//                        font.family: 'MScore Text'
//                        font.pointSize: 14
//                    }
                    onActivated: {
                        displayChordNotes(chordRootNoteBox.model.get(chordRootNoteBox.currentIndex).root_note, model.get(index).chord_type)
                    }
                }
                Label {
                    text: "Search for"
                    font.bold: true
                    color: "white"
                }
                RowLayout {
                    ExclusiveGroup { id: chordSizeGroup }
                    RadioButton {
                        text: "Triads"
                        checked: true
                        exclusiveGroup: chordSizeGroup
                        onClicked: {
                            chord_size = 3
                            displayChordNotes(chordRootNoteBox.model.get(chordRootNoteBox.currentIndex).root_note, chordTypeBox.model.get(chordTypeBox.currentIndex).chord_type)
                        }
                    }
                    RadioButton {
                        text: "7ths"
                        checked: false
                        exclusiveGroup: chordSizeGroup
                        onClicked: {
                            chord_size = 4
                            displayChordNotes(chordRootNoteBox.model.get(chordRootNoteBox.currentIndex).root_note, chordTypeBox.model.get(chordTypeBox.currentIndex).chord_type)
                        }
                    }
                }
                RowLayout {
                    CheckBox {
                        checked: true
                        text: "Strict"
                        onClicked: {
                            strict = checked;
                            displayChordNotes(chordRootNoteBox.model.get(chordRootNoteBox.currentIndex).root_note, chordTypeBox.model.get(chordTypeBox.currentIndex).chord_type)
                        }
                    }
                }
                GridLayout { // padding
                    columns: 1
                    anchors.fill: parent
                    anchors.margins: 10
                }
                Button {
                    id: searchButton
                    text: "Search"
                    onClicked: {
                        displayPivotChords(chordRootNoteBox.model.get(chordRootNoteBox.currentIndex).root_note, chordTypeBox.model.get(chordTypeBox.currentIndex).chord_type)
                    }
                }
                Button {
                    id: copyButton
                    text: "Copy"
                    onClicked: {
                        outputText.selectAll()
                        outputText.copy()
                        outputText.deselect()
                    }
                }
                Button {
                    id: clearButton
                    text: "Clear"
                    onClicked: {
                        outputText.text = ""
                        displayChordNotes(chordRootNoteBox.model.get(chordRootNoteBox.currentIndex).root_note, chordTypeBox.model.get(chordTypeBox.currentIndex).chord_type)
                    }
                }
                Button {
                    id: quitButton
                    text: "Quit"
                    onClicked: {
//                        Qt.quit() // in MuseScore3
                        quit() // in MuseScore4
                    }
                }
            }
            TextArea {
                id: outputText
                readOnly: true
                text: "<b>Choose a single note or a chord, then find all the chords (triads or seventh chords) in all keys and scales that include that or those notes.</b><br>" +
                      "The 'Strict' option indicates whether you want to find chords that strictly or partially share your chord.<br>" +
                      "<p style='color:#457596;'>Now select the root note and type of a chord.<br>Then click on <b>Search</b>.</p>"
                textFormat: TextEdit.RichText
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}

// vim: ft=javascript