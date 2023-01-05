// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//The problem code
contract MagicNum {
    address public solver;

    constructor() {}

    function setSolver(address _solver) public {
        solver = _solver;
    }

    /*
    ____________/\\\_______/\\\\\\\\\_____        
     __________/\\\\\_____/\\\///////\\\___       
      ________/\\\/\\\____\///______\//\\\__      
       ______/\\\/\/\\\______________/\\\/___     
        ____/\\\/__\/\\\___________/\\\//_____    
         __/\\\\\\\\\\\\\\\\_____/\\\//________   
          _\///////////\\\//____/\\\/___________  
           ___________\/\\\_____/\\\\\\\\\\\\\\\_ 
            ___________\///_____\///////////////__
  */
}

/*This WON'T go pass the challenge, as even the minimalist Solidity contract has way more than 10 OpCodes */
contract NaiveSolution {
    function whatIsTheMeaningOfLife() external pure returns (uint256) {
        return 42;
    }
}

// Let's try using Yul.
contract YulSolution {
    function whatIsTheMeaningOfLife() external pure returns (uint256) {
        assembly {
            mstore(0x80, 0x2a) //'0x80' is chosen arbitrarily, '0x2a' is '42' in hex
            return(0x80, 0x20) //first arg needs to coincide with memory slot chosen before, '0x20' is 32 in hex
        }
    }
}

/*
Unfortunately the above contract still exceeds 10 opcodes, because it has all the automatically-added checks, function selectors, jumps etc.
We will have to construct OpCodes sequence by ourselves manually. But the Yul code has give us a good starter reference what we should write.
Use https://evm.codes/ for reference about OpCodes:

PUSH1 2a => 602a
PUSH1 80 => 6080
MSTORE => 52
PUSH1 20 => 6020
PUSH1 80 => 6080
RETURN => f3

Transforming it into hex and concatenating we get the runtime bytecode: 602a60805260206080f3 (10 bytes)
We got the code which will return 0x2a (42) upon any call. 
Now we need to: 
    1) figure out the deployment bytecode and prepend to the runtime bytecode
    2) write a Smart Contract which will deploy the resulting bytecode and return its address
The deployment bytecode needs to do two main things: use CODECOPY to copy the current code bytes into the memory
and call RETURN to return them from the memory.
In Yul form this would look like:
    codecopy(destOffset, offset, size)
    return(offset, size)
Let's choose 0x00 as the memory destination. The size is 10 bytes. The 'offset' in the CODECOPY is unknown until we count the bytes 

PUSH1 0a => 600a
PUSH1 ?? => 60??
PUSH1 00 => 6000
CODECOPY => 39
PUSH1 0a => 600a
PUSH1 00 => 6000
RETURN => f3

Resulting bytecode: 600a60??600039600a6000f3
Size is 12 bytes, index starts from 0, we can safely assume that the 'offset' for CODECOPY should be '0x0c' (12 in hex form):
600a600c600039600a6000f3

Constructor bytecode + runtime bytecode = 600a600c600039600a6000f3602a60805260206080f3
The constructor part will be thrown away after deployment, so only the size of the runtime part matters (and it's 10 bytes)

Now let's write a Smart Contract which will deploy our minimalist Solver Smart Contract:
 */

contract Deployer {
    address public contrAddr;

    function create(bytes memory data) public {
        address contr;
        assembly {
            contr := create(0, add(data, 0x20), mload(data))
        }
        contrAddr = contr;
    }
}

/*
 Pass the complete bytecode and you grab the address from 'contrAddr'.
 Pass the address to Ethernaut 
 V●ᴥ●V
  */
