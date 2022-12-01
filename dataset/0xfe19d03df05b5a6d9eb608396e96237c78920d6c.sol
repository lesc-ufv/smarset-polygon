{{
  "language": "Solidity",
  "sources": {
    "/contracts/staking/Staking.sol": {
      "content": "pragma solidity ^0.6.0;\npragma experimental ABIEncoderV2;\n\nimport \"@openzeppelin/contracts/access/Ownable.sol\";\nimport \"@openzeppelin/contracts/token/ERC20/IERC20.sol\";\nimport \"../cluster-metadata/IDnsClusterMetadataStore.sol\";\n\ncontract Staking is Ownable {\n    uint256 constant EXP = 10**18;\n    uint256 constant DAY = 86400;\n    uint256 public lockAmountForBlocks = 500000;\n    address public stackToken;\n    address public dnsClusterStore;\n    uint256 public slashFactor;\n    uint256 public rewardsPerShare;\n    uint256 public rewardsPerUpvote;\n    uint256 public stakingAmount;\n    uint256 public slashCollected;\n    address public daoAddress;\n\n    struct Stake {\n        uint256 amount;\n        uint256 stakedAt;\n        uint256 share;\n        uint256 lastWithdraw;\n        bytes32 dns;\n        uint256 lastRewardsCollectedAt;\n    }\n\n    mapping(address => Stake) public stakes;\n\n    mapping(address => uint256) public lockTime;\n\n    event SlashCollectedLog(\n        address collector,\n        uint256 collectedSlash,\n        uint256 slashCollectedAt\n    );\n\n    /*\n     * @dev - constructor (being called at contract deployment)\n     * @param Address of DNSClusterMetadata Store deployed contract\n     * @param Address of stackToken deployed contract\n     * @param Minimum staking amount\n     * @param Slash Factor - Number of rewards be Slashed for bad actors\n     * @param Number of rewards for every Upvotes\n     * @param Number of rewards for every share of the whole staking pool\n     */\n    constructor(\n        address _dnsClusterStore,\n        address _stackToken,\n        uint256 _stakingAmount,\n        uint256 _slashFactor,\n        uint256 _rewardsPerUpvote,\n        uint256 _rewardsPerShare,\n        address _daoAddress\n    ) public {\n        stackToken = _stackToken;\n        dnsClusterStore = _dnsClusterStore;\n        stakingAmount = _stakingAmount;\n        slashFactor = _slashFactor;\n        rewardsPerUpvote = _rewardsPerUpvote;\n        rewardsPerShare = _rewardsPerShare;\n        daoAddress = _daoAddress;\n    }\n\n    /*\n     * @title Update the minimum staking amount\n     * @param Updated minimum staking amount\n     * @dev Could only be invoked by the contract owner\n     */\n    function setStakingAmount(uint256 _stakingAmount) public onlyOwner {\n        stakingAmount = _stakingAmount;\n    }\n\n    /*\n     * @title Update the dao address\n     * @param Updated dao address\n     * @param Dns Cluster Store address\n     * @dev Could only be invoked by the contract owner\n     */\n    function setAddressSettings(address _daoAddress, address _dnsClusterStore)\n        public\n        onlyOwner\n    {\n        daoAddress = _daoAddress;\n        dnsClusterStore = _dnsClusterStore;\n    }\n\n    /*\n     * @title Update the Slash Factor\n     * @param New slash factor amount\n     * @dev Could only be invoked by the contract owner\n     */\n    function setSlashFactor(uint256 _slashFactor) public onlyOwner {\n        slashFactor = _slashFactor;\n    }\n\n    /*\n     * @title Update the Rewards per Share\n     * @param Updated amount of Rewards for each share\n     * @dev Could only be invoked by the contract owner\n     */\n    function setRewardsPerShare(uint256 _rewardsPerShare) public onlyOwner {\n        rewardsPerShare = _rewardsPerShare;\n    }\n\n    /*\n     * @title Update the Amount Locked For Blocks\n     * @param Updated number of blocks till the value is locked\n     * @dev Could only be invoked by the dao address\n     */\n    function setLockAmountForBlocks(uint256 _lockAmountForBlocks) public {\n        require(\n            msg.sender == daoAddress,\n            \"You are not allowed to change this variable\"\n        );\n        lockAmountForBlocks = _lockAmountForBlocks;\n    }\n\n    /*\n     * @title Users could stake there stack tokens\n     * @param Number of stack tokens to stake\n     * @param Name of DNS\n     * @param IPAddress of the DNS\n     * @param whitelisted IP\n     * @return True if successfully invoked\n     */\n    function deposit(\n        uint256 _amount,\n        bytes32 _dns,\n        string memory _ipAddress,\n        string memory _whitelistedIps,\n        string memory _clusterType,\n        bool _isPrivate\n    ) public returns (bool) {\n        require(\n            _amount > stakingAmount,\n            \"Amount should be greater than the stakingAmount\"\n        );\n        Stake storage stake = stakes[msg.sender];\n        IERC20(stackToken).transferFrom(msg.sender, address(this), _amount);\n        stake.stakedAt = block.timestamp;\n        stake.amount = _amount;\n        stake.dns = _dns;\n        stake.share = _calcStakedShare(_amount, msg.sender);\n\n        // Staking contract creates a ClusterMetadata Entry\n        IDnsClusterMetadataStore(dnsClusterStore).addDnsToClusterEntry(\n            _dns,\n            address(msg.sender),\n            _ipAddress,\n            _whitelistedIps,\n            _clusterType,\n            _isPrivate\n        );\n        return true;\n    }\n\n    /*\n     * @title Staker could revoke withdrawal request\n     * @param Set lockTime for the sender to be zero\n     * @return True if successfully invoked\n     */\n\n    function revokeWithdrawalRequest() public returns (bool) {\n        lockTime[msg.sender] = 0;\n        return true;\n    }\n\n    /*\n     * @title Staker could withdraw there staked stack tokens\n     * @param Amount of stack tokens to unstake\n     * @return True if successfully invoked\n     */\n\n    function withdraw(uint256 _amount) public returns (bool) {\n        if (lockTime[msg.sender] == 0) {\n            lockTime[msg.sender] = block.number + lockAmountForBlocks;\n        } else {\n            require(\n                block.number >= lockTime[msg.sender],\n                \"You are not allowed to withdraw as withdrawal locked time is not passed yet\"\n            );\n            Stake storage stake = stakes[msg.sender];\n            require(stake.amount >= _amount, \"Insufficient amount to withdraw\");\n\n            (\n                ,\n                ,\n                ,\n                uint256 upvotes,\n                uint256 downvotes,\n                bool isDefaulter,\n                ,\n                ,\n                ,\n\n            ) = IDnsClusterMetadataStore(dnsClusterStore).dnsToClusterMetadata(\n                    stake.dns\n                );\n            uint256 slash;\n            if (isDefaulter == true) {\n                slash = (downvotes / upvotes) * slashFactor;\n            }\n            uint256 actualWithdrawAmount;\n            if (_amount > slash) {\n                actualWithdrawAmount = _amount - slash;\n            } else {\n                actualWithdrawAmount = 0;\n            }\n            stake.lastWithdraw = block.timestamp;\n            stake.amount = stake.amount - (actualWithdrawAmount + slash);\n            if (stake.amount <= 0) {\n                // Remove entry from metadata contract\n                IDnsClusterMetadataStore(dnsClusterStore)\n                    .removeDnsToClusterEntry(stake.dns);\n            }\n            stake.share = _calcStakedShare(stake.amount, msg.sender);\n            slashCollected = slashCollected + slash;\n\n            IERC20(stackToken).transfer(msg.sender, actualWithdrawAmount);\n            return true;\n        }\n    }\n\n    /*\n     * @title Non Defaulter Users could claim the slashed rewards that is accumulated from bad actors\n     */\n    function claimSlashedRewards() public {\n        Stake storage stake = stakes[msg.sender];\n        require(stake.stakedAt > 0, \"Not a staker\");\n        require(\n            (block.timestamp - stake.lastRewardsCollectedAt) > DAY,\n            \"Try again after 24 Hours\"\n        );\n        (\n            ,\n            ,\n            ,\n            uint256 upvotes,\n            ,\n            bool isDefaulter,\n            ,\n            ,\n            ,\n\n        ) = IDnsClusterMetadataStore(dnsClusterStore).dnsToClusterMetadata(\n                stake.dns\n            );\n        require(\n            !isDefaulter,\n            \"Stakers marked as defaulters are not eligible to claim the rewards\"\n        );\n        uint256 stakedShare = getStakedShare();\n        uint256 stakedShareRewards = stakedShare * rewardsPerShare;\n        uint256 upvoteRewards = upvotes * rewardsPerUpvote;\n        uint256 rewardFunds = stakedShareRewards + upvoteRewards;\n        require(slashCollected >= rewardFunds, \"Insufficient reward funds\");\n        slashCollected = slashCollected - (rewardFunds);\n        stake.lastRewardsCollectedAt = block.timestamp;\n        IERC20(stackToken).transfer(msg.sender, rewardFunds);\n\n        emit SlashCollectedLog(msg.sender, rewardFunds, block.timestamp);\n    }\n\n    /*\n     * @title Fetches the Invoker Staked share from the total pool\n     * @return User's Share\n     */\n    function getStakedShare() public view returns (uint256) {\n        Stake storage stake = stakes[msg.sender];\n        return _calcStakedShare(stake.amount, msg.sender);\n    }\n\n    function _calcStakedShare(uint256 stakedAmount, address staker)\n        internal\n        view\n        returns (uint256 share)\n    {\n        uint256 totalSupply = IERC20(stackToken).balanceOf(address(this));\n        uint256 exponentialAmount = EXP * stakedAmount;\n        share = exponentialAmount / totalSupply;\n    }\n}\n"
    },
    "/contracts/cluster-metadata/IDnsClusterMetadataStore.sol": {
      "content": "pragma solidity ^0.6.12;\npragma experimental ABIEncoderV2;\n\ninterface IDnsClusterMetadataStore {\n    function dnsToClusterMetadata(bytes32)\n        external\n        returns (\n            address,\n            string memory,\n            string memory,\n            uint256,\n            uint256,\n            bool,\n            uint256,\n            bool,\n            string memory,\n            bool\n        );\n\n    function addDnsToClusterEntry(\n        bytes32 _dns,\n        address _clusterOwner,\n        string memory ipAddress,\n        string memory _whitelistedIps,\n        string memory _clusterType,\n        bool _isPrivate\n    ) external;\n\n    function removeDnsToClusterEntry(bytes32 _dns) external;\n\n    function upvoteCluster(bytes32 _dns) external;\n\n    function downvoteCluster(bytes32 _dns) external;\n\n    function markClusterAsDefaulter(bytes32 _dns) external;\n\n    function getClusterOwner(bytes32 clusterDns) external returns (address);\n}\n"
    },
    "@openzeppelin/contracts/utils/Context.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.6.0 <0.8.0;\n\n/*\n * @dev Provides information about the current execution context, including the\n * sender of the transaction and its data. While these are generally available\n * via msg.sender and msg.data, they should not be accessed in such a direct\n * manner, since when dealing with GSN meta-transactions the account sending and\n * paying for execution may not be the actual sender (as far as an application\n * is concerned).\n *\n * This contract is only required for intermediate, library-like contracts.\n */\nabstract contract Context {\n    function _msgSender() internal view virtual returns (address payable) {\n        return msg.sender;\n    }\n\n    function _msgData() internal view virtual returns (bytes memory) {\n        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691\n        return msg.data;\n    }\n}\n"
    },
    "@openzeppelin/contracts/token/ERC20/IERC20.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.6.0 <0.8.0;\n\n/**\n * @dev Interface of the ERC20 standard as defined in the EIP.\n */\ninterface IERC20 {\n    /**\n     * @dev Returns the amount of tokens in existence.\n     */\n    function totalSupply() external view returns (uint256);\n\n    /**\n     * @dev Returns the amount of tokens owned by `account`.\n     */\n    function balanceOf(address account) external view returns (uint256);\n\n    /**\n     * @dev Moves `amount` tokens from the caller's account to `recipient`.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transfer(address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Returns the remaining number of tokens that `spender` will be\n     * allowed to spend on behalf of `owner` through {transferFrom}. This is\n     * zero by default.\n     *\n     * This value changes when {approve} or {transferFrom} are called.\n     */\n    function allowance(address owner, address spender) external view returns (uint256);\n\n    /**\n     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * IMPORTANT: Beware that changing an allowance with this method brings the risk\n     * that someone may use both the old and the new allowance by unfortunate\n     * transaction ordering. One possible solution to mitigate this race\n     * condition is to first reduce the spender's allowance to 0 and set the\n     * desired value afterwards:\n     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729\n     *\n     * Emits an {Approval} event.\n     */\n    function approve(address spender, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Moves `amount` tokens from `sender` to `recipient` using the\n     * allowance mechanism. `amount` is then deducted from the caller's\n     * allowance.\n     *\n     * Returns a boolean value indicating whether the operation succeeded.\n     *\n     * Emits a {Transfer} event.\n     */\n    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);\n\n    /**\n     * @dev Emitted when `value` tokens are moved from one account (`from`) to\n     * another (`to`).\n     *\n     * Note that `value` may be zero.\n     */\n    event Transfer(address indexed from, address indexed to, uint256 value);\n\n    /**\n     * @dev Emitted when the allowance of a `spender` for an `owner` is set by\n     * a call to {approve}. `value` is the new allowance.\n     */\n    event Approval(address indexed owner, address indexed spender, uint256 value);\n}\n"
    },
    "@openzeppelin/contracts/access/Ownable.sol": {
      "content": "// SPDX-License-Identifier: MIT\n\npragma solidity >=0.6.0 <0.8.0;\n\nimport \"../utils/Context.sol\";\n/**\n * @dev Contract module which provides a basic access control mechanism, where\n * there is an account (an owner) that can be granted exclusive access to\n * specific functions.\n *\n * By default, the owner account will be the one that deploys the contract. This\n * can later be changed with {transferOwnership}.\n *\n * This module is used through inheritance. It will make available the modifier\n * `onlyOwner`, which can be applied to your functions to restrict their use to\n * the owner.\n */\nabstract contract Ownable is Context {\n    address private _owner;\n\n    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);\n\n    /**\n     * @dev Initializes the contract setting the deployer as the initial owner.\n     */\n    constructor () internal {\n        address msgSender = _msgSender();\n        _owner = msgSender;\n        emit OwnershipTransferred(address(0), msgSender);\n    }\n\n    /**\n     * @dev Returns the address of the current owner.\n     */\n    function owner() public view virtual returns (address) {\n        return _owner;\n    }\n\n    /**\n     * @dev Throws if called by any account other than the owner.\n     */\n    modifier onlyOwner() {\n        require(owner() == _msgSender(), \"Ownable: caller is not the owner\");\n        _;\n    }\n\n    /**\n     * @dev Leaves the contract without owner. It will not be possible to call\n     * `onlyOwner` functions anymore. Can only be called by the current owner.\n     *\n     * NOTE: Renouncing ownership will leave the contract without an owner,\n     * thereby removing any functionality that is only available to the owner.\n     */\n    function renounceOwnership() public virtual onlyOwner {\n        emit OwnershipTransferred(_owner, address(0));\n        _owner = address(0);\n    }\n\n    /**\n     * @dev Transfers ownership of the contract to a new account (`newOwner`).\n     * Can only be called by the current owner.\n     */\n    function transferOwnership(address newOwner) public virtual onlyOwner {\n        require(newOwner != address(0), \"Ownable: new owner is the zero address\");\n        emit OwnershipTransferred(_owner, newOwner);\n        _owner = newOwner;\n    }\n}\n"
    }
  },
  "settings": {
    "remappings": [],
    "optimizer": {
      "enabled": false,
      "runs": 200
    },
    "evmVersion": "istanbul",
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