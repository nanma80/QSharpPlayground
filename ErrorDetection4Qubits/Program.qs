// https://arxiv.org/abs/0905.2794 Section VI
// https://arxiv.org/pdf/0710.4858.pdf Fig 1a
namespace ErrorDetection4Qubits {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;

    operation SetupRandomQubit(q : Qubit) : Unit {
        let thetaX = RandomReal(10) * PI();
        let thetaY = RandomReal(10) * PI();
        let thetaZ = RandomReal(10) * PI();

        R(PauliX, thetaX, q);
        R(PauliY, thetaY, q);
        R(PauliZ, thetaZ, q);
    }


    operation CauseError(qubits : Qubit[]) : Int {
        let errorOccurs = RandomInt(2);

        if (errorOccurs == 1) {
            let errorPosition = RandomInt(4);
            let errorDirection = RandomInt(3);
            if (errorDirection == 0) {
                X(qubits[errorPosition]);
            } elif (errorDirection == 1) {
                Y(qubits[errorPosition]);
            } elif (errorDirection == 2) {
                Z(qubits[errorPosition]);
            }
        }
        return errorOccurs;
    }

    operation SingleTest() : Int[] {
        mutable errorOccurs = 0;
        mutable errorDetected = 0;

        using (qOriginals = Qubit[2]) {
            for(position in 0..1) {
                SetupRandomQubit(qOriginals[position]);
            }

            using (qPadding = Qubit[2]) {
                CNOT(qOriginals[1], qOriginals[0]);

                H(qPadding[1]);
                CNOT(qPadding[1], qPadding[0]);

                CNOT(qPadding[1], qOriginals[1]);
                CNOT(qPadding[1], qOriginals[0]);
                CNOT(qOriginals[1], qPadding[0]);
                CNOT(qOriginals[0], qPadding[0]);

                mutable allQubits = [qOriginals[0], qOriginals[1], qPadding[0], qPadding[1]];

                // noisy channel
                set errorOccurs = CauseError(allQubits);

                // detection
                using (syndromes = Qubit[2]) {
                    for(qIndex in 0..3) {
                        CNOT(allQubits[qIndex], syndromes[0]);
                    }

                    for(qIndex in 0..3) {
                        H(allQubits[qIndex]);
                    }

                    for(qIndex in 0..3) {
                        CNOT(allQubits[qIndex], syndromes[1]);
                    }

                    for(qIndex in 0..3) {
                        H(allQubits[qIndex]);
                    }

                    let syndromeResults = ForEach(MResetZ, syndromes);
                    let syndromeInt = ResultArrayAsInt(syndromeResults);
                    if (syndromeInt > 0) {
                        set errorDetected = 1;
                    }

                    // if (errorOccurs != errorDetected) {
                    //     Message($"{[errorOccurs, errorDetected, syndromeInt]}");
                    // }
                }

                ResetAll(allQubits);
            }
        }
        
        // Fact(errorOccurs == errorDetected, $"Assert failed: errorOccurs != errorDetected: {errorOccurs} != {errorDetected}");
        return [errorOccurs, errorDetected];
    }

    @EntryPoint()
    operation RepeatedTest() : Unit {
        let repeatCount = 1000;

        mutable errorOccursCounts = new Int[2];
        mutable errorDetectedCounts = new Int[2];
        mutable detectionCounts = new Int[2];

        for(repeatIndex in 1..repeatCount) {
            let testOutput = SingleTest();

            let errorOccurs = testOutput[0];
            let errorDetected = testOutput[1];

            if (errorOccurs == errorDetected) {
                set detectionCounts w/= 0 <- detectionCounts[0] + 1;
            } else {
                set detectionCounts w/= 1 <- detectionCounts[1] + 1;
            }

            set errorOccursCounts w/= errorOccurs <- errorOccursCounts[errorOccurs] + 1;
            set errorDetectedCounts w/= errorDetected <- errorDetectedCounts[errorDetected] + 1;
        }

        Message($"duplicated input: {errorOccursCounts}");
        Message($"output no correc: {errorDetectedCounts}");
        Message($"detected/nondete: {detectionCounts}");
    }
}

// Cannot detect a rotation with a small angle. Probably by design. Only a large enough
// rotation is considered an error
// large rotation like X, Y, Z can all be detected in any qubit
// duplicated input: [512,488]
// output no correc: [512,488]
// detected/nondete: [1000,0]
