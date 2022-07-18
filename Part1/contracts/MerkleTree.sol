//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract
import "hardhat/console.sol";

contract MerkleTree is Verifier {
  uint256[] public hashes; // the Merkle tree in flattened array form
  uint256 public index = 0; // the current index of the first unfilled leaf
  uint256 public root; // the current Merkle root

  constructor() {
    // [assignment] initialize a Merkle tree of 8 with blank leaves
    for (uint i = 0; i < 8; i++) hashes.push(0);
    index = 0;
    console.log("computing hashes...");
    computeHashes();
  }

  function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
    // [assignment] insert a hashed leaf into the Merkle tree
    hashes[index] = hashedLeaf;

    console.log("inserted node %s with value: %d", index, hashedLeaf);
    console.log("re-computing hashes...");

    computeHashes();
    index += 1;

    return index;
  }

  function computeHashes() private {
    
    uint offset = 0;

    while (hashes.length > 8) hashes.pop();

    for (uint i = 8; i > 1; i /= 2) {
      for (uint j = offset; j < i + offset; j += 2) {
        uint h = PoseidonT3.poseidon([hashes[j], hashes[j + 1]]);
        hashes.push(h);
      }
      offset += i;
    }
    
    root = hashes[hashes.length - 1];
  }

  function verify(
      uint[2] memory a,
      uint[2][2] memory b,
      uint[2] memory c,
      uint[1] memory input
    ) public view returns (bool) {

    // [assignment] verify an inclusion proof and 
    //              check that the proof root matches current root
    console.log("input:\t%s", input[0]);
    console.log("root:\t%s", root);
    return verifyProof(a, b, c, input) && input[0] == root;
  }
}
