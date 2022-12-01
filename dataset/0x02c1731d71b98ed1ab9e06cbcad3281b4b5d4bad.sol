{{
  "language": "Solidity",
  "sources": {
    "contracts/persistent/vault/VaultProxy.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0\n\n/*\n    This file is part of the Enzyme Protocol.\n\n    (c) Enzyme Council <council@enzyme.finance>\n\n    For the full license information, please view the LICENSE\n    file that was distributed with this source code.\n*/\n\npragma solidity 0.6.12;\n\nimport \"./utils/ProxiableVaultLib.sol\";\n\n/// @title VaultProxy Contract\n/// @author Enzyme Council <security@enzyme.finance>\n/// @notice A proxy contract for all VaultProxy instances, slightly modified from EIP-1822\n/// @dev Adapted from the recommended implementation of a Proxy in EIP-1822, updated for solc 0.6.12,\n/// and using the EIP-1967 storage slot for the proxiable implementation.\n/// i.e., `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`, which is\n/// \"0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc\"\n/// See: https://eips.ethereum.org/EIPS/eip-1822\ncontract VaultProxy {\n    constructor(bytes memory _constructData, address _vaultLib) public {\n        // \"0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5\" corresponds to\n        // `bytes32(keccak256('mln.proxiable.vaultlib'))`\n        require(\n            bytes32(0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5) ==\n                ProxiableVaultLib(_vaultLib).proxiableUUID(),\n            \"constructor: _vaultLib not compatible\"\n        );\n\n        assembly {\n            // solium-disable-line\n            sstore(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, _vaultLib)\n        }\n\n        (bool success, bytes memory returnData) = _vaultLib.delegatecall(_constructData); // solium-disable-line\n        require(success, string(returnData));\n    }\n\n    fallback() external payable {\n        assembly {\n            // solium-disable-line\n            let contractLogic := sload(\n                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc\n            )\n            calldatacopy(0x0, 0x0, calldatasize())\n            let success := delegatecall(\n                sub(gas(), 10000),\n                contractLogic,\n                0x0,\n                calldatasize(),\n                0,\n                0\n            )\n            let retSz := returndatasize()\n            returndatacopy(0, 0, retSz)\n            switch success\n                case 0 {\n                    revert(0, retSz)\n                }\n                default {\n                    return(0, retSz)\n                }\n        }\n    }\n}\n"
    },
    "contracts/persistent/vault/utils/ProxiableVaultLib.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0\n\n/*\n    This file is part of the Enzyme Protocol.\n\n    (c) Enzyme Council <council@enzyme.finance>\n\n    For the full license information, please view the LICENSE\n    file that was distributed with this source code.\n*/\n\npragma solidity 0.6.12;\n\n/// @title ProxiableVaultLib Contract\n/// @author Enzyme Council <security@enzyme.finance>\n/// @notice A contract that defines the upgrade behavior for VaultLib instances\n/// @dev The recommended implementation of the target of a proxy according to EIP-1822 and EIP-1967\n/// Code position in storage is `bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)`,\n/// which is \"0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc\".\nabstract contract ProxiableVaultLib {\n    /// @dev Updates the target of the proxy to be the contract at _nextVaultLib\n    function __updateCodeAddress(address _nextVaultLib) internal {\n        require(\n            bytes32(0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5) ==\n                ProxiableVaultLib(_nextVaultLib).proxiableUUID(),\n            \"__updateCodeAddress: _nextVaultLib not compatible\"\n        );\n        assembly {\n            // solium-disable-line\n            sstore(\n                0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc,\n                _nextVaultLib\n            )\n        }\n    }\n\n    /// @notice Returns a unique bytes32 hash for VaultLib instances\n    /// @return uuid_ The bytes32 hash representing the UUID\n    /// @dev The UUID is `bytes32(keccak256('mln.proxiable.vaultlib'))`\n    function proxiableUUID() public pure returns (bytes32 uuid_) {\n        return 0x027b9570e9fedc1a80b937ae9a06861e5faef3992491af30b684a64b3fbec7a5;\n    }\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 200,
      "details": {
        "yul": false
      }
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