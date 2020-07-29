// https://arxiv.org/abs/0905.2794 Section IV (keeping ancillary qubits)
// https://en.wikipedia.org/wiki/Quantum_error_correction (dropping ancillary qubits)
namespace ErrorCorrection3Qubits {
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
            if (errorPosition <= 2) {
                // X(qubits[errorPosition]);
                // Y(qubits[errorPosition]);
                Z(qubits[errorPosition]);
            }
        } else {
            // rotation error
            let epsilonX = PI() / 12.0; // 15 degrees
            for (position in 0..2) {
                R(PauliX, epsilonX, qubits[position]);
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
                // (qInput, qInput2, qInput3) is alpha * |000> + beta * |111>

                CauseError([qInput, qInput2, qInput3]);

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
        Message($"corrected output: {recordCorrectedResults}");

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

// single error X rotation: perfect correction, theoretically
// No correction, repeated 100000 times
// duplicated input: [62634,37366]
// corrected output: [57377,42623]
// With correction, repeated 100000 times
// duplicated input: [62744,37256]
// corrected output: [62612,37388]

// 15 deg rotation around X on every qubit:
// No correction, repeated 100000 times
// duplicated input: [30870,69130]
// corrected output: [32054,67946]
// With correction, repeated 100000 times
// duplicated input: [30957,69043]
// corrected output: [30602,69398]

// single bit error, Y rotation. Measure by X. Cannot correct
// No correction, repeated 100000 times
// duplicated input: [58922,41078]
// corrected output: [49928,50072]
// With correction, repeated 100000 times
// duplicated input: [58913,41087]
// corrected output: [48320,51680]

// single bit error, Z rotation. Measure by X. Cannot correct
// No correction, repeated 100000 times
// duplicated input: [63161,36839]
// corrected output: [49760,50240]
// With correction, repeated 100000 times
// duplicated input: [62668,37332]
// corrected output: [47553,52447]
