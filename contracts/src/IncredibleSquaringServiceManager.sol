// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@eigenlayer/contracts/libraries/BytesLib.sol";
import "./IIncredibleSquaringTaskManager.sol";
import "@eigenlayer-middleware/src/ServiceManagerBase.sol";

/**
 * @title Primary entrypoint for procuring services from IncredibleSquaring.
 * @author Layr Labs, Inc.
 */
contract IncredibleSquaringServiceManager is ServiceManagerBase {
    using BytesLib for bytes;

    /// @notice The current task number
    uint32 public taskNum;

    /// @notice Unit of measure (in blocks) for which Ethereum censorship window will last.

    IIncredibleSquaringTaskManager
        public immutable incredibleSquaringTaskManager;
    uint32 public immutable ETHEREUM_CENSORSHIP_WINDOW;

    /// @notice when applied to a function, ensures that the function is only callable by the `registryCoordinator`.
    modifier onlyIncredibleSquaringTaskManager() {
        require(
            msg.sender == address(incredibleSquaringTaskManager),
            "onlyIncredibleSquaringTaskManager: not from credible squaring task manager"
        );
        _;
    }

    constructor(
        IBLSRegistryCoordinatorWithIndices _registryCoordinator,
        ISlasher _slasher,
        IIncredibleSquaringTaskManager _incredibleSquaringTaskManager,
        uint32 _ethereumCensorshipWindow
    ) ServiceManagerBase(_registryCoordinator, _slasher) {
        incredibleSquaringTaskManager = _incredibleSquaringTaskManager;
        ETHEREUM_CENSORSHIP_WINDOW = _ethereumCensorshipWindow;
    }

    /// @notice Called in the event of challenge resolution, in order to forward a call to the Slasher, which 'freezes' the `operator`.
    function freezeOperator(
        address operatorAddr
    ) external override onlyIncredibleSquaringTaskManager {
        // require(
        //     msg.sender == address(???),
        //     "IncredibleSquaringServiceManager.freezeOperator: Only ??? can slash operators"
        // );
        slasher.freezeOperator(operatorAddr);
    }

    /// @notice Returns the current 'taskNumber' for the middleware
    function taskNumber() external view override returns (uint32) {
        return incredibleSquaringTaskManager.taskNumber();
    }

    /// @notice Returns the block until which operators must serve.
    function latestServeUntilBlock() public view override returns (uint32) {
        return
            uint32(block.number) +
            incredibleSquaringTaskManager.getTaskResponseWindowBlock() +
            ETHEREUM_CENSORSHIP_WINDOW;
    }
}