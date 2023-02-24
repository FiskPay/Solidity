//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetOwner() external view returns(address);
    function GetMATIC() external view returns(address);
}

interface IERC20{

    function symbol() external view returns (string memory);
}

contract Currencies{

//-----------------------------------------------------------------------// v EVENTS

    event CurrencyAddition(address indexed _currency);
    event CurrencyRemoval(address indexed _currency);
    //
    event UpdateFee(address indexed _currency, uint24 _fee);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x477D7bd757c281419b69154Ac05116748cd6E6df;
    //
    address immutable private MATIC;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Currencies";
    //
    string[] private currencies;

//-----------------------------------------------------------------------// v STRUCTS


//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(string => address) private symbolToAddress;
    mapping(address => string) private addressToSymbol;
    //
    mapping(address => uint24) private currencyFee;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(pt.GetOwner() != msg.sender)
            revert("Owner only");

        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

    constructor(){
    
        MATIC = pt.GetMATIC();
        currencyFee[MATIC] = 200;
    }

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetCurrencyAddress(string calldata _symbol) public view returns(address){

        return symbolToAddress[_symbol];
    }

    function GetCurrencySymbol(address _address) public view returns(string memory){

        return addressToSymbol[_address];
    }
    //
    function GetTokenFee(string calldata _symbol) public view returns(uint24){

        return currencyFee[symbolToAddress[_symbol]];
    }

    function GetMATICFee() public view returns(uint24){

        return currencyFee[MATIC];
    }
    //
    function GetCurrencyList() public view returns(string[] memory){

        return(currencies);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function AddCurrency(string calldata _symbol, address _address) public ownerOnly returns(bool){

        address tokenAddress = symbolToAddress[_symbol];

        if(tokenAddress != address(0))
            revert("Symbol already used");
        else if(keccak256(abi.encodePacked(addressToSymbol[_address])) != keccak256(abi.encodePacked("")))
            revert("Address already used");

        uint32 size;
        assembly{size := extcodesize(_address)}

        if(size == 0)
            revert("Not a contract");

        string memory sb = IERC20(_address).symbol();

        if(keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked(sb)))
            revert("Symbol mismatch");

        symbolToAddress[_symbol] = _address;
        addressToSymbol[_address] = _symbol;
        currencyFee[_address] = 220;

        currencies.push(_symbol);

        emit CurrencyAddition(tokenAddress);
        return(true);
    }

    function RemoveCurrency(string calldata _symbol) public ownerOnly returns(bool){

        address tokenAddress = symbolToAddress[_symbol];

        if(tokenAddress == address(0))
            revert("Symbol not used");
        
        delete addressToSymbol[tokenAddress];
        delete symbolToAddress[_symbol];
        delete currencyFee[tokenAddress];

        uint256 lng = currencies.length;

        for(uint256 i = 0; i < lng; i++){

            if(keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked(currencies[i]))){

                currencies[i] = currencies[lng-1];
                break;
            }
        }

        currencies.pop();

        emit CurrencyRemoval(tokenAddress);
        return(true);
    }
    //
    function UpdateTokenFee(string calldata _symbol, uint24 _fee) public ownerOnly returns(bool){

        address tokenAddress = symbolToAddress[_symbol];

        if(tokenAddress == address(0))
            revert("Symbol not used");
            
        if(_fee > 10000)
            revert("Exceeded maximum fee");

        currencyFee[tokenAddress] = _fee;

        emit UpdateFee(tokenAddress, _fee);
        return(true);
    }

    function UpdateMATICFee(uint24 _fee) public ownerOnly returns(bool){

        if(_fee > 10000)
            revert("Exceeded maximum fee");

        currencyFee[MATIC] = _fee;

        emit UpdateFee(MATIC, _fee);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external payable{}
}