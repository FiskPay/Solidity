//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

	function GetContractAddress(string calldata _name) external view returns(address);
    function Owner() external view returns(address);
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

    event Payout(address indexed employee, uint256 _amount);
    //
    event EmployeeAddition(address indexed employee, uint256 dailyWage);
    event EmployeeUpdate(address indexed employee, uint256 dailyWage);
    event EmployeeRemoval(address indexed employee);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

    bool private reentrantLocked = false;

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0x477D7bd757c281419b69154Ac05116748cd6E6df;

//-----------------------------------------------------------------------// v NUMBERS

//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Corporation.Employees";

//-----------------------------------------------------------------------// v STRUCTS

    struct Employee{

        bool isActive;
        uint16 dailyWage;
        uint32 lastPayment;  
    }

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(address => Employee) private employees;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(pt.Owner() != msg.sender)
            revert("Owner only");

        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v PRIVATE FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function GetEmployeeDailyWage(address _employee) public view returns(uint16){

        return(employees[_employee].dailyWage);
    }

    function GetEmployeeStatus(address _employee) public view returns(bool){

        if(employees[_employee].isActive == true)
            return(true);

        return(false);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function Payoff() public returns(bool){

        if(reentrantLocked == true)
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

        if(success != true)
            revert("Oracle unreachable");

        uint256 price = oc.GetMATICPrice();

        if(price <= 0)
            revert("Unaccepted price");

        uint32 unpaidDays = uint32((block.timestamp - employee.lastPayment) / (1 days));
        uint32 moduloDays = uint32((block.timestamp - employee.lastPayment) % (1 days));
        uint256 amount = uint256(employee.dailyWage * unpaidDays * (10 ** 18) * (10 ** decimals) / (price * 100));

        if(amount == 0)
            revert("Already paid");

        if(employee.isActive == true)
            employee.lastPayment = uint32(block.timestamp - moduloDays);
        else{

            employee.lastPayment = 0;
            employee.dailyWage = 0;
        }

        try cl.EmployeesWithdraw(msg.sender, amount){}
        catch{ revert("Payoff failed"); }

        reentrantLocked = false;

        emit Payout(msg.sender, amount);
        return(true);
    }
    //
    function AddEmployee(address _employee, uint16 _dailyWage) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.isActive == true)
            revert("Already employeed");

        uint32 size;
        assembly{size := extcodesize(_employee)}

        if(size != 0)
            revert("Employee is contract");

        if(_dailyWage == 0)
            revert("Zero wage");

        employee.dailyWage = _dailyWage;
        employee.lastPayment = uint32(block.timestamp);
        employee.isActive = true;

        emit EmployeeAddition(_employee,  _dailyWage);
        return(true);
    }

    function UpdateEmployee(address _employee, uint16 _dailyWage) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.isActive != true)
            revert("Not an employee");

        if(_dailyWage == 0)
            revert("Zero wage");

        employee.dailyWage = _dailyWage;

        emit EmployeeUpdate(_employee, _dailyWage);
        return(true);
    }

    function RemoveEmployee(address _employee) public ownerOnly returns(bool){

        Employee storage employee = employees[_employee];

        if(employee.isActive != true)
            revert("Not an employee");

        employee.isActive = false;

        emit EmployeeRemoval( _employee);
        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{}
    fallback() external{}
}