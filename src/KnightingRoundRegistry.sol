// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Initializable} from "openzeppelin-contracts-upgradeable/proxy/utils/Initializable.sol";
import "openzeppelin-contracts/utils/structs/EnumerableSet.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import "./KnightingRound.sol";
import "./KnightingRoundWithEth.sol";
import "./GACProxyAdmin.sol";

/**
A simple registry contract that help to register different knighting round
*/
contract KnightingRoundRegistry is Initializable {
    // ===== Libraries  ====
    using EnumerableSet for EnumerableSet.AddressSet;

    GACProxyAdmin public gacProxyAdmin;

    address public globalAccessControl;
    address public tokenOut;
    address public saleRecipient;
    address public guestlist;
    uint256 public roundStart;
    uint256 public roundDuration;

    address public knightingRoundImplementation;
    address public knightingRoundWithEthImplementation;

    EnumerableSet.AddressSet private knightingRounds;
    address private knightingRoundsWithEth;

    struct InitParam {
        address _tokenIn;
        uint256 _tokenInLimit;
        uint256 _tokenOutPerTokenIn;
    }

    struct RoundData {
        address roundAddress;
        address tokenOut;
        address tokenIn;
        uint256 saleStart;
        uint256 saleDuration;
        address saleRecipient;
        bool finalized;
        uint256 tokenOutPerTokenIn;
        uint256 totalTokenIn;
        uint256 totalTokenOutBought;
        uint256 totalTokenOutClaimed;
        uint256 tokenInLimit;
        uint256 tokenInNormalizationValue;
        address guestlist;
        bool isEth;
    }

    /// initialize
    function initialize(
        address _globalAccessControl,
        uint256 _roundStart,
        uint256 _roundDuration,
        address _tokenOut,
        address _saleRecipient,
        address _guestlist,
        InitParam calldata _wethParams,
        InitParam[] calldata _roundParams
    ) public initializer {
        globalAccessControl = _globalAccessControl;
        roundStart = _roundStart;
        roundDuration = _roundDuration;

        tokenOut = _tokenOut;
        saleRecipient = _saleRecipient;
        guestlist = _guestlist;

        gacProxyAdmin = new GACProxyAdmin();
        gacProxyAdmin.initialize(_globalAccessControl);

        knightingRoundImplementation = address(new KnightingRound());
        knightingRoundWithEthImplementation = address(
            new KnightingRoundWithEth()
        );

        /// for weth
        initializeRound(_wethParams);
        initializeEthRound(_wethParams);
        /// for other
        for (uint256 i = 0; i < _roundParams.length; i++) {
            initializeRound(_roundParams[i]);
        }
    }

    function initializeRound(InitParam calldata _roundParams) private {
        TransparentUpgradeableProxy currKnightingRound = new TransparentUpgradeableProxy(
                address(knightingRoundImplementation),
                address(gacProxyAdmin),
                abi.encodeWithSelector(
                    KnightingRound(address(0)).initialize.selector,
                    globalAccessControl,
                    tokenOut,
                    _roundParams._tokenIn,
                    roundStart,
                    roundDuration,
                    _roundParams._tokenOutPerTokenIn,
                    saleRecipient,
                    guestlist,
                    _roundParams._tokenInLimit
                )
            );
        knightingRounds.add(address(currKnightingRound));
    }

    function initializeEthRound(InitParam calldata _roundParams) private {
        TransparentUpgradeableProxy knightinRoundWEth = new TransparentUpgradeableProxy(
                address(knightingRoundWithEthImplementation),
                address(gacProxyAdmin),
                abi.encodeWithSelector(
                    KnightingRoundWithEth(address(0)).initialize.selector,
                    globalAccessControl,
                    tokenOut,
                    _roundParams._tokenIn,
                    roundStart,
                    roundDuration,
                    _roundParams._tokenOutPerTokenIn,
                    saleRecipient,
                    guestlist,
                    _roundParams._tokenInLimit
                )
            );
        knightingRoundsWithEth = address(knightinRoundWEth);
    }

    /// getRoundData
    function getRoundData(address _roundAddress)
        public
        view
        returns (RoundData memory roundData)
    {
        KnightingRound targetRound = KnightingRound(_roundAddress);
        roundData.roundAddress = _roundAddress;
        roundData.tokenOut = address(targetRound.tokenOut());
        roundData.tokenIn = address(targetRound.tokenIn());
        roundData.saleStart = targetRound.saleStart();
        roundData.saleDuration = targetRound.saleDuration();
        roundData.saleRecipient = targetRound.saleRecipient();
        roundData.finalized = targetRound.finalized();
        roundData.tokenOutPerTokenIn = targetRound.tokenOutPerTokenIn();
        roundData.totalTokenIn = targetRound.totalTokenIn();
        roundData.totalTokenOutBought = targetRound.totalTokenOutBought();
        roundData.totalTokenOutClaimed = targetRound.totalTokenOutClaimed();
        roundData.tokenInLimit = targetRound.tokenInLimit();
        roundData.tokenInNormalizationValue = targetRound
            .tokenInNormalizationValue();
        roundData.guestlist = address(targetRound.guestlist());
        if (_roundAddress == knightingRoundsWithEth) {
            roundData.isEth = true;
        } else {
            roundData.isEth = false;
        }
    }

    /// @notice using to get all rounds
    function getAllRounds() public view returns (address[] memory) {
        address[] memory knightingRoundsList = new address[](
            knightingRounds.length() + 1
        );
        for (uint256 i = 0; i < knightingRounds.length(); i++) {
            knightingRoundsList[i] = knightingRounds.at(i);
        }
        knightingRoundsList[knightingRounds.length()] = knightingRoundsWithEth;
        return knightingRoundsList;
    }

    /// @notice using to get all rounds
    function getAllRoundsData() public view returns (RoundData[] memory) {
        RoundData[] memory roundsData = new RoundData[](
            knightingRounds.length() + 1
        );
        for (uint256 i = 0; i < knightingRounds.length(); i++) {
            roundsData[i] = getRoundData(knightingRounds.at(i));
        }
        roundsData[knightingRounds.length()] = getRoundData(
            knightingRoundsWithEth
        );
        return roundsData;
    }
}
