//SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IParent{

	function GetContractAddress(string calldata name) external view returns(address);
    function Owner() external view returns(address);
}

contract Subscribers{

//-----------------------------------------------------------------------// v EVENTS

    event Subscribed(address subscriber, uint32 dayNumber);

//-----------------------------------------------------------------------// v INTERFACES

    IParent constant private pt = IParent(parentAddress);

//-----------------------------------------------------------------------// v BOOLEANS

//-----------------------------------------------------------------------// v ADDRESSES

    address constant private parentAddress = 0xA00A1ED23A4cC11182db678a67FcdfB45fEe1FF8;

//-----------------------------------------------------------------------// v NUMBERS

    uint256 private subscriptionCostPerDay = 1 * (10**17);
    //
    uint32 private subscriptionsToReward = 5;
    //
    uint32 private transactionsPerPeriod = 50;
    uint32 private daysPerPeriod = 30;
    uint256 private minimumAmount = 25 * (10**16);


//-----------------------------------------------------------------------// v BYTES

//-----------------------------------------------------------------------// v STRINGS

    string constant public Name = ".Payment.Subscribers";

//-----------------------------------------------------------------------// v STRUCTS

    struct Subscriber{

        address referredBy;
        uint32 transactionCount;
        uint32 nextPeriod;
        uint32 subscribedUntil;
        uint32 lastTransaction;  
    }

//-----------------------------------------------------------------------// v ENUMS

//-----------------------------------------------------------------------// v MAPPINGS

    mapping(address => Subscriber) private subscribers;
    mapping(address => uint32) private referrerSubscriptions;

//-----------------------------------------------------------------------// v MODIFIERS

    modifier ownerOnly{

        if(pt.Owner() != msg.sender)
            revert("Owner only");

        _;
    }

//-----------------------------------------------------------------------// v CONSTRUCTOR

//-----------------------------------------------------------------------// v INTERNAL FUNCTIONS

//-----------------------------------------------------------------------// v GET FUNCTIONS

    function SubscriberProfile(address _subscriber) public view returns (address referredBy, uint32 transactionCount, uint32 nextPeriod, uint32 subscribedUntil, uint32 lastTransaction){
    
        Subscriber memory subscriber = subscribers[_subscriber];

        referredBy = subscriber.referredBy;
        transactionCount = subscriber.transactionCount;
        nextPeriod = subscriber.nextPeriod;
        subscribedUntil = subscriber.subscribedUntil;
        lastTransaction = subscriber.lastTransaction;
    }
    //
    function GetSubscriptionCostPerDay() public view returns(uint256){

        return (subscriptionCostPerDay);
    }
    //
    function GetSubscriptionsToReward() public view returns(uint32){

        return (subscriptionsToReward);
    }
   //
    function GetTransactionsPerPeriod() public view returns(uint32){

        return (transactionsPerPeriod);
    }

    function GetDaysPerPeriod() public view returns(uint32){

        return (daysPerPeriod);
    }

    function GetMinimumAmount() public view returns(uint256){

        return (minimumAmount);
    }

//-----------------------------------------------------------------------// v SET FUNTIONS

    function Subscribe(uint32 _days, address _referrer) payable public returns(bool){

        uint32 size;
        address sender = msg.sender;

        assembly{size := extcodesize(sender)}

        if(size != 0)
            revert("Contracts can not subscribe");

        if(_days * subscriptionCostPerDay != msg.value)
            revert("Wrong MATIC amount");

        Subscriber storage subscriber = subscribers[sender];

        uint32 subscribedUntil = subscriber.subscribedUntil;

        if(subscriber.lastTransaction == 0 && subscribedUntil == 0){

           assembly{size := extcodesize(_referrer)}

            if(size != 0)
                revert("Referrer is contract");

            if(_days < 10)
                revert("First subscription should be at least 10 days");

            referrerSubscriptions[_referrer]++;
            subscriber.referredBy = _referrer;
        }

        uint32 tnow = uint32(block.timestamp);

        if(subscribedUntil <= tnow)
            subscribedUntil = tnow + uint32(_days * 1 days);
        else
            subscribedUntil += uint32(_days * 1 days);

        if(subscribedUntil > uint32(tnow + 365 days))
            revert("Total subscription can not exceed 365 days");

        subscriber.subscribedUntil = subscribedUntil;

        if(subscriber.referredBy != address(0)){

            uint256 subscriberReward = msg.value * 10 / 100;
            uint256 referrerReward = (msg.value - subscriberReward) / 100;

            payable(sender).call{value : subscriberReward}("");
            
            if(referrerSubscriptions[subscriber.referredBy] >= subscriptionsToReward)
                payable(subscriber.referredBy).call{value : referrerReward}("");
        }

        payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : address(this).balance}("");

        emit Subscribed(sender, _days);
        return true;
    }
    //
    function SetSubscriptionCostPerDay(uint256 _amount) public ownerOnly returns(bool){

        if(_amount == 0)
            revert("Zero amount");

        subscriptionCostPerDay = _amount;

        return (true);
    }
    //
    function SetSubscriptionsToReward(uint32 _subscriptions) public ownerOnly returns(bool){

        if(_subscriptions == 0)
            revert("Zero subscriptions");

        subscriptionsToReward = _subscriptions;

        return (true);
    }
    //
    function SetTransactionsPerPeriod(uint32 _transactions) public ownerOnly returns(bool){

        if(_transactions == 0)
            revert("Zero transactions");

        transactionsPerPeriod = _transactions;

        return (true);
    }

    function SetDaysPerPeriod(uint32 _days) public ownerOnly returns(bool){

        if(_days == 0)
            revert("Zero days");

        daysPerPeriod = _days;

        return (true);
    }

    function SetMinimumAmount(uint256 _amount) public ownerOnly returns(bool){

        if(_amount == 0)
            revert("Zero amount");

        minimumAmount = _amount;

        return (true);
    }
    //
    function AllowProcessing(address _subscriber, uint256 _amount) public returns (bool){

        if(pt.GetContractAddress(".Payment.Processor") != msg.sender)
            revert("Processor only");

        Subscriber storage subscriber = subscribers[_subscriber];

        uint32 tnow = uint32(block.timestamp);

        if(tnow <= subscriber.subscribedUntil){

            subscriber.nextPeriod = subscriber.subscribedUntil + uint32(daysPerPeriod * 1 days);
            subscriber.transactionCount = 0;
        }
        else if(tnow > subscriber.nextPeriod){

            subscriber.nextPeriod = tnow + uint32(daysPerPeriod * 1 days);
            subscriber.transactionCount = 0;
        }
        
        if(tnow > subscriber.subscribedUntil)
            if(subscriber.transactionCount >= transactionsPerPeriod || _amount <  minimumAmount)
                return(false);

        subscriber.transactionCount++;
        subscriber.lastTransaction = tnow;

        return(true);
    }

//-----------------------------------------------------------------------// v DEFAULTS

    receive() external payable{

        if(msg.value > 0)
            payable(address(pt.GetContractAddress(".Corporation.Vault"))).call{value : msg.value}("");
        
    }

    fallback() external {}
}