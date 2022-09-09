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
// INFMSTAKING
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmStaking {
    function _returnDepositsOfDay(uint256 Day) external view returns (uint256);
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

contract NFMStakeReserveERC20 {
    using SafeMath for uint256;

    INfmController private _Controller;
    address private _Owner;
    address private _SController;

    //CONTRACT VARIABLE
    uint256 public DayCounter = 0;
    uint256 public Time24Hours = 300;
    uint256 public NextUpdateTime;

    bool public inUpdate = false;
    address[] public Currencies;
    uint256 public CurrenciesUpdateCounter = 0;
    //Coin => DayCounter => Total Amount per Day for rewards.
    mapping(address => mapping(uint256 => uint256))
        public TotalAmountPerDayForRewards; //Gesamt Verteilungsbetrag für diesen Tag
    //Coin => DayCounter => Amount per Day for 1 NFM.
    mapping(address => mapping(uint256 => uint256)) public DailyRewardPer1NFM; //Verteilungsbetrag für 1 NFM an diesen Tag
    //Coin => TotalAmount of Rewards all Time - Payouts
    mapping(address => uint256) public TotalRewardSupply;
    //Coin => Total of Rewards paid
    mapping(address => uint256) public TotalRewardsPaid;
    //Modifier
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
        NextUpdateTime = block.timestamp + 300;
        Currencies.push(Cont._getNFM());
    }

    function _addCurrencies(address Coin) public onlyOwner returns (bool) {
        Currencies.push(Coin);
        return true;
    }

    function _returnBalanceContract(address Currency)
        public
        view
        returns (uint256)
    {
        return IERC20(address(Currency)).balanceOf(address(this));
    }

    function _returnDayCounter() public view returns (uint256) {
        return DayCounter;
    }

    function _returnNextUpdateTime() public view returns (uint256) {
        return NextUpdateTime;
    }

    function _returnCurrencies()
        public
        view
        returns (address[] memory CurrenciesArray)
    {
        return Currencies;
    }

    function _returnCurrenciesArrayLength() public view returns (uint256) {
        return Currencies.length;
    }

    function _returnTotalAmountPerDayForRewards(address Coin, uint256 Day)
        public
        view
        returns (uint256)
    {
        return TotalAmountPerDayForRewards[Coin][Day];
    }

    function _returnDailyRewardPer1NFM(address Coin, uint256 Day)
        public
        view
        returns (uint256)
    {
        return DailyRewardPer1NFM[Coin][Day];
    }

    function _returnTotalRewardSupply(address Coin)
        public
        view
        returns (uint256)
    {
        return TotalRewardSupply[Coin];
    }

    function _returnTotalRewardsPaid(address Coin)
        public
        view
        returns (uint256)
    {
        return TotalRewardsPaid[Coin];
    }

    function _remainingFromDayAgoRewards(address Currency, uint256 Day)
        public
        view
        returns (uint256)
    {
        uint256 CoinDecimal = IERC20(address(Currency)).decimals();
        if (CoinDecimal < 18) {
            return
                SafeMath.sub(
                    TotalAmountPerDayForRewards[Currency][Day],
                    SafeMath.div(
                        SafeMath.div(
                            SafeMath.mul(
                                INfmStaking(_Controller._getNFMStaking())
                                    ._returnDepositsOfDay(Day),
                                (DailyRewardPer1NFM[Currency][Day] *
                                    10**(18 - CoinDecimal))
                            ),
                            10**18
                        ),
                        (10**(18 - CoinDecimal))
                    )
                );
        } else {
            return
                SafeMath.sub(
                    TotalAmountPerDayForRewards[Currency][Day],
                    SafeMath.div(
                        SafeMath.mul(
                            INfmStaking(_Controller._getNFMStaking())
                                ._returnDepositsOfDay(Day),
                            DailyRewardPer1NFM[Currency][Day]
                        ),
                        10**18
                    )
                );
        }
    }

    function _calculateRewardPerNFM(address Currency, uint256 Day)
        public
        view
        returns (uint256)
    {
        uint256 CoinDecimal = IERC20(address(Currency)).decimals();
        if (CoinDecimal < 18) {
            //Totalamountperdayforrewards divided by totalssupply of NFM Contract
            return
                SafeMath.div(
                    SafeMath.div(
                        (
                            (TotalAmountPerDayForRewards[Currency][Day] *
                                10**(18 - CoinDecimal) *
                                10**18)
                        ),
                        IERC20(address(_Controller._getNFM())).totalSupply()
                    ),
                    (10**(18 - CoinDecimal))
                );
        } else {
            return
                SafeMath.div(
                    (TotalAmountPerDayForRewards[Currency][Day] * 10**18),
                    IERC20(address(_Controller._getNFM())).totalSupply()
                );
        }
    }

    function _updateStake() public onlyOwner returns (bool) {
        require(NextUpdateTime < block.timestamp || inUpdate == true, "NT");
        if (NextUpdateTime < block.timestamp) {
            DayCounter++;
            NextUpdateTime = NextUpdateTime + Time24Hours;
            inUpdate = true;
        }
        for (uint256 i = 0; i < Currencies.length; i++) {
            TotalAmountPerDayForRewards[Currencies[i]][DayCounter] =
                (_returnBalanceContract(Currencies[i]) -
                    TotalRewardSupply[Currencies[i]]) +
                _remainingFromDayAgoRewards(Currencies[i], DayCounter - 1);
            TotalRewardSupply[Currencies[i]] = _returnBalanceContract(
                Currencies[i]
            );
            DailyRewardPer1NFM[Currencies[i]][
                DayCounter
            ] = _calculateRewardPerNFM(Currencies[i], DayCounter);
        }
        return true;
    }

    function _realizePayments(
        address Coin,
        uint256 Amount,
        address Staker
    ) public onlyOwner returns (bool) {
        require(msg.sender != address(0), "0A");
        require(Staker != address(0), "0A");
        if (Amount > 0) {
            if (IERC20(address(Coin)).transfer(Staker, Amount) == true) {
                TotalRewardSupply[Coin] -= Amount;
                TotalRewardsPaid[Coin] += Amount;
            }
        }
        return true;
    }
}
