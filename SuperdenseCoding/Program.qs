// https://en.wikipedia.org/wiki/Superdense_coding
namespace SuperdenseCoding {
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Diagnostics;
    open Microsoft.Quantum.Arrays;
    open Microsoft.Quantum.Convert;
    open Microsoft.Quantum.Math;
    
    // messageInt can take 0, 1, 2, 3
    operation SingleTest(messageInt : Int) : Int {
        mutable bobInt = 0;
        using((qa, qb) = (Qubit(), Qubit())) {
            // prepare an entangled pair of qubits
            H(qa);
            CNOT(qa, qb);

            // Alice encodes classical bits to qa
            if(messageInt == 1 or messageInt == 3) {
                X(qa);
            }

            if(messageInt == 2 or messageInt == 3) {
                Z(qa);
            }

            // qa and qb are sent over

            // Bob decodes
            CNOT(qa, qb);
            H(qa);

            let bobMeasureResults = ForEach(MResetZ, [qb, qa]);
            set bobInt = ResultArrayAsInt(bobMeasureResults);
            // Message($"{bobInt}");

            ResetAll([qa, qb]);
        }
        return bobInt;
    }

    @EntryPoint()
    operation RepeatedTest() : Unit {
        let repeatCount = 4;

        for(repeatIndex in 1..repeatCount) {
            let messageIn = repeatIndex - 1;
            let messageOut = SingleTest(messageIn);
            Message($"(input, output) = ({messageIn}, {messageOut})");
        }
    }
}
