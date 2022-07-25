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
    function _getExtraBonusAirdropTime() external view returns (uint256);

    function _getEndExtraBonusAirdropTime() external view returns (uint256);
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
///         -   Every 6 days, profit distributions are made available to this protocol in various currencies by the IDO Launchpad
///             in different currencies, also non IDO Tokens can be made available.
///         -   As soon as the amounts are available, a amount per NFM will be calculated by the protocol. The calculation is as follows:
///             Amount available for distribution / NFM total supply = X
///         -   The distribution happens automatically during the transaction. As soon as an NFM owner makes a transfer within the bonus window,
///             the bonus will automatically be calculated on his NFM balance and credited to his account. The NFM owner is informed about upcoming
///             special payments via the homepage. A prerequisite for participation in the bonus payments is a minimum balance of 150 NFM on the
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
    uint256 lastRoundCounter     => Contains the initial index or the starting index during the event
    uint256 nextRoundCounter    => Contains the last index reached, or the final index within the event
    uint256 Schalter                     => Regulates the execution of the one time calculations for the coming airdrop
    address[] AirdropCoins          => Contains all token addresses of the approved airdrops
    struct Airdrop                          => Contains important information for checking non-ido airdrops
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    struct Airdrop {
        string Webpage;
        string Description;
        string Logo;
    }

    uint256 public AirdropNum = 0; //Actual Airdrop Number
    uint256 public AirdropNextNumAllowance = 0; //Airdrop Number for allowances (its only 3 Coins allowed per Airdrops. Once 3 Coins are reached the AirdropNextNumAllowance will increase
    mapping(uint256 => address[]) public _AirdropCoinsOnAirdropNumAllowed; //Airdrop Number => 3 addresses per Airdrop allowed
    mapping(address => mapping(address => bool)) public _CoinsStatus; //Owner => CoinAddress => true if allowed or false if denied
    mapping(address => mapping(address => bool)) public _allCoinsOpenRequest; //CoinAddress => Owner => true if accepted or false if open
    mapping(address => Airdrop) public _AirdropInfo; // Coin Address => Struct
    mapping(address => uint256) public _wasPaidCheck; // Coin  Address => Time End Event
    mapping(address => uint256) public _totalBalCoin; // Coin Address => Full Balance Coin
    mapping(address => uint256) public _CoinforNFM; // Coin Address => Coins for 1 NFM calculations
    address[] public AllCoinsArray;
    uint256 public _locked = 0;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTRACT EVENTS
    Airdrops(address receiver, address Coin, uint256 amount, uint256 timer);
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    event Airdrops(
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
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    reentrancyGuard       => secures the protocol against reentrancy attacks
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier reentrancyGuard() {
        require(_locked == 0);
        _locked = 1;
        _;
        _locked = 0;
    }

    constructor(address Controller) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _SController = Controller;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_checkPayment(address sender) returns (uint256);
    This function returns the timestamp of the address. If the timestamp is set to the end of the event, then the sender has 
    already received their airdrop.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _checkPayment(address sender) public view returns (uint256) {
        return _wasPaidCheck[sender];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_showAirdropToken() returns (address);
    This function returns the Token address of an airdrop.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _showAirdropToken()
        public
        view
        returns (
            address,
            bool,
            Airdrop memory
        )
    {
        address Coin = _CoinsStatus[msg.sender];
        return (Coin, _CoinsStatus[msg.sender][Coin], _AirdropInfo[Coin]);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_showUpComingAirdrops() returns (uint256);
    This function gives the index number of the last airdrops paid out. This allows upcoming airdrops to be displayed.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _showUpComingAirdrops()
        public
        view
        returns (address[] memory Arr)
    {
        if (_AirdropCoinsOnAirdropNumAllowed[AirdropNum + 1].length == 2) {
            return _AirdropCoinsOnAirdropNumAllowed[AirdropNum + 1];
        } else {
            return [];
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_showAirdropArray() returns (addresses Array);
    This function returns the all successful airdrop token addresses.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _showAirdropArray() public view returns (address[] memory Arr) {
        return AllCoinsArray;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_showAirdropInfo(address Coin) returns (Struct);
    This function returns the all Information about a provided airdrop.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _showAirdropInfo(address Coin)
        public
        view
        returns (Airdrop memory)
    {
        return _AirdropInfo[Coin];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_updateAirdropInfo(address Coin, string memory Website, string memory Tokendescription,string memory Tokenlogo) returns (bool);
    This function updates Information about the Airdrop like token logo, webpage, description
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _updateAirdropInfo(
        address Coin,
        string memory Website,
        string memory Tokendescription,
        string memory Tokenlogo
    ) public returns (bool) {
        require(_CoinsStatus[msg.sender] == Coin, "oO");
        _AirdropInfo[Coin] = Airdrop(Website, Tokendescription, Tokenlogo);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_confirmPayment(address receiver) returns (bool);
    This function returns the timestamp of the address. If the timestamp is set to the end of the event, then the sender has 
    already received their airdrop.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _confirmPayment(address receiver) public onlyOwner returns (bool) {
        _wasPaidCheck[receiver] = INfmTimer(_Controller._getTimer())
            ._getEndExtraBonusAirdropTime();
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_confirmWL(address Coin) returns (bool);
    This function This function is responsible for whitelisting the registered airdrops. All non-IDO airdrops need to be 
    pre-checked against fraud
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _confirmWL(address Coin) public onlyOwner returns (bool) {
        address CoinOwner = _allCoinsOpenRequest[Coin];
        _CoinsStatus[CoinOwner][Coin] = true;
        _allCoinsOpenRequest[Coin][CoinOwner] = true;
        if (
            _AirdropCoinsOnAirdropNumAllowed[_AirdropCoinsOnAirdropNumAllowed]
                .length == 3
        ) {
            _AirdropCoinsOnAirdropNumAllowed++;
            _AirdropCoinsOnAirdropNumAllowed[_AirdropCoinsOnAirdropNumAllowed]
                .push(Coin);
        } else {
            _AirdropCoinsOnAirdropNumAllowed[_AirdropCoinsOnAirdropNumAllowed]
                .push(Coin);
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_requestWLAirdrop(address Coin) returns (bool);
    This function registers the listing. In the case of a non-IDO, the listing will only be approved after the Dao members 
    have checked and approved it. Important: Only Coins with minimum 6 decimals are allowed for listing
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _requestWLAirdrop(
        address Coin,
        string memory Website,
        string memory Tokendescription,
        string memory Tokenlogo
    ) public returns (bool) {
        if (IERC20(address(Coin)).decimals() < 6) {
            return false;
        } else {
            _CoinsStatus[msg.sender][Coin] = false;
            _allCoinsOpenRequest[Coin][msg.sender] = false;
            _AirdropInfo[Coin] = Airdrop(Website, Tokendescription, Tokenlogo);
            AllCoinsArray.push(Coin);

            return true;
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_approveDeposit(address Coin, uint256 Amount) returns (bool);
    This function authorizes the delivery of tokens for the airdrop. The minimum amount for an airdrop is 1000 tokens
    For the execution of the function, the owner must have approved the amount in advance.
     */
    //-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _approveDeposit(address Coin, uint256 Amount)
        public
        returns (bool)
    {
        if (
            _allCoinsOpenRequest[Coin][msg.sender] == true &&
            IERC20(address(Coin)).allowance(msg.sender, address(this)) ==
            Amount &&
            IERC20(address(Coin)).allowance(msg.sender, address(this)) >=
            1000 * 10**IERC20(address(Coin)).decimals() &&
        ) {
            require(
                IERC20(address(Coin)).transferFrom(
                    msg.sender,
                    address(this),
                    Amount
                ) == true,
                "<A"
            );
            _totalBalCoin[Coin] += Amount;
            return true;
        }
        return false;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @makeCalc(address Coin) returns (bool);
    This function is executed at the beginning of an Airdrop event. It calculates the bonus amount 
    that is paid out for 1 NFM
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function makeCalc(address Coin) internal virtual returns (bool) {
        address CoinOwner = _allCoinsOpenRequest[Coin];
        if (
            _totalBalCoin[Coin] > 0 &&
            _allCoinsOpenRequest[Coin][CoinOwner] == true
        ) {
            //Get actual TotalSupply NFM
            uint256 NFMTotalSupply = IERC20(address(_Controller._getNFM()))
                .totalSupply();
            //Get full Amount of Coin
            uint256 CoinTotal = IERC20(address(Coin)).balanceOf(address(this));
            //Get Coindecimals for calculations
            uint256 CoinDecimals = IERC20(address(Coin)).decimals();
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
            _CoinforNFM[Coin] = CoinvsNFM;
            return true;
        }
        return false;
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
    function _getAmountToPay(address Sender, address Coin)
        internal
        virtual
        returns (uint256)
    {
        uint256 balanceAmount = INFM(address(_Controller._getNFM())).bonusCheck(
            address(Sender)
        );
        //Calculate Bonus amount for sender.
        uint256 CoinDecimals = IERC20(address(Coin)).decimals();
        uint256 CoinEighteen;
        if (CoinDecimals < 18) {
            //if smaller than 18 Digits, convert to 18 digits
            CoinEighteen = _CoinforNFM[Coin] * 10**(18 - CoinDecimals);
        }
        uint256 PayAmount = SafeMath.div(
            SafeMath.mul(balanceAmount, CoinEighteen),
            10**18
        );
        if (CoinDecimals < 18) {
            //if smaller than 18 Digits, convert to Coin digits
            PayAmount = SafeMath.div(PayAmount, 10**(18 - CoinDecimals));
        }
        return PayAmount;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @updateSchalter() returns (bool);
    This function updates the switcher. This is used to separate logic that has to be executed once for the event from 
    the rest of the logic
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function updateSchalter() public onlyOwner returns (bool) {
        Schalter = 0;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @startAirdropLogic() returns (bool);
    This function creates all calculations for the upcoming airdrop once. A maximum of 3 different tokens in one payout are possible.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _startAirdropLogic() public onlyOwner returns (bool) {
        if (allCoinsCounter > 0) {
            if (lastRoundCounter == allCoinsCounter) {
                //No Airdrops available
                return false;
            } else {
                lastRoundCounter = nextRoundCounter;
                uint256 nextindexes = lastRoundCounter + 3;
                uint256 calcounter = lastRoundCounter;
                if (nextindexes > allCoinsCounter) {
                    //take allCoinsCounter as indexer
                    nextRoundCounter = allCoinsCounter;
                    while (calcounter != allCoinsCounter) {
                        calcounter++;
                        if (
                            _showAirdropStatus(_allIdoCoins[calcounter]) == true
                        ) {
                            //Make calculations
                            if (makeCalc(_allIdoCoins[calcounter]) == false) {
                                _CoinforNFM[_allIdoCoins[calcounter]] = 0;
                            }
                        }
                    }
                    return true;
                } else {
                    //take nextindexes as indexer
                    nextRoundCounter = nextindexes;
                    while (calcounter != nextindexes) {
                        calcounter++;
                        if (
                            _showAirdropStatus(_allIdoCoins[calcounter]) == true
                        ) {
                            //Make calculations
                            if (makeCalc(_allIdoCoins[calcounter]) == false) {
                                _CoinforNFM[_allIdoCoins[calcounter]] = 0;
                            }
                        }
                    }
                    return true;
                }
            }
        } else {
            //No Airdrops available
            return false;
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getAirdrop(address Sender) returns (bool);
    This function executes the payout of the airdrop. A maximum of 3 payouts are allowed if there are enough airdrops.
    In the first step, all necessary preliminary calculations are made and the switch is activated
    In the second step, the payments are made to the transaction participants
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getAirdrop(address Sender)
        public
        onlyOwner
        reentrancyGuard
        returns (bool)
    {
        if (AirdropCoins.length > nextRoundCounter + 3) {
            threeAirdrops = true;
            if (Schalter == 0) {
                if (_startAirdropLogic() == true) {
                    Schalter = 1;
                    return true;
                }
                return false;
            } else {
                ///     lastRoundCounter contains inicializing index and nextRoundCounter contains final index (3 Airdrop Tokens maximum)
                uint256 calcounter = lastRoundCounter;
                while (calcounter != nextRoundCounter) {
                    calcounter++;
                    ///     Check if Airdrop is whitelisted
                    if (_showAirdropStatus(_allIdoCoins[calcounter]) == true) {
                        ///     Check if value per NFM is bigger as zero (then Airdrop exists)
                        if (_CoinforNFM[_allIdoCoins[calcounter]] > 0) {
                            ///     If Value per NFM exists, payout can be made
                            uint256 airdropAmount = _getAmountToPay(
                                Sender,
                                address(_allIdoCoins[calcounter])
                            );
                            IERC20(address(_allIdoCoins[calcounter])).transfer(
                                Sender,
                                airdropAmount
                            );
                            //Save an payout event on each Airdrop
                            emit Airdrops(
                                Sender,
                                _allIdoCoins[calcounter],
                                airdropAmount,
                                block.timestamp
                            );
                        }
                    }
                }
                //Update Timestamp as Paid on receiver
                _wasPaidCheck[Sender] = INfmTimer(_Controller._getTimer())
                    ._getEndExtraBonusAirdropTime();
                return true;
            }
        }
        threeAirdrops = false;
        return false;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_returnPayoutCounter()  returns (uint256);
    This function returns the withdraw counter.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnPayoutCounter() public view returns (uint256) {
        return PayOutCounter;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_resetPayOutCounter()  returns (bool);
    This function reset the withdraw counter.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _resetPayOutCounter() public onlyOwner returns (bool) {
        PayOutCounter = 1;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getWithdraw(uint256 _index, address StakeReserve, address Treasury)  returns (bool);
    This function is responsible for the distribution of the remaining bonus payments that have not been redeemed. The remaining 
    balance is split between the staking pool and treasury.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getWithdraw(
        uint256 _index,
        address Stake,
        address Tresury
    ) public onlyOwner returns (bool) {
        if (threeAirdrops == true) {
            if (_showAirdropStatus(_allIdoCoins[_index]) == true) {
                uint256 CoinAmount = IERC20(_allIdoCoins[_index]).balanceOf(
                    address(this)
                );
                //makeCalcs on Percentatge
                uint256 AmountToSend = SafeMath.div(
                    SafeMath.mul(CoinAmount, 50),
                    100
                );
                IERC20(address(_allIdoCoins[_index])).transfer(
                    Stake,
                    AmountToSend
                );
                IERC20(address(_allIdoCoins[_index])).transfer(
                    Tresury,
                    (CoinAmount - AmountToSend)
                );
                PayOutCounter++;
                return true;
            } else {
                PayOutCounter++;
                return true;
            }
        } else {
            PayOutCounter++;
            return true;
        }
    }
}
