// SPDX-License-Identifier: MIT
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
// INFMSTAKINGRESERVEERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmStakingReserveERC20 {
    function _updateStake() external returns (bool);

    function _returnDayCounter() external view returns (uint256);

    function _returnNextUpdateTime() external view returns (uint256);

    function _returnCurrenciesArrayLength() external view returns (uint256);

    function _returnCurrencies()
        external
        view
        returns (address[] memory CurrenciesArray);

    function _returnTotalAmountPerDayForRewards(address Coin, uint256 Day)
        external
        view
        returns (uint256);

    function _returnDailyRewardPer1NFM(address Coin, uint256 Day)
        external
        view
        returns (uint256);

    function _realizePayments(
        address Coin,
        uint256 Amount,
        address Staker
    ) external returns (bool);
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
/// @title NFMStaking.sol
/// @author Fernando Viktor Seidl E-mail: viktorseidl@gmail.com
/// @notice This contract holds the entire ERC-20 Reserves of the NFM Staking Pool.
/// @dev This extension regulates project Investments.
///
///
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMStaking {
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

    //Stores all nfm locked
    uint256 public TotalDepositsOnStake;
    uint256 public generalIndex;
    address[] public CurrenciesReserveArray;
    //Struct for each deposit
    struct Staker {
        uint256 index;
        uint256 startday;
        uint256 inicialtimestamp;
        uint256 deposittimeDays;
        uint256 amountNFMStaked;
        address ofStaker;
        bool claimed;
    }

    //GIndex => Staker
    mapping(uint256 => Staker) public StakerInfo;
    //Address Staker => Array GIndexes by Staker
    mapping(address => uint256[]) public DepositsOfStaker;
    //Day => TotalDeposits
    mapping(uint256 => uint256) public TotalStakedPerDay;
    //GIndex => Coin address => 1 if paid
    mapping(uint256 => mapping(address => uint256)) public ClaimingConfirmation;
    //Gindex => Array of Claimed Rewards
    mapping(uint256 => uint256[]) public RewardsToWithdraw;

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
        generalIndex = 0;
    }

    function _updateCurrenciesList() internal returns (bool) {
        if (
            CurrenciesReserveArray.length <
            INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnCurrenciesArrayLength()
        ) {
            CurrenciesReserveArray = INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnCurrencies();
        }
        return true;
    }

    function _returnTotalDepositsOnStake() public view returns (uint256) {
        return TotalDepositsOnStake;
    }

    function _returngeneralIndex() public view returns (uint256) {
        return generalIndex;
    }

    function _returnStakerInfo(uint256 Gindex)
        public
        view
        returns (Staker memory)
    {
        return StakerInfo[Gindex];
    }

    function _returnDepositsOfDay(uint256 Day) public view returns (uint256) {
        return TotalStakedPerDay[Day];
    }

    function _returnDepositsOfStaker() public view returns (uint256[] memory) {
        return DepositsOfStaker[msg.sender];
    }

    function _returnClaimingConfirmation(address Coin, uint256 Gindex)
        public
        view
        returns (uint256)
    {
        return ClaimingConfirmation[Gindex][Coin];
    }

    function _setDepositOnDailyMap(
        uint256 Amount,
        uint256 Startday,
        uint256 Period
    ) internal returns (bool) {
        for (uint256 i = Startday; i < (Startday + Period); i++) {
            TotalStakedPerDay[i] += Amount;
        }
        return true;
    }

    function _calculateRewardPerDeposit(
        address Coin,
        uint256 RewardAmount,
        uint256 DepositAmount
    ) public view returns (uint256) {
        uint256 CoinDecimal = IERC20(address(Coin)).decimals();
        if (CoinDecimal < 18) {
            return
                SafeMath.div(
                    SafeMath.div(
                        SafeMath.mul(
                            (RewardAmount * 10**(18 - CoinDecimal)),
                            DepositAmount
                        ),
                        10**18
                    ),
                    (10**(18 - CoinDecimal))
                );
        } else {
            return
                SafeMath.div(SafeMath.mul(RewardAmount, DepositAmount), 10**18);
        }
    }

    function _calculateEarnings(
        address Coin,
        uint256 StakedAmount,
        uint256 StartDay,
        uint256 Period
    ) public view returns (uint256) {
        uint256 Earned;
        for (uint256 i = StartDay; i < (StartDay + Period); i++) {
            Earned += _calculateRewardPerDeposit(
                Coin,
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._returnDailyRewardPer1NFM(Coin, i),
                StakedAmount
            );
        }
        return Earned;
    }

    function deposit(uint256 Amount, uint256 Period) public returns (bool) {
        if (
            INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnNextUpdateTime() < block.timestamp
        ) {
            require(
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._updateStake() == true,
                "NU"
            );
        }
        _updateCurrenciesList();
        require(
            IERC20(address(_Controller._getNFM())).transferFrom(
                msg.sender,
                address(this),
                Amount
            ) == true,
            "<A"
        );
        require(
            _setDepositOnDailyMap(
                Amount,
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._returnDayCounter(),
                Period
            ) == true,
            "NDD"
        );
        StakerInfo[generalIndex] = Staker(
            generalIndex,
            INfmStakingReserveERC20(
                address(_Controller._getNFMStakingTreasuryERC20())
            )._returnDayCounter(),
            block.timestamp,
            Period,
            Amount,
            msg.sender,
            false
        );
        TotalDepositsOnStake += Amount;
        DepositsOfStaker[msg.sender].push(generalIndex);
        generalIndex++;
        return true;
    }

    function _claimRewards(uint256 Index) public returns (bool) {
        require(StakerInfo[Index].ofStaker == msg.sender, "oO");
        require(
            StakerInfo[Index].inicialtimestamp +
                (300 * StakerInfo[Index].deposittimeDays) <
                block.timestamp,
            "CNT"
        );
        require(StakerInfo[Index].claimed == false, "AC");
        for (uint256 i = 0; i < CurrenciesReserveArray.length; i++) {
            RewardsToWithdraw[Index].push(
                _calculateEarnings(
                    CurrenciesReserveArray[i],
                    StakerInfo[Index].amountNFMStaked,
                    StakerInfo[Index].startday,
                    StakerInfo[Index].deposittimeDays
                )
            );
        }
        StakerInfo[Index].claimed = true;
        return true;
    }

    function _withdrawDepositAndRewards(uint256 Index) public returns (bool) {
        require(ClaimingConfirmation[Index][_Controller._getNFM()] == 0, "AW");
        require(
            StakerInfo[Index].inicialtimestamp +
                (300 * StakerInfo[Index].deposittimeDays) <
                block.timestamp,
            "CNT"
        );
        require(StakerInfo[Index].claimed == true, "AC");
        require(StakerInfo[Index].ofStaker == msg.sender, "oO");
        for (uint256 i = 0; i < RewardsToWithdraw[Index].length; i++) {
            require(
                INfmStakingReserveERC20(
                    address(_Controller._getNFMStakingTreasuryERC20())
                )._realizePayments(
                        CurrenciesReserveArray[i],
                        RewardsToWithdraw[Index][i],
                        msg.sender
                    ) == true,
                "NP"
            );
            ClaimingConfirmation[Index][CurrenciesReserveArray[i]] = 1;
        }
        require(
            IERC20(address(_Controller._getNFM())).transfer(
                msg.sender,
                StakerInfo[Index].amountNFMStaked
            ) == true,
            "NDP"
        );
        TotalDepositsOnStake -= StakerInfo[Index].amountNFMStaked;
        return true;
    }
}
