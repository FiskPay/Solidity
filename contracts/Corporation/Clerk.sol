//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetContractAddress(string calldata name) external view returns(address);
}

interface IVault{

    function ClerkWithdraw(uint256 _amount) external returns(bool);
}

contract Clerk{

//-----------------------------------------------------------------------// v EVENTS

    event ClerkWithdraw(address indexed _orderer, address indexed _receiver, uint256 _amount);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x477D7bd757c281419b69154Ac05116748cd6E6df;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Clerk";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

    modifier noReentrant{

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;
        _;
        reentrantLocked = false;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

    function _withdrawTo(address _reciever, uint256 _amount) private returns(bool){

        address vaultAddress = pt.GetContractAddress(".Corporation.Vault");
        IVault vt = IVault(vaultAddress);

        if(_amount > address(vaultAddress).balance)
            revert("Not enough MATIC");

        try vt.ClerkWithdraw(_amount){

            (bool sent,) = payable(_reciever).call{value : _amount}("");

            if(sent != true)
                return(false);

            return(true);
        }
        catch{ return(false); }
    }

//-----------------------------------------------------------------------// v GET FUNCTIONS

//-----------------------------------------------------------------------// v SET FUNTIONS

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
    fallback() external payable{}
}