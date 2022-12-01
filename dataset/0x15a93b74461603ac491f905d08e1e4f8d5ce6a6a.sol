{{
  "language": "Solidity",
  "sources": {
    "contracts/oracles/StablecoinPriceFeed.sol": {
      "content": "// SPDX-License-Identifier: BUSL-1.1\npragma solidity >=0.8.4;\n\nimport \"../external/chainlink/IAggregatorV3.sol\";\n\n/// @title StablecoinPriceFeed\n/// @author Hifi\ncontract StablecoinPriceFeed is IAggregatorV3 {\n    string internal internalDescription;\n    int256 internal immutable price;\n\n    constructor(int256 price_, string memory description_) {\n        price = price_;\n        internalDescription = description_;\n    }\n\n    function decimals() external pure override returns (uint8) {\n        return 8;\n    }\n\n    function description() external view override returns (string memory) {\n        return internalDescription;\n    }\n\n    function version() external pure override returns (uint256) {\n        return 1;\n    }\n\n    function getRoundData(uint80 roundId_)\n        external\n        view\n        override\n        returns (\n            uint80 roundId,\n            int256 answer,\n            uint256 startedAt,\n            uint256 updatedAt,\n            uint80 answeredInRound\n        )\n    {\n        return (roundId_, price, 0, 0, 0);\n    }\n\n    function latestRoundData()\n        external\n        view\n        override\n        returns (\n            uint80 roundId,\n            int256 answer,\n            uint256 startedAt,\n            uint256 updatedAt,\n            uint80 answeredInRound\n        )\n    {\n        return (0, price, 0, 0, 0);\n    }\n}\n"
    },
    "contracts/external/chainlink/IAggregatorV3.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity >=0.8.4;\n\n/// @title IAggregatorV3\n/// @author Hifi\n/// @dev Forked from Chainlink\n/// github.com/smartcontractkit/chainlink/blob/v1.2.0/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol\ninterface IAggregatorV3 {\n    function decimals() external view returns (uint8);\n\n    function description() external view returns (string memory);\n\n    function version() external view returns (uint256);\n\n    /// getRoundData and latestRoundData should both raise \"No data present\" if they do not have\n    /// data to report, instead of returning unset values which could be misinterpreted as\n    /// actual reported values.\n    function getRoundData(uint80 _roundId)\n        external\n        view\n        returns (\n            uint80 roundId,\n            int256 answer,\n            uint256 startedAt,\n            uint256 updatedAt,\n            uint80 answeredInRound\n        );\n\n    function latestRoundData()\n        external\n        view\n        returns (\n            uint80 roundId,\n            int256 answer,\n            uint256 startedAt,\n            uint256 updatedAt,\n            uint80 answeredInRound\n        );\n}\n"
    }
  },
  "settings": {
    "metadata": {
      "bytecodeHash": "none"
    },
    "optimizer": {
      "enabled": true,
      "runs": 800
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