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
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMTIMER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmTimer {
    function _getAirdropTime() external view returns (uint256);

    function _getEndAirdropTime() external view returns (uint256);
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
    function bonusCheck(address account) external pure returns (uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMAirdrop.sol
/// @author Fernando Viktor Seidl E-mail: viktorseidl@gmail.com
/// @notice This contract regulates the Airdrops of the Launchpad...to the NFM community
/// @dev This extension regulates a special payout from different currencies of the Launchpad to the community every 5 days.
///
///         INFO:
///         -   Every 5 days, profit distributions are made available to this protocol in various currencies by the IDO Launchpad
///             in different currencies.
///         -   As soon as the amounts are available, a amount per NFM will be calculated. The calculation is as follows:
///             Amount available for distribution / NFM total supply = X
///         -   The distribution happens automatically during the transaction. As soon as an NFM owner makes a transfer within the bonus window,
///             the bonus will automatically be calculated on his NFM balance and credited to his account. The NFM owner is informed about upcoming
///             special payments via the homepage. A prerequisite for participation in the bonus payments is a minimum balance of 50 NFM on the
///             participant's account.
///         -   The payout window is set to 24 hours. Every NFM owner who makes a transfer within this period will automatically have his share
///             credited to his account. All remaining amounts will be partially credited to the staking pool after the end of the time window,
///             and another portion will be send to the NFM treasury for investments.

///           ***All internal smart contracts belonging to the controller are excluded from the PAD check.***
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMAirdrop {
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
    uint256 allCoinsCounter        => Counts all registered airdrops 
    uint256 lastRoundCounter     => Indicates which index was last paid out.
    uint256 Schalter                    => regulates the execution of the one time calculations for the airdrop
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 public allCoinsCounter = 0;
    uint256 public lastRoundCounter = 0;
    uint256 private Schalter = 0;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    _wasPaidCheck (Owner address, ending Timestamp of Airdrop);         //Records when payments have been made
    _totalBalCoin (ERC20 address => Total amount of Airdrop);                 //Records the balance of the airdrop
    _CoinWLDao (Costumer address => mapping(ERC20 address => true 
    if accepted false if denied));                                                                  //Records whether the coin has been approved
    _CoinforNFM (ERC20 address => Amount per NFM);                          //Shows how many coins are paid out per NFM
    _CoinAvailable (ERC20 address => true if funds available false 
    if already done);                                                                                     //Records whether credit is still available
    _allIdoCoins (CoinCounterNum => ERC20 address);                           //Records the coin register
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => uint256) private _wasPaidCheck;
    mapping(address => uint256) private _totalBalCoin;
    mapping(address => mapping(address => bool)) private _CoinWLDao;
    mapping(address => uint256) private _CoinforNFM;
    mapping(address => bool) private _CoinAvailable;
    mapping(uint256 => address) private _allIdoCoins;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTRACT EVENTS
    EBonus(address receiver, address Coin, uint256 amount, uint256 timer);
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    event Airdrop(
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

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_requestWLAirdrop(address Coin) returns (bool);
    This function registers the listing. In the case of a non-IDO, the listing will only be approved after the Dao members 
    have checked and approved it.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _requestWLAirdrop(address Coin) public returns (bool) {
        if (_Controller._checkWLSC(_SController, msg.sender) == true) {
            _CoinWLDao[msg.sender][Coin] = true;
        } else {
            _CoinWLDao[msg.sender][Coin] = false;
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_approveDeposit(address Coin, uint256 Amount) returns (bool);
    This function authorizes the delivery of tokens for the airdrop. The minimum amount for an airdrop is 1000 tokens
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _approveDeposit(address Coin, uint256 Amount)
        public
        returns (bool)
    {
        if (
            _CoinWLDao[msg.sender][Coin] == true &&
            IERC20(address(Coin)).allowance(msg.sender, address(this)) ==
            Amount &&
            IERC20(address(Coin)).allowance(msg.sender, address(this)) >=
            1000 * 10**IERC20(address(Coin)).decimals()
        ) {
            require(
                IERC20(address(Coin)).transferFrom(
                    msg.sender,
                    address(this),
                    Amount
                ) == true,
                "<A"
            );
            if (_addAirDrop(Coin) == true) {
                return true;
            }
            return false;
        }
        return false;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_addAirDrop(address Coin, uint256 Amount) returns (bool);
    This feature saves all important data for the airdrop. In order for the airdrop to take place, a non-IDO airdrop must 
    have the approval of the Dao.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _addAirDrop(address Coin) public onlyOwner returns (bool) {
        if (
            _CoinWLDao[msg.sender][Coin] == true &&
            IERC20(address(Coin)).balanceOf(address(this)) > 0
        ) {
            _totalBalCoin[Coin] = IERC20(address(Coin)).balanceOf(
                address(this)
            );
            _CoinAvailable[Coin] = true;
            _allIdoCoins[allCoinsCounter] = Coin;
            allCoinsCounter++;
            return true;
        }
        return false;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_checkSwapCounter() returns (bool);
    This function checks the array index to use
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateAirdropArray() public onlyOwner returns (bool) {
        if (allCoinsCounter >= lastRoundCounter + 3) {
            //No problem just check Coin propiety
        } else {
            //allCoinsCounter - lastRoundCounter
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_checkOnNewPairs() returns (bool);
    This function checks whether new currencies have been implemented for the bonus system
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _checkOnNewPairs() public onlyOwner returns (bool) {
        uint256 Coins = INfmUV2Pool(address(_Controller._getUV2Pool()))
            ._showPairNum();
        if (Coins > _CoinArrLength) {
            _CoinArrLength = Coins;
            _CoinsArray = INfmUV2Pool(address(_Controller._getUV2Pool()))
                ._returnCoinsArray();
        }
        return true;
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
        uint256 CoinTotal = IERC20(address(_CoinsArray[_SwapCounter]))
            .balanceOf(address(this));
        //Get Coindecimals for calculations
        uint256 CoinDecimals = IERC20(address(_CoinsArray[_SwapCounter]))
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
    function _getAmountToPay(address Sender, uint256 Amount)
        internal
        virtual
        returns (uint256)
    {
        (
            uint256 issuedate,
            uint256 timestampBal,
            uint256 balanceAmount,
            bool status
        ) = INFM(address(_Controller._getNFM())).bonusCheck(address(Sender));
        if (
            issuedate <
            INfmTimer(address(_Controller._getTimer()))
                ._getExtraBonusAllTime() &&
            timestampBal <
            INfmTimer(address(_Controller._getTimer()))
                ._getEndExtraBonusAllTime() &&
            status == true
        ) {
            //Substract sending amount from senders balance before making calculations
            uint256 SenderBal = SafeMath.sub(balanceAmount, Amount);
            //Calculate Bonus amount for sender.
            uint256 CoinDecimals = IERC20(address(_CoinsArray[_SwapCounter]))
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
        } else {
            return 0;
        }
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
