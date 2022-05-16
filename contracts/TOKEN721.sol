// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NOMBRETOKEN is ERC721A, Pausable, ReentrancyGuard, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    uint256 constant maxTokensPerBuy = 25;
    uint256 constant totalTokens = 10101;
    uint256 private teamTokenMaxAmount = 350;
    uint256 private teamTokenMinted;
    uint256 private tokensSold;

    mapping(uint256 => uint256) public pricePerPhase;
    mapping(uint256 => uint256) public maxRangePerPhase;
    uint256 public numPhases;
    uint256 maxPrice;

    mapping(address => uint256) public tokensMintedPerUser;
    mapping(address => bool) private whiteList;
    bool private whiteListOn;

    string private _baseTokenURI;

    modifier isWhiteListed(){
        if(whiteListOn){
            require(whiteList[msg.sender] == true, "User is not whiteListed");
        }
        _;
    }

    constructor(uint256 _maxPrice, string memory baseURI) ERC721A("NOMBRETOKEN", "SIMBOLOTOKEN", maxTokensPerBuy, totalTokens) {
        whiteListOn = true;
        maxPrice = _maxPrice;
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setPricePerPhase(uint256 _phase, uint256 _price) public onlyOwner{
        pricePerPhase[_phase] = _price;
    }

    function setMaxRangePerPhase(uint256 _phase, uint256 _maxRange) public onlyOwner{
        maxRangePerPhase[_phase] = _maxRange;
    }

    function setNumPhases(uint256 _numPhases) public onlyOwner{
        numPhases = _numPhases;
    }

    function addUserToWhiteList(address _user) public onlyOwner{
        whiteList[_user] = true;
    }

    function removeUserFromWhiteList(address _user) public onlyOwner{
        whiteList[_user] = false;
    }

    function changeWhiteListState(bool state) public onlyOwner{
        whiteListOn = state;
    }

    function publicSaleMint(uint256 _amount) payable public nonReentrant isWhiteListed whenNotPaused{
        require(tokensSold + _amount <= totalTokens, "Amount surpases the tokens left to mint");
        require(_amount <= maxBatchSize, "Can only mint maximum of 25 tokens per call");
        require(tokensMintedPerUser[msg.sender] + _amount <= maxTokensPerBuy, "Quantity surpases the max amount per user");
        uint256 price = calculatePrice(_amount);
    
        teamTokenMinted += _amount;
        tokensSold += _amount;
        tokensMintedPerUser[msg.sender] += _amount;
        _safeMint(msg.sender, _amount);

        refundIfOver(price);
    }

    function devMint(address _reciever, uint256 _amount) public onlyOwner{
        require(teamTokenMinted+_amount <= teamTokenMaxAmount, "Amount surpases the tokens left to mint for the team");
        require(_amount <= maxBatchSize, "Can only mint maximum of 25 tokens per call");
        teamTokenMinted += _amount;
        tokensSold += _amount;
        _safeMint(_reciever, _amount);
    }

    function refundIfOver(uint256 price) private {
        require(msg.value >= price, "Need to send more ETH.");
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function withdrawMoney() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function calculatePrice(uint256 _amount) public view returns(uint256){
        for(uint256 i = 0; i < numPhases; i++){
            if(tokensSold < maxRangePerPhase[i]){
                return pricePerPhase[i] * _amount;
            }
        }
        return maxPrice * _amount;
    }


    function getOwnershipData(uint256 tokenId)
        public
        view
    returns (TokenOwnership memory)
    {
        return ownershipOf(tokenId);
    }

    function _beforeTokenTransfers(address from, address to, uint256 startTokenId, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfers(from, to, startTokenId, amount);
    }
    
}