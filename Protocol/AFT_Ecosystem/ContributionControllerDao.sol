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
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);

    function _getContributor() external pure returns (address);

    function _getNFM() external view returns (address);
}
interface INFMContributor {
    struct Project{
        uint256 projectID;
        string projecttyp;
        string projectname;
        string projectdesc;        
        address contributor;
        uint256 expectedrewardNFM;
        uint256 startdate;
        uint256 enddate;
        bool   projectstatus;
    }
    function _returnProjectNotify(uint256 pr) external view returns(string memory output);
    function _returnProjectInfo(uint256 prinfo) external view returns(Project memory output);
    function _returnIsContributor(address NFMAddress)
        external
        view
        returns (bool);
    function approveOrDenyProject(uint256 ProjectID, bool Stat) external returns (bool);
    function _approveReward(uint256 ProjectID, uint256 Amount, bool stat) external returns (bool);
}
interface IAFTGeneralPulling{
    struct GeneralPulls {
        uint256 PullId;
        string PullTitle;
        string PullDescription;
        uint256 PullTyp;
        address Requester;
        uint256 Terminated;
        uint256 VotingThema;
        bool PullVoteapproved;
        uint256 Timestart;
    }
    function returnAFTVotes(uint256 PullID)
        external
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256
        );
    function returnAddressesOnVotes(uint256 PullID)
        external
        view
        returns (address[] memory, uint256);
    function returnVotesCounterAll(
        uint256 PullID,
        bool Vote,
        uint256 Type
    ) external view returns (uint256);
    function returnPullsOnLevelEnded(uint256 Level)
        external
        view
        returns (GeneralPulls[] memory);
    
}

contract CalContriandPay{
   using SafeMath for uint256;
   
   INFMContributor public Cont;
   IAFTGeneralPulling public TPull;
   INfmController public NFMController; 

   constructor(address _cont, address _tpull, address _nfmcont){
       INFMContributor C= INFMContributor(address(_cont));
       Cont= C;
       IAFTGeneralPulling T= IAFTGeneralPulling(address(_tpull));
       TPull=T;
       INfmController N=INfmController(address(_nfmcont));
       NFMController=N;
   }
    //Returns if a contribution Pull has had success or not on voting 
   function checkVoting(string calldata ContributionString, uint256 Level) public view returns (bool,bool){
       (bool found, uint256 polId)=getEndedPulls(Level, ContributionString, msg.sender);
       if(found==true){
          uint256 yes=TPull.returnVotesCounterAll(polId, true, Level); 
          uint256 no=TPull.returnVotesCounterAll(polId, false, Level); 
          if(yes==0 && no == 0){
              return (true,false);
          }else if(no > yes){
              return (true,false);
          }else if(yes > no){
              return (true,true);
          }else{
              return (true,false);
          }
       }else{
           return (false,false);
       }
   }
   //CHECKS RESULT OF ENDED PULLS 
   function getEndedPulls(uint256 Level, string calldata Title, address sender) internal view returns (bool,uint256) {
        IAFTGeneralPulling.GeneralPulls[] memory Pulls = TPull.returnPullsOnLevelEnded(Level);
        uint256 p=0;
        for(uint256 i=Pulls.length-1; i>=0; i--){
            if(keccak256(abi.encodePacked(Pulls[i].PullTitle))==keccak256(abi.encodePacked(Title)) && (Pulls[i].Requester==sender)){
                p=Pulls[i].PullId;
            }
        }
        if(p>0){
        return (true, p);
        }else{
        return (false, p);
        }
    }

    function approveOrDeleteMyContri(uint256 ProjectID,string calldata ContributionString,uint256 Level,bool action) public returns (bool){
        (bool a, bool b) = checkVoting(ContributionString,Level);
        if(action==true){
        require(a==true && b == true,'VF');
        require(Cont.approveOrDenyProject(ProjectID, true)==true,'NA');
        }else{
        require(a==true && b == false,'VF');
        require(Cont.approveOrDenyProject(ProjectID, false)==true,'NA');    
        }
        return true;
    }

    function approvePaymentApprovalContri(uint256 ProjectID,string calldata ContributionString,bool action) public returns (bool){
        (bool a, bool b) = checkVoting(ContributionString,1);
        INFMContributor.Project memory pr= Cont._returnProjectInfo(ProjectID);
        if(action==true){
        string memory n = Cont._returnProjectNotify(ProjectID);
        require(a==true && b == true,'VF');
        require(keccak256(abi.encodePacked(n))!=keccak256(abi.encodePacked("Congratulations, your project has been accepted. The reward will be paid out on the next distribution date.")),'AR');
        require(keccak256(abi.encodePacked(n))!=keccak256(abi.encodePacked("Contribution has been paid.")),'AR');
        require(Cont._approveReward(ProjectID, pr.expectedrewardNFM , true)==true,'RE');
        }else{
        require(a==true && b == false,'VF');
        require(Cont._approveReward(ProjectID, pr.expectedrewardNFM , false)==true,'RE');  
        }
        return true;
    }
}