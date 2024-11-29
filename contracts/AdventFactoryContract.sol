// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ERC721.sol";
import "./Counters.sol";

// Collection Contract
contract AdventCollection is ERC721, Ownable(msg.sender) {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    uint256 public mintDay;
    mapping(address => bool) public hasMinted;
    bool public isRedeemable;

    mapping(uint256 tokenId => bool) private _redeemed;
    string private _tokenURI;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintDay,
        string memory _uri
    ) ERC721(name, symbol) {
        mintDay = _mintDay;
        isRedeemable = true;
        _tokenURI = _uri;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        _requireOwned(tokenId);
        return _tokenURI;
    }

    function checkNftRedeemed(uint256 tokenId) public view returns (bool) {
        return _redeemed[tokenId] == true;
    }

    function mint(address to) external onlyOwner returns (uint256) {
        require(!hasMinted[to], "Already minted for this collection");
        require(
            block.timestamp >= mintDay && block.timestamp < mintDay + 1 days,
            "Not mintable today"
        );

        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _safeMint(to, newTokenId);
        hasMinted[to] = true;

        return newTokenId;
    }

    function redeem(uint256 tokenId) external {
        require(isRedeemable, "Redemption is not available");
        require(ownerOf(tokenId) == msg.sender, "Not the owner");

        _redeemed[tokenId] = true;

        // Emit an event for NFT redemption
        emit NFTRedeemed(msg.sender, tokenId);
    }

    // Emit an event for redemption
    event NFTRedeemed(address indexed user, uint256 tokenId);

    // Prevent transfers but maintain compatibility with ERC721
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal pure override {
        require(false, "Transfers are disabled for this collection");
    }
}

// Updated DateLib
library DateLib {
    function convertToTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) internal pure returns (uint256) {
        require(year >= 1970, "Year must be 1970 or later");
        require(month >= 1 && month <= 12, "Month must be between 1 and 12");
        require(day >= 1 && day <= getDaysInMonth(year, month), "Invalid day");

        // Calculate the number of days since Unix epoch (1970-01-01)
        uint256 totalDays = (year - 1970) *
            365 +
            (year - 1969) /
            4 - // Leap years
            (year - 1901) /
            100 + // Skipped leap years
            (year - 1601) /
            400; // Reinstated leap years

        // Add days for months in the current year
        for (uint256 m = 1; m < month; m++) {
            totalDays += getDaysInMonth(year, m);
        }

        // Add days in the current month
        totalDays += day - 1;

        // Convert to seconds
        return totalDays * 1 days; // 86400 seconds in a day
    }

    function getDaysInMonth(
        uint256 year,
        uint256 month
    ) internal pure returns (uint256) {
        if (month == 2) {
            return
                (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
                    ? 29
                    : 28;
        }
        if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        }
        return 31;
    }

    function getCurrentMintDay() internal view returns (uint8) {
        uint256 timestamp = block.timestamp; // Current block timestamp
        uint256 startTimestamp = convertToTimestamp(2024, 11, 1); // Start of December 2024

        // Ensure we don't have a negative or erroneous result
        require(
            timestamp >= startTimestamp,
            "Timestamp is before the start of the minting period"
        );

        // Calculate the difference in seconds and convert to days
        uint256 diffInSeconds = timestamp - startTimestamp;
        uint8 currentDay = uint8(diffInSeconds / 1 days) + 1;

        return currentDay;
    }
}

// Factory Contract
contract AdventFactoryContract is Ownable(msg.sender) {
    mapping(uint8 => address) public collections;
    IERC20 public usdcToken;

    event CollectionCreated(uint256 day, address collection);
    event NFTMinted(address collection, address to, uint256 tokenId);

    constructor(address _usdcToken) {
        usdcToken = IERC20(_usdcToken);
    }

    function createCollection(
        uint8 day,
        string memory name,
        string memory symbol,
        string memory uri
    ) external onlyOwner {
        require(day >= 1 && day <= 30, "Invalid day");
        require(collections[day] == address(0), "Collection already exists");

        // , string memory uri

        uint256 mintTimestamp = DateLib.convertToTimestamp(2024, 11, day);

        bytes memory deploymentCode = abi.encodePacked(
            type(AdventCollection).creationCode,
            abi.encode(name, symbol, mintTimestamp, uri)
        );
        address newCollection;
        assembly {
            let codeSize := mload(deploymentCode)
            let codeStart := add(deploymentCode, 0x20)

            newCollection := create(0, codeStart, codeSize)

            if iszero(extcodesize(newCollection)) {
                revert(0, 0)
            }
        }

        collections[day] = address(newCollection);
        emit CollectionCreated(day, address(newCollection));
    }

    function mintNFT(uint256 donationAmount) external {
        uint8 day = DateLib.getCurrentMintDay();
        require(day >= 1, "NFT minting has not started yet");
        require(day <= 30, "NFT minting has already been completed");
        require(collections[day] != address(0), "Collection does not exist");
        require(donationAmount >= 1e6, "Minimum 1 USDC required");

        // Accept donation
        // require(
        //     usdcToken.transferFrom(msg.sender, address(this), donationAmount),
        //     "USDC transfer failed"
        // );

        // Mint NFT
        AdventCollection collection = AdventCollection(collections[day]);
        uint256 tokenId = collection.mint(msg.sender);

        emit NFTMinted(address(collection), msg.sender, tokenId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function withdrawUSDC() external onlyOwner {
        uint256 balance = usdcToken.balanceOf(address(this));
        require(balance > 0, "No USDC to withdraw");
        require(usdcToken.transfer(owner(), balance), "Transfer failed");
    }
}
