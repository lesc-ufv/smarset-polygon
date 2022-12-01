{{
  "language": "Solidity",
  "sources": {
    "contracts/libraries/Utils.sol": {
      "content": "// SPDX-License-Identifier: MIT\n/// @title Utils library for RNG and uint string interpolation\n/**\n>>>   Made with tears and confusion by LFBarreto   <<<\n>> https://github.com/LFBarreto/mamie-fait-des-nft  <<\n*/\n\npragma solidity 0.8.11;\n\nlibrary Utils {\n    /**\n        @param v uint number to convert ty bytes32\n        @return ret bytes32 string interpolatable format\n    */\n    function uintToBytes(uint256 v) public pure returns (bytes32 ret) {\n        if (v == 0) {\n            ret = \"0\";\n        } else {\n            while (v > 0) {\n                ret = bytes32(uint256(ret) / (2**8));\n                ret |= bytes32(((v % 10) + 48) * 2**(8 * 31));\n                v /= 10;\n            }\n        }\n        return ret;\n    }\n\n    function uint2str(uint256 _i)\n        internal\n        pure\n        returns (string memory _uintAsString)\n    {\n        if (_i == 0) {\n            return \"0\";\n        }\n        uint256 j = _i;\n        uint256 len;\n        while (j != 0) {\n            len++;\n            j /= 10;\n        }\n        bytes memory bstr = new bytes(len);\n        uint256 k = len;\n        while (_i != 0) {\n            k = k - 1;\n            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));\n            bytes1 b1 = bytes1(temp);\n            bstr[k] = b1;\n            _i /= 10;\n        }\n        return string(bstr);\n    }\n\n    /**\n        @param nonce uint number to use as random seed\n        @param max max number to generate\n        @return randomnumber uint256 random number generated\n    */\n    function random(uint256 nonce, uint256 max) public view returns (uint256) {\n        uint256 randomnumber = uint256(\n            keccak256(abi.encodePacked(msg.sender, nonce))\n        ) % max;\n        return randomnumber;\n    }\n\n    /**\n        generates random numbers every time timestamp of block execution changes\n        @param nonce uint number to use as random seed\n        @param max max number to generate\n        @return randomnumber uint256 random number generated\n    */\n    function randomWithTimestamp(uint256 nonce, uint256 max)\n        public\n        view\n        returns (uint256)\n    {\n        uint256 randomnumber = uint256(\n            keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))\n        ) % max;\n        return randomnumber;\n    }\n\n    function getIndexAt(uint256 a, uint8 n) internal pure returns (uint256) {\n        if (a & (1 << n) != 0) {\n            return 1;\n        }\n        return 0;\n    }\n\n    function getWeightedIndex(uint256 i, uint256 max)\n        internal\n        pure\n        returns (uint256)\n    {\n        return ((i % (max + 1)) + 1) % ((i % max) + 1);\n    }\n\n    function getBytesParams(uint256 targetId)\n        internal\n        pure\n        returns (string memory bytesParams)\n    {\n        for (uint8 i = 0; i < 9; i++) {\n            bytesParams = string(\n                abi.encodePacked(\n                    bytesParams,\n                    \"--b\",\n                    uint2str(i),\n                    \":\",\n                    uint2str(getIndexAt(targetId, i)),\n                    \";\"\n                )\n            );\n        }\n        return bytesParams;\n    }\n\n    function getSvgCircles(uint256 nbC)\n        internal\n        pure\n        returns (string memory circles)\n    {\n        for (uint16 j = 1; j <= nbC; j++) {\n            circles = string(\n                abi.encodePacked(\n                    circles,\n                    '<circle class=\"circle_',\n                    Utils.uint2str(j),\n                    '\" cx=\"300\" cy=\"',\n                    Utils.uint2str(300 - (j * 20)),\n                    '\" r=\"',\n                    Utils.uint2str(j * 20),\n                    '\" fill=\"url(#blobC_)\" />'\n                )\n            );\n        }\n\n        return circles;\n    }\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": false,
      "runs": 200
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
    "metadata": {
      "useLiteralContent": true
    },
    "libraries": {}
  }
}}