namespace QuantumRNG {
    open Microsoft.Quantum.Canon;
    open Microsoft.Quantum.Intrinsic;
    open Microsoft.Quantum.Measurement;
    open Microsoft.Quantum.Math;
    open Microsoft.Quantum.Convert;
    
    operation GenerateRandomBit() : Result {
        using (q = Qubit()) {
            H(q);
            return MResetZ(q);
        }
    }

    operation SampleRandomNumberInRange(max : Int) : Int {
        mutable output = 0;
        // repeat {
            mutable bits = new Result[0];
            for (idxBit in 1..BitSizeI(max)) {
                set bits += [GenerateRandomBit()];
            }
            set output = ResultArrayAsInt(bits);
        // } until (output <= max);
        return output;
    }

    @EntryPoint()
    operation SampleRandomNumber() : Unit {
        let max = 50;
        let repeatCount = 10;
        mutable numberArray = new Int[0];
        mutable sum = 0;

        Message($"Sampling a random number between 0 and {max}");
        for(repeatIndex in 1..repeatCount) {
            let rnd = SampleRandomNumberInRange(max);
            set numberArray += [rnd];
            set sum += rnd;
            // Message($"{rnd}");
        }
        Message($"{numberArray}");
        // let sum = numberArray[0] + numberArray[1];
        Message($"{sum}");
        
        // return SampleRandomNumberInRange(max);
    }
}
