{{
  "language": "Solidity",
  "sources": {
    "contracts/chainlink-keepers/PriceOracleKeeper.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity 0.8.0;\n\nimport \"./KeeperCompatibleInterface.sol\";\nimport \"../series/IPriceOracle.sol\";\nimport \"../configuration/IAddressesProvider.sol\";\n\ncontract PriceOracleKeeper is KeeperCompatibleInterface {\n    IAddressesProvider public immutable addressesProvider;\n\n    constructor(IAddressesProvider _addressesProvider) {\n        addressesProvider = _addressesProvider;\n    }\n\n    function checkUpkeep(\n        bytes calldata /* checkData */\n    )\n        external\n        override\n        returns (\n            bool upkeepNeeded,\n            bytes memory /*performData*/\n        )\n    {\n        IPriceOracle oracle = IPriceOracle(addressesProvider.getPriceOracle());\n        uint256 settlementTimestamp = oracle.get8amWeeklyOrDailyAligned(\n            block.timestamp\n        );\n        uint256 feedCount = oracle.getPriceFeedsCount();\n\n        for (uint256 i = 0; i < feedCount; i++) {\n            IPriceOracle.PriceFeed memory feed = oracle.getPriceFeed(i);\n            (bool isSet, ) = oracle.getSettlementPrice(\n                feed.underlyingToken,\n                feed.priceToken,\n                settlementTimestamp\n            );\n\n            if (!isSet) {\n                upkeepNeeded = true;\n                break; // exit early\n            }\n        }\n    }\n\n    function performUpkeep(\n        bytes calldata /* performData */\n    ) external override {\n        IPriceOracle oracle = IPriceOracle(addressesProvider.getPriceOracle());\n        uint256 settlementTimestamp = oracle.get8amWeeklyOrDailyAligned(\n            block.timestamp\n        );\n        uint256 feedCount = oracle.getPriceFeedsCount();\n\n        for (uint256 i = 0; i < feedCount; i++) {\n            IPriceOracle.PriceFeed memory feed = oracle.getPriceFeed(i);\n            (bool isSet, ) = oracle.getSettlementPrice(\n                feed.underlyingToken,\n                feed.priceToken,\n                settlementTimestamp\n            );\n\n            if (!isSet) {\n                oracle.setSettlementPrice(\n                    feed.underlyingToken,\n                    feed.priceToken\n                );\n            }\n        }\n    }\n}\n"
    },
    "contracts/chainlink-keepers/KeeperCompatibleInterface.sol": {
      "content": "pragma solidity ^0.8.0;\n\ninterface KeeperCompatibleInterface {\n    /**\n     * @notice checks if the contract requires work to be done.\n     * @param checkData data passed to the contract when checking for upkeep.\n     * @return upkeepNeeded boolean to indicate whether the keeper should call\n     * performUpkeep or not.\n     * @return performData bytes that the keeper should call performUpkeep with,\n     * if upkeep is needed.\n     */\n    function checkUpkeep(bytes calldata checkData)\n        external\n        returns (bool upkeepNeeded, bytes memory performData);\n\n    /**\n     * @notice Performs work on the contract. Executed by the keepers, via the registry.\n     * @param performData is the data which was passed back from the checkData\n     * simulation.\n     */\n    function performUpkeep(bytes calldata performData) external;\n}\n"
    },
    "contracts/series/IPriceOracle.sol": {
      "content": "// SPDX-License-Identifier: GPL-3.0-only\n\npragma solidity 0.8.0;\n\ninterface IPriceOracle {\n    struct PriceFeed {\n        address underlyingToken;\n        address priceToken;\n        address oracle;\n    }\n\n    function getSettlementPrice(\n        address underlyingToken,\n        address priceToken,\n        uint256 settlementDate\n    ) external view returns (bool, uint256);\n\n    function getCurrentPrice(address underlyingToken, address priceToken)\n        external\n        view\n        returns (uint256);\n\n    function setSettlementPrice(address underlyingToken, address priceToken)\n        external;\n\n    function setSettlementPriceForDate(\n        address underlyingToken,\n        address priceToken,\n        uint256 date\n    ) external;\n\n    function get8amWeeklyOrDailyAligned(uint256 _timestamp)\n        external\n        view\n        returns (uint256);\n\n    function addTokenPair(\n        address underlyingToken,\n        address priceToken,\n        address oracle\n    ) external;\n\n    function getPriceFeed(uint256 feedId)\n        external\n        view\n        returns (IPriceOracle.PriceFeed memory);\n\n    function getPriceFeedsCount() external view returns (uint256);\n}\n"
    },
    "contracts/configuration/IAddressesProvider.sol": {
      "content": "// SPDX-License-Identifier: agpl-3.0\npragma solidity 0.8.0;\n\n/**\n * @title IAddressesProvider contract\n * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles\n * @author Dakra-Mystic\n **/\ninterface IAddressesProvider {\n    event ConfigurationAdminUpdated(address indexed newAddress);\n    event EmergencyAdminUpdated(address indexed newAddress);\n    event PriceOracleUpdated(address indexed newAddress);\n    event AmmDataProviderUpdated(address indexed newAddress);\n    event SeriesControllerUpdated(address indexed newAddress);\n    event LendingRateOracleUpdated(address indexed newAddress);\n    event DirectBuyManagerUpdated(address indexed newAddress);\n    event ProxyCreated(bytes32 id, address indexed newAddress);\n    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);\n    event VolatilityOracleUpdated(address indexed newAddress);\n    event BlackScholesUpdated(address indexed newAddress);\n    event AirswapLightUpdated(address indexed newAddress);\n    event AmmFactoryUpdated(address indexed newAddress);\n    event WTokenVaultUpdated(address indexed newAddress);\n    event AmmConfigUpdated(address indexed newAddress);\n\n    function setAddress(bytes32 id, address newAddress) external;\n\n    function getAddress(bytes32 id) external view returns (address);\n\n    function getPriceOracle() external view returns (address);\n\n    function setPriceOracle(address priceOracle) external;\n\n    function getAmmDataProvider() external view returns (address);\n\n    function setAmmDataProvider(address ammDataProvider) external;\n\n    function getSeriesController() external view returns (address);\n\n    function setSeriesController(address seriesController) external;\n\n    function getVolatilityOracle() external view returns (address);\n\n    function setVolatilityOracle(address volatilityOracle) external;\n\n    function getBlackScholes() external view returns (address);\n\n    function setBlackScholes(address blackScholes) external;\n\n    function getAirswapLight() external view returns (address);\n\n    function setAirswapLight(address airswapLight) external;\n\n    function getAmmFactory() external view returns (address);\n\n    function setAmmFactory(address ammFactory) external;\n\n    function getDirectBuyManager() external view returns (address);\n\n    function setDirectBuyManager(address directBuyManager) external;\n\n    function getWTokenVault() external view returns (address);\n\n    function setWTokenVault(address wTokenVault) external;\n}\n"
    }
  },
  "settings": {
    "optimizer": {
      "enabled": true,
      "runs": 1
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