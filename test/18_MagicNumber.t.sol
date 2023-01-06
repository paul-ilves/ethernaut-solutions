// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import "../src/18_MagicNumber.sol";

contract MagicNumberTest is Test {
    Deployer public deployer;
    address public solverContrAddr;
    bytes public constant CONTRACT_CODE =
        hex"600a600c600039600a6000f3602a60805260206080f3";

    function setUp() public {
        deployer = new Deployer();
        deployer.create(CONTRACT_CODE);
        solverContrAddr = deployer.contrAddr();
    }

    function testSizeLe10() external {
        address addr = solverContrAddr;
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        assertLe(size, 10);
    }

    function testReturns42() external {
        (bool success, bytes memory resp) = solverContrAddr.call(hex"650500c1");
        require(success, "call failed");
        uint256 respValue = abi.decode(resp, (uint256));
        assertEq(respValue, 42);
    }

    function testSelector() external {
        bytes4 selector = bytes4(
            keccak256(abi.encodePacked("whatIsTheMeaningOfLife()"))
        );
        assertEq(selector, hex"650500c1");
    }
}
