//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

	function GetContractAddress(string calldata _name) external view returns(address);
    function GetOwner() external view returns(address);
}

interface IOracle{

    function GetMATICPrice() external view returns(uint256);
    function GetMATICDecimals() external view returns(uint8, bool);
}

interface IClerk{
    
    function EmployeesWithdraw(address _employee, uint256 _amount) external returns(bool);
}

contract Employees{

//-----------------------------------------------------------------------// v EVENTS

    event PayoffSent(address indexed _employee, uint256 _amount);
    //
    event EmployeeAddition(address indexed _employee, uint256 _dailyWage);
    event EmployeeUpdate(address indexed _employee, uint256 _dailyWage);
    event EmployeeRemoval(address indexed _employee);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x72ec1287FF5BB960fd54Ac2AdAE99145153C561F;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Employees";

//-----------------------------------------------------------------------// v STRUCTS

    struct Employee{

        bool status;
        uint16 dailyWage;
        uint32 lastPayment;
        
    }

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(address => Employee) private employees;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(pt.GetOwner() != msg.sender)
            revert("Owner only");

        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

//-----------------------------------------------------------------------// v SET FUNTIONS

    function EmployeePayoff() public returns(bool){

        if(reentrantLocked)
            revert("Reentrance failed");

        reentrantLocked = true;

        address oracleAddress = pt.GetContractAddress(".Corporation.Oracle");
        IOracle oc = IOracle(oracleAddress);

        address clerkAddress = pt.GetContractAddress(".Corporation.Clerk");
        IClerk cl = IClerk(clerkAddress);

        Employee storage employee = employees[msg.sender];
        
        if(employee.lastPayment == 0)
            revert("Employee only");

        (uint8 decimals, bool success) = oc.GetMATICDecimals();

        if(!success)
            revert("Oracle unreachable");

        uint256 price = oc.GetMATICPrice();

        if(price <= 0)
            revert("Unaccepted price");

        uint32 unpaidDays = uint32((block.timestamp - employee.lastPayment) / (1 days));
        uint32 moduloDays = uint32((block.timestamp - employee.lastPayment) % (1 days));
        uint256 amount = uint256(employee.dailyWage * unpaidDays * 10**decimals / price);

        if(employee.status == true)
            employee.lastPayment = uint32(block.timestamp - moduloDays);
        else{

            employee.lastPayment = 0;
            employee.dailyWage = 0;
        }

        try cl.EmployeesWithdraw(msg.sender, amount){}
        catch{ revert("Payoff failed"); }

        reentrantLocked = false;

        emit PayoffSent(msg.sender, amount);
        return true;
    }
    //
    function AddEmployee(address _employee, uint16 _dailyWage) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.status == true)
            revert("Already employeed");

        if(_dailyWage == 0)
            revert("Zero wage");

        employee.dailyWage = _dailyWage;
        employee.lastPayment = uint32(block.timestamp);
        employee.status = true;

        emit EmployeeAddition(_employee,  _dailyWage);
        return true;
    }

    function UpdateEmployee(address _employee, uint16 _dailyWage) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.status != true)
            revert("Not an employee");

        if(_dailyWage == 0)
            revert("Zero wage");

        employee.dailyWage = _dailyWage;

        emit EmployeeUpdate(_employee, _dailyWage);
        return true;
    }

    function RemoveEmployee(address _employee) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.status != true)
            revert("Not an employee");

        employee.status = false;

        emit EmployeeRemoval( _employee);
        return true;
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external payable{}
}