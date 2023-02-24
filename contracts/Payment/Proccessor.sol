//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetContractAddress(string calldata _name) external view returns(address);
    function GetOwner() external view returns(address);
    function GetMATIC() external pure returns(address);
}

interface ICurrencies{

    function GetCurrencyAddress(string calldata _symbol) external view returns(address);
    function GetCurrencySymbol(address _address) external view returns(string memory);
    function GetTokenFee(string calldata _symbol) external view returns(uint24);
    function GetMATICFee() external view returns(uint24);
}

interface IImplementors{

    function GetEpochReward(address _implementor) external returns(uint8);
}

interface IERC20{

    function approve(address _spender, uint256 _value) external returns(bool);
    function allowance(address _owner, address _spender) external view returns(uint256);
    function balanceOf(address _owner) external view returns(uint256);
    function transfer(address _receiver, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _receiver, uint256 _value) external returns(bool);
}

interface ISwapper{
    
    function Swap(address _receiverken, uint256 _amount) external returns(bool);
}

contract Proccessor{

//-----------------------------------------------------------------------// v EVENTS

    event Proccessed(address indexed _from, address indexed _receiver, address _currency, uint256 _amount);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x72ec1287FF5BB960fd54Ac2AdAE99145153C561F;
    //
    address immutable private MATIC;


//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Proccessor";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

//-----------------------------------------------------------------------// v CONSTRUCTOR

    constructor(){
    
        MATIC = pt.GetMATIC();
    }

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

    function _split(string memory _symbol, uint256 _amount, address _implementor) private returns(uint256 ramount, uint256 iamount, uint256 vamount){

        address implementorsAddress = pt.GetContractAddress(".Payment.Implementors");
        IImplementors ir = IImplementors(implementorsAddress);

        address currenciesAddress = pt.GetContractAddress(".Payment.Currencies");
        ICurrencies cy = ICurrencies(currenciesAddress);

        uint8 reward = 0;
        uint24 fee = 0;

        if(keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked("MATIC")))
            fee = cy.GetMATICFee();
        else
            fee = cy.GetTokenFee(_symbol);

        if(_implementor != address(0))
            reward = ir.GetEpochReward(_implementor);

        ramount = uint256(_amount - (_amount * fee) / 100000);
        iamount = uint256(((_amount - ramount) * reward) / 1000);
        vamount = _amount - (ramount + iamount);
    }

    function _transferMATIC(uint256 _amount, address _receiver, address _implementor) private returns(address){

        (uint256 ramount, uint256 iamount, uint256 vamount) = _split("MATIC", _amount, _implementor);

        address vaultAddress = pt.GetContractAddress(".Corporation.Vault");
        address swapAddress = pt.GetContractAddress(".Payment.Swapper");

        payable(_receiver).call{value : ramount}("");

        if(_implementor != address(0))
            payable(_implementor).call{value : iamount}("");
        
        if(vaultAddress != address(0))
            payable(vaultAddress).call{value : vamount}("");
        else if(swapAddress != address(0))
            payable(swapAddress).call{value : vamount}("");
        else
            payable(pt.GetOwner()).call{value : vamount}("");

        return(MATIC);
    }

    function _transferToken(string calldata _symbol, uint256 _amount, address _receiver, address _implementor) private returns(address){

        address swapperAddress = pt.GetContractAddress(".Payment.Swapper");
        ISwapper sw = ISwapper(swapperAddress);

        address currenciesAddress = pt.GetContractAddress(".Payment.Currencies");
        ICurrencies cc = ICurrencies(currenciesAddress);

        address tokenAddress = cc.GetCurrencyAddress(_symbol);
        IERC20 tk = IERC20(tokenAddress);

        if(tokenAddress == address(0))
            revert("Token not supported");

        if(tk.balanceOf(msg.sender) < _amount)
            revert("Insufficient balance");

        if(tk.allowance(msg.sender, address(this)) < _amount)
            revert("Proccessor not approved");

        tk.transferFrom(msg.sender, address(this), _amount);

        (uint256 ramount, uint256 iamount, uint256 vamount) = _split(_symbol, _amount, _implementor);

        tk.transfer(_receiver, ramount);

        if(_implementor != address(0))
            tk.transfer(_implementor, iamount);

        if(swapperAddress != address(0)){

            tk.approve(swapperAddress, vamount);
            sw.Swap(tokenAddress, vamount);
        }
        else
            tk.transfer(pt.GetOwner(), vamount);

        return(tokenAddress);
    }

//-----------------------------------------------------------------------// v GET FUNCTIONS

//-----------------------------------------------------------------------// v SET FUNTIONS

    function Proccess(string calldata _symbol, uint256 _amount, address _receiver, address _implementor) public payable returns(bool){

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;

        uint32 size;
        assembly{size := extcodesize(_receiver)}

        if(size != 0)
            revert("Receiver is contract");

        assembly{size := extcodesize(_implementor)}

        if(size != 0)
            revert("Implementor is contract");

        address tokenAddress = address(0);

        if(keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked("MATIC")) && msg.value > 0 && _amount == 0)
            tokenAddress = _transferMATIC(msg.value, _receiver, _implementor);
        else if(keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked("MATIC")) && _amount > 0 && msg.value == 0)
            tokenAddress = _transferToken(_symbol, _amount, _receiver, _implementor);
        else
            revert("Proccessing failed");

        reentrantLocked = false;

        emit Proccessed(msg.sender, _receiver, tokenAddress, _amount);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external payable{}
}