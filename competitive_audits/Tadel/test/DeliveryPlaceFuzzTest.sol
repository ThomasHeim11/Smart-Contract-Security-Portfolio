// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/core/DeliveryPlace.sol";
import {OfferInfo, OfferStatus, OfferType, OfferSettleType} from "../src/storage/OfferStatus.sol"; // Adjust the path accordingly
import {MarketPlaceStatus, MarketPlaceInfo} from "../src/interfaces/ISystemConfig.sol";
import {StockInfo, StockStatus, StockType} from "../src/interfaces/IPerMarkets.sol";

contract DeliveryPlaceFuzzTest is Test {
    DeliveryPlace deliveryPlace;

    function setUp() public {
        // Deploy the DeliveryPlace contract
        deliveryPlace = new DeliveryPlace();
    }

    function testCloseBidOfferFuzz(uint8 _offerType, uint8 _status, uint8 _offerStatus) public {
        // Fuzz input values with enums ensuring they are within bounds
        _offerType = uint8(bound(_offerType, 0, 1));
        _status = uint8(bound(_status, 0, 2));
        _offerStatus = uint8(bound(_offerStatus, 0, 2));

        // Mock OfferInfo and related structs with fuzzed enum values
        OfferInfo memory offerInfo = OfferInfo({
            offerType: OfferType(_offerType),
            offerStatus: OfferStatus(_offerStatus),
            amount: 1000,
            points: 500,
            usedPoints: 300,
            collateralRate: 200,
            authority: address(this),
            maker: address(this)
        });

        MakerInfo memory makerInfo = MakerInfo({
            offerSettleType: OfferSettleType.Standard,
            tokenAddress: address(this),
            marketPlace: address(this),
            originOffer: address(this)
        });

        MarketPlaceStatus marketPlaceStatus = MarketPlaceStatus(_status);

        // Call closeBidOffer and expect certain behaviors based on the fuzzed inputs
        if (_offerType == uint8(OfferType.Ask)) {
            vm.expectRevert();
            deliveryPlace.closeBidOffer(address(offerInfo));
        } else if (_offerStatus != uint8(OfferStatus.Virgin)) {
            vm.expectRevert();
            deliveryPlace.closeBidOffer(address(offerInfo));
        } else {
            // If inputs are valid, the function should pass without reverting
            deliveryPlace.closeBidOffer(address(offerInfo));
        }
    }

    function testSettleAskMakerFuzz(
        uint8 _offerType,
        uint8 _status,
        uint8 _offerStatus,
        uint256 _settledPoints,
        uint256 _usedPoints
    ) public {
        // Fuzz input values with enums ensuring they are within bounds
        _offerType = uint8(bound(_offerType, 0, 1));
        _status = uint8(bound(_status, 0, 2));
        _offerStatus = uint8(bound(_offerStatus, 0, 2));

        // Mock OfferInfo and related structs with fuzzed enum values
        OfferInfo memory offerInfo = OfferInfo({
            offerType: OfferType(_offerType),
            offerStatus: OfferStatus(_offerStatus),
            amount: 1000,
            points: 500,
            usedPoints: _usedPoints,
            collateralRate: 200,
            authority: address(this),
            maker: address(this)
        });

        MakerInfo memory makerInfo = MakerInfo({
            offerSettleType: OfferSettleType.Standard,
            tokenAddress: address(this),
            marketPlace: address(this),
            originOffer: address(this)
        });

        MarketPlaceStatus marketPlaceStatus = MarketPlaceStatus(_status);

        if (_offerType == uint8(OfferType.Bid) || _offerStatus != uint8(OfferStatus.Virgin)) {
            vm.expectRevert();
            deliveryPlace.settleAskMaker(address(offerInfo), _settledPoints);
        } else if (_settledPoints > _usedPoints) {
            vm.expectRevert();
            deliveryPlace.settleAskMaker(address(offerInfo), _settledPoints);
        } else {
            // If inputs are valid, the function should pass without reverting
            deliveryPlace.settleAskMaker(address(offerInfo), _settledPoints);
        }
    }

    // More fuzz tests for other functions can be added in a similar fashion
}
