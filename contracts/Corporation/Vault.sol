//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetAddress(string calldata name) external view returns(address);
}

contract Vault{

//-----------------------------------------------------------------------// v EVENTS

    event VaultWithdraw(uint256 _amount);
    event Deposit(address indexed _from, uint256 _amount);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x72ec1287FF5BB960fd54Ac2AdAE99145153C561F;

//-----------------------------------------------------------------------// v NUMBERS

    uint256 private totalMATIC = 0;

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Vault";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetTotalMATIC() public view returns(uint256){

        return (totalMATIC);
    }

    function GetCurrentMATIC() public view returns(uint256){

        return (address(this).balance);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function ClerkWithdraw(uint256 _amount) public returns(bool){

        if(reentrantLocked)
            revert("Reentrance failed");

        reentrantLocked = true;

        address clerkAddress = pt.GetAddress(".Corporation.Clerk");

        if(clerkAddress != msg.sender)
            revert("Clerk only");

        (bool sent,) = payable(clerkAddress).call{value : _amount}("");

        if(sent != true)
            revert("ClerkWithdraw failed");

        reentrantLocked = false;

        emit VaultWithdraw(_amount);
        return true;
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        totalMATIC += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external{

        address clerkAddress = pt.GetAddress(".Corporation.Clerk");

        if(clerkAddress != msg.sender)
            revert("Clerk only");
    }
}