/**
 *Submitted for verification at polygonscan.com on 2022-11-14
 Polygon Mainnet: 0x2A8c7a45983b69eA1104e7B5d38b08e4EE6e0625
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IAFTCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IAFTController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getNFMController() external pure returns (address);

    function _getAFT() external view returns (address);

    function _getDaoReserveERC20() external pure returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INFMController {
    function _getNFM() external view returns (address);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IAFT
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IAFT {
    function balanceOf(address account) external view returns (uint256);

    function _returnTokenReference(address account)
        external
        view
        returns (uint256, uint256);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function _mint(address to) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFM
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INFM {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IDAOReserveERC20
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IDAOReserveERC20 {
    function withdraw(
        address Coin,
        address To,
        uint256 amount,
        bool percent
    ) external returns (bool);
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title AFTExchange.sol
/// @author Fernando Viktor Seidl E-mail: viktorseidl@gmail.com
/// @notice This contract is responsible for the exchange of NFM for AFT. The exchange is and will only be possible via this exchange. This ensures a
///         fixed exchange rate between AFT and NFM, which is always 10000NFM = 1 AFT.
/// @dev    Since the AFT has an internal algorithm that prohibits having more than 1 AFT on one address, the DaoReserve
///         contract was whitelisted for the exchange contract. Only this address has the right to hold more than 1 AFT.
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract AFTExchange {
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //EXCHANGE STRUCT
    /*
    Contains all Exchanges Information
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    struct Exchanges {
        address _Applier;
        uint256 _Type;
        uint256 _AFTid;
        uint256 _TimeAction;
        address TxValue;
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //VARIABLES
    /*
    @ exchanges = Exchange Counter
    @ allExchanges = Array with all Exchanges
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    uint256 private _exchangesCount = 0;
    Exchanges[] private allExchanges;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Owner;
    uint256 _locked = 0;
    IAFTController private _AFTController;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    MAPPINGS
    ExchangeID(uint256 => Exchanges)          Exchange Counter => Exchange Struct.
    */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(uint256 => Exchanges) private ExchangeID;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /* 
    MODIFIER
    reentrancyGuard       => Safety agains Reentrancy attacks.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    modifier reentrancyGuard() {
        require(_locked == 0);
        _locked = 1;
        _;
        _locked = 0;
    }

    constructor(address AFTCon) {
        _Owner = msg.sender;
        IAFTController _AFTCo = IAFTController(address(AFTCon));
        _AFTController = _AFTCo;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ storeEX(address Aktion,uint256 Type,uint256 AFTId,address TX)
    Store Exchange Information
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function storeEX(
        address Aktion,
        uint256 Type, //1 is buy 2 is sold
        uint256 AFTId,
        address TX
    ) public returns (bool) {
        require(msg.sender != address(0), "0A");
        require(
            _AFTController._checkWLSC(address(_AFTController), msg.sender) ==
                true,
            "oO"
        );
        ExchangeID[_exchangesCount] = Exchanges(
            Aktion,
            Type,
            AFTId,
            block.timestamp,
            TX
        );
        allExchanges.push(ExchangeID[_exchangesCount]);
        _exchangesCount++;
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnallEX( )
    Return all Exchanges made
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnallEX() public view returns (Exchanges[] memory) {
        return allExchanges;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ returnEXOnID(uint256 ExId)
    Return Exchange on ID
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function returnEXOnID(uint256 ExId) public view returns (Exchanges memory) {
        return ExchangeID[ExId];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ exchangeMyNFM()
    Exchange NFM against AFT. The user must have previously given the contract an allowance of 10000 NFM.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function exchangeMyNFM() public reentrancyGuard returns (bool) {
        address NFMCont = _AFTController._getNFMController();
        require(
            INFM(address(INFMController(address(NFMCont))._getNFM())).allowance(
                msg.sender,
                address(this)
            ) == 10000 * 10**18,
            "<A"
        );
        require(
            IAFT(address(_AFTController._getAFT())).totalSupply() < 1000000 ||
                IAFT(address(_AFTController._getAFT())).balanceOf(
                    address(_AFTController._getDaoReserveERC20())
                ) >
                0,
            "NE"
        );
        if (
            IAFT(address(_AFTController._getAFT())).balanceOf(
                address(_AFTController._getDaoReserveERC20())
            ) > 0
        ) {
            //no new issue, just exchange existing aft agains nfm
            require(
                INFM(address(INFMController(address(NFMCont))._getNFM()))
                    .transferFrom(
                        msg.sender,
                        address(_AFTController._getDaoReserveERC20()),
                        10000 * 10**18
                    ) == true,
                "RA"
            );
            require(
                IDAOReserveERC20(address(_AFTController._getDaoReserveERC20()))
                    .withdraw(
                        address(_AFTController._getAFT()),
                        msg.sender,
                        1,
                        false
                    ) == true,
                "RD"
            );
            (, uint256 Tref) = IAFT(address(_AFTController._getAFT()))
                ._returnTokenReference(msg.sender);
            require(storeEX(msg.sender, 1, Tref, tx.origin) == true, "NS");
        } else {
            //new issue
            require(
                INFM(address(INFMController(address(NFMCont))._getNFM()))
                    .transferFrom(
                        msg.sender,
                        address(_AFTController._getDaoReserveERC20()),
                        10000 * 10**18
                    ) == true,
                "RA"
            );
            require(
                IAFT(address(_AFTController._getAFT()))._mint(msg.sender) ==
                    true,
                "NT"
            );
            (, uint256 Tref) = IAFT(address(_AFTController._getAFT()))
                ._returnTokenReference(msg.sender);
            require(storeEX(msg.sender, 1, Tref, tx.origin) == true, "NS");
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @ exchangeMyAFT()
    Exchange AFT against NFM. The user must have previously given the contract an allowance of 1 AFT.
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function exchangeMyAFT() public reentrancyGuard returns (bool) {
        address NFMCont = _AFTController._getNFMController();
        require(
            IAFT(address(_AFTController._getAFT())).allowance(
                msg.sender,
                address(this)
            ) == 1,
            "<A"
        );
        require(
            INFM(address(INFMController(address(NFMCont))._getNFM())).balanceOf(
                address(_AFTController._getDaoReserveERC20())
            ) >= 10000 * 10**18,
            "NE"
        );

        (, uint256 Tref) = IAFT(address(_AFTController._getAFT()))
            ._returnTokenReference(msg.sender);
        require(
            IAFT(address(_AFTController._getAFT())).transferFrom(
                msg.sender,
                address(_AFTController._getDaoReserveERC20()),
                1
            ) == true,
            "RA"
        );
        require(
            IDAOReserveERC20(address(_AFTController._getDaoReserveERC20()))
                .withdraw(
                    address(INFMController(address(NFMCont))._getNFM()),
                    msg.sender,
                    10000 * 10**18,
                    false
                ) == true,
            "RD"
        );
        require(storeEX(msg.sender, 2, Tref, tx.origin) == true, "NS");
        return true;
    }
}
