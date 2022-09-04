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

    function _getNFMStaking() external pure returns (address);

    function _getNFMStakingTreasuryERC20() external pure returns (address);

    function _getNFMStakingTreasuryETH() external pure returns (address);
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
/// @title NFMStakingTreasuryERC20.sol
/// @author Fernando Viktor Seidl E-mail: viktorseidl@gmail.com
/// @notice This contract holds the entire ERC-20 Reserves of the NFM Staking Pool.
/// @dev This extension regulates project Investments.
///
///
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMStakingTreasuryERC20 {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    INfmController private _Controller;
    address private _Owner;
    address private _SController;
    uint256 private _locked = 0;
    //Counts everyday + 1
    uint256 public TotalDayCount = 0;
    //indicates timestamp for next day
    uint256 public Timecounter;
    //Array of all currencies allowed
    address[] public Currencies;
    //Counts last updated Currency Index
    uint256 public CurrenciesCount;
    // Coinaddress => DayCount => Amounttotalavailable for Reward this day Day
    mapping(address => mapping(uint256 => uint256)) public DailyTotalAvailable;
    // Coinaddress => DayCount => rewardPerDayPer1NFM
    mapping(address => mapping(uint256 => uint256))
        public DailyrewardCoinperNFM;
    // Coinaddress => Totalsupply of coins all entries - payouts
    mapping(address => uint256) public TotalsupplyCoinsRewardsandNFM;

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /* 
    mapping(address => mapping(uint256 => uint256))            => Staker - Daycounter - days to live
    mapping(address => mapping(uint256 => bool))            => Staker - Daycounter - claimed status
    mapping(address => mapping(uint256 => uint256))            => Staker - Daycounter - deposited amount
    mapping(address => mapping(index => Struct[Daycount, days to live, status, amount]))            => Staker - Daycounter - deposited amount

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
    reentrancyGuard       => Security against Reentrancy attacks
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier reentrancyGuard() {
        require(_locked == 0);
        _locked = 1;
        _;
        _locked = 0;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    EVENT
    Received(address caller, uint amount)       => Tracks Matic deposits
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    constructor(address Controller) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _SController = Controller;
        Timecounter = block.timestamp + (3600 * 24);
        Currencies.push(address(Cont._getNFM()));
        CurrenciesCount++;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    Add new currencies
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function addCurrency(address Currency) public onlyOwner returns (bool) {
        Currencies.push(Currency);
        CurrenciesCount++;
    }

    function returntime() public view returns (uint256, uint256) {
        return (Timecounter, TotalDayCount);
    }

    function updateBalancesStake() public onlyOwner returns (bool) {
        require(Timecounter < block.timestamp, "NT");
        TotalDayCount++;
        Timecounter = Timecounter + (3600 * 24);
        uint256 balanceContract;
        for (uint256 i = 0; i < Currencies.length; i++) {
            balanceContract = IERC20(address(Currencies[i])).balanceOf(
                address(this)
            );
            if (
                balanceContract > TotalsupplyCoinsRewardsandNFM[Currencies[i]]
            ) {
                DailyTotalAvailable[Currencies[i]][Timecounter] = SafeMath.sub(
                    balanceContract,
                    TotalsupplyCoinsRewardsandNFM[Currencies[i]]
                );
                uint256 cdecimal = IERC20(address(Currencies[i])).decimals();
                if (cdecimal < 18) {
                    balanceContract = (DailyTotalAvailable[Currencies[i]][
                        Timecounter
                    ] *
                        10**(18 - cdecimal) *
                        10**18);
                }
                balanceContract = SafeMath.div(
                    balanceContract,
                    IERC20(address(_Controller._getNFM())).totalSupply()
                );
                if (cdecimal < 18) {
                    balanceContract = SafeMath.div(
                        balanceContract,
                        10**(18 - cdecimal)
                    );
                }
                DailyrewardCoinperNFM[Currencies[i]][
                    Timecounter
                ] = balanceContract;
                TotalsupplyCoinsRewardsandNFM[
                    Currencies[i]
                ] += DailyTotalAvailable[Currencies[i]][Timecounter];
            }
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @withdraw(address Coin, address To, uint256 amount, bool percent) returns (bool);
    This function is responsible for the withdraw.
    There are 3 ways to initiate payouts. Either as a fixed amount, the full amount or a percentage of the balance.
    Fixed Amount    =>   Address Coin, Address Receiver, Fixed Amount, false
    Total Amount     =>   Address Coin, Address Receiver, 0, false
    A percentage     =>   Address Coin, Address Receiver, percentage, true
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function withdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) public onlyOwner returns (bool) {
        require(To != address(0), "0A");
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
