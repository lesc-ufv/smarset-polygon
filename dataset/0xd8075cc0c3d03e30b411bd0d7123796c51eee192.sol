{{
  "language": "Solidity",
  "sources": {
    "contracts/diamond/facets/DiamondLoupeFacet.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n/******************************************************************************\\\n* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)\n* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535\n/******************************************************************************/\n\nimport {LibDiamond} from \"../libraries/LibDiamond.sol\";\nimport {IDiamondLoupe} from \"../interfaces/IDiamondLoupe.sol\";\nimport {IERC165} from \"../interfaces/IERC165.sol\";\n\ncontract DiamondLoupeFacet is IDiamondLoupe, IERC165 {\n    // Diamond Loupe Functions\n    ////////////////////////////////////////////////////////////////////\n    /// These functions are expected to be called frequently by tools.\n    //\n    // struct Facet {\n    //     address facetAddress;\n    //     bytes4[] functionSelectors;\n    // }\n    /// @notice Gets all facets and their selectors.\n    /// @return facets_ Facet\n    function facets() external view override returns (Facet[] memory facets_) {\n        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();\n        uint256 selectorCount = ds.selectors.length;\n        // create an array set to the maximum size possible\n        facets_ = new Facet[](selectorCount);\n        // create an array for counting the number of selectors for each facet\n        uint8[] memory numFacetSelectors = new uint8[](selectorCount);\n        // total number of facets\n        uint256 numFacets;\n        // loop through function selectors\n        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {\n            bytes4 selector = ds.selectors[selectorIndex];\n            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;\n            bool continueLoop = false;\n            // find the functionSelectors array for selector and add selector to it\n            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {\n                if (facets_[facetIndex].facetAddress == facetAddress_) {\n                    facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;\n                    // probably will never have more than 256 functions from one facet contract\n                    require(numFacetSelectors[facetIndex] < 255);\n                    numFacetSelectors[facetIndex]++;\n                    continueLoop = true;\n                    break;\n                }\n            }\n            // if functionSelectors array exists for selector then continue loop\n            if (continueLoop) {\n                continueLoop = false;\n                continue;\n            }\n            // create a new functionSelectors array for selector\n            facets_[numFacets].facetAddress = facetAddress_;\n            facets_[numFacets].functionSelectors = new bytes4[](selectorCount);\n            facets_[numFacets].functionSelectors[0] = selector;\n            numFacetSelectors[numFacets] = 1;\n            numFacets++;\n        }\n        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {\n            uint256 numSelectors = numFacetSelectors[facetIndex];\n            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;\n            // setting the number of selectors\n            assembly {\n                mstore(selectors, numSelectors)\n            }\n        }\n        // setting the number of facets\n        assembly {\n            mstore(facets_, numFacets)\n        }\n    }\n\n    /// @notice Gets all the function selectors supported by a specific facet.\n    /// @param _facet The facet address.\n    /// @return _facetFunctionSelectors The selectors associated with a facet address.\n    function facetFunctionSelectors(address _facet)\n        external\n        view\n        override\n        returns (bytes4[] memory _facetFunctionSelectors)\n    {\n        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();\n        uint256 selectorCount = ds.selectors.length;\n        uint256 numSelectors;\n        _facetFunctionSelectors = new bytes4[](selectorCount);\n        // loop through function selectors\n        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {\n            bytes4 selector = ds.selectors[selectorIndex];\n            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;\n            if (_facet == facetAddress_) {\n                _facetFunctionSelectors[numSelectors] = selector;\n                numSelectors++;\n            }\n        }\n        // Set the number of selectors in the array\n        assembly {\n            mstore(_facetFunctionSelectors, numSelectors)\n        }\n    }\n\n    /// @notice Get all the facet addresses used by a diamond.\n    /// @return facetAddresses_\n    function facetAddresses() external view override returns (address[] memory facetAddresses_) {\n        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();\n        uint256 selectorCount = ds.selectors.length;\n        // create an array set to the maximum size possible\n        facetAddresses_ = new address[](selectorCount);\n        uint256 numFacets;\n        // loop through function selectors\n        for (uint256 selectorIndex; selectorIndex < selectorCount; selectorIndex++) {\n            bytes4 selector = ds.selectors[selectorIndex];\n            address facetAddress_ = ds.facetAddressAndSelectorPosition[selector].facetAddress;\n            bool continueLoop = false;\n            // see if we have collected the address already and break out of loop if we have\n            for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {\n                if (facetAddress_ == facetAddresses_[facetIndex]) {\n                    continueLoop = true;\n                    break;\n                }\n            }\n            // continue loop if we already have the address\n            if (continueLoop) {\n                continueLoop = false;\n                continue;\n            }\n            // include address\n            facetAddresses_[numFacets] = facetAddress_;\n            numFacets++;\n        }\n        // Set the number of facet addresses in the array\n        assembly {\n            mstore(facetAddresses_, numFacets)\n        }\n    }\n\n    /// @notice Gets the facet address that supports the given selector.\n    /// @dev If facet is not found return address(0).\n    /// @param _functionSelector The function selector.\n    /// @return facetAddress_ The facet address.\n    function facetAddress(bytes4 _functionSelector)\n        external\n        view\n        override\n        returns (address facetAddress_)\n    {\n        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();\n        facetAddress_ = ds.facetAddressAndSelectorPosition[_functionSelector].facetAddress;\n    }\n\n    // This implements ERC-165.\n    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {\n        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();\n        return ds.supportedInterfaces[_interfaceId];\n    }\n}\n"
    },
    "contracts/diamond/libraries/LibDiamond.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n\n/******************************************************************************\\\n* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)\n* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535\n/******************************************************************************/\nimport {IDiamondCut} from \"../interfaces/IDiamondCut.sol\";\n\nlibrary LibDiamond {\n    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256(\"diamond.standard.diamond.storage\");\n\n    struct FacetAddressAndSelectorPosition {\n        address facetAddress;\n        uint16 selectorPosition;\n    }\n\n    struct DiamondStorage {\n        // function selector => facet address and selector position in selectors array\n        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;\n        bytes4[] selectors;\n        mapping(bytes4 => bool) supportedInterfaces;\n        // owner of the contract\n        address contractOwner;\n    }\n\n    function diamondStorage() internal pure returns (DiamondStorage storage ds) {\n        bytes32 position = DIAMOND_STORAGE_POSITION;\n        assembly {\n            ds.slot := position\n        }\n    }\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    function setContractOwner(address _newOwner) internal {\n        DiamondStorage storage ds = diamondStorage();\n        address previousOwner = ds.contractOwner;\n        ds.contractOwner = _newOwner;\n        emit OwnershipTransferred(previousOwner, _newOwner);\n    }\n\n    function contractOwner() internal view returns (address contractOwner_) {\n        contractOwner_ = diamondStorage().contractOwner;\n    }\n\n    function enforceIsContractOwner() internal view {\n        require(msg.sender == diamondStorage().contractOwner, \"LibDiamond: Must be contract owner\");\n    }\n\n    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);\n\n    // Internal function version of diamondCut\n    function diamondCut(\n        IDiamondCut.FacetCut[] memory _diamondCut,\n        address _init,\n        bytes memory _calldata\n    ) internal {\n        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {\n            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;\n            if (action == IDiamondCut.FacetCutAction.Add) {\n                addFunctions(\n                    _diamondCut[facetIndex].facetAddress,\n                    _diamondCut[facetIndex].functionSelectors\n                );\n            } else if (action == IDiamondCut.FacetCutAction.Replace) {\n                replaceFunctions(\n                    _diamondCut[facetIndex].facetAddress,\n                    _diamondCut[facetIndex].functionSelectors\n                );\n            } else if (action == IDiamondCut.FacetCutAction.Remove) {\n                removeFunctions(\n                    _diamondCut[facetIndex].facetAddress,\n                    _diamondCut[facetIndex].functionSelectors\n                );\n            } else {\n                revert(\"LibDiamondCut: Incorrect FacetCutAction\");\n            }\n        }\n        emit DiamondCut(_diamondCut, _init, _calldata);\n        initializeDiamondCut(_init, _calldata);\n    }\n\n    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {\n        require(_functionSelectors.length > 0, \"LibDiamondCut: No selectors in facet to cut\");\n        DiamondStorage storage ds = diamondStorage();\n        uint16 selectorCount = uint16(ds.selectors.length);\n        require(_facetAddress != address(0), \"LibDiamondCut: Add facet can't be address(0)\");\n        enforceHasContractCode(_facetAddress, \"LibDiamondCut: Add facet has no code\");\n        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {\n            bytes4 selector = _functionSelectors[selectorIndex];\n            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;\n            require(\n                oldFacetAddress == address(0),\n                \"LibDiamondCut: Can't add function that already exists\"\n            );\n            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(\n                _facetAddress,\n                selectorCount\n            );\n            ds.selectors.push(selector);\n            selectorCount++;\n        }\n    }\n\n    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {\n        require(_functionSelectors.length > 0, \"LibDiamondCut: No selectors in facet to cut\");\n        DiamondStorage storage ds = diamondStorage();\n        require(_facetAddress != address(0), \"LibDiamondCut: Replace facet can't be address(0)\");\n        enforceHasContractCode(_facetAddress, \"LibDiamondCut: Replace facet has no code\");\n        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {\n            bytes4 selector = _functionSelectors[selectorIndex];\n            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;\n            // can't replace immutable functions -- functions defined directly in the diamond\n            require(\n                oldFacetAddress != address(this),\n                \"LibDiamondCut: Can't replace immutable function\"\n            );\n            require(\n                oldFacetAddress != _facetAddress,\n                \"LibDiamondCut: Can't replace function with same function\"\n            );\n            require(\n                oldFacetAddress != address(0),\n                \"LibDiamondCut: Can't replace function that doesn't exist\"\n            );\n            // replace old facet address\n            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;\n        }\n    }\n\n    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {\n        require(_functionSelectors.length > 0, \"LibDiamondCut: No selectors in facet to cut\");\n        DiamondStorage storage ds = diamondStorage();\n        uint256 selectorCount = ds.selectors.length;\n        require(\n            _facetAddress == address(0),\n            \"LibDiamondCut: Remove facet address must be address(0)\"\n        );\n        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {\n            bytes4 selector = _functionSelectors[selectorIndex];\n            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds\n            .facetAddressAndSelectorPosition[selector];\n            require(\n                oldFacetAddressAndSelectorPosition.facetAddress != address(0),\n                \"LibDiamondCut: Can't remove function that doesn't exist\"\n            );\n            // can't remove immutable functions -- functions defined directly in the diamond\n            require(\n                oldFacetAddressAndSelectorPosition.facetAddress != address(this),\n                \"LibDiamondCut: Can't remove immutable function.\"\n            );\n            // replace selector with last selector\n            selectorCount--;\n            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {\n                bytes4 lastSelector = ds.selectors[selectorCount];\n                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;\n                ds\n                .facetAddressAndSelectorPosition[lastSelector]\n                .selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;\n            }\n            // delete last selector\n            ds.selectors.pop();\n            delete ds.facetAddressAndSelectorPosition[selector];\n        }\n    }\n\n    function initializeDiamondCut(address _init, bytes memory _calldata) internal {\n        if (_init == address(0)) {\n            require(\n                _calldata.length == 0,\n                \"LibDiamondCut: _init is address(0) but_calldata is not empty\"\n            );\n        } else {\n            require(\n                _calldata.length > 0,\n                \"LibDiamondCut: _calldata is empty but _init is not address(0)\"\n            );\n            if (_init != address(this)) {\n                enforceHasContractCode(_init, \"LibDiamondCut: _init address has no code\");\n            }\n            (bool success, bytes memory error) = _init.delegatecall(_calldata);\n            if (!success) {\n                if (error.length > 0) {\n                    // bubble up the error\n                    revert(string(error));\n                } else {\n                    revert(\"LibDiamondCut: _init function reverted\");\n                }\n            }\n        }\n    }\n\n    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {\n        uint256 contractSize;\n        assembly {\n            contractSize := extcodesize(_contract)\n        }\n        require(contractSize > 0, _errorMessage);\n    }\n}\n"
    },
    "contracts/diamond/interfaces/IDiamondLoupe.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n\n/******************************************************************************\\\n* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)\n* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535\n/******************************************************************************/\n\n// A loupe is a small magnifying glass used to look at diamonds.\n// These functions look at diamonds\ninterface IDiamondLoupe {\n    /// These functions are expected to be called frequently\n    /// by tools.\n\n    struct Facet {\n        address facetAddress;\n        bytes4[] functionSelectors;\n    }\n\n    /// @notice Gets all facet addresses and their four byte function selectors.\n    /// @return facets_ Facet\n    function facets() external view returns (Facet[] memory facets_);\n\n    /// @notice Gets all the function selectors supported by a specific facet.\n    /// @param _facet The facet address.\n    /// @return facetFunctionSelectors_\n    function facetFunctionSelectors(address _facet)\n        external\n        view\n        returns (bytes4[] memory facetFunctionSelectors_);\n\n    /// @notice Get all the facet addresses used by a diamond.\n    /// @return facetAddresses_\n    function facetAddresses() external view returns (address[] memory facetAddresses_);\n\n    /// @notice Gets the facet that supports the given selector.\n    /// @dev If facet is not found return address(0).\n    /// @param _functionSelector The function selector.\n    /// @return facetAddress_ The facet address.\n    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);\n}\n"
    },
    "contracts/diamond/interfaces/IERC165.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n\ninterface IERC165 {\n    /// @notice Query if a contract implements an interface\n    /// @param interfaceId The interface identifier, as specified in ERC-165\n    /// @dev Interface identification is specified in ERC-165. This function\n    ///  uses less than 30,000 gas.\n    /// @return `true` if the contract implements `interfaceID` and\n    ///  `interfaceID` is not 0xffffffff, `false` otherwise\n    function supportsInterface(bytes4 interfaceId) external view returns (bool);\n}\n"
    },
    "contracts/diamond/interfaces/IDiamondCut.sol": {
      "content": "// SPDX-License-Identifier: MIT\npragma solidity ^0.8.0;\n\n/******************************************************************************\\\n* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)\n* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535\n/******************************************************************************/\n\ninterface IDiamondCut {\n    enum FacetCutAction {\n        Add,\n        Replace,\n        Remove\n    }\n    // Add=0, Replace=1, Remove=2\n\n    struct FacetCut {\n        address facetAddress;\n        FacetCutAction action;\n        bytes4[] functionSelectors;\n    }\n\n    /// @notice Add/replace/remove any number of functions and optionally execute\n    ///         a function with delegatecall\n    /// @param _diamondCut Contains the facet addresses and function selectors\n    /// @param _init The address of the contract or facet to execute _calldata\n    /// @param _calldata A function call, including function selector and arguments\n    ///                  _calldata is executed with delegatecall on _init\n    function diamondCut(\n        FacetCut[] calldata _diamondCut,\n        address _init,\n        bytes calldata _calldata\n    ) external;\n\n    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);\n}\n"
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
    "libraries": {}
  }
}}