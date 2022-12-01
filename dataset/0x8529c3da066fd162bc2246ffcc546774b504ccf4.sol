{{
  "language": "Solidity",
  "sources": {
    "contracts/OlympusAuthority.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0\npragma solidity >=0.7.5;\n\nimport \"./interfaces/IOlympusAuthority.sol\";\n\nimport \"./types/OlympusAccessControlled.sol\";\n\ncontract OlympusAuthority is IOlympusAuthority, OlympusAccessControlled {\n    /* ========== STATE VARIABLES ========== */\n\n    address public override governor;\n\n    address public override guardian;\n\n    address public override policy;\n\n    address public override vault;\n\n    address public newGovernor;\n\n    address public newGuardian;\n\n    address public newPolicy;\n\n    address public newVault;\n\n    /* ========== Constructor ========== */\n\n    constructor(\n        address _governor,\n        address _guardian,\n        address _policy,\n        address _vault\n    ) OlympusAccessControlled(IOlympusAuthority(address(this))) {\n        governor = _governor;\n        emit GovernorPushed(address(0), governor, true);\n        guardian = _guardian;\n        emit GuardianPushed(address(0), guardian, true);\n        policy = _policy;\n        emit PolicyPushed(address(0), policy, true);\n        vault = _vault;\n        emit VaultPushed(address(0), vault, true);\n    }\n\n    /* ========== GOV ONLY ========== */\n\n    function pushGovernor(address _newGovernor, bool _effectiveImmediately) external onlyGovernor {\n        if (_effectiveImmediately) governor = _newGovernor;\n        newGovernor = _newGovernor;\n        emit GovernorPushed(governor, newGovernor, _effectiveImmediately);\n    }\n\n    function pushGuardian(address _newGuardian, bool _effectiveImmediately) external onlyGovernor {\n        if (_effectiveImmediately) guardian = _newGuardian;\n        newGuardian = _newGuardian;\n        emit GuardianPushed(guardian, newGuardian, _effectiveImmediately);\n    }\n\n    function pushPolicy(address _newPolicy, bool _effectiveImmediately) external onlyGovernor {\n        if (_effectiveImmediately) policy = _newPolicy;\n        newPolicy = _newPolicy;\n        emit PolicyPushed(policy, newPolicy, _effectiveImmediately);\n    }\n\n    function pushVault(address _newVault, bool _effectiveImmediately) external onlyGovernor {\n        if (_effectiveImmediately) vault = _newVault;\n        newVault = _newVault;\n        emit VaultPushed(vault, newVault, _effectiveImmediately);\n    }\n\n    /* ========== PENDING ROLE ONLY ========== */\n\n    function pullGovernor() external {\n        require(msg.sender == newGovernor, \"!newGovernor\");\n        emit GovernorPulled(governor, newGovernor);\n        governor = newGovernor;\n    }\n\n    function pullGuardian() external {\n        require(msg.sender == newGuardian, \"!newGuard\");\n        emit GuardianPulled(guardian, newGuardian);\n        guardian = newGuardian;\n    }\n\n    function pullPolicy() external {\n        require(msg.sender == newPolicy, \"!newPolicy\");\n        emit PolicyPulled(policy, newPolicy);\n        policy = newPolicy;\n    }\n\n    function pullVault() external {\n        require(msg.sender == newVault, \"!newVault\");\n        emit VaultPulled(vault, newVault);\n        vault = newVault;\n    }\n}\n"
    },
    "contracts/interfaces/IOlympusAuthority.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0\npragma solidity >=0.7.5;\n\ninterface IOlympusAuthority {\n    /* ========== EVENTS ========== */\n\n    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);\n    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);\n    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);\n    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);\n\n    event GovernorPulled(address indexed from, address indexed to);\n    event GuardianPulled(address indexed from, address indexed to);\n    event PolicyPulled(address indexed from, address indexed to);\n    event VaultPulled(address indexed from, address indexed to);\n\n    /* ========== VIEW ========== */\n\n    function governor() external view returns (address);\n\n    function guardian() external view returns (address);\n\n    function policy() external view returns (address);\n\n    function vault() external view returns (address);\n}\n"
    },
    "contracts/types/OlympusAccessControlled.sol": {
      "content": "// SPDX-License-Identifier: AGPL-3.0-only\npragma solidity >=0.7.5;\n\nimport \"../interfaces/IOlympusAuthority.sol\";\n\nabstract contract OlympusAccessControlled {\n    /* ========== EVENTS ========== */\n\n    event AuthorityUpdated(IOlympusAuthority indexed authority);\n\n    string UNAUTHORIZED = \"UNAUTHORIZED\"; // save gas\n\n    /* ========== STATE VARIABLES ========== */\n\n    IOlympusAuthority public authority;\n\n    /* ========== Constructor ========== */\n\n    constructor(IOlympusAuthority _authority) {\n        authority = _authority;\n        emit AuthorityUpdated(_authority);\n    }\n\n    /* ========== MODIFIERS ========== */\n\n    modifier onlyGovernor() {\n        require(msg.sender == authority.governor(), UNAUTHORIZED);\n        _;\n    }\n\n    modifier onlyGuardian() {\n        require(msg.sender == authority.guardian(), UNAUTHORIZED);\n        _;\n    }\n\n    modifier onlyPolicy() {\n        require(msg.sender == authority.policy(), UNAUTHORIZED);\n        _;\n    }\n\n    modifier onlyVault() {\n        require(msg.sender == authority.vault(), UNAUTHORIZED);\n        _;\n    }\n\n    /* ========== GOV ONLY ========== */\n\n    function setAuthority(IOlympusAuthority _newAuthority) external onlyGovernor {\n        authority = _newAuthority;\n        emit AuthorityUpdated(_newAuthority);\n    }\n}\n"
    }
  },
  "settings": {
    "metadata": {
      "bytecodeHash": "none",
      "useLiteralContent": true
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