/**
 *Submitted for verification at polygonscan.com on 2022-08-26
 Polygon Mainnet: 0xE6d69e99FD18fcdA9a29Dcdc39A561Ed08b9FF39
*/

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
/// @title NFMDistribute.sol
/// @author Fernando Viktor Seidl E-mail: viktorseidl@gmail.com
/// @notice This contract is responsible for the distribution of the Developer Funds to all participants.
/// @dev This extension includes all necessary functionalities for distributing the Funds.
///
///
///
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract NFMDistribute {
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
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    address[] _PArray       => Contains the Distribution Array
    uint256 Index           => Contains the upcoming index 
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address[] public _PArray;

    mapping(address => bool) public _isP_allowed;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MODIFIER
    onlyOwner       => Only Controller listed Contracts and Owner can interact with this contract.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier onlyOwner() {
        require(_Owner == msg.sender, "oO");
        require(msg.sender != address(0), "0A");
        _;
    }

    constructor(address Controller) {
        _Owner = msg.sender;
        INfmController Cont = INfmController(Controller);
        _Controller = Cont;
        _SController = Controller;
    }

    function allowOrblockP(address Person) public onlyOwner returns (bool) {
        if (_isP_allowed[Person] == true) {
            _isP_allowed[Person] = false;
        } else {
            _isP_allowed[Person] = true;
        }
        return true;
    }

    function showAddressArray()
        public
        view
        onlyOwner
        returns (address[] memory Array)
    {
        return _PArray;
    }

    function addP(address Person) public onlyOwner returns (bool) {
        _PArray.push(Person);
        _isP_allowed[Person] = true;
        return true;
    }

    function makecalculationsAndSendNFM(address Coin)
        public
        onlyOwner
        returns (bool)
    {
        uint256 balanceCoin = IERC20(address(Coin)).balanceOf(address(this));
        uint256 allcount = 0;
        uint256 Pcount = 0;
        uint256 i = 0;
        for (i; i < _PArray.length; i++) {
            if (_isP_allowed[_PArray[i]] == true) {
                Pcount++;
            }
        }
        i = 0;
        uint256 payCount = 0;
        uint256 Ppercent = SafeMath.div(100, Pcount);
        uint256 share = SafeMath.div(SafeMath.mul(balanceCoin, Ppercent), 100);
        for (i; i < _PArray.length; i++) {
            if (payCount == Pcount - 1) {
                if (_isP_allowed[_PArray[i]] == true) {
                    IERC20(address(Coin)).transfer(
                        _PArray[i],
                        SafeMath.sub(balanceCoin, allcount)
                    );
                }
            } else {
                if (_isP_allowed[_PArray[i]] == true) {
                    IERC20(address(Coin)).transfer(_PArray[i], share);
                    allcount += share;
                    payCount++;
                }
            }
        }
        if (IERC20(address(Coin)).balanceOf(address(this)) == 0) {
            return true;
        } else {
            return false;
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_getWithdraw(address Coin,address To,uint256 amount,bool percent) returns (bool);
    This function is used by NFMLiquidity and NFM Swap to execute transactions.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _getWithdraw(
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
