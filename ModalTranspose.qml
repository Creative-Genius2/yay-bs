import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import MuseScore 3.0

MuseScore {
    version: "1.1"
    description: "Modal transposition - scale degree mapping"
    menuPath: "Plugins.Modal Transpose"
    requiresScore: true
    pluginType: "dialog"
    
    width: 400
    height: 520
    
    property var displayRoots: ["C", "C#", "Db", "D", "D#", "Eb", "E", "F", "F#", "Gb", "G", "G#", "Ab", "A", "A#", "Bb", "B"]
    property var modeNames: ["Ionian", "Dorian", "Phrygian", "Lydian", "Mixolydian", "Aeolian", "Locrian"]
    
    property var ionianIntervals: [0, 2, 4, 5, 7, 9, 11]
    
    property var modeOffsets: {
        "Ionian": 0,
        "Dorian": 1,
        "Phrygian": 2,
        "Lydian": 3,
        "Mixolydian": 4,
        "Aeolian": 5,
        "Locrian": 6
    }
    
    property var modeRootOffsets: {
        "Ionian": 0,
        "Dorian": 2,
        "Phrygian": 4,
        "Lydian": 5,
        "Mixolydian": 7,
        "Aeolian": 9,
        "Locrian": 11
    }
    
    property var modeIntervals: {
        "Ionian": [0, 2, 4, 5, 7, 9, 11],
        "Dorian": [0, 2, 3, 5, 7, 9, 10],
        "Phrygian": [0, 1, 3, 5, 7, 8, 10],
        "Lydian": [0, 2, 4, 6, 7, 9, 11],
        "Mixolydian": [0, 2, 4, 5, 7, 9, 10],
        "Aeolian": [0, 2, 3, 5, 7, 8, 10],
        "Locrian": [0, 1, 3, 5, 6, 8, 10]
    }
    
    // Triad qualities for each scale degree in each mode
    property var modeChordQualities: {
        "Ionian": ["maj", "min", "min", "maj", "maj", "min", "dim"],
        "Dorian": ["min", "min", "maj", "maj", "min", "dim", "maj"],
        "Phrygian": ["min", "maj", "maj", "min", "dim", "maj", "min"],
        "Lydian": ["maj", "maj", "min", "dim", "maj", "min", "min"],
        "Mixolydian": ["maj", "min", "dim", "maj", "min", "min", "maj"],
        "Aeolian": ["min", "dim", "maj", "min", "min", "maj", "maj"],
        "Locrian": ["dim", "maj", "min", "min", "maj", "maj", "min"]
    }
    
    // 7th chord qualities for each scale degree in each mode
    property var mode7thQualities: {
        "Ionian": ["maj7", "min7", "min7", "maj7", "dom7", "min7", "m7b5"],
        "Dorian": ["min7", "min7", "maj7", "dom7", "min7", "m7b5", "maj7"],
        "Phrygian": ["min7", "maj7", "dom7", "min7", "m7b5", "maj7", "min7"],
        "Lydian": ["maj7", "dom7", "min7", "m7b5", "maj7", "min7", "min7"],
        "Mixolydian": ["dom7", "min7", "m7b5", "maj7", "min7", "min7", "maj7"],
        "Aeolian": ["min7", "m7b5", "maj7", "min7", "min7", "maj7", "dom7"],
        "Locrian": ["m7b5", "maj7", "min7", "min7", "maj7", "dom7", "min7"]
    }
    
    // Complete chord interval structures
    property var chordIntervals: {
        // Triads
        "maj": [0, 4, 7],
        "min": [0, 3, 7],
        "dim": [0, 3, 6],
        "aug": [0, 4, 8],
        // 7th chords
        "maj7": [0, 4, 7, 11],
        "min7": [0, 3, 7, 10],
        "dom7": [0, 4, 7, 10],
        "m7b5": [0, 3, 6, 10],
        "dim7": [0, 3, 6, 9],
        "minMaj7": [0, 3, 7, 11],
        "augMaj7": [0, 4, 8, 11],
        "aug7": [0, 4, 8, 10],
        // Extended (common voicings, not full extensions)
        "add9": [0, 4, 7, 14],
        "madd9": [0, 3, 7, 14],
        "sus2": [0, 2, 7],
        "sus4": [0, 5, 7],
        "dom7sus4": [0, 5, 7, 10],
        // 6th chords
        "maj6": [0, 4, 7, 9],
        "min6": [0, 3, 7, 9]
    }
    
    // Interval to scale degree offset mapping (for chord tone identification)
    property var intervalToDegree: {
        0: 0,   // root
        2: 1,   // sus2/9th → 2nd degree
        3: 2,   // minor 3rd → 3rd degree
        4: 2,   // major 3rd → 3rd degree
        5: 3,   // sus4/11th → 4th degree
        6: 4,   // diminished 5th → 5th degree
        7: 4,   // perfect 5th → 5th degree
        8: 4,   // augmented 5th → 5th degree
        9: 5,   // 6th/13th → 6th degree
        10: 6,  // minor 7th → 7th degree
        11: 6,  // major 7th → 7th degree
        14: 1   // 9th (octave + 2) → 2nd degree
    }
    
    property var naturalPitches: {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
    property var letterOrder: ["C", "D", "E", "F", "G", "A", "B"]
    property var tpcBase: {"C": 14, "D": 16, "E": 18, "F": 13, "G": 15, "A": 17, "B": 19}
    
    // Track processed notes to handle ties
    property var processedNoteIds: ({})
    
    function rootToPitch(root) {
        var base = root.charAt(0);
        var pitch = naturalPitches[base];
        if (root.indexOf("##") !== -1) pitch += 2;
        else if (root.indexOf("#") !== -1) pitch += 1;
        else if (root.indexOf("bb") !== -1) pitch -= 2;
        else if (root.indexOf("b") !== -1) pitch -= 1;
        return (pitch + 12) % 12;
    }
    
    function buildScale(root, mode) {
        var rootPitch = rootToPitch(root);
        var rootLetter = root.charAt(0);
        var rootLetterIndex = letterOrder.indexOf(rootLetter);
        var intervals = modeIntervals[mode];
        var scale = [];
        
        for (var deg = 0; deg < 7; deg++) {
            var targetPitch = (rootPitch + intervals[deg]) % 12;
            var letter = letterOrder[(rootLetterIndex + deg) % 7];
            var natural = naturalPitches[letter];
            var diff = (targetPitch - natural + 12) % 12;
            var accidental = "";
            
            if (diff === 0) accidental = "";
            else if (diff === 1) accidental = "#";
            else if (diff === 2) accidental = "##";
            else if (diff === 11) accidental = "b";
            else if (diff === 10) accidental = "bb";
            
            scale.push({letter: letter, accidental: accidental, pitch: targetPitch});
        }
        return scale;
    }
    
    function tpcToLetter(tpc) {
        var letters = ["F", "C", "G", "D", "A", "E", "B"];
        return letters[((tpc - 13) % 7 + 7) % 7];
    }
    
    function findDegreeInfo(pitch, tpc, scale) {
        var pc = pitch % 12;
        var letter = tpcToLetter(tpc);
        
        for (var i = 0; i < scale.length; i++) {
            if (scale[i].letter === letter) {
                var offset = (pc - scale[i].pitch + 12) % 12;
                if (offset > 6) offset -= 12;
                return {degree: i, offset: offset};
            }
        }
        
        for (var i = 0; i < scale.length; i++) {
            if (scale[i].pitch === pc) {
                return {degree: i, offset: 0};
            }
        }
        
        var bestDegree = 0;
        var bestOffset = 12;
        for (var i = 0; i < scale.length; i++) {
            var diff = (pc - scale[i].pitch + 12) % 12;
            if (diff > 6) diff -= 12;
            if (Math.abs(diff) < Math.abs(bestOffset)) {
                bestOffset = diff;
                bestDegree = i;
            }
        }
        
        return {degree: bestDegree, offset: bestOffset};
    }
    
    function getModeRotationShift(srcMode, tgtMode) {
        var shift = (modeOffsets[tgtMode] - modeOffsets[srcMode] + 7) % 7;
        if (shift > 3) shift = shift - 7;
        return shift;
    }
    
    function findChordDegree(chordRootPitch, scale) {
        for (var i = 0; i < scale.length; i++) {
            if (scale[i].pitch === chordRootPitch) {
                return i;
            }
        }
        var minDist = 12;
        var closestDeg = 0;
        for (var i = 0; i < scale.length; i++) {
            var dist = Math.abs((chordRootPitch - scale[i].pitch + 6 + 12) % 12 - 6);
            if (dist < minDist) {
                minDist = dist;
                closestDeg = i;
            }
        }
        return closestDeg;
    }
    
    function buildTargetChord(degree, targetScale, targetMode, use7ths) {
        var quality = use7ths ? mode7thQualities[targetMode][degree] : modeChordQualities[targetMode][degree];
        var intervals = chordIntervals[quality];
        if (!intervals) {
            intervals = chordIntervals["maj"]; // fallback
        }
        var rootNote = targetScale[degree];
        var rootPitch = rootNote.pitch;
        
        var chordNotes = [];
        for (var i = 0; i < intervals.length; i++) {
            var interval = intervals[i];
            var targetPitch = (rootPitch + interval) % 12;
            
            var degreeOffset = intervalToDegree[interval];
            if (degreeOffset === undefined) degreeOffset = Math.round(interval / 2) % 7;
            var targetDegree = (degree + degreeOffset) % 7;
            var scaleNote = targetScale[targetDegree];
            
            var pitchDiff = (targetPitch - scaleNote.pitch + 12) % 12;
            if (pitchDiff > 6) pitchDiff -= 12;
            
            var accidental = scaleNote.accidental;
            var accVal = (accidental === "##" ? 2 : accidental === "#" ? 1 : accidental === "b" ? -1 : accidental === "bb" ? -2 : 0);
            accVal += pitchDiff;
            
            if (accVal === 0) accidental = "";
            else if (accVal === 1) accidental = "#";
            else if (accVal === 2) accidental = "##";
            else if (accVal === -1) accidental = "b";
            else if (accVal === -2) accidental = "bb";
            else if (accVal > 2) accidental = "##";
            else accidental = "bb";
            
            chordNotes.push({
                pitch: targetPitch,
                letter: scaleNote.letter,
                accidental: accidental,
                degree: targetDegree,
                interval: interval
            });
        }
        
        return chordNotes;
    }
    
    function respell(letter, accidental, preferFlats) {
        if (accidental !== "##" && accidental !== "bb") {
            return {letter: letter, accidental: accidental};
        }
        
        var pitch = (naturalPitches[letter] + (accidental === "##" ? 2 : -2) + 12) % 12;
        
        for (var l in naturalPitches) {
            if (naturalPitches[l] === pitch) {
                return {letter: l, accidental: ""};
            }
        }
        
        for (var l in naturalPitches) {
            var diff = (pitch - naturalPitches[l] + 12) % 12;
            if (diff === 1 && !preferFlats) return {letter: l, accidental: "#"};
            if (diff === 11 && preferFlats) return {letter: l, accidental: "b"};
        }
        
        return {letter: letter, accidental: accidental};
    }
    
    function calcTPC(letter, accidental) {
        var base = tpcBase[letter];
        var tpc = base;
        if (accidental === "#") tpc = base + 7;
        else if (accidental === "##") tpc = base + 14;
        else if (accidental === "b") tpc = base - 7;
        else if (accidental === "bb") tpc = base - 14;
        
        if (tpc < -1) tpc = -1;
        if (tpc > 33) tpc = 33;
        
        return tpc;
    }
    
    function getChordAtTick(tick) {
        var pitches = [];
        var cursor = curScore.newCursor();
        
        for (var staff = 0; staff < curScore.nstaves; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.staffIdx = staff;
                cursor.voice = voice;
                cursor.rewind(Cursor.SCORE_START);
                
                while (cursor.segment && cursor.tick < tick) {
                    cursor.next();
                }
                
                if (cursor.segment && cursor.tick === tick) {
                    if (cursor.element && cursor.element.type === Element.CHORD) {
                        var notes = cursor.element.notes;
                        for (var i = 0; i < notes.length; i++) {
                            var pc = notes[i].pitch % 12;
                            if (pitches.indexOf(pc) === -1) pitches.push(pc);
                        }
                    }
                }
            }
        }
        return pitches;
    }
    
    function identifyChord(pitches) {
        if (pitches.length === 0) return null;
        
        // Sort pitches for consistent analysis
        pitches = pitches.slice().sort(function(a, b) { return a - b; });
        
        // Try each pitch as potential root
        for (var r = 0; r < pitches.length; r++) {
            var root = pitches[r];
            var intervals = [];
            for (var i = 0; i < pitches.length; i++) {
                intervals.push((pitches[i] - root + 12) % 12);
            }
            intervals.sort(function(a, b) { return a - b; });
            
            // Check against all known chord types
            for (var chordType in chordIntervals) {
                var template = chordIntervals[chordType];
                if (template.length !== intervals.length) continue;
                
                var match = true;
                for (var j = 0; j < template.length; j++) {
                    // Handle octave equivalence for extended chords
                    var templateInterval = template[j] % 12;
                    if (intervals.indexOf(templateInterval) === -1) {
                        match = false;
                        break;
                    }
                }
                
                if (match) {
                    return {root: root, quality: chordType};
                }
            }
        }
        
        // Fallback: check just for basic triads with extra notes
        for (var r = 0; r < pitches.length; r++) {
            var root = pitches[r];
            var intervals = [];
            for (var i = 0; i < pitches.length; i++) {
                intervals.push((pitches[i] - root + 12) % 12);
            }
            
            var has0 = intervals.indexOf(0) !== -1;
            var has3 = intervals.indexOf(3) !== -1;
            var has4 = intervals.indexOf(4) !== -1;
            var has6 = intervals.indexOf(6) !== -1;
            var has7 = intervals.indexOf(7) !== -1;
            var has8 = intervals.indexOf(8) !== -1;
            
            if (has0 && has4 && has7) return {root: root, quality: "maj"};
            if (has0 && has3 && has7) return {root: root, quality: "min"};
            if (has0 && has3 && has6) return {root: root, quality: "dim"};
            if (has0 && has4 && has8) return {root: root, quality: "aug"};
        }
        
        return {root: pitches[0], quality: "unknown"};
    }
    
    function detectKeyAndMode() {
        if (!curScore) return {root: "C", mode: "Aeolian"};
        
        var cursor = curScore.newCursor();
        
        // Track chord roots with position weighting
        var chordRoots = [0,0,0,0,0,0,0,0,0,0,0,0];
        var bassNotes = [0,0,0,0,0,0,0,0,0,0,0,0];
        var firstChordRoot = -1;
        var lastChordRoot = -1;
        var firstBassNote = -1;
        var lastBassNote = -1;
        
        cursor.rewind(Cursor.SCORE_START);
        var visitedTicks = {};
        var totalTicks = 0;
        
        // Find total duration for position weighting
        cursor.rewind(Cursor.SCORE_END);
        if (cursor.segment) totalTicks = cursor.tick;
        if (totalTicks === 0) totalTicks = 1;
        
        // Analyze chords and bass notes
        for (var staff = 0; staff < curScore.nstaves; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.staffIdx = staff;
                cursor.voice = voice;
                cursor.rewind(Cursor.SCORE_START);
                
                while (cursor.segment) {
                    var tick = cursor.tick;
                    var tickKey = tick + "_" + staff + "_" + voice;
                    
                    if (!visitedTicks[tickKey] && cursor.element && cursor.element.type === Element.CHORD) {
                        visitedTicks[tickKey] = true;
                        
                        var notes = cursor.element.notes;
                        if (notes.length > 0) {
                            // Find lowest note (bass)
                            var lowestPitch = 127;
                            for (var n = 0; n < notes.length; n++) {
                                if (notes[n].pitch < lowestPitch) {
                                    lowestPitch = notes[n].pitch;
                                }
                            }
                            var bassPC = lowestPitch % 12;
                            
                            // Weight bass notes by metric position (downbeats stronger)
                            var beatWeight = 1;
                            if (cursor.segment && cursor.segment.tick % 1920 === 0) beatWeight = 3; // downbeat
                            else if (cursor.segment && cursor.segment.tick % 960 === 0) beatWeight = 2; // half-bar
                            
                            bassNotes[bassPC] += beatWeight;
                            
                            if (firstBassNote === -1) firstBassNote = bassPC;
                            lastBassNote = bassPC;
                        }
                        
                        // Chord analysis
                        var chordPitches = [];
                        for (var n = 0; n < notes.length; n++) {
                            var pc = notes[n].pitch % 12;
                            if (chordPitches.indexOf(pc) === -1) chordPitches.push(pc);
                        }
                        
                        if (chordPitches.length >= 2) {
                            var chord = identifyChord(chordPitches);
                            if (chord && chord.root !== undefined) {
                                // Position weight: first and last 10% of piece get bonus
                                var posWeight = 1;
                                var relPos = tick / totalTicks;
                                if (relPos < 0.1) posWeight = 2;
                                if (relPos > 0.9) posWeight = 3;
                                
                                chordRoots[chord.root] += posWeight;
                                if (firstChordRoot === -1) firstChordRoot = chord.root;
                                lastChordRoot = chord.root;
                            }
                        }
                    }
                    cursor.next();
                }
            }
        }
        
        // Combine bass note analysis with chord root analysis
        // Bass notes are strong indicator of tonic
        var combinedWeight = [0,0,0,0,0,0,0,0,0,0,0,0];
        for (var i = 0; i < 12; i++) {
            combinedWeight[i] = chordRoots[i] + bassNotes[i] * 2;
        }
        
        // Strong bonus for last bass note (resolution point)
        if (lastBassNote !== -1) {
            combinedWeight[lastBassNote] += 10;
        }
        
        // Bonus for first bass note
        if (firstBassNote !== -1) {
            combinedWeight[firstBassNote] += 5;
        }
        
        // Find tonic
        var tonic = 0;
        var maxWeight = 0;
        for (var i = 0; i < 12; i++) {
            if (combinedWeight[i] > maxWeight) {
                maxWeight = combinedWeight[i];
                tonic = i;
            }
        }
        
        // Analyze scale content for mode detection
        cursor.rewind(Cursor.SCORE_START);
        var scaleProfile = [0,0,0,0,0,0,0,0,0,0,0,0];
        
        for (var staff = 0; staff < curScore.nstaves; staff++) {
            for (var voice = 0; voice < 4; voice++) {
                cursor.staffIdx = staff;
                cursor.voice = voice;
                cursor.rewind(Cursor.SCORE_START);
                
                while (cursor.segment) {
                    if (cursor.element && cursor.element.type === Element.CHORD) {
                        var notes = cursor.element.notes;
                        for (var i = 0; i < notes.length; i++) {
                            var pc = notes[i].pitch % 12;
                            scaleProfile[pc]++;
                        }
                    }
                    cursor.next();
                }
            }
        }
        
		        // Analyze intervals relative to detected tonic
        var m2 = (tonic + 1) % 12;
        var M2 = (tonic + 2) % 12;
        var m3 = (tonic + 3) % 12;
        var M3 = (tonic + 4) % 12;
        var P4 = (tonic + 5) % 12;
        var A4 = (tonic + 6) % 12;
        var P5 = (tonic + 7) % 12;
        var m6 = (tonic + 8) % 12;
        var M6 = (tonic + 9) % 12;
        var m7 = (tonic + 10) % 12;
        var M7 = (tonic + 11) % 12;
        
        var hasMinor2 = scaleProfile[m2] > scaleProfile[M2];
        var hasMinor3 = scaleProfile[m3] > scaleProfile[M3];
        var hasAug4 = scaleProfile[A4] > scaleProfile[P4] && scaleProfile[A4] > 0;
        var hasDim5 = scaleProfile[A4] > scaleProfile[P5];
        var hasMinor6 = scaleProfile[m6] > scaleProfile[M6];
        var hasMajor6 = scaleProfile[M6] > scaleProfile[m6];
        var hasMinor7 = scaleProfile[m7] > scaleProfile[M7];
        var hasMajor7 = scaleProfile[M7] > scaleProfile[m7];
        
        // Mode detection logic
        var mode = "Ionian";
        
        if (hasMinor3) {
            // Minor family: Dorian, Phrygian, Aeolian, Locrian
            if (hasDim5) {
                mode = "Locrian";
            } else if (hasMinor2) {
                mode = "Phrygian";
            } else if (hasMajor6) {
                mode = "Dorian";
            } else {
                mode = "Aeolian";
            }
        } else {
            // Major family: Ionian, Lydian, Mixolydian
            if (hasAug4) {
                mode = "Lydian";
            } else if (hasMinor7) {
                mode = "Mixolydian";
            } else {
                mode = "Ionian";
            }
        }
        
        // Choose appropriate spelling for tonic
        var preferFlats = scaleProfile[(tonic + 1) % 12] < scaleProfile[(tonic + 11) % 12];
        var pcToRootSharp = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        var pcToRootFlat = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];
        
        var rootName = preferFlats ? pcToRootFlat[tonic] : pcToRootSharp[tonic];
        
        return {root: rootName, mode: mode};
    }
    
    function getRelativeRoot(root, mode, toMajor) {
        var pitch = rootToPitch(root);
        var modeOffset = modeRootOffsets[mode];
        
        if (toMajor) {
            pitch = (pitch - modeOffset + 12) % 12;
        } else {
            var ionianRoot = (pitch - modeOffset + 12) % 12;
            pitch = (ionianRoot + modeRootOffsets["Aeolian"]) % 12;
        }
        
        var preferFlats = root.indexOf("b") !== -1;
        var pcToRootSharp = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
        var pcToRootFlat = ["C", "Db", "D", "Eb", "E", "F", "Gb", "G", "Ab", "A", "Bb", "B"];
        
        return preferFlats ? pcToRootFlat[pitch] : pcToRootSharp[pitch];
    }
    
    function hasSelection() {
        if (!curScore) return false;
        var sel = curScore.selection;
        if (!sel) return false;
        var elements = sel.elements;
        if (!elements || elements.length === 0) return false;
        
        // Check if any notes are selected
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].type === Element.NOTE) {
                return true;
            }
        }
        return false;
    }
    
    function getSelectedNotes() {
        var notes = [];
        if (!curScore) return notes;
        var sel = curScore.selection;
        if (!sel) return notes;
        var elements = sel.elements;
        if (!elements) return notes;
        
        for (var i = 0; i < elements.length; i++) {
            if (elements[i].type === Element.NOTE) {
                notes.push(elements[i]);
            }
        }
        return notes;
    }
    
    function getNoteId(note) {
        // Create unique identifier for a note based on its properties
        // This helps track tied notes
        if (!note || !note.parent) return null;
        var chord = note.parent;
        if (!chord.parent) return null;
        var seg = chord.parent;
        return seg.tick + "_" + note.pitch + "_" + note.track;
    }
    
    function transformNotes() {
        if (!curScore) return;
        
        var srcRoot = displayRoots[sourceRoot.currentIndex];
        var srcMode = modeNames[sourceMode.currentIndex];
        var tgtRoot = displayRoots[targetRoot.currentIndex];
        var tgtMode = modeNames[targetMode.currentIndex];
        
        var srcScale = buildScale(srcRoot, srcMode);
        var tgtScale = buildScale(tgtRoot, tgtMode);
        var preferFlats = tgtRoot.indexOf("b") !== -1;
        
        var modeShift = getModeRotationShift(srcMode, tgtMode);
        
        // Reset processed notes tracker
        processedNoteIds = {};
        
        curScore.startCmd();
        
        // Check if we have a selection
        var useSelection = hasSelection();
        
        if (useSelection) {
            // Transform only selected notes
            var selectedNotes = getSelectedNotes();
            
            for (var i = 0; i < selectedNotes.length; i++) {
                var note = selectedNotes[i];
                var noteId = getNoteId(note);
                
                // Skip if already processed (tied note) or if this is continuation of tie
                if (noteId && processedNoteIds[noteId]) continue;
                if (note.tieBack) continue;
                
                if (noteId) processedNoteIds[noteId] = true;
                
                transformSingleNote(note, srcScale, tgtScale, preferFlats, tgtMode);
            }
            
            statusLabel.text = srcRoot + " " + srcMode + " → " + tgtRoot + " " + tgtMode + " (selection)";
        } else {
            // Transform entire score
            var cursor = curScore.newCursor();
            
            // Build chord context map
            var chordContextMap = {};
            
            for (var staff = 0; staff < curScore.nstaves; staff++) {
                for (var voice = 0; voice < 4; voice++) {
                    cursor.staffIdx = staff;
                    cursor.voice = voice;
                    cursor.rewind(Cursor.SCORE_START);
                    
                    while (cursor.segment) {
                        var tick = cursor.tick;
                        if (!chordContextMap[tick] && cursor.element && cursor.element.type === Element.CHORD) {
                            var chordPitches = getChordAtTick(tick);
                            if (chordPitches.length >= 2) {
                                var chordInfo = identifyChord(chordPitches);
                                if (chordInfo && chordInfo.quality !== "unknown") {
                                    var chordDegree = findChordDegree(chordInfo.root, srcScale);
                                    var use7ths = chordPitches.length >= 4;
                                    var targetChord = findFunctionalChord(chordDegree, chordInfo.quality, srcMode, tgtScale, tgtMode, use7ths);
                                    chordContextMap[tick] = {
                                        srcDegree: chordDegree,
                                        srcQuality: chordInfo.quality,
                                        srcRoot: chordInfo.root,
                                        tgtChord: targetChord,
                                        tgtQuality: use7ths ? mode7thQualities[tgtMode][targetChord[0].degree] : modeChordQualities[tgtMode][targetChord[0].degree]
                                    };
                                }
                            }
                        }
                        cursor.next();
                    }
                }
            }
            
            // Transform notes with chord awareness
            for (var staff = 0; staff < curScore.nstaves; staff++) {
                for (var voice = 0; voice < 4; voice++) {
                    cursor.staffIdx = staff;
                    cursor.voice = voice;
                    cursor.rewind(Cursor.SCORE_START);
                    
                    while (cursor.segment) {
                        if (cursor.element && cursor.element.type === Element.CHORD) {
                            var tick = cursor.tick;
                            var notes = cursor.element.notes;
                            var chordContext = chordContextMap[tick];
                            
                            for (var i = 0; i < notes.length; i++) {
                                var note = notes[i];
                                var noteId = getNoteId(note);
                                
                                // Skip tied notes (continuation of previous note)
                                if (noteId && processedNoteIds[noteId]) continue;
                                if (note.tieBack) continue;
                                
                                if (noteId) processedNoteIds[noteId] = true;
                                
                                transformSingleNoteWithContext(note, srcScale, tgtScale, preferFlats, tgtMode, chordContext);
                            }
                        }
                        cursor.next();
                    }
                }
            }
            
            statusLabel.text = srcRoot + " " + srcMode + " → " + tgtRoot + " " + tgtMode;
        }
        
        curScore.endCmd();
    }
    
    function transformSingleNote(note, srcScale, tgtScale, preferFlats, tgtMode) {
        // Simple transformation without chord context (for selections)
        transformSingleNoteWithContext(note, srcScale, tgtScale, preferFlats, tgtMode, null);
    }
    
    function findFunctionalChord(srcDegree, srcQuality, srcMode, tgtScale, tgtMode, use7ths) {
        var tgtQualityTable = use7ths ? mode7thQualities[tgtMode] : modeChordQualities[tgtMode];
        var tgtQuality = tgtQualityTable[srcDegree];

        var srcIsDim = (srcQuality === "dim" || srcQuality === "m7b5" || srcQuality === "dim7");
        var tgtIsDim = (tgtQuality === "dim" || tgtQuality === "m7b5" || tgtQuality === "dim7");

        if (tgtQuality === srcQuality) {
            return buildTargetChord(srcDegree, tgtScale, tgtMode, use7ths);
        }

        if (!srcIsDim && tgtIsDim) {
            var srcQualityTable = use7ths ? mode7thQualities[srcMode] : modeChordQualities[srcMode];
            for (var d = 0; d < 7; d++) {
                if (d === srcDegree) continue;
                if (tgtQualityTable[d] === srcQuality || tgtQualityTable[d] === srcQualityTable[srcDegree]) {
                    return buildTargetChord(d, tgtScale, tgtMode, use7ths);
                }
            }
        }

        return buildTargetChord(srcDegree, tgtScale, tgtMode, use7ths);
    }

    function transformSingleNoteWithContext(note, srcScale, tgtScale, preferFlats, tgtMode, chordContext) {
        var pitch = note.pitch;
        var tpc = note.tpc1;
        var octave = Math.floor(pitch / 12);
        var pitchClass = pitch % 12;

        var info = findDegreeInfo(pitch, tpc, srcScale);
        var degree = info.degree;
        var offset = info.offset;

        var useChordContext = false;
        var chordToneIndex = -1;

        if (chordContext && chordContext.tgtChord) {
            var srcChordRoot = chordContext.srcRoot;
            var intervalFromRoot = (pitchClass - srcChordRoot + 12) % 12;

            var srcQualityIntervals = chordIntervals[chordContext.srcQuality];
            if (srcQualityIntervals) {
                for (var ci = 0; ci < srcQualityIntervals.length; ci++) {
                    var templateInterval = srcQualityIntervals[ci] % 12;
                    if (templateInterval === intervalFromRoot) {
                        chordToneIndex = ci;
                        useChordContext = true;
                        break;
                    }
                }
            }
        }

        var newLetter, newAcc, newPitchClass;

        if (useChordContext && chordToneIndex >= 0 && chordToneIndex < chordContext.tgtChord.length) {
            var tgtChordNote = chordContext.tgtChord[chordToneIndex];
            newLetter = tgtChordNote.letter;
            newAcc = tgtChordNote.accidental;
            newPitchClass = tgtChordNote.pitch;
        } else {
            var targetDeg = tgtScale[degree];

            newPitchClass = (targetDeg.pitch + offset + 12) % 12;
            newLetter = targetDeg.letter;
            var baseAcc = targetDeg.accidental;

            var accVal = (baseAcc === "##" ? 2 : baseAcc === "#" ? 1 : baseAcc === "b" ? -1 : baseAcc === "bb" ? -2 : 0);
            accVal += offset;

            if (accVal === 0) newAcc = "";
            else if (accVal === 1) newAcc = "#";
            else if (accVal === 2) newAcc = "##";
            else if (accVal === -1) newAcc = "b";
            else if (accVal === -2) newAcc = "bb";
            else if (accVal > 2) newAcc = "##";
            else newAcc = "bb";
        }

        var basePitch = naturalPitches[newLetter] + (newAcc === "##" ? 2 : newAcc === "#" ? 1 : newAcc === "b" ? -1 : newAcc === "bb" ? -2 : 0);
        basePitch = (basePitch + 12) % 12;

        var finalPitch = octave * 12 + basePitch;
        var distCurrent = Math.abs(finalPitch - pitch);
        var distUp = Math.abs((finalPitch + 12) - pitch);
        var distDown = Math.abs((finalPitch - 12) - pitch);

        if (distUp < distCurrent && distUp <= distDown) {
            finalPitch += 12;
        } else if (distDown < distCurrent && distDown < distUp) {
            finalPitch -= 12;
        }

        if (finalPitch < 0) finalPitch += 12;
        if (finalPitch > 127) finalPitch -= 12;

        var newTpc = calcTPC(newLetter, newAcc);

        note.pitch = finalPitch;
        note.tpc1 = newTpc;
        note.tpc2 = newTpc;

        var tiedNote = note.tieForward ? note.tieForward.endNote : null;
        while (tiedNote) {
            tiedNote.pitch = finalPitch;
            tiedNote.tpc1 = newTpc;
            tiedNote.tpc2 = newTpc;
            tiedNote = tiedNote.tieForward ? tiedNote.tieForward.endNote : null;
        }
    }
    
    Component.onCompleted: {
        var detected = detectKeyAndMode();
        
        for (var i = 0; i < displayRoots.length; i++) {
            if (displayRoots[i] === detected.root) {
                sourceRoot.currentIndex = i;
                break;
            }
        }
        
        for (var j = 0; j < modeNames.length; j++) {
            if (modeNames[j] === detected.mode) {
                sourceMode.currentIndex = j;
                break;
            }
        }
        
        statusLabel.text = "Detected: " + detected.root + " " + detected.mode;
		
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12
        
        Label {
            text: "Modal Transpose"
            font.pixelSize: 18
            font.bold: true
        }
        
        Label {
            id: statusLabel
            text: "Ready"
            font.pixelSize: 11
            color: "#666"
        }
        
        GroupBox {
            title: "Source"
            Layout.fillWidth: true
            
            GridLayout {
                columns: 2
                columnSpacing: 10
                
                Label { text: "Root:" }
                ComboBox {
                    id: sourceRoot
                    Layout.fillWidth: true
                    model: displayRoots
                }
                
                Label { text: "Mode:" }
                ComboBox {
                    id: sourceMode
                    Layout.fillWidth: true
                    model: modeNames
                    currentIndex: 5
                }
            }
        }
        
        GroupBox {
            title: "Target"
            Layout.fillWidth: true
            
            GridLayout {
                columns: 2
                columnSpacing: 10
                
                Label { text: "Root:" }
                ComboBox {
                    id: targetRoot
                    Layout.fillWidth: true
                    model: displayRoots
                }
                
                Label { text: "Mode:" }
                ComboBox {
                    id: targetMode
                    Layout.fillWidth: true
                    model: modeNames
                }
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Button {
                text: "Parallel Major"
                Layout.fillWidth: true
                onClicked: {
                    targetRoot.currentIndex = sourceRoot.currentIndex;
                    targetMode.currentIndex = 0;
                    transformNotes();
                }
            }
            
            Button {
                text: "Parallel Minor"
                Layout.fillWidth: true
                onClicked: {
                    targetRoot.currentIndex = sourceRoot.currentIndex;
                    targetMode.currentIndex = 5;
                    transformNotes();
                }
            }
        }
        
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            
            Button {
                text: "Relative Major"
                Layout.fillWidth: true
                onClicked: {
                    var srcRootStr = displayRoots[sourceRoot.currentIndex];
                    var srcModeStr = modeNames[sourceMode.currentIndex];
                    var relRoot = getRelativeRoot(srcRootStr, srcModeStr, true);
                    
                    for (var i = 0; i < displayRoots.length; i++) {
                        if (displayRoots[i] === relRoot) {
                            targetRoot.currentIndex = i;
                            break;
                        }
                    }
                    targetMode.currentIndex = 0;
                    transformNotes();
                }
            }
            
            Button {
                text: "Relative Minor"
                Layout.fillWidth: true
                onClicked: {
                    var srcRootStr = displayRoots[sourceRoot.currentIndex];
                    var srcModeStr = modeNames[sourceMode.currentIndex];
                    var relRoot = getRelativeRoot(srcRootStr, srcModeStr, false);
                    
                    for (var i = 0; i < displayRoots.length; i++) {
                        if (displayRoots[i] === relRoot) {
                            targetRoot.currentIndex = i;
                            break;
                        }
                    }
                    targetMode.currentIndex = 5;
                    transformNotes();
                }
            }
        }
        
        Button {
            text: "Transform"
            Layout.fillWidth: true
            highlighted: true
            onClicked: transformNotes()
        }
        
        Item { Layout.fillHeight: true }
        
        Label {
            text: "Chord-aware modal transposition. Select notes or transform full score."
            font.italic: true
            font.pixelSize: 9
            opacity: 0.5
        }
    }
}