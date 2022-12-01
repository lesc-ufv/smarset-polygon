{{
  "language": "Solidity",
  "sources": {
    "contracts/UserProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT\r\npragma solidity 0.8.11;\r\n\r\n/**\r\n * @title UserProxy\r\n * @author Penrose\r\n * @notice Minimal upgradeable EIP-1967 proxy\r\n * @dev Each user gets their own user proxy contract\r\n * @dev Each user has complete control and custody of their UserProxy (similar to Maker's DSProxy)\r\n * @dev Users can upgrade their proxies if desired for additional functionality in the future\r\n */\r\ncontract UserProxy {\r\n    bytes32 constant IMPLEMENTATION_SLOT =\r\n        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc; // keccak256('eip1967.proxy.implementation')\r\n    bytes32 constant OWNER_SLOT =\r\n        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103; // keccak256('eip1967.proxy.admin')\r\n\r\n    constructor(address _implementationAddress, address _ownerAddress) {\r\n        assembly {\r\n            sstore(IMPLEMENTATION_SLOT, _implementationAddress)\r\n            sstore(OWNER_SLOT, _ownerAddress)\r\n        }\r\n    }\r\n\r\n    function implementationAddress()\r\n        external\r\n        view\r\n        returns (address _implementationAddress)\r\n    {\r\n        assembly {\r\n            _implementationAddress := sload(IMPLEMENTATION_SLOT)\r\n        }\r\n    }\r\n\r\n    function ownerAddress() public view returns (address _ownerAddress) {\r\n        assembly {\r\n            _ownerAddress := sload(OWNER_SLOT)\r\n        }\r\n    }\r\n\r\n    function updateImplementationAddress(address _implementationAddress)\r\n        external\r\n    {\r\n        require(\r\n            msg.sender == ownerAddress(),\r\n            \"Only owners can update implementation\"\r\n        );\r\n        assembly {\r\n            sstore(IMPLEMENTATION_SLOT, _implementationAddress)\r\n        }\r\n    }\r\n\r\n    function updateOwnerAddress(address _ownerAddress) external {\r\n        require(msg.sender == ownerAddress(), \"Only owners can update owners\");\r\n        assembly {\r\n            sstore(OWNER_SLOT, _ownerAddress)\r\n        }\r\n    }\r\n\r\n    fallback() external {\r\n        assembly {\r\n            let contractLogic := sload(IMPLEMENTATION_SLOT)\r\n            calldatacopy(0x0, 0x0, calldatasize())\r\n            let success := delegatecall(\r\n                gas(),\r\n                contractLogic,\r\n                0x0,\r\n                calldatasize(),\r\n                0,\r\n                0\r\n            )\r\n            let returnDataSize := returndatasize()\r\n            returndatacopy(0, 0, returnDataSize)\r\n            switch success\r\n            case 0 {\r\n                revert(0, returnDataSize)\r\n            }\r\n            default {\r\n                return(0, returnDataSize)\r\n            }\r\n        }\r\n    }\r\n}\r\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
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
    "libraries": {}
  }
}}