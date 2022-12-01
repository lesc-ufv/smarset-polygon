{{
  "language": "Solidity",
  "sources": {
    "contracts/TrustPoap.sol": {
      "content": "pragma solidity ^0.8.13;\n\nimport \"./IPoap.sol\";\nimport \"./IGetterLogic.sol\";\n\ncontract TrustPOAP {\n    address humanboundToken;\n    address poap;\n\n    mapping(uint256 => string) reviewURIbyReviewId;\n    mapping(uint256 => uint256[]) reviewersByEventId;\n\n    constructor(address _humanboundToken, address _poap) {\n        humanboundToken = _humanboundToken;\n        poap = _poap;\n    }\n\n    modifier onlyUniqueHuman(uint256 hbtId) {\n        require(IGetterLogic(humanboundToken).balanceOf(msg.sender) > 0, \"caller is not human\");\n        require(IGetterLogic(humanboundToken).ownerOf(hbtId) == msg.sender, \"caller is not holder of this hbt\");\n        _;\n    }\n\n    modifier onlyUnwrittenReview(uint256 eventId, uint256 hbtId, uint256 tokenId) {\n        // uint256 eventId = IPoap(poap).tokenEvent(tokenId);\n        uint256 reviewId = calculateReviewId(hbtId, eventId);\n\n        require(bytes(reviewURIbyReviewId[reviewId]).length > 0);\n        _;\n    }\n\n    modifier onlyAttendee(uint256 tokenId) {\n        require(IGetterLogic(poap).ownerOf(tokenId) == msg.sender);\n        _;\n    }\n\n    function submitReview(uint256 eventId, uint256 hbtId, uint256 poapTokenId, string calldata uri) public \n        onlyUniqueHuman(hbtId)\n        // onlyAttendee(poapTokenId) \n        onlyUnwrittenReview(eventId, hbtId, poapTokenId)\n    {\n        // uint256 eventId = IPoap(poap).tokenEvent(poapTokenId);\n        uint256 reviewId = calculateReviewId(hbtId, eventId);\n\n        reviewURIbyReviewId[reviewId] = uri;\n    }\n\n    function getEventReviewURIs(uint256 eventId) public view returns(string[] memory reviews) {\n        uint256[] memory reviewers = reviewersByEventId[eventId];\n\n        reviews = new string[](reviewers.length);\n        for (uint256 i = 0; i < reviewers.length; i++) {\n            uint256 reviewer = reviewers[i];\n            uint256 reviewId = calculateReviewId(reviewer, eventId);\n            reviews[i] = reviewURIbyReviewId[reviewId];\n        }\n    }\n\n    function calculateReviewId(uint256 hbt, uint256 eventId) internal pure returns(uint256) {\n        return uint256(keccak256(abi.encodePacked(hbt, eventId)));\n    }\n}"
    },
    "contracts/IPoap.sol": {
      "content": "pragma solidity ^0.8.13;\n\ninterface IPoap {\n    event EventToken(uint256 eventId, uint256 tokenId);\n\n    /**\n     * @dev Gets the token name\n     * @return string representing the token name\n     */\n    function name() external view returns (string memory);\n\n    /**\n     * @dev Gets the token symbol\n     * @return string representing the token symbol\n     */\n    function symbol() external view returns (string memory);\n\n    /**\n     * @dev Gets the event id for a token\n     * @return string representing the token symbol\n     */\n    function tokenEvent(uint256 tokenId) external view returns (uint256);\n\n    /**\n     * @dev Gets the token ID at a given index of the tokens list of the requested owner\n     * @param owner address owning the tokens list to be accessed\n     * @param index uint256 representing the index to be accessed of the requested tokens list\n     * @return tokenId token ID at the given index of the tokens list owned by the requested address\n     * @return eventId event ID for the token at the given index of the tokens owned by the address\n     */\n    function tokenDetailsOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId, uint256 eventId);\n\n    /**\n     * @dev Gets the token uri\n     * @return string representing the token uri\n     */\n    function tokenURI(uint256 tokenId) external view returns (string memory);\n\n    /**\n     * @dev Function to mint tokens\n     * @param eventId EventId for the new token\n     * @param to The address that will receive the minted tokens.\n     * @return A boolean that indicates if the operation was successful.\n     */\n    function mintEventToManyUsers(uint256 eventId, address[] memory to)\n    external returns (bool);\n\n    /**\n     * @dev Function to mint tokens\n     * @param eventIds EventIds to assing to user\n     * @param to The address that will receive the minted tokens.\n     * @return A boolean that indicates if the operation was successful.\n     */\n    function mintUserToManyEvents(uint256[] memory eventIds, address to)\n    external returns (bool);\n\n    /**\n     * @dev Burns a specific ERC721 token.\n     * @param tokenId uint256 id of the ERC721 token to be burned.\n     */\n    function burn(uint256 tokenId) external;\n}"
    },
    "contracts/IGetterLogic.sol": {
      "content": "//SPDX-License-Identifier: MIT\npragma solidity ^0.8.4;\n\ninterface IGetterLogic {\n    /**\n     * @dev See {IERC721-balanceOf}.\n     */\n    function balanceOf(address owner) external returns (uint256);\n\n    /**\n     * @dev See {IERC721-ownerOf}.\n     */\n    function ownerOf(uint256 tokenId) external returns (address);\n\n    /**\n     * @dev See {IERC721-getApproved}.\n     */\n    function getApproved(uint256 tokenId) external returns (address);\n\n    /**\n     * @dev See {IERC721-isApprovedForAll}.\n     */\n    function isApprovedForAll(address owner, address operator) external returns (bool);\n\n    /**\n     * @dev Returns whether `tokenId` exists.\n     *\n     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.\n     *\n     * Tokens start existing when they are minted (`_mint`),\n     * and stop existing when they are burned (`_burn`).\n     *\n     * Requirements:\n     *\n     * - Must be modified with `public _internal`.\n     */\n    function _exists(uint256 tokenId) external returns (bool);\n\n    /**\n     * @dev Returns whether `spender` is allowed to manage `tokenId`.\n     *\n     * Requirements:\n     *\n     * - `tokenId` must exist.\n     * - Must be modified with `public _internal`.\n     */\n    function _isApprovedOrOwner(address spender, uint256 tokenId) external returns (bool);\n}"
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