//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetAddress(string calldata name) external view returns(address);
}

interface IVault{

    function ClerkWithdraw(uint256 _amount) external returns(bool);
}

contract Clerk{

//-----------------------------------------------------------------------// v EVENTS

    event Withdraw(address indexed _orderer, address indexed _receiver, uint256 _amount);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x72ec1287FF5BB960fd54Ac2AdAE99145153C561F;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Clerk";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

    modifier noReentrant{

        if(reentrantLocked)
            revert("Reentrance failed");

        reentrantLocked = true;
        _;
        reentrantLocked = false;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

    function _withdrawTo(address _reciever, uint256 _amount) private{

        address vaultAddress = pt.GetAddress(".Corporation.Vault");
        IVault vt = IVault(vaultAddress);

        if(_amount > address(vaultAddress).balance)
            revert("Not enough MATIC");

        try vt.ClerkWithdraw(_amount){}
        catch{ revert("ClerkWithdraw failed"); }

        payable(_reciever).transfer(_amount);
    }

//-----------------------------------------------------------------------// v GET FUNCTIONS

//-----------------------------------------------------------------------// v SET FUNTIONS

    function EmployeesWithdraw(address _employee, uint256 _amount) public noReentrant returns(bool){

        address employeesAddress = pt.GetAddress(".Corporation.Employees");

        if(employeesAddress != msg.sender)
            revert("Employees only");

        _withdrawTo(_employee, _amount);

        emit Withdraw(employeesAddress, _employee, _amount);
        return true;
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external payable{}
}