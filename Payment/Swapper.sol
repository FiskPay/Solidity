//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;
pragma abicoder v2;

interface IParent{

    function GetContractAddress(string calldata _name) external view returns(address);
    function Owner() external view returns(address);
    function WMATIC() external view returns(address);
}

interface ISwapRouter{

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);
}

interface IERC20{

    function approve(address _spender, uint256 _value) external returns(bool);
    function allowance(address _owner, address _spender) external view returns(uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns(bool);
    function balanceOf(address _owner) external view returns(uint256);
}

interface IWMATIC{

    function balanceOf(address _owner) external view returns(uint256);
    function withdraw(uint _wad) external;
}

contract Swapper{

//-----------------------------------------------------------------------// v EVENTS

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);
    //
    ISwapRouter constant private sr = ISwapRouter(routerAddress);
    //
    IWMATIC immutable private wm;

//-----------------------------------------------------------------------// v BOOLEANS

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x477D7bd757c281419b69154Ac05116748cd6E6df;
    //
    address constant private routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
    //
    address immutable private WMATIC;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Swapper";

//-----------------------------------------------------------------------// v STRUCTS

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

//-----------------------------------------------------------------------// v MODIFIERS

//-----------------------------------------------------------------------// v CONSTRUCTOR
    constructor(){
    
        WMATIC = pt.WMATIC();
        wm = IWMATIC(WMATIC);
    }
//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

//-----------------------------------------------------------------------// v SET FUNTIONS

    function Swap(address _token, uint256 _amount) public returns(bool) {

        if(pt.GetContractAddress(".Payment.Proccessor") != msg.sender)
            revert("Proccessor only");

        address vaultAddress = pt.GetContractAddress(".Corporation.Vault");

        IERC20 tk = IERC20(_token);

        if(tk.allowance(msg.sender, address(this)) < _amount)
            revert("Swapper not approved");

        tk.transferFrom(msg.sender, address(this), _amount);
        
        if(_token != WMATIC){
            
            tk.approve(routerAddress, tk.balanceOf(address(this)));

            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _token,
                    tokenOut: WMATIC,
                    fee: 3000,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: tk.balanceOf(address(this)),
                    amountOutMinimum: 0,
                    sqrtPriceLimitX96: 0
                });

            try sr.exactInputSingle(params){}
            catch{}
        }
        
        if(wm.balanceOf(address(this)) > 0){

            try wm.withdraw(wm.balanceOf(address(this))){}
            catch{}
        }

        if(vaultAddress != address(0) && address(this).balance > 0)
            payable(vaultAddress).call{value : address(this).balance}("");

        return(true);
    }
    
    function WithdrawToken(address _token) public returns(bool) {

        if(pt.Owner() != msg.sender)
            revert("Owner only");

        if(IERC20(_token).balanceOf(address(this)) > 0)
            IERC20(_token).transfer(msg.sender, IERC20(_token).balanceOf(address(this)));
        else
            revert("Token balance is zero");

        return(true);
    }

    function WithdrawMATIC() public returns(bool) {

        if(pt.Owner() != msg.sender)
            revert("Owner only");

        if(address(this).balance > 0){

            (bool sent,) = payable(msg.sender).call{value : address(this).balance}("");

            if(sent != true)
                revert("Withdraw failed");
        }
        else
            revert("MATIC balance is zero");

        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external payable{}
}