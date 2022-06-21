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

    function _getUV2Pool() external pure returns (address);

    function _getExchange() external pure returns (address);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMUV2POOL
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmUV2Pool {
    function _returnCoinsArray() external view returns (address[] memory);

    function _showContractBalanceOf(address Coin)
        external
        view
        returns (uint256);

    function _showPairNum() external view returns (uint256);

    function getamountOutOnSwap(uint256 amount, address Coin)
        external
        view
        returns (uint256);

    function swapNFMforTokens(address Coin, uint256 amount)
        external
        returns (bool);

    function _getWithdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) external returns (bool);
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
interface INFM{
    function bonusCheck(address account) external pure returns (uint256,uint256,uint256,bool); 
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMEXCHANGE
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmExchange {
    function withdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) external returns (bool);

    function calcNFMAmount(
        address Coin,
        uint256 amount,
        uint256 offchainOracle
    )
        external
        view
        returns (
            bool check,
            uint256 NFMsAmount,
            uint256 MedianPrice,
            bool MaxPrice,
            bool MinPrice
        );

    function checkOracle1Price(address Coin) external view returns (uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title NFMBonus.sol
/// @author Fernando Viktor Seidl E-mail: viktorseidl@gmail.com
/// @notice This contract regulates the special payments from other currencies like WBTC,WBNB, WETH,...to the NFM community
/// @dev This extension regulates a special payout from different currencies like WBTC, WETH,... to the community every 100 days. Payments are 
///      made in the form of a withdrawal.
///     
///         INFO:
///         -   Every 100 days, profit distributions are made available to this protocol in various currencies by the treasury and the UV2Pool 
///             in different currencies. The profits are generated from Treasury investments and one-time swaps of the UniswapV2 protocol.
///         -   As soon as the amounts are available, a fee per NFM will be calculated. The calculation is as follows:
///             Amount available for distribution / NFM total supply = X
///         -   The distribution happens automatically during the transaction. As soon as an NFM owner makes a transfer within the bonus window, 
///             the bonus will automatically be calculated on his NFM balance and credited to his account. The NFM owner is informed about upcoming 
///             special payments via the homepage. A prerequisite for participation in the bonus payments is a minimum balance of 150 NFM on the 
///             participant's account.
///         -   The currencies to be paid out are based on the UniswapV2 protocol. Permitted currencies from this protocol are also provided for 
///             the bonus payments. It is possible to receive additional shares from the IDO Launchpad.
///         -   The payout window is set to 24 hours. Every NFM owner who makes a transfer within this period will automatically have his share 
///             credited to his account. All remaining amounts will be partially credited to the staking pool after the end of the time window, 
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
    _CoinArrLength     => Length of Array 
    _CoinsArray        => Array of accepted coins for bonus payments
    _SwapCounter       => Counter of Swap
    Schalter           => 
    IsBonus            => 
    CoinProNFM         => 
    _wasPaidCheck      => 
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 public _CoinArrLength;
    address[] public _CoinsArray;
    uint256 public _SwapCounter;

    uint256 private Schalter = 0;
    bool private IsBonus=false;
    uint256 private CoinProNFM;

    mapping(address => uint256) public _wasPaidCheck; //Sender -> Timestamp ended Extrabonus

    event EBonus(
        address indexed receiver,
        address indexed Coin,
        uint256 amount,
        uint256 timer
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

    constructor(address Controller) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _SController = Controller;
    }

    function _checkSwapCounter() public onlyOwner returns (bool) {
        if (_SwapCounter == _CoinArrLength) {
            _SwapCounter = 0;
        }
        return true;
    }

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

    //Check if Swapping is available to get bigger BonusAmount for Holders
    function checkforLiquify() public view onlyOwner returns (bool) {
        //Get NFM Balance of UV2Pool
        uint256 NFMBalanceUV2 = INfmUV2Pool(address(_Controller._getUV2Pool()))
            ._showContractBalanceOf(address(_Controller._getNFM()));
        //Get Amount of Coin if Swapping 50000 NFM
        uint256 CoinAmountAsBonus = INfmUV2Pool(
            address(_Controller._getUV2Pool())
        ).getamountOutOnSwap(50000 * 10**18, address(_Controller._getNFM()));
        //Check USD Value on Coin (is 18 Digits format)
        uint256 USDValueCoin = INfmExchange(address(_Controller._getExchange()))
            .checkOracle1Price(address(_CoinsArray[_SwapCounter]));
        //Get Coin Decimals for calculations
        uint256 CoinDec = IERC20(address(_CoinsArray[_SwapCounter])).decimals();
        //if Coin decimals smaller than 18 digits, convert to 18 digits.
        if (CoinDec < 18) {
            CoinAmountAsBonus = CoinAmountAsBonus * 10**(18 - CoinDec);
        }
        //Calculate USD Value of possible Swap
        uint256 Total = SafeMath.div(
            SafeMath.mul(CoinAmountAsBonus, USDValueCoin),
            10**18
        );
        //If USD Value bigger as 10000 USD, then approve Swap (return true)
        if (Total >= 10000 * 10**18) {
            if (NFMBalanceUV2 >= 50000 * 10**18) {
                return true;
            } else {
                return false;
            }
        } else {
            //Makes no sense to swap for that small money.
            return false;
        }
    }

    //if Swap available, call doSwap()
    function doSwap() public onlyOwner returns (bool) {
        if (
            INfmUV2Pool(address(_Controller._getUV2Pool())).swapNFMforTokens(
                address(_CoinsArray[_SwapCounter]),
                50000 * 10**18
            ) == true
        ) {
            return true;
        } else {
            return false;
        }
    }

    //After Swap withdraw 90% of Coin Balance on UV2Pool Contract for Bonus.
    function withdrawToBonusSC() public onlyOwner returns (bool) {
        if(IERC20(address(_CoinsArray[_SwapCounter])).balanceOf(address(_Controller._getUV2Pool())) > 0){
            if (
                INfmUV2Pool(address(_Controller._getUV2Pool()))._getWithdraw(
                    address(_CoinsArray[_SwapCounter]),
                    address(this),
                    90,
                    true
                ) == true
            ) {
                return true;
            } else {
                return false;
            }
        }else{ 
            return false;
        }
    }

    //Make Calculation Coin vs NFM (how much will sender get for each NFM?)
    //This Funktion is only executed once each turn
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

    //Check senders Bonus amount on his NFM Balance and return Amount Coin to pay
    function _getAmountToPay(address Sender, uint256 Amount)
        internal
        virtual
        returns (uint256)
    {
        (uint256 issuedate, uint256 timestampBal, uint256 balanceAmount, bool status)=INFM(address(_Controller._getNFM())).bonusCheck(address(Sender));
        if(issuedate < INfmTimer(address(_Controller._getTimer()))._getExtraBonusAllTime() && timestampBal < INfmTimer(address(_Controller._getTimer()))._getEndExtraBonusAllTime()
        && status == true
            ){

            
        //Substract sending amount from senders balance before making calculations
        uint256 SenderBal = SafeMath.sub(
            balanceAmount,
            Amount
        );
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
        }else{
            return 0;
        }
    }

    //Set Schalter to 0 again
    function updateSchalter() public onlyOwner returns (bool) {
        Schalter = 0;
        return true;
    }

    function _getBonus(address from, uint256 amount)
        public
        virtual
        onlyOwner
        returns (bool)
    {
        if (
            _wasPaidCheck[from] ==
            INfmTimer(address(_Controller._getTimer()))
                ._getEndExtraBonusAllTime()
        ) {
            return true;
        } else {
            //First check on new Coins
            _checkOnNewPairs();
            _checkSwapCounter();

            //Make first full calculation for all Bonuses
            //Swap and calculate Bonuses for all only once on each turn
            if (Schalter == 0) {
                if (checkforLiquify() == true) {
                    doSwap();
                }
                if (withdrawToBonusSC() == true) {
                    makeCalc();
                    IsBonus=true;
                    Schalter = 1;
                }else{
                    IsBonus=false;
                    Schalter = 1;
                }
            }
            if(IsBonus==true){
            //Get Bonus Amount to pay on senders Balance
            uint256 CAmount = _getAmountToPay(from, amount);
            if(CAmount==0){
                _wasPaidCheck[from] = INfmTimer(
                        address(_Controller._getTimer())
                    )._getEndExtraBonusAllTime();
                    return true;
            }else{
                if (
                    IERC20(address(_CoinsArray[_SwapCounter])).transfer(
                        from,
                        CAmount
                    ) == true
                ) {
                    emit EBonus(
                        from,
                        address(_CoinsArray[_SwapCounter]),
                        CAmount,
                        block.timestamp
                    );
                    _wasPaidCheck[from] = INfmTimer(
                        address(_Controller._getTimer())
                    )._getEndExtraBonusAllTime();
                    return true;
                } else {
                    return true;
                }
            }
            }else{
                return true;
            }
        }
    }

    //WithdrawFunction for funds will be managed by Governance and other contracts.
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
