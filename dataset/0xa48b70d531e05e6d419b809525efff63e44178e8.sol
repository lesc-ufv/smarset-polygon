{{
  "language": "Solidity",
  "sources": {
    "./contracts/ApePair.sol": {
      "content": "pragma solidity =0.5.16;\n\n/*\n * ApeSwapFinance \n * App:             https://apeswap.finance\n * Medium:          https://ape-swap.medium.com    \n * Twitter:         https://twitter.com/ape_swap \n * Telegram:        https://t.me/ape_swap\n * Announcements:   https://t.me/ape_swap_news\n * GitHub:          https://github.com/ApeSwapFinance\n */\n\nimport './interfaces/IApePair.sol';\nimport './ApeERC20.sol';\nimport './libraries/Math.sol';\nimport './libraries/UQ112x112.sol';\nimport './interfaces/IERC20.sol';\nimport './interfaces/IApeFactory.sol';\nimport './interfaces/IApeCallee.sol';\n\ncontract ApePair is IApePair, ApeERC20 {\n    using SafeMath  for uint;\n    using UQ112x112 for uint224;\n\n    uint public constant MINIMUM_LIQUIDITY = 10**3;\n    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));\n\n    address public factory;\n    address public token0;\n    address public token1;\n\n    uint112 private reserve0;           // uses single storage slot, accessible via getReserves\n    uint112 private reserve1;           // uses single storage slot, accessible via getReserves\n    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves\n\n    uint public price0CumulativeLast;\n    uint public price1CumulativeLast;\n    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event\n\n    uint private unlocked = 1;\n    modifier lock() {\n        require(unlocked == 1, 'ApeSwap: LOCKED');\n        unlocked = 0;\n        _;\n        unlocked = 1;\n    }\n\n    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {\n        _reserve0 = reserve0;\n        _reserve1 = reserve1;\n        _blockTimestampLast = blockTimestampLast;\n    }\n\n    function _safeTransfer(address token, address to, uint value) private {\n        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));\n        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ApeSwap: TRANSFER_FAILED');\n    }\n\n    event Mint(address indexed sender, uint amount0, uint amount1);\n    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);\n    event Swap(\n        address indexed sender,\n        uint amount0In,\n        uint amount1In,\n        uint amount0Out,\n        uint amount1Out,\n        address indexed to\n    );\n    event Sync(uint112 reserve0, uint112 reserve1);\n\n    constructor() public {\n        factory = msg.sender;\n    }\n\n    // called once by the factory at time of deployment\n    function initialize(address _token0, address _token1) external {\n        require(msg.sender == factory, 'ApeSwap: FORBIDDEN'); // sufficient check\n        token0 = _token0;\n        token1 = _token1;\n    }\n\n    // update reserves and, on the first call per block, price accumulators\n    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {\n        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'ApeSwap: OVERFLOW');\n        uint32 blockTimestamp = uint32(block.timestamp % 2**32);\n        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired\n        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {\n            // * never overflows, and + overflow is desired\n            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;\n            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;\n        }\n        reserve0 = uint112(balance0);\n        reserve1 = uint112(balance1);\n        blockTimestampLast = blockTimestamp;\n        emit Sync(reserve0, reserve1);\n    }\n\n    // if fee is on, mint liquidity equivalent to 1/6th of the growth in sqrt(k)\n    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {\n        address feeTo = IApeFactory(factory).feeTo();\n        feeOn = feeTo != address(0);\n        uint _kLast = kLast; // gas savings\n        if (feeOn) {\n            if (_kLast != 0) {\n                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));\n                uint rootKLast = Math.sqrt(_kLast);\n                if (rootK > rootKLast) {\n                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));\n                    uint denominator = (rootK / 3).add(rootKLast);\n                    uint liquidity = numerator / denominator;\n                    if (liquidity > 0) _mint(feeTo, liquidity);\n                }\n            }\n        } else if (_kLast != 0) {\n            kLast = 0;\n        }\n    }\n\n    // this low-level function should be called from a contract which performs important safety checks\n    function mint(address to) external lock returns (uint liquidity) {\n        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings\n        uint balance0 = IERC20(token0).balanceOf(address(this));\n        uint balance1 = IERC20(token1).balanceOf(address(this));\n        uint amount0 = balance0.sub(_reserve0);\n        uint amount1 = balance1.sub(_reserve1);\n\n        bool feeOn = _mintFee(_reserve0, _reserve1);\n        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee\n        if (_totalSupply == 0) {\n            liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);\n           _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens\n        } else {\n            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);\n        }\n        require(liquidity > 0, 'ApeSwap: INSUFFICIENT_LIQUIDITY_MINTED');\n        _mint(to, liquidity);\n\n        _update(balance0, balance1, _reserve0, _reserve1);\n        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date\n        emit Mint(msg.sender, amount0, amount1);\n    }\n\n    // this low-level function should be called from a contract which performs important safety checks\n    function burn(address to) external lock returns (uint amount0, uint amount1) {\n        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings\n        address _token0 = token0;                                // gas savings\n        address _token1 = token1;                                // gas savings\n        uint balance0 = IERC20(_token0).balanceOf(address(this));\n        uint balance1 = IERC20(_token1).balanceOf(address(this));\n        uint liquidity = balanceOf[address(this)];\n\n        bool feeOn = _mintFee(_reserve0, _reserve1);\n        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee\n        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution\n        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution\n        require(amount0 > 0 && amount1 > 0, 'ApeSwap: INSUFFICIENT_LIQUIDITY_BURNED');\n        _burn(address(this), liquidity);\n        _safeTransfer(_token0, to, amount0);\n        _safeTransfer(_token1, to, amount1);\n        balance0 = IERC20(_token0).balanceOf(address(this));\n        balance1 = IERC20(_token1).balanceOf(address(this));\n\n        _update(balance0, balance1, _reserve0, _reserve1);\n        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date\n        emit Burn(msg.sender, amount0, amount1, to);\n    }\n\n    // this low-level function should be called from a contract which performs important safety checks\n    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {\n        require(amount0Out > 0 || amount1Out > 0, 'ApeSwap: INSUFFICIENT_OUTPUT_AMOUNT');\n        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings\n        require(amount0Out < _reserve0 && amount1Out < _reserve1, 'ApeSwap: INSUFFICIENT_LIQUIDITY');\n\n        uint balance0;\n        uint balance1;\n        { // scope for _token{0,1}, avoids stack too deep errors\n        address _token0 = token0;\n        address _token1 = token1;\n        require(to != _token0 && to != _token1, 'ApeSwap: INVALID_TO');\n        if (amount0Out > 0) _safeTransfer(_token0, to, amount0Out); // optimistically transfer tokens\n        if (amount1Out > 0) _safeTransfer(_token1, to, amount1Out); // optimistically transfer tokens\n        if (data.length > 0) IApeCallee(to).apeCall(msg.sender, amount0Out, amount1Out, data);\n        balance0 = IERC20(_token0).balanceOf(address(this));\n        balance1 = IERC20(_token1).balanceOf(address(this));\n        }\n        uint amount0In = balance0 > _reserve0 - amount0Out ? balance0 - (_reserve0 - amount0Out) : 0;\n        uint amount1In = balance1 > _reserve1 - amount1Out ? balance1 - (_reserve1 - amount1Out) : 0;\n        require(amount0In > 0 || amount1In > 0, 'ApeSwap: INSUFFICIENT_INPUT_AMOUNT');\n        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors\n        uint balance0Adjusted = balance0.mul(1000).sub(amount0In.mul(2));\n        uint balance1Adjusted = balance1.mul(1000).sub(amount1In.mul(2));\n        require(balance0Adjusted.mul(balance1Adjusted) >= uint(_reserve0).mul(_reserve1).mul(1000**2), 'ApeSwap: K');\n        }\n\n        _update(balance0, balance1, _reserve0, _reserve1);\n        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);\n    }\n\n    // force balances to match reserves\n    function skim(address to) external lock {\n        address _token0 = token0; // gas savings\n        address _token1 = token1; // gas savings\n        _safeTransfer(_token0, to, IERC20(_token0).balanceOf(address(this)).sub(reserve0));\n        _safeTransfer(_token1, to, IERC20(_token1).balanceOf(address(this)).sub(reserve1));\n    }\n\n    // force reserves to match balances\n    function sync() external lock {\n        _update(IERC20(token0).balanceOf(address(this)), IERC20(token1).balanceOf(address(this)), reserve0, reserve1);\n    }\n}\n"
    },
    "./contracts/interfaces/IApePair.sol": {
      "content": "pragma solidity >=0.5.0;\n\n/*\n * ApeSwapFinance \n * App:             https://apeswap.finance\n * Medium:          https://ape-swap.medium.com    \n * Twitter:         https://twitter.com/ape_swap \n * Telegram:        https://t.me/ape_swap\n * Announcements:   https://t.me/ape_swap_news\n * GitHub:          https://github.com/ApeSwapFinance\n */\n\ninterface IApePair {\n    event Approval(address indexed owner, address indexed spender, uint value);\n    event Transfer(address indexed from, address indexed to, uint value);\n\n    function name() external pure returns (string memory);\n    function symbol() external pure returns (string memory);\n    function decimals() external pure returns (uint8);\n    function totalSupply() external view returns (uint);\n    function balanceOf(address owner) external view returns (uint);\n    function allowance(address owner, address spender) external view returns (uint);\n\n    function approve(address spender, uint value) external returns (bool);\n    function transfer(address to, uint value) external returns (bool);\n    function transferFrom(address from, address to, uint value) external returns (bool);\n\n    function DOMAIN_SEPARATOR() external view returns (bytes32);\n    function PERMIT_TYPEHASH() external pure returns (bytes32);\n    function nonces(address owner) external view returns (uint);\n\n    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;\n\n    event Mint(address indexed sender, uint amount0, uint amount1);\n    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);\n    event Swap(\n        address indexed sender,\n        uint amount0In,\n        uint amount1In,\n        uint amount0Out,\n        uint amount1Out,\n        address indexed to\n    );\n    event Sync(uint112 reserve0, uint112 reserve1);\n\n    function MINIMUM_LIQUIDITY() external pure returns (uint);\n    function factory() external view returns (address);\n    function token0() external view returns (address);\n    function token1() external view returns (address);\n    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);\n    function price0CumulativeLast() external view returns (uint);\n    function price1CumulativeLast() external view returns (uint);\n    function kLast() external view returns (uint);\n\n    function mint(address to) external returns (uint liquidity);\n    function burn(address to) external returns (uint amount0, uint amount1);\n    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;\n    function skim(address to) external;\n    function sync() external;\n\n    function initialize(address, address) external;\n}\n"
    },
    "./contracts/ApeERC20.sol": {
      "content": "pragma solidity =0.5.16;\n\n/*\n * ApeSwapFinance \n * App:             https://apeswap.finance\n * Medium:          https://ape-swap.medium.com    \n * Twitter:         https://twitter.com/ape_swap \n * Telegram:        https://t.me/ape_swap\n * Announcements:   https://t.me/ape_swap_news\n * GitHub:          https://github.com/ApeSwapFinance\n */\n\nimport './interfaces/IApeERC20.sol';\nimport './libraries/SafeMath.sol';\n\ncontract ApeERC20 is IApeERC20 {\n    using SafeMath for uint;\n\n    string public constant name = 'ApeSwapFinance LPs';\n    string public constant symbol = 'APE-LP';\n    uint8 public constant decimals = 18;\n    uint  public totalSupply;\n    mapping(address => uint) public balanceOf;\n    mapping(address => mapping(address => uint)) public allowance;\n\n    bytes32 public DOMAIN_SEPARATOR;\n    // keccak256(\"Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)\");\n    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;\n    mapping(address => uint) public nonces;\n\n    event Approval(address indexed owner, address indexed spender, uint value);\n    event Transfer(address indexed from, address indexed to, uint value);\n\n    constructor() public {\n        uint chainId;\n        assembly {\n            chainId := chainid\n        }\n        DOMAIN_SEPARATOR = keccak256(\n            abi.encode(\n                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),\n                keccak256(bytes(name)),\n                keccak256(bytes('1')),\n                chainId,\n                address(this)\n            )\n        );\n    }\n\n    function _mint(address to, uint value) internal {\n        totalSupply = totalSupply.add(value);\n        balanceOf[to] = balanceOf[to].add(value);\n        emit Transfer(address(0), to, value);\n    }\n\n    function _burn(address from, uint value) internal {\n        balanceOf[from] = balanceOf[from].sub(value);\n        totalSupply = totalSupply.sub(value);\n        emit Transfer(from, address(0), value);\n    }\n\n    function _approve(address owner, address spender, uint value) private {\n        allowance[owner][spender] = value;\n        emit Approval(owner, spender, value);\n    }\n\n    function _transfer(address from, address to, uint value) private {\n        balanceOf[from] = balanceOf[from].sub(value);\n        balanceOf[to] = balanceOf[to].add(value);\n        emit Transfer(from, to, value);\n    }\n\n    function approve(address spender, uint value) external returns (bool) {\n        _approve(msg.sender, spender, value);\n        return true;\n    }\n\n    function transfer(address to, uint value) external returns (bool) {\n        _transfer(msg.sender, to, value);\n        return true;\n    }\n\n    function transferFrom(address from, address to, uint value) external returns (bool) {\n        if (allowance[from][msg.sender] != uint(-1)) {\n            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);\n        }\n        _transfer(from, to, value);\n        return true;\n    }\n\n    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {\n        require(deadline >= block.timestamp, 'ApeSwap: EXPIRED');\n        bytes32 digest = keccak256(\n            abi.encodePacked(\n                '\\x19\\x01',\n                DOMAIN_SEPARATOR,\n                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))\n            )\n        );\n        address recoveredAddress = ecrecover(digest, v, r, s);\n        require(recoveredAddress != address(0) && recoveredAddress == owner, 'ApeSwap: INVALID_SIGNATURE');\n        _approve(owner, spender, value);\n    }\n}\n"
    },
    "./contracts/interfaces/IApeERC20.sol": {
      "content": "pragma solidity >=0.5.0;\n\n/*\n * ApeSwapFinance \n * App:             https://apeswap.finance\n * Medium:          https://ape-swap.medium.com    \n * Twitter:         https://twitter.com/ape_swap \n * Telegram:        https://t.me/ape_swap\n * Announcements:   https://t.me/ape_swap_news\n * GitHub:          https://github.com/ApeSwapFinance\n */\n\ninterface IApeERC20 {\n    event Approval(address indexed owner, address indexed spender, uint value);\n    event Transfer(address indexed from, address indexed to, uint value);\n\n    function name() external pure returns (string memory);\n    function symbol() external pure returns (string memory);\n    function decimals() external pure returns (uint8);\n    function totalSupply() external view returns (uint);\n    function balanceOf(address owner) external view returns (uint);\n    function allowance(address owner, address spender) external view returns (uint);\n\n    function approve(address spender, uint value) external returns (bool);\n    function transfer(address to, uint value) external returns (bool);\n    function transferFrom(address from, address to, uint value) external returns (bool);\n\n    function DOMAIN_SEPARATOR() external view returns (bytes32);\n    function PERMIT_TYPEHASH() external pure returns (bytes32);\n    function nonces(address owner) external view returns (uint);\n\n    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;\n}\n"
    },
    "./contracts/libraries/SafeMath.sol": {
      "content": "pragma solidity =0.5.16;\n\n// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)\n\nlibrary SafeMath {\n    function add(uint x, uint y) internal pure returns (uint z) {\n        require((z = x + y) >= x, 'ds-math-add-overflow');\n    }\n\n    function sub(uint x, uint y) internal pure returns (uint z) {\n        require((z = x - y) <= x, 'ds-math-sub-underflow');\n    }\n\n    function mul(uint x, uint y) internal pure returns (uint z) {\n        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');\n    }\n}\n"
    },
    "./contracts/libraries/Math.sol": {
      "content": "pragma solidity =0.5.16;\n\n// a library for performing various math operations\n\nlibrary Math {\n    function min(uint x, uint y) internal pure returns (uint z) {\n        z = x < y ? x : y;\n    }\n\n    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)\n    function sqrt(uint y) internal pure returns (uint z) {\n        if (y > 3) {\n            z = y;\n            uint x = y / 2 + 1;\n            while (x < z) {\n                z = x;\n                x = (y / x + x) / 2;\n            }\n        } else if (y != 0) {\n            z = 1;\n        }\n    }\n}\n"
    },
    "./contracts/libraries/UQ112x112.sol": {
      "content": "pragma solidity =0.5.16;\n\n// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))\n\n// range: [0, 2**112 - 1]\n// resolution: 1 / 2**112\n\nlibrary UQ112x112 {\n    uint224 constant Q112 = 2**112;\n\n    // encode a uint112 as a UQ112x112\n    function encode(uint112 y) internal pure returns (uint224 z) {\n        z = uint224(y) * Q112; // never overflows\n    }\n\n    // divide a UQ112x112 by a uint112, returning a UQ112x112\n    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {\n        z = x / uint224(y);\n    }\n}\n"
    },
    "./contracts/interfaces/IERC20.sol": {
      "content": "pragma solidity >=0.5.0;\n\n/*\n * ApeSwapFinance \n * App:             https://apeswap.finance\n * Medium:          https://ape-swap.medium.com    \n * Twitter:         https://twitter.com/ape_swap \n * Telegram:        https://t.me/ape_swap\n * Announcements:   https://t.me/ape_swap_news\n * GitHub:          https://github.com/ApeSwapFinance\n */\n\ninterface IERC20 {\n    event Approval(address indexed owner, address indexed spender, uint value);\n    event Transfer(address indexed from, address indexed to, uint value);\n\n    function name() external view returns (string memory);\n    function symbol() external view returns (string memory);\n    function decimals() external view returns (uint8);\n    function totalSupply() external view returns (uint);\n    function balanceOf(address owner) external view returns (uint);\n    function allowance(address owner, address spender) external view returns (uint);\n\n    function approve(address spender, uint value) external returns (bool);\n    function transfer(address to, uint value) external returns (bool);\n    function transferFrom(address from, address to, uint value) external returns (bool);\n}\n"
    },
    "./contracts/interfaces/IApeFactory.sol": {
      "content": "pragma solidity >=0.5.0;\n\n/*\n * ApeSwapFinance \n * App:             https://apeswap.finance\n * Medium:          https://ape-swap.medium.com    \n * Twitter:         https://twitter.com/ape_swap \n * Telegram:        https://t.me/ape_swap\n * Announcements:   https://t.me/ape_swap_news\n * GitHub:          https://github.com/ApeSwapFinance\n */\n\ninterface IApeFactory {\n    event PairCreated(address indexed token0, address indexed token1, address pair, uint);\n\n    function feeTo() external view returns (address);\n    function feeToSetter() external view returns (address);\n\n    function getPair(address tokenA, address tokenB) external view returns (address pair);\n    function allPairs(uint) external view returns (address pair);\n    function allPairsLength() external view returns (uint);\n\n    function createPair(address tokenA, address tokenB) external returns (address pair);\n\n    function setFeeTo(address) external;\n    function setFeeToSetter(address) external;\n}\n"
    },
    "./contracts/interfaces/IApeCallee.sol": {
      "content": "pragma solidity >=0.5.0;\n\n/*\n * ApeSwapFinance \n * App:             https://apeswap.finance\n * Medium:          https://ape-swap.medium.com    \n * Twitter:         https://twitter.com/ape_swap \n * Telegram:        https://t.me/ape_swap\n * Announcements:   https://t.me/ape_swap_news\n * GitHub:          https://github.com/ApeSwapFinance\n */\n\ninterface IApeCallee {\n    function apeCall(address sender, uint amount0, uint amount1, bytes calldata data) external;\n}\n"
    }
  },
  "settings": {
    "metadata": {
      "useLiteralContent": true
    },
    "optimizer": {
      "enabled": true,
      "runs": 999999
    },
    "outputSelection": {
      "*": {
        "*": [
          "evm.bytecode",
          "evm.deployedBytecode",
          "abi"
        ]
      }
    }
  }
}}