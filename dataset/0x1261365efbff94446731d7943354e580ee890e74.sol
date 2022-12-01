{{
  "language": "Solidity",
  "sources": {
    "contracts/Dependencies/Multicall.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity 0.8.0;\n\npragma experimental ABIEncoderV2;\n\n/// @title Multicall - Aggregate results from multiple read-only function calls\n/// @author Michael Elliot <mike@makerdao.com>\n/// @author Joshua Levine <joshua@makerdao.com>\n/// @author Nick Johnson <arachnid@notdot.net>\n\ncontract Multicall {\n    struct Call {\n        address target;\n        bytes callData;\n    }\n\n    function aggregate(Call[] memory calls)\n        public\n        returns (uint256 blockNumber, bytes[] memory returnData)\n    {\n        blockNumber = block.number;\n        returnData = new bytes[](calls.length);\n        for (uint256 i = 0; i < calls.length; i++) {\n            (bool success, bytes memory ret) = calls[i].target.call(calls[i].callData);\n            require(success);\n            returnData[i] = ret;\n        }\n    }\n\n    // Helper functions\n    function getEthBalance(address addr) public view returns (uint256 balance) {\n        balance = addr.balance;\n    }\n\n    function getBlockHash(uint256 blockNumber) public view returns (bytes32 blockHash) {\n        blockHash = blockhash(blockNumber);\n    }\n\n    function getLastBlockHash() public view returns (bytes32 blockHash) {\n        blockHash = blockhash(block.number - 1);\n    }\n\n    function getCurrentBlockTimestamp() public view returns (uint256 timestamp) {\n        timestamp = block.timestamp;\n    }\n\n    function getCurrentBlockDifficulty() public view returns (uint256 difficulty) {\n        difficulty = block.difficulty;\n    }\n\n    function getCurrentBlockGasLimit() public view returns (uint256 gaslimit) {\n        gaslimit = block.gaslimit;\n    }\n\n    function getCurrentBlockCoinbase() public view returns (address coinbase) {\n        coinbase = block.coinbase;\n    }\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 100
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "devdoc",
          "userdoc",
          "metadata",
          "abi"
        ]
      }
    },
    "libraries": {}
  }
}}