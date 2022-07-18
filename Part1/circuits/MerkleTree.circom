pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/comparators.circom";

// This circuit returns the sum of the inputs.
// n must be greater than 0.
// Credit: https://github.com/privacy-scaling-explorations/maci/blob/v1/circuits/circom/trees/calculateTotal.circom
template CalculateTotal(n) {
    signal input nums[n];
    signal output sum;

    signal sums[n];
    sums[0] <== nums[0];

    for (var i=1; i < n; i++) {
        sums[i] <== sums[i - 1] + nums[i];
    }

    sum <== sums[n - 1];
}

template CheckRoot(n) {
    signal input leaves[2**n];
    signal output root;

    component hash[n][2**n];
    var h[2**n] = leaves;

    for (var i = 0; i < n; i++) {
        var index = 0;
        for (var j = 0; j < 2**(n-1); j += 2) {
            hash[i][j] = Poseidon(2);
            hash[i][j].inputs[0] <== h[j];
            hash[i][j].inputs[1] <== h[j+1];
            h[index] = hash[i][j].out;
            index += 1;
        }
    }

    root <== h[0];
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n];
    signal output root;

    component hash_l[n];
    component hash_r[n];
    component lt[n];
    component eq[n];
    component sum[n];

    var h = leaf;

    for (var i = 0; i < n; i++) {
        hash_l[i] = Poseidon(2);
        hash_r[i] = Poseidon(2);

        hash_l[i].inputs[0] <== h;
        hash_l[i].inputs[1] <== path_elements[i];

        hash_r[i].inputs[0] <== path_elements[i];
        hash_r[i].inputs[1] <== h;
        
        // lt.out === 0 iff path_elements[i] === 1 else 1
        lt[i] = LessThan(2);
        lt[i].in[0] <== path_index[i];
        lt[i].in[1] <== 1;

        eq[i] = IsEqual();
        eq[i].in[0] <== path_index[i];
        eq[i].in[1] <== 1;

        sum[i] = CalculateTotal(2);
        sum[i].nums[0] <== lt[i].out * hash_l[i].out;
        sum[i].nums[1] <== eq[i].out * hash_r[i].out;

        h = sum[i].sum;
    }

    root <== h;
}
