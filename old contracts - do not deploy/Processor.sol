//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

    function GetContractAddress(string calldata _name) external view returns(address);
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
    function transfer(address _receiver, uint256 _value) external returns(bool);
    function transferFrom(address _from, address _receiver, uint256 _value) external returns(bool);
}

interface ISwapper{
    
    function Swap(address _receiver, uint256 _amount) external returns(bool);
}

contract Processor{

//-----------------------------------------------------------------------// v EVENTS

    event Processed(bytes32 verification, uint32 timestamp);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0xA00A1ED23A4cC11182db678a67FcdfB45fEe1FF8;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Processor";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

//-----------------------------------------------------------------------// v CONSTRUCTOR

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

    function _transferMATIC(uint256 _amount, address _receiver, address _implementor) private{

        (uint256 ramount, uint256 iamount, uint256 vamount) = _split("MATIC", _amount, _implementor);

        payable(_receiver).call{value : ramount}("");

        payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : vamount}("");

        if(_implementor != address(0))
            payable(_implementor).call{value : iamount}("");
    }

    function _transferToken(string calldata _symbol, uint256 _amount, address _receiver, address _implementor) private{

        address swapperAddress = pt.GetContractAddress(".Payment.Swapper");
        ISwapper sw = ISwapper(swapperAddress);

        address currenciesAddress = pt.GetContractAddress(".Payment.Currencies");
        ICurrencies cc = ICurrencies(currenciesAddress);

        address tokenAddress = cc.GetCurrencyAddress(_symbol);
        IERC20 tk = IERC20(tokenAddress);

        if(tokenAddress == address(0))
            revert("Token not supported");

        if(tk.allowance(msg.sender, address(this)) < _amount)
            revert("Processor not approved");

        tk.transferFrom(msg.sender, address(this), _amount);

        (uint256 ramount, uint256 iamount, uint256 vamount) = _split(_symbol, _amount, _implementor);

        tk.transfer(_receiver, ramount);

        tk.approve(swapperAddress, vamount);
        sw.Swap(tokenAddress, vamount);

        if(_implementor != address(0))
            tk.transfer(_implementor, iamount);  
    }

//-----------------------------------------------------------------------// v GET FUNCTIONS

//-----------------------------------------------------------------------// v SET FUNTIONS

    function Process(string calldata _symbol, uint256 _amount, address _receiver, address _implementor, bytes32 _verification, uint32 _timestamp) public payable returns(bool){

        if(reentrantLocked == true)
            revert("Reentrance failed");

        reentrantLocked = true;

        if(pt.GetContractAddress(".Payment.Processor") != address(this))
            revert("Deprecated Processor");

        uint32 size;
        assembly{size := extcodesize(_receiver)}

        if(size != 0)
            revert("Receiver is contract");

        assembly{size := extcodesize(_implementor)}

        if(size != 0)
            revert("Implementor is contract");

        if(keccak256(abi.encodePacked(_symbol)) == keccak256(abi.encodePacked("MATIC")) && msg.value > 0 && _amount == 0){

            if(sha256(abi.encodePacked(_symbol, msg.sender, _receiver, msg.value, _timestamp)) != _verification)
                revert("Verification failed");

            _transferMATIC(msg.value, _receiver, _implementor);
        }
        else if(keccak256(abi.encodePacked(_symbol)) != keccak256(abi.encodePacked("MATIC")) && _amount > 0 && msg.value == 0){

            if(sha256(abi.encodePacked(_symbol, msg.sender, _receiver, _amount, _timestamp)) != _verification)
                revert("Verification failed");

             _transferToken(_symbol, _amount, _receiver, _implementor);
        }
        else
            revert("Processing failed");

        reentrantLocked = false;

        emit Processed(_verification, _timestamp);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external payable{}
}