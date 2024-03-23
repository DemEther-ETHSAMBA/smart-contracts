//SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

/// -----------------------------------------------------------------------
/// Imports
/// -----------------------------------------------------------------------

//  ==========  External imports  ==========

import { DN404 } from "@DN404/src/DN404.sol";
import { DN404Mirror } from "@DN404/src/DN404Mirror.sol";
import { LibString } from "@DN404/lib/solady/src/utils/LibString.sol";
import { SafeTransferLib } from "@DN404/lib/solady/src/utils/SafeTransferLib.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";


// This import includes functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/automation/KeeperCompatible.sol";

import {IPriceSafraAgregadorV3} from "./chainlink/IPriceSafraAgregadorV3.sol";

//  ==========  Internal imports  ==========

import { SecurityUpgradeable } from "./SecurityUpgradeable.sol";

/// -----------------------------------------------------------------------
/// Contract
/// -----------------------------------------------------------------------

/**
 * @title DN-404 hybrid token smart contract.
 * @dev Uses {DN404} smart contract from @Vectorized (https://github.com/Vectorized/dn404).
 */
contract DN404Upgradeable is DN404, 
SecurityUpgradeable, 
UUPSUpgradeable, 
KeeperCompatibleInterface {
    /// -----------------------------------------------------------------------
    /// State variables
    /// -----------------------------------------------------------------------

    IPriceSafraAgregadorV3 public priceFeed; //price real time Safra token
    int256 public currentPrice;

    string private s_name;
    string private s_symbol;
    string private s_baseURI;


    // IPFS URIs for the dynamic nft https://nft.storage/
    // NOTE: IPFs valuation Safra
    string constant public SafraHype = "https://ipfs.io/ipfs/QmTXGUE8ciatzL1epqZTQRDDpzCXQSksQndQnaATfT9ATN";
    string constant public SafraMedium = "https://ipfs.io/ipfs/QmWYLkVwHR29GzYXQzZfAnvjNFQtWs2QGJSxEHspgr71YL";

    uint public /*immutable*/ interval;
    uint public lastTimeStamp;
    event TokenUpdated(string SafraURI);

    /// -----------------------------------------------------------------------
    /// Initializer/constructor
    /// -----------------------------------------------------------------------

    /**
     * @dev Constructor with {_disableInitializers} internal function from {UUPSUpgradeable}
     * proxy smart contract. This function disables initializer function calls in the implementation
     * contract.
     */
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initializes the smart contract.
     * @dev This function is required so that the upgradeable proxy is functional.
     * @dev Callable only once.
     * @dev Uses `initializer` from OpenZeppelin's {Initializer}.
     * @param owner_: owner address of the contract.
     * @param name_: name of the collection.
     * @param symbol_: collection symbol.
     * @param initialTokenSupply: initial token supply
     * @param initialSupplyOwner: initial supply given to the owner.
     */
    function initialize(
        address deployer,
        address owner_,
        string memory name_,
        string memory symbol_,
        uint96 initialTokenSupply,
        address initialSupplyOwner,
        uint256 updateInterval,
        address _priceFeed
    ) external initializer {
        __Security_init(owner_);

        s_name = name_;
        s_symbol = symbol_;    

        // address mirror = address(new DN404Mirror(owner_));
        address mirror = address(new DN404Mirror(deployer));
        _initializeDN404(initialTokenSupply, initialSupplyOwner, mirror);
        _mint(address(this), 100e18);
        ///@dev mint in the contract for sale
    
        ///@dev Chainlink information above
        //sets the keepers update interval
        interval = updateInterval;
        lastTimeStamp = block.timestamp;

        // the value of the Safra is updated from the interface contract, 
        //which is updated in real time with the values of the tokenized Safra
       priceFeed = IPriceSafraAgregadorV3(_priceFeed);
        currentPrice = getLatestPrice();
    }

    /// -----------------------------------------------------------------------
    /// State-change public/external functions
    /// -----------------------------------------------------------------------

    /**
     * @notice Mints given amount of tokens. This allows the owner of the contract to mint more tokens.
     * @param to: address to which tokens should be minted.
     * @param amount: amount of tokens to mint.
     */
    function mint(address to, uint256 amount) external nonReentrant{
        _mint(to, amount);
    }

    /**
     * @notice Mints given amount of tokens. This allows the owner of the contract to mint more tokens.
     * @param _amount: amount of tokens to mint.
     */
    function buy(uint _amount, address _to) external nonReentrant{
        _transfer(address(this), _to, _amount);
    }

    /**
     * @notice Mints given amount of tokens. This allows the owner of the contract to mint more tokens.
     * @param _amount: amount of tokens to burn.
     */
    function burn(uint _amount)external{
        _burn(msg.sender, _amount);
    }

    /**
     * @notice Sets new base URI for the NFT collection.
     * @param baseURI_: new base URI string.
     */
    function _setBaseURI(string memory baseURI_) private{
        s_baseURI = baseURI_;
    }

    /**
     * @notice Sets new base URI for the NFT collection.
     * @param baseURI_: new base URI string.
     */
    function setBaseURI(string memory baseURI_) public onlyOwner{
        _setBaseURI(baseURI_);
    }

    /**
     * @notice Withdraws all deposited ETH to caller.
     */
    function withdraw() external onlyOwner{
        SafeTransferLib.safeTransferAllETH(msg.sender);
    }

    /// -----------------------------------------------------------------------
    /// View internal/private functions
    /// -----------------------------------------------------------------------

    /**
     * @dev Authorizes smart contract upgrade (required by {UUPSUpgradeable}).
     * @dev Only contract owner or backend can call this function.
     * @dev Won't work if contract is paused.
     * @inheritdoc UUPSUpgradeable
     */
    function _authorizeUpgrade(address /*newImplementation*/) internal view onlyOwner override(UUPSUpgradeable) {
        __whenNotPaused();
    }

    /// -----------------------------------------------------------------------
    /// Chainlink functions
    /// -----------------------------------------------------------------------

/** keepers function to check the date here, for example, it could be the time.
* https://docs.chain.link/docs/chainlink-keepers/compatible-contracts/
* Study the link above, but basically the function below checks the data entered, one of the examples could be the balance of a given address
* The function is ovverride which must be exactly the same as defined in the inherited contract.  
* performData checks offchain the gas used to give more performance
* Register your upKeep to be able to check
* https://keepers.chain.link/?_ga=2.242618306.19640795.1664047080-2058578950.1640689712
*/ 
   /**
     * @notice Sets new base URI for the NFT collection.
     */
     function checkUpkeep(bytes calldata /* checkData */) external view override returns(bool upkeepNeeded, bytes memory /*performData*/) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }


/**The performance function refers to the gas limit, where when registering keepers you can define the limit for execution
If the defined limit is exceeded, the function is not executed. 
Thus, you get better performance by specifying the function's execution gas limit in callGasLimit when data is inserted.
*/

     /**
     * @notice Sets new base URI for the NFT collection.
     */
    function performUpkeep(bytes calldata /*performData*/) external override {
        if ((block.timestamp - lastTimeStamp) > interval){
            lastTimeStamp = block.timestamp;

            int latestPrice = getLatestPrice(); 

            if(latestPrice == currentPrice){
                return;
            } 
            if(latestPrice < currentPrice){
                //bear
                updateAllTokenUris("basic");
            } else {
                ///bull
                updateAllTokenUris("luxo");
            }

        currentPrice = latestPrice;
        } else {
            // interval nor elapsed. intervalo não decorrido. No upkeep

        }
    }

    /**
    @dev priceFeed.latestRoundData()
    look we have defined the AgregatorV3 contract we have inserted the address of the contract that pulls the price of the asset we want in dollars
    So, here it will return the value we want..
    Look at the specifications on the Chainlink website in API References:
    https://docs.chain.link/docs/data-feeds/price-feeds/api-reference/
    notice that we are returning the function defined in the chainlink data feed contract itself to return the asset price
     */

    function getLatestPrice() public view returns(int256){
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return price; //decimals detail: https://docs.chain.link/docs/data-feeds/price-feeds/addresses/
    } // example price return 3034715771688


    //  /**
    //  * @notice Update TokenUris.
    //  * @param trend: trend according to the Safra price
    //  */
     function updateAllTokenUris(string memory trend) internal{
        if(compareStrings("basic", trend)){
                _setBaseURI(SafraMedium);
        }else {
                _setBaseURI(SafraHype);
        }

        emit TokenUpdated(trend);
    }

    /// -----------------------------------------------------------------------
    /// Helpers chainlink functions
    /// -----------------------------------------------------------------------

    
    function compareStrings(string memory a, string memory b) internal pure returns(bool){
        return (keccak256(abi.encodePacked(a)) ==  keccak256(abi.encodePacked(b)));
    }

    function setInterval(uint256 newInterval)public onlyOwner{
        interval = newInterval;
    }

    function setPriceFeed(address newFeed) public onlyOwner{
        priceFeed = IPriceSafraAgregadorV3(newFeed);
    }


     /// -----------------------------------------------------------------------
    /// View public/external functions
    /// -----------------------------------------------------------------------


    /**
     * @notice Reads s_name storage variable.
     * @return the name of the token.
     * @inheritdoc DN404
     */
    function name() public view override(DN404) returns (string memory) {
        return s_name;
    }

    /**
     * @notice Reads s_symbol storage variable.
     * @return the symbol of the token.
     * @inheritdoc DN404
     */
    function symbol() public view override(DN404) returns (string memory) {
        return s_symbol;
    }

    /**
     * @notice Gets the URI of the given token ID.
     * @param tokenId: ID of the token for its URI.
     * @return result the URI of the token.
     * @inheritdoc DN404
     */
    function tokenURI(uint256 tokenId) public view override(DN404) returns (string memory result) {
        //no use tokenId always returns base URI 
        result = string(abi.encodePacked(s_baseURI));//insert ".json" ;
    }

    /**
     * @notice Reads the s_baseURI storage variable.
     * @return the base URI of this collection.
     */
    function getBaseURI() external view returns (string memory) {
        return s_baseURI;
    }
}
