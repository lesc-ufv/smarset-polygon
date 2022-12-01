{{
  "language": "Solidity",
  "sources": {
    "/contracts/proxy/IDOProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.7;\nimport \"./UpgradableProxy.sol\";\n\ncontract IDOProxy is UpgradableProxy {\n    constructor(address _implementation, address owner)\n        UpgradableProxy(_implementation, owner)\n    {}\n}\n"
    },
    "/contracts/proxy/UpgradableProxy.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.7;\nimport \"../libraries/proxy/Proxy.sol\";\nimport \"../libraries/proxy/ProxyOwnable.sol\";\n\ncontract UpgradableProxy is Proxy, ProxyOwnable {\n    /**\n     * @dev Storage slot with the address of the current implementation.\n     * This is the keccak-256 hash of \"eip1967.proxy.implementation\" subtracted by 1, and is\n     * validated in the constructor.\n     */\n    bytes32 private constant _IMPLEMENTATION_SLOT =\n        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;\n\n    constructor(address implementation_, address _owner) ProxyOwnable(_owner) {\n        _setImplementation(implementation_);\n    }\n\n    function upgradeDelegate(address newDelegateAddress) public ifAdmin {\n        _setImplementation(newDelegateAddress);\n    }\n\n    /**\n     * @dev Stores a new address in the EIP1967 implementation slot.\n     */\n    function _setImplementation(address newImplementation) private {\n        bytes32 slot = _IMPLEMENTATION_SLOT;\n        // solhint-disable-next-line no-inline-assembly\n        assembly {\n            sstore(slot, newImplementation)\n        }\n    }\n\n    /**\n     * @dev Returns the current implementation address.\n     */\n    function _implementation()\n        internal\n        view\n        virtual\n        override\n        returns (address impl)\n    {\n        bytes32 slot = _IMPLEMENTATION_SLOT;\n        // solhint-disable-next-line no-inline-assembly\n        assembly {\n            impl := sload(slot)\n        }\n    }\n}\n"
    },
    "/contracts/libraries/proxy/ProxyOwnable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.7;\n\ncontract ProxyOwnable {\n    /**\n     * @dev Storage slot with the admin of the contract.\n     * This is the keccak-256 hash of \"eip1967.proxy.admin\" subtracted by 1, and is\n     * validated in the constructor.\n     */\n    bytes32 private constant _ADMIN_SLOT =\n        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;\n\n    /**\n     * @dev Emitted when the admin account has changed.\n     */\n    event AdminChanged(address previousAdmin, address newAdmin);\n\n    constructor(address _owner) payable {\n        assert(\n            _ADMIN_SLOT ==\n                bytes32(uint256(keccak256(\"eip1967.proxy.admin\")) - 1)\n        );\n        _setAdmin(_owner);\n    }\n\n    /**\n     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.\n     */\n    modifier ifAdmin() {\n        require(msg.sender == _admin(), \"Ownable: caller is not the admin\");\n        _;\n    }\n\n    /**\n     * @dev Returns the current admin.\n     */\n    function _admin() internal view returns (address adm) {\n        bytes32 slot = _ADMIN_SLOT;\n        // solhint-disable-next-line no-inline-assembly\n        assembly {\n            adm := sload(slot)\n        }\n    }\n\n    function changeAdmin(address newAdmin) external ifAdmin {\n        require(\n            newAdmin != address(0),\n            \"TransparentUpgradeableProxy: new admin is the zero address\"\n        );\n        emit AdminChanged(_admin(), newAdmin);\n        _setAdmin(newAdmin);\n    }\n\n    /**\n     * @dev Stores a new address in the EIP1967 admin slot.\n     */\n    function _setAdmin(address newAdmin) private {\n        bytes32 slot = _ADMIN_SLOT;\n\n        // solhint-disable-next-line no-inline-assembly\n        assembly {\n            sstore(slot, newAdmin)\n        }\n    }\n}\n"
    },
    "/contracts/libraries/proxy/Proxy.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity ^0.8.7;\n\n/**\n * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM\n * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to\n * be specified by overriding the virtual {_implementation} function.\n *\n * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a\n * different contract through the {_delegate} function.\n *\n * The success and return data of the delegated call will be returned back to the caller of the proxy.\n */\nabstract contract Proxy {\n    /**\n     * @dev Delegates the current call to `implementation`.\n     *\n     * This function does not return to its internall call site, it will return directly to the external caller.\n     */\n    function _delegate(address implementation) internal {\n        // solhint-disable-next-line no-inline-assembly\n        assembly {\n            // Copy msg.data. We take full control of memory in this inline assembly\n            // block because it will not return to Solidity code. We overwrite the\n            // Solidity scratch pad at memory position 0.\n            calldatacopy(0, 0, calldatasize())\n\n            // Call the implementation.\n            // out and outsize are 0 because we don't know the size yet.\n            let result := delegatecall(\n                gas(),\n                implementation,\n                0,\n                calldatasize(),\n                0,\n                0\n            )\n\n            // Copy the returned data.\n            returndatacopy(0, 0, returndatasize())\n\n            switch result\n            // delegatecall returns 0 on error.\n            case 0 {\n                revert(0, returndatasize())\n            }\n            default {\n                return(0, returndatasize())\n            }\n        }\n    }\n\n    /**\n     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function\n     * and {_fallback} should delegate.\n     */\n    function _implementation() internal view virtual returns (address);\n\n    /**\n     * @dev Delegates the current call to the address returned by `_implementation()`.\n     *\n     * This function does not return to its internall call site, it will return directly to the external caller.\n     */\n    function _fallback() internal {\n        _beforeFallback();\n        _delegate(_implementation());\n    }\n\n    /**\n     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other\n     * function in the contract matches the call data.\n     */\n    fallback() external payable {\n        _fallback();\n    }\n\n    /**\n     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data\n     * is empty.\n     */\n    receive() external payable {\n        _fallback();\n    }\n\n    /**\n     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`\n     * call, or as part of the Solidity `fallback` or `receive` functions.\n     *\n     * If overriden should call `super._beforeFallback()`.\n     */\n    function _beforeFallback() internal virtual {}\n}\n"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": true,
      "runs": 200
    },
    "evmVersion": "london",
    "libraries": {},
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
    }
  }
}}