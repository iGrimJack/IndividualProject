pragma solidity ^0.4.24;

import "./IPMemory.sol";
import "./EventManager.sol";
import "remix_tests.sol";

contract EventTest {
	address owner = msg.sender;
	IPMemory mem;
	EventManager eventMan;
	address userP = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
	address userS = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db;
	uint eventID;

	modifier onlyOwner() {
		require(msg.sender == owner, "Not authorise to do action");
	}

	function setContract(address _mem, address _event) external onlyOwner() {
		mem = IPMemory(_mem);
		eventMan = EventManager(_event);
		bytes32 crypt = keccak256(abi.encodePacked(userP,"Primary"));
		mem.storeUint(crypt,1);
		crypt = keccak256(abi.encodePacked(userS,"Secondary"));
		mem.storeUint(crypt,1);
	}

	function testBadParamsCreateEvent() external {
		// Call by address of userP
		ThrowProxy throwproxy = new ThrowProxy(address(eventMan)); 
	    EventManager(address(throwproxy)).registerEvent("","",now + 1, now + 10, uint(8));
	    bool r = throwproxy.execute.gas(200000)(); 
	    Assert.equal(false, r, "Empty name/URL revert");
	   
	    EventManager(address(throwproxy)).registerEvent("EventTest","example.com",now + 10, now + 1, uint(10));
	    r = throwproxy.execute.gas(200000)();
	    Assert.equal(r,false,"Illegal time revert");

	    EventManager(address(throwproxy)).registerEvent("","",now + 1, now + 10, uint(0));
	    r = throwproxy.execute.gas(200000)();
	    Assert.equal(r,false,"Non-positive price revert");
	}

	function testRepeateEventCreate() external {
	    EventManager(address(throwproxy)).registerEvent("EventTest","example.com",start,end,10);
	    r = throwproxy.execute.gas(200000)();
	    Assert.equal(r,false,"Event hash actived revert");
	}

	function testCreateEvent() external {
		if (msg.sender == userP) {
			eventID = eventMan.getEventCount();
		    uint start = now;
		    start += 300;
		    uint end = start + 120;
		    eventMan.registerEvent("EventTest","example.com",start,end,10);
			bytes32 hash = keccak256(abi.encodePacked("EventTest","example.com",start,end,10));
			bytes32 _key = keccak256(abi.encodePacked(eventID,"Event Hash"));
			Assert.equal(eventMan.getEventCount(), eventID + 1,"event count test");
			Assert.equal(mem.getBytes32(_key),hash,"storing event hash test");
		}
		else {
			ThrowProxy throwproxy = new ThrowProxy(address(eventMan)); 
	    	EventManager(address(throwproxy)).registerEvent();
	    	bool r = throwproxy.execute.gas(200000)(); 
	    	Assert.equal(false, r, "Secondary user cannot create event");
		}
	}

	function testEventData() external {
		_key = keccak256(abi.encodePacked(eventID,"Event Owner"));
		Assert.equal(mem.getAddress(_key),userP,"storing event owner test");
		_key = keccak256(abi.encodePacked(hash,"Event Active Status"));
		Assert.equal(1,mem.getUint(_key),"Event Active Status test");
	}

	function testCancelEvent() external {
		memMan.cancelEvent(eventID);
		_key = keccak256(abi.encodePacked(hash,"Event Active Status"));
		Assert.equal(0,mem.getUint(_key),"Event Cancel test");
	}
}

// Proxy contract for testing throws
contract ThrowProxy {
	address public target;
	bytes data;

	function ThrowProxy(address _target) {
		target = _target;
	}

	//prime the data using the fallback function.
	function() {
		data = msg.data;
	}

	function execute() returns (bool) {
		return target.call(data);
	}
}