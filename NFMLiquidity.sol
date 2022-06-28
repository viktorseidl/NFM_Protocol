//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// LIBRARIES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// SAFEMATH its a Openzeppelin Lib. Check out for more info @ https://docs.openzeppelin.com/contracts/2.x/api/math
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);

    function _getUV2Pool() external pure returns (address);

    function _getExchange() external pure returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMTIMER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmTimer {
    function _updateUV2_Liquidity_event() external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IUNISWAPV2ROUTER01
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IUNISWAPV2ROUTER02
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IUNISWAPV2PAIR
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IUNISWAPV2FACTORY
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMLiquidity.sol
/// @author Fernando Viktor Seidl E-mail: viktorseidl@gmail.com
/// @notice This contract regulates the Liquidity Management for the UniswapV2 Protocol
/// @dev This extension regulates and controls the liquidity management for the Uniswap protocol.
///
///         INFO:
///         -   This process is carried out almost automatically every 7 days by the trading cycle of the NFM. The process runs through an
///             index that contains all permitted currency addresses. With each execution, another currency from the index is funded with
///             liquidity in the UniswapV2 protocol
///         -   The liquidity tokens received will be blocked for a period of 11 years. After 11 years, these are redeemed automatically at
///             monthly intervals through the LP-Extension by the NFM protocol. The profits made are divided as follows:
///                     - NFM Community will receive 20% of all LP-Yields (Yields will be distributed via the Bonus Event in the NFM Protocol.)
///                     - Governance will receive 30% of all LP-Yields (The proceeds are set aside for the BuyBack program and are intended
///                       to generate additional income for greater purchasing power.)
///                     - NFM Treasury will receive 40% of all LP-Yields (The proceeds are set aside for the bonus program and are intended to
///                       generate additional income for larger bonus payments.)
///                     - Developers will receive 10% of all LP-Yields (Is paid out as commission payments)
///         -   The initial credit is drawn from the UniswapPool protocol. This contract manages the NFM deposits and all other permitted
///             currencies and is also responsible for generating income.
///
///           ***All internal smart contracts belonging to the controller are excluded from the PAD check.***
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMLiquidity {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Owner;
    INfmController private _Controller;
    address private _SController;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    _CoinArrLength        => Length of Array 
    _CoinsArray             => Array of accepted coins for bonus payments
    _Index                      => Counter of Swap
    Schalter                    => regulates the execution of the swap for the bonus
    CoinProNFM             => Payout Amount for an NFM
    _MinUSD                   => Minimum liquidity amount in NFM
    _MaxUSD                  => Maximum liquidity amount in NFM
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 public _CoinArrLength;
    address[] public _CoinsArray;
    uint256 public Index;
    uint256 private _MinNFM = 35000 * 10**18;
    uint256 private _MaxNFM = 100000 * 10**18;
    uint256 private Schalter = 0;
    uint256 private PayoutRule = 0;
    struct LiquidityAdded {
        uint256 AmountA;
        uint256 AmountB;
        uint256 LP;
        address currency;
        uint256 timer;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    _wasPaidCheck (Owner address, ending Timestamp of Bonus);
    _updatedCoinBalance (Coin address, Balance uint256 )  //Records full Amount paid.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(uint256 => LiquidityAdded) public _AddedLiquidity;
    uint256 private _LiquidityCounter = 0;
    mapping(address => uint256[]) public _priceCoinPerNfm;

    event Liquidity(
        address indexed Coin,
        address indexed NFM,
        uint256 AmountCoin,
        uint256 AmountNFM
    );
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }

    function _storeLiquidity(
        uint256 AmountA,
        uint256 AmountB,
        uint256 LP,
        address currency
    ) internal virtual onlyOwner {
        _AddedLiquidity[_LiquidityCounter] = LiquidityAdded(
            AmountA,
            AmountB,
            LP,
            currency,
            block.timestamp
        );
        _LiquidityCounter++;
    }

    function _returnFullLiquidityArray(uint256 Elements)
        public
        view
        returns (LiquidityAdded[] memory)
    {
        LiquidityAdded[] memory lLiquidityAdded = new LiquidityAdded[](
            _LiquidityCounter
        );
        for (uint256 i = Elements; i < _LiquidityCounter; i++) {
            LiquidityAdded storage lLiquidityAdd = _AddedLiquidity[i];
            lLiquidityAdded[i] = lLiquidityAdd;
        }
        return lLiquidityAdded;
    }

    function _returnLiquidityElement(uint256 Element)
        public
        view
        returns (LiquidityAdded memory)
    {
        return _AddedLiquidity[Element];
    }
}
