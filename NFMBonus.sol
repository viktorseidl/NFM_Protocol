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

    function _getController() external pure returns (address);

    function _getNFM() external pure returns (address);

    function _getTimer() external pure returns (address);
    
    function _getSwap() external pure returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMTIMER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmTimer {
    function _getExtraBonusAllTime() external view returns (uint256);

    function _getEndExtraBonusAllTime() external view returns (uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFM
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INFM {
    function bonusCheck(address account)
        external
        pure
        returns (uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMSWAP
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmSwap{
    function returnLastSwapingIndex()
        external
        pure
        returns (
            uint256
        );
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMBonus.sol
/// @author Fernando Viktor Seidl E-mail: viktorseidl@gmail.com
/// @notice This contract regulates the special payments of currencies like WBTC,WBNB, WETH,...to the NFM community
/// @dev This extension regulates a special payout from different currencies like WBTC, WETH,... to the community every 100 days. Payments are
///      made in the form of a transfer and generated by the NfmSwap Protocol and Treasury Vaults. 10% of every realized Swap Event 
///      will be send to this contract for distribution. 
///
///         INFO:
///         -   Every 100 days, profit distributions are made available to this protocol in various currencies by the treasury and the UV2Pool
///             in different currencies. The profits are generated from Treasury Vaults investments and one-time swaps of the UniswapV2 protocol.
///         -   As soon as the amounts are available, a fee per NFM will be calculated. The calculation is as follows:
///             Amount available for distribution / NFM total supply = X
///         -   The distribution happens automatically during the transaction. As soon as an NFM owner makes a transfer within the bonus window,
///             the bonus will automatically be calculated on his 24 hours NFM balance and credited to his account. The NFM owner is informed about upcoming
///             special payments via the homepage. A prerequisite for participation in the bonus payments is a minimum balance of 250 NFM on the
///             participant's account.
///         -   The currencies to be paid out are based on the NfmUniswapV2 protocol.
///         -   The payout window is set to 24 hours. Every NFM owner who makes a transfer within this time window will automatically have his share
///             credited to his account. All remaining amounts will be partially credited to the staking pool after the end of the event,
///             and another portion will be returned to the treasury for investments.

///           ***All internal smart contracts belonging to the controller are excluded from the PAD check.***
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMExtraBonus {
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
    _CoinArrLength          => Length of Array 
    _CoinsArray             => Array of accepted coins for bonus payments
    _Index                  => Counter of Swap
    Schalter                => regulates the execution of the swap for the bonus
    CoinProNFM              => Payout Amount for an NFM
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 public _CoinArrLength;
    address[] public _CoinsArray;
    uint256 public Index;
    uint256 private Schalter = 0;
    uint256 private CoinProNFM;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    _wasPaidCheck (Owner address, ending Timestamp of Bonus);
    _updatedCoinBalance (Coin address, Balance uint256 )  //Records full Amount paid.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => uint256) public _wasPaidCheck;
    mapping(address => uint256) public _updatedCoinBalance;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTRACT EVENTS
    EBonus(address receiver, address Coin, uint256 amount, uint256 timer);
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    event SBonus(
        address indexed receiver,
        address indexed Coin,
        uint256 amount,
        uint256 timer
    );
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    onlyOwner       => Only Controller listed Contracts and Owner can interact with this contract.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier onlyOwner() {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                _Owner == msg.sender,
            "oO"
        );
        require(msg.sender != address(0), "0A");
        _;
    }

    constructor(address Controller) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _SController = Controller;
    }
    function _updatePayoutBalance(address Coin) public onlyOwner returns(bool){
        uint256 actualBalance=_updatedCoinBalance[Coin];
        uint256 CoinTotal = IERC20(address(_CoinsArray[Index])).balanceOf(address(this));
            if(actualBalance<CoinTotal){
                _updatedCoinBalance[Coin]=CoinTotal;
            }
            return true;
    }
    function _updateIndex() public view returns(bool){
        uint256 nextIndex=INfmSwap(address(_Controller._getSwap())).returnLastSwapingIndex();
        if(nextIndex==Index){
        return true;
        }
        return false;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @makeCalc() returns (bool);
    This function is executed once at the beginning of an event. It calculates the bonus amount that is paid out for 1 NFM
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function makeCalc() public virtual onlyOwner returns (bool) {
        //Get actual TotalSupply NFM
        uint256 NFMTotalSupply = IERC20(address(_Controller._getNFM()))
            .totalSupply();
        //Get full Amount of Coin
        uint256 CoinTotal = IERC20(address(_CoinsArray[Index]))
            .balanceOf(address(this));
        //Get Coindecimals for calculations
        uint256 CoinDecimals = IERC20(address(_CoinsArray[Index]))
            .decimals();
        if (CoinDecimals < 18) {
            //if smaller than 18 Digits, convert to 18 digits
            CoinTotal = CoinTotal * 10**(18 - CoinDecimals);
        }
        //Calculate how much Coin will receive each NFM.
        uint256 CoinvsNFM = SafeMath.div(
            SafeMath.mul(CoinTotal, 10**18),
            NFMTotalSupply
        );
        if (CoinDecimals < 18) {
            //If coin decimals not equal to 18, return to coin decimals
            CoinvsNFM = SafeMath.div(CoinvsNFM, 10**(18 - CoinDecimals));
        }
        CoinProNFM = CoinvsNFM;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getAmountToPay(address Sender, uint256 Amount) returns (uint256);
    This function calculates the bonus amount to be paid on the sender's balance. The algorithm uses the 24-hour balance 
    as a value.
    The reason for this is to counteract manipulation of newly created accounts and balance shifts that would be used for 
    multiple bonus payments.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getAmountToPay(address Sender)
        internal
        virtual
        returns (uint256)
    {
        uint256 SenderBal = INFM(address(_Controller._getNFM())).bonusCheck(address(Sender));
        
            //Calculate Bonus amount for sender.
            uint256 CoinDecimals = IERC20(address(_CoinsArray[Index]))
                .decimals();
            uint256 CoinEighteen;
            if (CoinDecimals < 18) {
                //if smaller than 18 Digits, convert to 18 digits
                CoinEighteen = CoinProNFM * 10**(18 - CoinDecimals);
            }
            uint256 PayAmount = SafeMath.div(
                SafeMath.mul(SenderBal, CoinEighteen),
                10**18
            );
            if (CoinDecimals < 18) {
                //if smaller than 18 Digits, convert to 18 digits
                PayAmount = SafeMath.div(PayAmount, 10**(18 - CoinDecimals));
            }
            return PayAmount;
        
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @updateSchalter() returns (bool);
    This function updates the switcher
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function updateSchalter() public onlyOwner returns (bool) {
        Schalter = 0;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getWithdraw(address Coin, address To, uint256 amount, bool percent)  returns (bool);
    This function is responsible for the distribution of the remaining bonus payments that have not been redeemed. The remaining 
    balance is split between the staking pool and treasury.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getWithdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) public onlyOwner returns (bool) {
        uint256 CoinAmount = IERC20(address(Coin)).balanceOf(address(this));
        if (percent == true) {
            //makeCalcs on Percentatge
            uint256 AmountToSend = SafeMath.div(
                SafeMath.mul(CoinAmount, amount),
                100
            );
            IERC20(address(Coin)).transfer(To, AmountToSend);
            return true;
        } else {
            if (amount == 0) {
                IERC20(address(Coin)).transfer(To, CoinAmount);
            } else {
                IERC20(address(Coin)).transfer(To, amount);
            }
            return true;
        }
    }
}
