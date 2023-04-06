//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetContractAddress(string calldata name) external view returns(address);
}

contract Vault{

//-----------------------------------------------------------------------// v EVENTS

    event VaultWithdraw(uint256 amount);
    event Deposit(address indexed from, uint256 amount);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0xA00A1ED23A4cC11182db678a67FcdfB45fEe1FF8;

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

        return(totalMATIC);
    }

    function GetCurrentMATIC() public view returns(uint256){

        return(address(this).balance);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function ClerkWithdraw(uint256 _amount) public returns(bool){

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;

        address clerkAddress = pt.GetContractAddress(".Corporation.Clerk");

        if(clerkAddress != msg.sender)
            revert("Clerk only");

        (bool sent,) = payable(clerkAddress).call{value : _amount}("");

        if(sent != true)
           revert("ClerkWithdraw failed");

        reentrantLocked = false;

        emit VaultWithdraw(_amount);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        totalMATIC += msg.value;
        
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external{

        if(pt.GetContractAddress(".Corporation.Clerk") != msg.sender)
            revert("Clerk only");
    }
}