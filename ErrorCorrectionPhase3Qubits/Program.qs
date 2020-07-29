// https://en.wikipedia.org/wiki/Quantum_error_correction (dropping ancillary qubits)
// Sign flip code
namespace ErrorCorrectionPhase3Qubits {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;

    operation SetupMessage(q : Qubit, thetaX : Double, thetaY : Double, thetaZ : Double) : Unit {
        R(PauliX, thetaX, q);
        R(PauliY, thetaY, q);
        R(PauliZ, thetaZ, q);

        // H(q);
    }

    operation CauseError(qubits : Qubit[]) : Unit {
        let singleError = true;
        if (singleError) {
            // if errorPosition >= 3, no error is introduced
            // if errorPosition == 0, 1, 2, a single qubit is flipped
            let errorPosition = RandomInt(5);
            // let errorPosition = 1;
            if (errorPosition <= 2) {
                // X(qubits[errorPosition]);
                Y(qubits[errorPosition]);
                // Z(qubits[errorPosition]);
            }
        } else {
            // rotation error
            let epsilonX = PI() / 12.0; // 15 degrees
            for (position in 0..2) {
                R(PauliY, epsilonX, qubits[position]);
                // R(PauliZ, epsilonX, qubits[position]);
            }
        }
    }

    operation SingleTest(thetaX : Double, thetaY : Double, thetaZ : Double, applyCorrection : Bool) : Int[] {
        mutable measureDupInput = 0;
        mutable measureCorrected = 0;

        using ((qInput, qDupInput) = (Qubit(), Qubit())) {
            // qInput is the input qubit, qDupInput is its dup which goes through the same setup step
            // they are not necessarily equal. qDupInput is for statistical validation
            SetupMessage(qInput, thetaX, thetaY, thetaZ);
            SetupMessage(qDupInput, thetaX, thetaY, thetaZ);

            // set measureDupInput = ResultArrayAsInt([MResetZ(qDupInput)]);
            set measureDupInput = ResultArrayAsInt([MResetX(qDupInput)]);

            using((qInput2, qInput3) = (Qubit(), Qubit())) {
                CNOT(qInput, qInput2);
                CNOT(qInput2, qInput3);
                H(qInput);
                H(qInput2);
                H(qInput3);

                // (qInput, qInput2, qInput3) is alpha * |000> + beta * |111>

                CauseError([qInput, qInput2, qInput3]);

                H(qInput);
                H(qInput2);
                H(qInput3);

                if (applyCorrection) {
                    CNOT(qInput, qInput2);
                    CNOT(qInput, qInput3);
                    CCNOT(qInput2, qInput3, qInput);
                }

                // set measureCorrected = ResultArrayAsInt([MResetZ(qInput)]);
                set measureCorrected = ResultArrayAsInt([MResetX(qInput)]);
                ResetAll([qInput, qInput2, qInput3]);
            }
        }
        return [measureDupInput, measureCorrected];
    }

    @EntryPoint()
    operation RepeatedTest() : Unit {
        let repeatCount = 100000;

        let thetaX = RandomReal(10) * PI();
        let thetaY = RandomReal(10) * PI();
        let thetaZ = RandomReal(10) * PI();

        Message($"No correction, repeated {repeatCount} times");
        mutable recordCorrectedResults = new Int[2];
        mutable recordDupInputResults = new Int[2];

        for(repeatIndex in 1..repeatCount) {
            let testOutput = SingleTest(thetaX, thetaY, thetaZ, false);

            let measureDupInput = testOutput[0];
            let measureCorrected = testOutput[1];

            set recordDupInputResults w/= measureDupInput <- recordDupInputResults[measureDupInput] + 1;
            set recordCorrectedResults w/= measureCorrected <- recordCorrectedResults[measureCorrected] + 1;
        }

        Message($"duplicated input: {recordDupInputResults}");
        Message($"output no correc: {recordCorrectedResults}");

        Message($"With correction, repeated {repeatCount} times");
        set recordCorrectedResults = new Int[2];
        set recordDupInputResults = new Int[2];

        for(repeatIndex in 1..repeatCount) {
            let testOutput = SingleTest(thetaX, thetaY, thetaZ, true);

            let measureDupInput = testOutput[0];
            let measureCorrected = testOutput[1];

            set recordDupInputResults w/= measureDupInput <- recordDupInputResults[measureDupInput] + 1;
            set recordCorrectedResults w/= measureCorrected <- recordCorrectedResults[measureCorrected] + 1;
        }

        Message($"duplicated input: {recordDupInputResults}");
        Message($"corrected output: {recordCorrectedResults}");
    }
}

// single bit error, Z rotation. Measure by X
// No correction, repeated 100000 times
// duplicated input: [59007,40993]
// output no correc: [49872,50128]
// With correction, repeated 100000 times
// duplicated input: [59036,40964]
// corrected output: [58993,41007]

// single bit error, Y rotation. Measure by X, cannot correct
// No correction, repeated 100000 times
// duplicated input: [42240,57760]
// output no correc: [50110,49890]
// With correction, repeated 100000 times
// duplicated input: [42415,57585]
// corrected output: [51557,48443]


// rotation 15 deg around Z on all qubits
// No correction, repeated 100000 times
// duplicated input: [79917,20083]
// output no correc: [49895,50105]
// With correction, repeated 100000 times
// duplicated input: [79970,20030]
// corrected output: [79932,20068]

// If the rotation is around X, it can't correct
// No correction, repeated 100000 times
// duplicated input: [7572,92428]
// output no correc: [50328,49672]
// With correction, repeated 100000 times
// duplicated input: [7500,92500]
// corrected output: [37379,62621]

// If the rotation is around Y, it can correct well
// No correction, repeated 100000 times
// duplicated input: [85120,14880]
// output no correc: [55800,44200]
// With correction, repeated 100000 times
// duplicated input: [84790,15210]
// corrected output: [81848,18152]

