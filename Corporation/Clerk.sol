//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetContractAddress(string calldata name) external view returns(address);
    function Owner() external view returns(address);
}

interface IVault{

    function ClerkWithdraw(uint256 amount) external returns(bool);
}

contract Clerk{

//-----------------------------------------------------------------------// v EVENTS

    event ClerkWithdraw(address indexed orderer, address indexed receiver, uint256 amount);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0xA00A1ED23A4cC11182db678a67FcdfB45fEe1FF8;

//-----------------------------------------------------------------------// v NUMBERS

    uint32 private lastModification = uint32(block.timestamp);
    uint32 private nextSeason = lastModification;
    uint32 private daysPerSeason = 4;
    uint256 private maximumAmountPerSeason = 200 * 10**18;
    uint256 private seasonTotalAmount;
    
//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Clerk";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{
        
        if(pt.Owner() != msg.sender)
            revert("Owner only");

        uint32 tnow = uint32(block.timestamp);

        if((tnow - 1 days) < lastModification)
            revert("One modification per days");

        lastModification = tnow;
        _;
    }
    //
    modifier noReentrant{

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;
        _;
        reentrantLocked = false;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

    function _withdrawalClearance(uint256 _amount) private{

        uint32 tnow = uint32(block.timestamp);

        if(tnow > nextSeason){

            nextSeason = tnow + uint32(daysPerSeason * 1 days);
            delete seasonTotalAmount;
        }

        seasonTotalAmount += _amount;

        if(seasonTotalAmount > maximumAmountPerSeason)
            revert("Maximum withdraw reached");
    }

    function _withdrawTo(address _receiver, uint256 _amount) private returns(bool){

        _withdrawalClearance(_amount);

        address vaultAddress = pt.GetContractAddress(".Corporation.Vault");
        IVault vt = IVault(vaultAddress);

        if(_amount > address(vaultAddress).balance)
            revert("Not enough MATIC");

        try vt.ClerkWithdraw(_amount){

            (bool sent,) = payable(_receiver).call{value : _amount}("");
            return(sent);
        }
        catch{ return(false); }
    }

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetDaysPerSeason() public view returns(uint32){

        return (daysPerSeason);
    }

    function GetMaximumAmountPerSeason() public view returns(uint256){

        return (maximumAmountPerSeason);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function SetDaysPerSeason(uint32 _days) public ownerOnly returns(bool){

        if(_days == 0)
            revert("Zero days");

        daysPerSeason = _days;

        return (true);
    }

    function SetMaximumAmountPerSeason(uint256 _amount, uint16 _maticAmount) public ownerOnly returns(bool){

        if(_amount == 0)
            revert("Zero amount");
        else if(_amount > (200 * 10**18 + maximumAmountPerSeason))
            revert("Maximum increase is 200 MATIC");
        else if((_amount / 10**18) != _maticAmount)
            revert("Amounts mismatch");

        maximumAmountPerSeason = _amount;

        return (true);
    }
    //
    //
    //
    function EmployeesWithdraw(address _employee, uint256 _amount) public noReentrant returns(bool){

        address employeesAddress = pt.GetContractAddress(".Corporation.Employees");

        if(employeesAddress != msg.sender)
            revert("Employees only");

        if(_withdrawTo(_employee, _amount) != true)
            revert("EmployeesWithdraw failed");
        
        emit ClerkWithdraw(employeesAddress, _employee, _amount);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external{}
}