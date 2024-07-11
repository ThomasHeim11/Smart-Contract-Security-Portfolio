// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableMap.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableMap.js.

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32Map`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003c0000, 1037618708540) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003c0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003c0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003c6002, value) }
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003d0000, 1037618708541) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003d0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003d0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003d6001, key) }
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003f0000, 1037618708543) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003f0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003f0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003f6001, key) }
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00400000, 1037618708544) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00400001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00400005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00406000, map.slot) }
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003e0000, 1037618708542) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003e0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003e0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff003e6001, index) }
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00410000, 1037618708545) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00410001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00410005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00416001, key) }
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00420000, 1037618708546) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00420001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00420005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00426001, key) }
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00430000, 1037618708547) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00430001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00430005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00436002, errorMessage) }
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00440000, 1037618708548) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00440001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00440005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00446002, value) }
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00450000, 1037618708549) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00450001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00450005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00456001, key) }
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00460000, 1037618708550) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00460001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00460005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00466001, key) }
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00470000, 1037618708551) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00470001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00470005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00476000, map.slot) }
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00480000, 1037618708552) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00480001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00480005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00486001, index) }
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00490000, 1037618708553) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00490001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00490005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00496001, key) }
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004a0000, 1037618708554) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004a0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004a0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004a6001, key) }
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004b0000, 1037618708555) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004b0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004b0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004b6002, errorMessage) }
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00580000, 1037618708568) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00580001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00580005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00586002, value) }
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00570000, 1037618708567) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00570001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00570005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00576001, key) }
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00560000, 1037618708566) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00560001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00560005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00566001, key) }
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00590000, 1037618708569) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00590001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00590005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00596000, map.slot) }
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005a0000, 1037618708570) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005a0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005a0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005a6001, index) }
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b0000, 1037618708571) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005b6001, key) }
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c0000, 1037618708572) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005c6001, key) }
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005d0000, 1037618708573) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005d0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005d0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005d6002, errorMessage) }
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005e0000, 1037618708574) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005e0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005e0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005e6002, value) }
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005f0000, 1037618708575) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005f0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005f0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff005f6001, key) }
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00530000, 1037618708563) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00530001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00530005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00536001, key) }
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00540000, 1037618708564) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00540001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00540005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00546000, map.slot) }
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00550000, 1037618708565) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00550001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00550005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00556001, index) }
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004c0000, 1037618708556) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004c0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004c0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004c6001, key) }
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004d0000, 1037618708557) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004d0001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004d0005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004d6001, key) }
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004e0000, 1037618708558) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004e0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004e0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004e6002, errorMessage) }
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004f0000, 1037618708559) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004f0001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004f0005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff004f6002, value) }
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00500000, 1037618708560) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00500001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00500005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00506001, key) }
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00510000, 1037618708561) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00510001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00510005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00516001, key) }
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00520000, 1037618708562) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00520001, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00520005, 1) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00526000, map.slot) }
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00600000, 1037618708576) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00600001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00600005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00606001, index) }
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`. O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00610000, 1037618708577) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00610001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00610005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00616001, key) }
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`. O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00620000, 1037618708578) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00620001, 2) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00620005, 9) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00626001, key) }
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {assembly ("memory-safe") { mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00630000, 1037618708579) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00630001, 3) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00630005, 73) mstore(0xffffff6e4604afefe123321beef1b01fffffffffffffffffffffffff00636002, errorMessage) }
        return uint256(get(map._inner, key, errorMessage));
    }
}