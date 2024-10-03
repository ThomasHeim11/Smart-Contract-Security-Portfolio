// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/sn/Cairo.sol";

/**
 * @title Cairo testing.
 */
contract CairoFuzz is Test {
    function setUp() public {}

    // Fuzz test for uint256Serialize
    function testFuzz_uint256Serialize(uint256 value) public {
        uint256[] memory buf = new uint256[](2);
        uint256 offset = 0;

        offset += Cairo.uint256Serialize(value, buf, offset);
        assertEq(offset, 2);
        assertEq(buf[0], uint128(value));
        assertEq(buf[1], uint128(value >> 128));
    }

    function testFuzz_uint256Deserialize(uint256 value) public {
        uint256[] memory buf = new uint256[](2);
        buf[0] = uint128(value);
        buf[1] = uint128(value >> 128);

        uint256 v = Cairo.uint256Deserialize(buf, 0);
        assertEq(v, value);
    }

    // Fuzz test for uint256ArraySerialize
    function testFuzz_uint256ArraySerialize(uint256[] memory data) public {
        uint256 len = data.length;
        uint256[] memory buf = new uint256[](1 + len * 2);
        uint256 offset = 0;

        uint256 inc = Cairo.uint256ArraySerialize(data, buf, offset);
        assertEq(inc, 1 + len * 2);
        assertEq(buf[0], len);
        for (uint256 i = 0; i < len; i++) {
            assertEq(buf[1 + i * 2], uint128(data[i]));
            assertEq(buf[2 + i * 2], uint128(data[i] >> 128));
        }
    }

    function testFuzz_uint256ArrayDeserialize(uint256[] memory data) public {
        uint256 len = data.length;
        uint256[] memory buf = new uint256[](1 + len * 2);
        buf[0] = len;
        for (uint256 i = 0; i < len; i++) {
            buf[1 + i * 2] = uint128(data[i]);
            buf[2 + i * 2] = uint128(data[i] >> 128);
        }

        (uint256 inc, uint256[] memory result) = Cairo.uint256ArrayDeserialize(buf, 0);
        assertEq(inc, 1 + len * 2);
        assertEq(result.length, len);
        for (uint256 i = 0; i < len; i++) {
            assertEq(result[i], data[i]);
        }
    }

    // Fuzz test for cairoStringPack
    function testFuzz_cairoStringPack(string memory s) public {
        uint256[] memory buf = Cairo.cairoStringPack(s);
        string memory unpacked = Cairo.cairoStringUnpack(buf, 0);
        assertEq(unpacked, s);
    }

    // Fuzz test for cairoStringArraySerialize
    function testFuzz_cairoStringArraySerialize(string[] memory data) public {
        uint256 len = data.length;
        // Calculate the required buffer length
        uint256 totalLength = 1; // Start with the length of the array
        for (uint256 i = 0; i < len; i++) {
            totalLength += Cairo.cairoStringSerializedLength(data[i]);
        }
        uint256[] memory buf = new uint256[](totalLength);

        uint256 inc = Cairo.cairoStringArraySerialize(data, buf, 0);
        assertEq(inc, totalLength);

        (uint256 dec, string[] memory result) = Cairo.cairoStringArrayDeserialize(buf, 0);
        assertEq(dec, totalLength);
        assertEq(result.length, data.length);
        for (uint256 i = 0; i < data.length; i++) {
            assertEq(result[i], data[i]);
        }
    }

    // Fuzz test for arithmetic errors in serialization functions using Foundry
    function testFuzz_ArithmeticErrorsInSerialization(uint256 value, uint256[] memory data, string memory s) public {
        // Edge case for uint256 serialization/deserialization
        uint256[] memory buf = new uint256[](2);
        Cairo.uint256Serialize(value, buf, 0);
        assertEq(buf[0], uint128(value));
        assertEq(buf[1], uint128(value >> 128));

        uint256 deserializedValue = Cairo.uint256Deserialize(buf, 0);
        assertEq(deserializedValue, value);

        // Edge case for uint256 array serialization/deserialization
        uint256 len = data.length;
        if (len > type(uint256).max / 2 - 1) return; // Ensure we do not overflow buffer size
        buf = new uint256[](1 + len * 2);
        uint256 inc = Cairo.uint256ArraySerialize(data, buf, 0);
        (uint256 inc2, uint256[] memory deserializedArray) = Cairo.uint256ArrayDeserialize(buf, 0);
        assertEq(inc, 1 + len * 2);
        assertEq(inc2, 1 + len * 2);
        assertEq(deserializedArray.length, len);
        for (uint256 i = 0; i < len; i++) {
            assertEq(deserializedArray[i], data[i]);
        }

        // Edge case for string serialization/deserialization
        uint256[] memory stringBuf = Cairo.cairoStringPack(s);
        string memory unpacked = Cairo.cairoStringUnpack(stringBuf, 0);
        assertEq(unpacked, s);
    }
}
