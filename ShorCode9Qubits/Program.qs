// https://en.wikipedia.org/wiki/Quantum_error_correction (dropping ancillary qubits)
namespace ShorCode9Qubits {
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

    operation CauseError(qubit : Qubit, qubits : Qubit[]) : Unit {
        let singleError = true;
        let thetaX = RandomReal(10) * PI();
        let thetaY = RandomReal(10) * PI();
        let thetaZ = RandomReal(10) * PI();

        if (singleError) {
            let errorPosition = RandomInt(9);
            // let errorPosition = 8;
            if (errorPosition <= 7) {
                X(qubits[errorPosition]);
                // Y(qubits[errorPosition]);
                // Z(qubits[errorPosition]);
                // R(PauliX, thetaX, qubits[errorPosition]);
                // R(PauliY, thetaY, qubits[errorPosition]);
                // R(PauliZ, thetaZ, qubits[errorPosition]);

            } else {
                X(qubit);
                // Y(qubit);
                // Z(qubit);
                // R(PauliX, thetaX, qubit);
                // R(PauliY, thetaY, qubit);
                // R(PauliZ, thetaZ, qubit);
            }
        } else {
            // rotation error
            let thetaFactor = 1.0/6.0;

            for (position in 0..7) {
                R(PauliX, thetaX * thetaFactor, qubits[position]);
                R(PauliY, thetaY * thetaFactor, qubits[position]);
                R(PauliZ, thetaZ * thetaFactor, qubits[position]);
            }

            R(PauliX, thetaX * thetaFactor, qubit);
            R(PauliY, thetaY * thetaFactor, qubit);
            R(PauliZ, thetaZ * thetaFactor, qubit);

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

            set measureDupInput = ResultArrayAsInt([MResetZ(qDupInput)]);
            // set measureDupInput = ResultArrayAsInt([MResetX(qDupInput)]);

            using(qInputs = Qubit[8]) {
                CNOT(qInput, qInputs[2]);
                CNOT(qInput, qInputs[5]);
                H(qInput);
                H(qInputs[2]);
                H(qInputs[5]);
                CNOT(qInput, qInputs[0]);
                CNOT(qInput, qInputs[1]);

                CNOT(qInputs[2], qInputs[3]);
                CNOT(qInputs[2], qInputs[4]);

                CNOT(qInputs[5], qInputs[6]);
                CNOT(qInputs[5], qInputs[7]);

                // noisy channel
                CauseError(qInput, qInputs);

                // correction
                CNOT(qInput, qInputs[0]);
                CNOT(qInput, qInputs[1]);

                if (applyCorrection) {
                    CCNOT(qInputs[0], qInputs[1], qInput);
                }


                CNOT(qInputs[2], qInputs[3]);
                CNOT(qInputs[2], qInputs[4]);
                CCNOT(qInputs[3], qInputs[4], qInputs[2]);

                CNOT(qInputs[5], qInputs[6]);
                CNOT(qInputs[5], qInputs[7]);
                CCNOT(qInputs[6], qInputs[7], qInputs[5]);

                H(qInput);
                H(qInputs[2]);
                H(qInputs[5]);

                CNOT(qInput, qInputs[2]);
                CNOT(qInput, qInputs[5]);

                if (applyCorrection) {
                    CCNOT(qInputs[2], qInputs[5], qInput);
                }

                set measureCorrected = ResultArrayAsInt([MResetZ(qInput)]);
                // set measureCorrected = ResultArrayAsInt([MResetX(qInput)]);
                ResetAll([qInput]);
                ResetAll(qInputs);
            }
        }
        return [measureDupInput, measureCorrected];
    }

    @EntryPoint()
    operation RepeatedTest() : Unit {
        let repeatCount = 10000;

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

// single error on X. Measure on Z. Can correct
// With correction, repeated 10000 times
// duplicated input: [3474,6526]
// corrected output: [3421,6579]

// single error on Y. Measure on X. Can correct
// No correction, repeated 10000 times
// duplicated input: [9042,958]
// output no correc: [8169,1831]
// With correction, repeated 10000 times
// duplicated input: [9047,953]
// corrected output: [9049,951]


// single error on Z. Measure on X. Can correct
// With correction, repeated 10000 times
// duplicated input: [8290,1710]
// corrected output: [8200,1800]
// duplicated input: [5155,4845]
// corrected output: [5179,4821]

// Single error, random rotation. Can correct.
// No correction, repeated 100000 times
// duplicated input: [89178,10822]
// output no correc: [84920,15080]
// With correction, repeated 100000 times
// duplicated input: [89273,10727]
// corrected output: [89410,10590]

// all small random rotation, applied to every qubit. factor 1/6
// No correction, repeated 100000 times
// duplicated input: [82103,17897]
// output no correc: [79449,20551]
// With correction, repeated 100000 times
// duplicated input: [82231,17769]
// corrected output: [82233,17767]
