# Aeternity migration scheme [proposal]

## Intro
This proposal aims to describe a possible aeternity erc20 token migration implementation for Lima HF.


## Specification

#### Requirements:
- [0] Aeternity ERC20 token (locked contract)
- [1] Aeternity Migration smart contract (Solidity, Ethereum)
- [2] Aeternity Migration smart contract (Sophia, Aeternity)
- [3] New tokens introduced in the HF
- [4] Oracle (consisted of smart contract + backend service)

#### Scheme of the workflow

```

         +-------------------------------------------+
         |  Ethereum Blockchain                      |
         |-------------------------------------------|
         |   +---------------+         +----------+  |
         |   |Aeternity      |         |Aeternity |  |       User
         |   |Ethereum       |         |Ethereum  |<-------+ - eth address
         |   |ERC20 Token    |<-------+|Migration |  |       - ae address
         |   |Locked Contract|         |Contract  |  |
         |   +---------------+         +----+-----+  |       ^
         |                                  |        |       |
         |                                  |        |       |
         |    +-------------------+         |        |       |
         |    | Fire Migration    | <-------+        |       |
         |    | Event             |                  |       |
         |    +--------------+----+                  |       |
         |              ^    |                       |       |
         +--------------|----|-----------------------+       |
                        |    |                               |
                        |    |                               |
                        |    |                               |
               +--------+----v---------------+               |
               |                             |               |
               |  Backend service / Oracle   |               |
               |                             |               |
               |                             |               |
               +-----------------------+-----+               |
                                       |                     |
                                       |                     |
             +-------------------------|-----------+         |
             | Aeternity Blockchain    |           |         |
             |-------------------------|-----------|         |
             |                         |           |         |
             |  +--------------+       |           |         |
             |  | Aeternity    |       |           |         |
             |  | Sophia       <-------+           |         |
             |  | Migration    |                   |         |
             |  | Contract     |                   |         |
             |  |              +-----------------------------+
             |  +--------------+                   |
             |                                     |
             |                                     |
             |                                     |
             |                                     |
             +-------------------------------------+
```


## Implementation
#### 0. Aeternity ERC20 token

We do not need to do anything here - tokens are already locked.

#### 1. Ethereum smart contract

Implement and deploy a solidity smart contract which has only one function with an event attached to it like so:

Every one could call the `migrate` function passing aeternity address (beneficiary for the migrated tokens), if the caller has tokens locked in the aeternity erc20 token contract, then and only then, an event will be emitted with the following parameters:
- user ethereum address
- balance of aeternity erc20 tokens locked in the ethereum smart contract
- aeternity beneficiary address to receive the migrated tokens

```
pragma solidity >=0.4.22 <0.6.0;

contract ERC20 {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AeternityMigration {
    address aeternityTokenAddress  = 0x5CA9a71B1d01849C0a95490Cc00559717fCF0D1d;
    mapping(address => bool) migrated;
    event LogMigrated(address indexed caller, uint256 indexed balance, string indexed migrationAddress);

    constructor() public {}
    
    function migrate(string memory migrateToAddress) public returns(bool)
    {
        require(!migrated[msg.sender], "Already migrated!");
        migrated[msg.sender] = true;
        ERC20 aeternityToken = ERC20(aeternityTokenAddress);
        uint256 balance = aeternityToken.balanceOf(msg.sender);
        require(balance > 0, "You don't have any balance.");
        emit LogMigrated(msg.sender, balance, migrateToAddress);
    }
}
```

#### 2. Sophia smart contract

```
contract AeternityMigration =
  record state = { migrated: map(address, bool) }
  
  entrypoint init() = { migrated = { } }

  entrypoint get_state() : state = state
  
  stateful entrypoint migrate(amount: int, beneficiary: address) : bool =
    require(state.migrated[beneficiary] == false, "Already migrated")
    
    // Query the oracle to check for the presence
    // of emited event with the beneficiary address, amount migrated
    // and ethereum address
    
    // Oracle.query()
    // Oracle.get_answer()

    // eventually
    put(state{ migrated[beneficiary] = true })
    Chain.spend(beneficiary, amount)
    true
```
#### 3. New tokens from the HF

Deploy contract initialy and keep it locked with until the HF when the whole amount of migrated tokens needed to be introduced in cicruclation are 'given' to the contract.

#### 4. Oracle

The oracle backend service is listening for emitted events in the ethereum smart contract, and is persisting the balance in:
    
- a) on-chain smart contract [if the oracle is smart-contract based]
- b) database [if the oracle is NOT smart-contract based]
