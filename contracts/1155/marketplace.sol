//SPDX-License-Identifier: MIX

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Marketplace {

    using SafeMath for uint256;

    address private admin;

    uint256 public marketplaceFee = 5;

    mapping (uint => address) public recipient;
    mapping (uint => uint) public fee;
    uint256 public recipientCount;

    mapping (uint => SellList) public sales;
    uint256 public salesId;

    mapping (uint => mapping (uint => OfferData)) public offerInfo;
    mapping (uint => uint) public offerCount;

    mapping (address => uint) public escrowAmount;

    mapping (uint => AuctionData) public auction;
    uint256 public auctionId;

    /// @notice This is the Sell struct, the basic structures contain the owner of the selling tokens.
    struct SellList {
        address seller;
        address token;
        uint256 tokenId;
        uint256 amountOfToken;
        uint256 deadline;
        uint256 price;
        bool isSold;
    }

    struct OfferData {
        address offerAddress;
        uint256 offerPrice;
        bool isAccepted;
    }

    struct AuctionData {
        address creator;
        address token;
        address highestBidder;
        uint256 tokenId;
        uint256 amountOfToken;
        uint256 highestBid;
        uint256 startPrice;
        uint256 minIncrement;
        uint256 startDate;
        uint256 duration;
        Action action;
    }

    enum Action {
        RESERVED, STARTED
    }
    /// @notice This is the emitted event, when a offer for a certain amount of tokens.
    event SellEvent (
        address _seller,
        address _token,
        uint256 _offerId,
        uint256 _tokenId,
        uint256 _amount
    );

    /// @notice This is the emitted event, when a sell is canceled.
    event CanceledSell (
        address _seller,
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken
    );

    /// @notice This is the emitted event, when a buy is made.
    event BuyEvent (
        address _buyer,
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _price
    );

    constructor()  {
        admin = msg.sender;
    }
    /**
        @param _newFee This is new marketplace fee amount
    **/
    function updateTotalFee(
        uint256 _newFee
    ) external onlyAdmin {
        // Set the new Marketplace fee
        marketplaceFee = _newFee;
    }

    /**
        @param _recipient These are the updated recipient addresses of the fees.
        @param _fee These are the updated fees for the recipients to receive.
    **/
    function updateFeeAndRecipient(
        address[] memory _recipient,
        uint256[] memory _fee
    ) external onlyAdmin {
        // _recipient and _fee counts should be the same
        require(_recipient.length == _fee.length, "updateFee: Not match");

        // Reset the recipientCount as updated data
        recipientCount = _fee.length;

        // Reset recipient and fee with newly data
        for (uint i = 0; i < recipientCount; i++) {
            recipient[i] = _recipient[i];
            fee[i] = _fee[i];
        }
    }

    /*
        @param _token This is the address of the ERC1155 token.
        @param _tokenId This is the ID of the token that's inside of the ERC1155 token.
        @param _amountOfToken This is the amount of tokens that are going to be sold in the offer.
        @param _deadline This is the final date in (seconds) so the offer ends.
        @param _price This is the full price for the amountOfToken that user passed as the param.
        @dev We are making some require for the parameters that needs to be required.
        @return Return true if the sell is created successfully.

        @param _token 这是 ERC1155 令牌的地址。
        @param _tokenId 这是 ERC1155 令牌内部的令牌 ID。
        @param _amountOfToken 这是将在要约中出售的代币数量。
        @param _deadline 这是以（秒）为单位的最终日期，因此优惠结束。
        @param _price 这是用户作为参数传递的 amountOfToken 的全价。
        @dev 我们正在对需要的参数提出一些要求。
        @return 如果销售创建成功则返回真。
    */
    function createList(
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _deadline,
        uint256 _price
    ) external returns (bool) {
        /*
            Check if amount of token is greater than 0
                full price for token  is greater than 0
                the deadline is longer than 1 hr

            检查token数量是否大于0
                令牌的全价大于 0
                截止日期超过 1 小时
        */
        require(_amountOfToken > 0, "The amount of tokens to sell, needs to be greater than 0");
        require(_price >= 0, "The full price for the tokens need to be greater than 0");
        require(_deadline >= 3600, "The deadline needs to be greater than 1 hour");

        /*
            Add variables to the SellList struct with tokenAddress, seller, tokenId, amountOfToken, deadline, price
            使用 tokenAddress、seller、tokenId、amountOfToken、deadline、price 将变量添加到 SellList 结构
        */
        sales[salesId] = SellList (
            msg.sender,
            _token,
            _tokenId,
            _amountOfToken,
            block.timestamp + _deadline,
            _price,
            false
        );

        /*
            Add the salesId as increment 1
            添加 salesId 作为增量 1
        */
        salesId ++;

        /*
            Emit the event when a sell is created.
            创建卖出时发出事件。
        */
        emit SellEvent(
            msg.sender,
            _token,
            salesId,
            _tokenId,
            _amountOfToken
        );

        return true;
    }

    /**
        @param _sellId This is the ID of the SellList that's stored in mapping function.
    **/
    function buyListToken(
        uint256 _sellId
    ) external payable returns (bool) {
        /*
            Check if the msg.sender is not zero address
            of this sell, and if is sold
            msg.value needs to be greater than the price
            检查 msg.sender 是否不是零地址
            这个卖，如果卖
            msg.value 需要大于价格
        */
        require(msg.sender != address(0), "buyToken: Needs to be a address.");
        require(sales[_sellId].isSold != true, "buyToken: The tokends were bought.");
        require(msg.value >= sales[_sellId].price, "buyToken: Needs to be greater or equal to the price.");

        /*
            Get salePrice and feePrice from the marketplaceFee
        */
        uint256 salePrice = sales[_sellId].price;
        uint256 feePrice = salePrice * marketplaceFee / 100;

        /*
            Transfer salePrice-feePrice to the seller's wallet
        */
        payable(sales[_sellId].seller).transfer(salePrice - feePrice);

        /*
            Distribution feePrice to the recipients' wallets
        */
        for (uint i = 0; i < recipientCount;  i++) {
        payable(recipient[i]).transfer(feePrice * fee[i] / 100);
        }


        /*
            After we send the Matic to the user, we send
            the amountOfToken to the msg.sender.
        */
        IERC1155(sales[_sellId].token).safeTransferFrom(
        sales[_sellId].seller,
        msg.sender,
        sales[_sellId].tokenId,
        sales[_sellId].amountOfToken,
        "0x0"
        );

    return true;
    }

    /**
        @param _sellId The ID of the sell that you want to cancel.
    **/
    function cancelList(
        uint256 _sellId
    ) external returns (bool) {
        /*
            Check if the msg.sender is really the owner
            of this sell, and if is not sold yet.
        */
        require(sales[_sellId].seller == msg.sender, "Cancel: should be the owner of the sell.");
        require(sales[_sellId].isSold != true, "Cancel: already sold.");
        /*
            After that checking we can safely delete the sell
            in our marketplace.
        */
        delete sales[_sellId];

        /*
            Emit the event when a sell is cancelled.
        */
        emit CanceledSell(
            sales[_sellId].seller,
            sales[_sellId].token,
            sales[_sellId].tokenId,
            sales[_sellId].amountOfToken
        );

        return true;
    }

    /*
        @param _receiver This is the address which will be receive the token.
        @param _token This is the address of the ERC1155 token.
        @param _tokenId This is the ID of the token that's inside of the ERC1155 token.
        @param _amountOfToken This is the amount of tokens that are going to be transferred.
        @dev We are making some require for the parameters that needs to be required.
        @return Return true if the sell is created successfully.

        @param _receiver 这是接收令牌的地址。
        @param _token 这是 ERC1155 令牌的地址。
        @param _tokenId 这是 ERC1155 令牌内部的令牌 ID。
        @param _amountOfToken 这是要转移的代币数量。
        @dev 我们正在对需要的参数提出一些要求。
        @return 如果销售创建成功则返回真。
    */
    function transfer(
        address _receiver,
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken
    ) external returns (bool) {
        /*
            Send ERC1155 token to _receiver wallet
            _amountOfToken to the _receiver


            将 ERC1155 代币发送到 _receiver 钱包
            _amountOfToken 到 _receiver
        */
        IERC1155(_token).safeTransferFrom(
            msg.sender,
            _receiver,
            _tokenId,
            _amountOfToken,
            "0x0"
        );

        return true;

    }

    /**
        @param _sellId The ID of the sell that you want to make an offer.
        @param _price The offer price for _sellId.

        @param _sellId 您要出价的销售ID。
        @param _price _sellId 的报价。
    **/
    function makeOffer(
        uint256 _sellId,
        uint256 _price
    ) external payable returns (bool) {

        /*
            Check if the msg.value is the same as the _price value of this sell,
             if the seller is msg.sender
             if it is not sold yet.

             检查 msg.value 是否与本次销售的 _price 值相同，
             如果卖家是 msg.sender
             如果还没有卖。
        */
        require(msg.value == _price, "makeOffer: msg.value should be the _price");
        require(sales[_sellId].seller != msg.sender, "makeOffer: seller shouldn't offer");
        require(sales[_sellId].isSold != true, "makeOffer: already sold.");

        /*
            Get the offerCount of this _sellId
            获取这个 _sellId 的 offerCount
        */
        uint256 counter = offerCount[_sellId];

        /*
            Add variables to the OfferData struct with offerAddress, offerPrice, offerAcceptable bool value
            使用 offerAddress、offerPrice、offerAcceptable 布尔值将变量添加到 OfferData 结构
        */
        offerInfo[_sellId][counter] = OfferData (
            msg.sender,
            msg.value,
            false
        );

        /*
            The offerCount[_sellId] value add +1
            offerCount[_sellId] 值加+1
        */
        offerCount[_sellId] ++;

        /*
            Add the value to the `escrowAmount[address]`
            将值添加到 `escrowAmount[address]`
        */
        escrowAmount[msg.sender] += msg.value;

        return true;
    }

    /**
        @param _sellId The ID of the sell that you want to make an offer.
        @param _offerCount The offer count to be accepted from the seller.


        @param _sellId 您要出价的销售ID。
        @param _offerCount 从卖家那里接受的报价数量。
    **/
    function acceptOffer(
        uint256 _sellId,
        uint256 _offerCount
    ) external returns (bool) {

        /*
            Get the offer data from _sellId and 
            从 _sellId 和 _offerCount 获取报价数据
        */
        OfferData memory offer = offerInfo[_sellId][_offerCount];

        /*
            Check if the sale NFTs are not sold
             if the seller is msg.sender
             if it is already accepted
             if offerPrice is larger than escrowAmount
            检查出售的 NFT 是否未售出
             如果卖家是 msg.sender
             如果它已经被接受
             如果 offerPrice 大于 escrowAmount 
        */
        require(sales[_sellId].isSold != true, "acceptOffer: already sold.");
        require(sales[_sellId].seller == msg.sender, "acceptOffer: not seller");
        require(offer.isAccepted == false, "acceptOffer: already accepted");
        require(offer.offerPrice <= escrowAmount[offer.offerAddress], "acceptOffer: lower amount");

        /*
            Get offerPrice and feePrice from the marketplaceFee
            从 marketplace 获取 offerPrice 和 feePriceFee
        */
        uint256 offerPrice = offer.offerPrice;
        uint256 feePrice = offerPrice * marketplaceFee / 100;

        /*
            Transfer offerPrice - feePrice to the seller's wallet
            将 offerPrice - feePrice 转入卖家钱包
        */
        payable(offer.offerAddress).transfer(offerPrice - feePrice);

    /*
        Distribution feePrice to the recipients' wallets
    */
    for (uint i = 0; i < recipientCount;  i++) {
    payable(recipient[i]).transfer(feePrice * fee[i] / 100);
    }

        /*
            Substract the offerPrice from the `escrowAmount[address]`
            从 escrowAmount[address] 中减去 offerPrice
        */
        escrowAmount[offer.offerAddress] -= offerPrice;

        /*
            After we send the Matic to the user, we send
            the amountOfToken to the msg.sender.
            在我们将 Matic 发送给用户之后，我们发送
            amountOfToken 到 msg.sender。
        */
        IERC1155(sales[_sellId].token).safeTransferFrom(
        sales[_sellId].seller,
        offer.offerAddress,
        sales[_sellId].tokenId,
        sales[_sellId].amountOfToken,
        "0x0"
        );

        /*
            Set the offer data as it is accepted
            在接受时设置报价数据
        */
        offerInfo[_sellId][_offerCount].isAccepted = true;

    return true;

    }


    /**
        @param _sellId The ID of the sell that you want to make an offer.
        @param _offerCount The offer count to be cancelled from the offerAddress.


        @param _sellId 您要出价的销售ID。
        @param _offerCount 要从 offerAddress 中取消的报价计数。
    **/
    function cancelOffer(
        uint256 _sellId,
        uint256 _offerCount
    ) external returns (bool) {

        /*
            Get the offer data from _sellId and _offerCount
            从 _sellId 和 _offerCount 获取报价数据
        */
        OfferData memory offer = offerInfo[_sellId][_offerCount];

        /*
            Check if the offer's offerAddress is msg.sender
                if the offer is already accepted
                if the offerPrice is larger than the escrowAmount
            检查offer的offerAddress是否为msg.sender
                如果报价已经被接受
                如果 offerPrice 大于 escrowAmount    
        */
        require(msg.sender == offer.offerAddress, "cancelOffer: not offerAddress");
        require(offer.isAccepted == false, "acceptOffer: already accepted");
        require(offer.offerPrice <= escrowAmount[msg.sender], "cancelOffer: lower amount");


        /*
            Transfer offerPrice return to the offerAddress
        */
        payable(offer.offerAddress).transfer(offer.offerPrice);

        /*
            Substract the offerPrice from the `escrowAmount[address]`
        */
        escrowAmount[msg.sender] -= offer.offerPrice;

        /*
            After that checking we can safely delete the offerData
            in our marketplace.
        */
        delete offerInfo[_sellId][_offerCount];

    return true;
    }

    /**
        @dev This function used to deposit the Matic on this platform
    **/
    function depositEscrow() external payable returns (bool) {
        /*
            Add the value to the `escrowAmount[address]`
        */
        escrowAmount[msg.sender] += msg.value;

        return true;

    }


    /**
        @dev This function used to withdraw the Matic on this platform
        @param _amount This is the amount of the Matic to withdraw from the marketplace

        @dev 这个函数用来在这个平台上撤回 Matic
        @param _amount 这是从市场上撤出的 Matic 数量
    **/
    function withdrawEscrow(
        uint256 _amount
    ) external returns (bool) {
        /*
            The _amount should be smaller than the `escrowAmount[address]`
        */
        require(_amount < escrowAmount[msg.sender], "withdrawEscrow: lower amount");

        /*
            Transfer _amount to the msg.sender wallet
        */
        payable(msg.sender).transfer(_amount);


        /*
            Substract the _amount from the `escrowAmount[address]`
        */
        escrowAmount[msg.sender] -= _amount;

    return true;

    }


    /*
        @param _token This is the address of the ERC1155 token.
        @param _tokenId This is the ID of the token that's inside of the ERC1155 token.
        @param _amountOfToken This is the amount of tokens that are going to be created in auction.
        @param _startPrice This is the start Price of the auction.
        @param _minIncrement This is the min increment of the bids in this auction.
        @param _startDate This is the start date in (seconds) so the auction starts.
        @param _duration This is the duration of this auction.
        @param _reserved 1: reserved acution 0: normal auction
        @dev We are making some require for the parameters that needs to be required.
        @return Return true if the auction is created successfully.

        @param _token 这是 ERC1155 令牌的地址。
        @param _tokenId 这是 ERC1155 令牌内部的令牌 ID。
        @param _amountOfToken 这是将在拍卖中创建的代币数量。
        @param _startPrice 这是拍卖的起始价格。
        @param _minIncrement 这是本次拍卖中出价的最小增量。
        @param _startDate 这是拍卖开始的开始日期（以秒为单位）。
        @param _duration 这是这次拍卖的持续时间。
        @param _reserved 1: 预留拍卖 0: 正常拍卖
        @dev 我们正在对需要的参数提出一些要求。
        @return 如果拍卖创建成功则返回真。
    */
    function createAuction(
        address _token,
        uint256 _tokenId,
        uint256 _amountOfToken,
        uint256 _startPrice,
        uint256 _minIncrement,
        uint256 _startDate,
        uint256 _duration,
        bool _reserved
    ) external returns (bool) {
        /*
            Check if amount of token is greater than 0
                the full price for token  is greater than 0
                the deadline is longer than 1 day
                the startPrice should be larger than 0
                the minIncrement should be larger than 0
                the startDate should be later than now
            检查token数量是否大于0
                token 的全价大于 0
                截止日期超过 1 天
                startPrice 应该大于 0
                minIncrement 应该大于 0
                开始日期应该晚于现在    
        */
        require(_amountOfToken > 0, "createAuction: The amount of tokens to sell, needs to be greater than 0");
        require(_startPrice > 0, "createAuction: The startPrice for the tokens need to be greater than 0");
        require(_duration > 86400, "createAuction: The deadline should to be greater than 1 day");
        require(_startPrice > 0, "createAuction: The start Price should be bigger than 0");
        require(_minIncrement > 0, "createAuction: The minIncrement should be bigger than 0");
        require(_startDate > block.timestamp, "createAuction: The start date should be after now");

        Action action;

        if (!_reserved) {
            action = Action.STARTED;
        }

        /*
            Add variables to the SellList struct with tokenAddress, seller, tokenId, amountOfToken, deadline, price
            使用 tokenAddress、seller、tokenId、amountOfToken、deadline、price 将变量添加到 SellList 结构
        */
        auction[auctionId] = AuctionData (
            msg.sender,
            _token,
            address(0),
            _tokenId,
            _amountOfToken,
            _startPrice - _minIncrement,
            _startPrice,
            _minIncrement,
            _startDate,
            _duration,
            action
        );

        /*
            Add the auctionId as increment 1
        */
        auctionId ++;

        return true;

    }

    /*
        @param _auctionId Users can bid to the _auctionId with value
    */
    function placeBid(
        uint256 _auctionId
    ) external payable returns (bool) {
        /*
            Get the auction data from _aucitonId
        */
        AuctionData memory auctionInfo = auction[_auctionId];

        /*
            Check if bidAmount is bigger than the higestBid + minIncrement
                if the creator is msg.sender
                if the bidTime is after the startDate
        */
        require(msg.value >= auctionInfo.highestBid + auctionInfo.minIncrement, "placeBid: Bid amount should be bigger than highestBid");
        require(msg.sender != auctionInfo.creator, "placeBid: Creator can't bid");
        require(block.timestamp >= auctionInfo.startDate, "placeBid: Bid should be after the startDate");
        require(auctionInfo.action == Action.RESERVED || auctionInfo.startDate + auctionInfo.duration > block.timestamp, "placeBid: It is Ended");

        /*
            Send back the highestBid to the highestBidder - who is not zero address
        */
        if (auctionInfo.highestBidder != address(0)) {
            payable(auctionInfo.highestBidder).transfer(auctionInfo.highestBid);
        }

        /*
            If the auction is reserved, set the startDate as now
            action as Action Enum - STARTED
        */
        if (auctionInfo.action == Action.RESERVED) {
            auction[_auctionId].startDate = block.timestamp;
            auction[_auctionId].action = Action.STARTED;
        }

        /*
            Set the auctionData's highest bidder as msg.sender - who is the new bidder
                the auctionData's highest bid as msg.value - what is the new bid value
        */
        auction[_auctionId].highestBidder = msg.sender;
        auction[_auctionId].highestBid = msg.value;

        return true;

    }

    /*
        @param _auctionId The auction Creator can cancel the auction
    */
    function cancelAuction(
        uint256 _auctionId
    ) external returns (bool) {
        /*
            Get the auction data from _aucitonId
        */
        AuctionData memory auctionInfo = auction[_auctionId];

        /*
            Check if the msg.sender should be the auction's creator
                if the now time should be after auction's endDate
                if the auction's highestBidder should be zero address
        */
        require(msg.sender == auctionInfo.creator, "cancelAuction: Only auction creator can cancel it");
        require(block.timestamp > auctionInfo.startDate + auctionInfo.duration, "cancelAuction: The time should be after endDate");
        require(auctionInfo.highestBidder == address(0), "cancelAuction: There should be not highestBidder");

        /*
            Delete the auctionData from the blockchain
        */
        delete auction[_auctionId];

        return true;

    }

    /*
        @param _auctionId The highest bidder can claim the _auctionId's result
    */
    function claimAuction(
        uint256 _auctionId
    ) external returns (bool) {
        /*
            Get the auction data from _aucitonId
        */
        AuctionData memory auctionInfo = auction[_auctionId];

        /*
            Check if the msg.sender should be the highestBidder
                if the now time should be after auction's endDate
                if the auction's highestBidder should be zero address
        */
        require(msg.sender == auctionInfo.highestBidder, "claimAuction: The msg.sender should be the highest Bidder");
        require(block.timestamp > auctionInfo.startDate + auctionInfo.duration, "claimAuction: The time should be after endDate");

        /*
            Send the amountOfToken to the highest Bidder.
        */
        IERC1155(auctionInfo.token).safeTransferFrom(
            auctionInfo.creator,
            auctionInfo.highestBidder,
            auctionInfo.tokenId,
            auctionInfo.amountOfToken,
            "0x0"
        );

        /*
            Get bidPrice and feePrice from the marketplaceFee
        */
        uint256 bidPrice = auctionInfo.highestBid;
        uint256 feePrice = bidPrice * marketplaceFee / 100;

        /*
            Transfer bidPrice-feePrice to the creator's wallet
        */
        payable(auctionInfo.creator).transfer(bidPrice - feePrice);

        /*
            Distribution feePrice to the recipients' wallets
        */
        for (uint i = 0; i < recipientCount;  i++) {
        payable(recipient[i]).transfer(feePrice * fee[i] / 100);
        }


    return true;

    }



    /**
        @dev This is the modifier to make - only Admin can access the function
        @dev 这是要制作的修饰符 - 只有管理员可以访问该功能
    **/
    modifier onlyAdmin{
        require(admin == msg.sender, "OA");
        _;
    }

}