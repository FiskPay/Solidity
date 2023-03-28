//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetContractAddress(string calldata _name) external view returns(address);
}

contract Implementors{

//-----------------------------------------------------------------------// v EVENTS

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0xA00A1ED23A4cC11182db678a67FcdfB45fEe1FF8;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Implementors";

//-----------------------------------------------------------------------// v STRUCTS

    struct Implementor{
        uint32 epochSales;
        uint32 epochEnd;
        uint8 epochReward;
    }

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(string => address) private nameToAddress;
    mapping(address => string) private addressToName;
    //
    mapping(address => Implementor) private implementor;

//-----------------------------------------------------------------------// v MODIFIERS

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetImplementorProfile(address _implementor) public view returns(uint32 epochSales, uint32 epochEnd, uint8 epochReward){

        Implementor memory imp = implementor[_implementor];

        epochSales = imp.epochSales;
        epochEnd = imp.epochEnd;
        epochReward = imp.epochReward;
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function GetEpochReward(address _implementor) public returns(uint8){

        if(pt.GetContractAddress(".Payment.Proccessor") != msg.sender)
            revert("Proccessor only");

        Implementor storage imp = implementor[_implementor];

        if(imp.epochEnd < uint32(block.timestamp)){

            uint32 epochSales = imp.epochSales;

            if(epochSales > 24999)
                imp.epochReward = 200;
            else if(epochSales > 12499)
                imp.epochReward = 150;
            else if(epochSales > 7499)
                imp.epochReward = 125;
            else if(epochSales > 4999)
                imp.epochReward = 100;
            else if(epochSales > 2499)
                imp.epochReward = 80;
            else if(epochSales > 1499)
                imp.epochReward = 60;
            else if(epochSales > 999)
                imp.epochReward = 50;
            else if(epochSales > 499)
                imp.epochReward = 40;
            else if(epochSales > 249)
                imp.epochReward = 35;
            else
                imp.epochReward = 30;

            delete imp.epochSales;
            imp.epochEnd = uint32(block.timestamp + 15 days);
        }

        imp.epochSales += 1;

        return(imp.epochReward);
    }
    
//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        if(msg.value > 0)
            payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : msg.value}("");
        
    }

    fallback() external {}
}