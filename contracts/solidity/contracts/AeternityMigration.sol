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