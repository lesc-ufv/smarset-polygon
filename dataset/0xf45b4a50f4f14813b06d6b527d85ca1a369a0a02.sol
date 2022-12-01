{{
  "language": "Solidity",
  "sources": {
    "contracts/external/walletproxy.sol": {
      "content": "// SPDX-License-Identifier: LBUSL-1.1-or-later\n// Taken from: https://github.com/gnosis/safe-contracts/blob/development/contracts/proxies/GnosisSafeProxy.sol\npragma solidity >=0.7.0;\n\n/// @title IWalletProxyImplementation - Helper interface to access masterCopy of the Proxy on-chain\n/// @author Richard Meissner - <richard@gnosis.io>\ninterface IWalletProxyImplementation {\n\tfunction masterCopy() external view returns (address);\n\n\tfunction walletFactory() external view returns (address);\n\n\tfunction version() external view returns (uint256);\n\n\tfunction upgradeMasterCopy(address newMasterCopy) external;\n\n\tfunction initialize(\n\t\taddress resolver_,\n\t\tstring[2] calldata domain_,\n\t\taddress owner_,\n\t\taddress feeRecipient,\n\t\tuint256 feeAmount\n\t) external;\n}\n\n/// @title WalletProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.\n/// @author Stefan George - <stefan@gnosis.io>\n/// @author Richard Meissner - <richard@gnosis.io>\ncontract WalletProxy {\n\t// masterCopy and walletFactory always need to be the first declared variables, to ensure that they are at the same location in the contracts to which calls are delegated.\n\t// To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`\n\taddress internal masterCopy;\n\taddress internal walletFactory;\n\n\t/// @dev Constructor function sets the address of walletFactory contract\n\tconstructor() {\n\t\twalletFactory = msg.sender;\n\t}\n\n\t/// @param _masterCopy Master copy address.\n\tfunction initializeFromWalletFactory(address _masterCopy) external {\n\t\trequire(msg.sender == walletFactory, \"WalletProxy: Forbidden\");\n\t\trequire(\n\t\t\t_masterCopy != address(0),\n\t\t\t\"Invalid master copy address provided\"\n\t\t);\n\t\tmasterCopy = _masterCopy;\n\t}\n\n\t/// @dev Fallback function forwards all transactions and returns all received return data.\n\tfallback() external payable {\n\t\tassembly {\n\t\t\tlet _masterCopy := and(\n\t\t\t\tsload(0),\n\t\t\t\t0xffffffffffffffffffffffffffffffffffffffff\n\t\t\t)\n\t\t\t// 0xa619486e == keccak(\"masterCopy()\"). The value is right padded to 32-bytes with 0s\n\t\t\tif eq(\n\t\t\t\tcalldataload(0),\n\t\t\t\t0xa619486e00000000000000000000000000000000000000000000000000000000\n\t\t\t) {\n\t\t\t\tmstore(0, _masterCopy)\n\t\t\t\treturn(0, 0x20)\n\t\t\t}\n\t\t\tcalldatacopy(0, 0, calldatasize())\n\t\t\tlet success := delegatecall(\n\t\t\t\tgas(),\n\t\t\t\t_masterCopy,\n\t\t\t\t0,\n\t\t\t\tcalldatasize(),\n\t\t\t\t0,\n\t\t\t\t0\n\t\t\t)\n\t\t\treturndatacopy(0, 0, returndatasize())\n\t\t\tif eq(success, 0) {\n\t\t\t\trevert(0, returndatasize())\n\t\t\t}\n\t\t\treturn(0, returndatasize())\n\t\t}\n\t}\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 99999999
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