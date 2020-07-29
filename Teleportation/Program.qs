// https://en.wikipedia.org/wiki/Quantum_teleportation
namespace Teleportation {
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

    operation SingleTest(thetaX : Double, thetaY : Double, thetaZ : Double) : Int[] {
        mutable measureDup = 0;
        mutable measureTeleported = 0;
        mutable messageInt = 0;
        using ((qm, qdup) = (Qubit(), Qubit())) {
            // qm is the message qubit to be teleported
            // prepare qm and qdup
            SetupMessage(qm, thetaX, thetaY, thetaZ);
            SetupMessage(qdup, thetaX, thetaY, thetaZ);

            set measureDup = ResultArrayAsInt([MResetZ(qdup)]);

            using((qa, qb) = (Qubit(), Qubit())) {
                // prepare an entangled pair of qubits
                H(qa);
                CNOT(qa, qb);

                // Alice processes qm and qa
                CNOT(qm, qa);
                H(qm);

                let aliceMeasureResults = ForEach(MResetZ, [qm, qa]);
                let aliceBools = ResultArrayAsBoolArray(aliceMeasureResults);
                set messageInt = ResultArrayAsInt(aliceMeasureResults);

                // Bob's reconstruction
                if(aliceBools[1]) {
                    X(qb);
                }

                if(aliceBools[0]) {
                    Z(qb);
                }

                // This assert only works for setup operation: H
                // AssertQubitIsInStateWithinTolerance((Complex(1./Sqrt(2.), 0.), Complex(1./Sqrt(2.), 0.)), qb, 1e-5);
                let resultTeleported = MResetZ(qb);

                set measureTeleported = ResultArrayAsInt([resultTeleported]);

                ResetAll([qa, qb]);
            }
        }
        return [measureDup, measureTeleported, messageInt];
    }

    @EntryPoint()
    operation RepeatedTest() : Unit {
        let repeatCount = 40000;

        mutable aliceMessageCount = new Int[4];
        mutable recordTeleportedResults = new Int[2];
        mutable recordDupResults = new Int[2];

        let thetaX = RandomReal(10);
        let thetaY = RandomReal(10);
        let thetaZ = RandomReal(10);

        for(repeatIndex in 1..repeatCount) {
            let testOutput = SingleTest(thetaX, thetaY, thetaZ);

            let measureDup = testOutput[0];
            let measureTeleported = testOutput[1];
            let messageInt = testOutput[2];

            set recordDupResults w/= measureDup <- recordDupResults[measureDup] + 1;
            set recordTeleportedResults w/= measureTeleported <- recordTeleportedResults[measureTeleported] + 1;
            set aliceMessageCount w/= messageInt <- aliceMessageCount[messageInt] + 1;
        }

        Message($"dup: {recordDupResults}");
        Message($"tel: {recordTeleportedResults}");
        Message($"{aliceMessageCount}");
    }
}
