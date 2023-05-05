// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.8;

import {PermissionLib} from "@aragon/osx/core/permission/PermissionLib.sol";
import {PluginSetup, IPluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {VetoPlugin} from "./VetoPlugin.sol";

import {MajorityVotingBase} from "@aragon/osx/plugins/governance/majority-voting/MajorityVotingBase.sol";

/// @title SimpleStorageSetup build 1
contract VetoPluginSetup is PluginSetup {
    enum VotingMode {
        Standard,
        EarlyExecution,
        VoteReplacement
    }

    struct VotingSettings {
        VotingMode votingMode;
        uint32 supportThreshold;
        uint32 minParticipation;
        uint64 minDuration;
        uint256 minProposerVotingPower;
    }

    address private immutable vetoPluginImplementation;

    constructor() {
        vetoPluginImplementation = address(new VetoPlugin());
    }

    function prepareInstallation(
        address _dao,
        bytes memory _data
    ) external returns (address plugin, PreparedSetupData memory preparedSetupData) {
        address _token;
        VotingSettings memory _votingSettings;
        
        (_token, _votingSettings) = abi.decode(_data, (address, VotingSettings));

        plugin = createERC1967Proxy(
            vetoPluginImplementation,
            abi.encodeWithSelector(
                VetoPlugin.initializeBuild.selector,
                _dao,
                _votingSettings,
                _token
            )
        );

        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](1);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Grant,
            where: plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("VETO_PERMISSION")
        });

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    ) external pure returns (PermissionLib.MultiTargetPermission[] memory permissions) {
        permissions = new PermissionLib.MultiTargetPermission[](3);

        permissions[0] = PermissionLib.MultiTargetPermission({
            operation: PermissionLib.Operation.Revoke,
            where: _payload.plugin,
            who: _dao,
            condition: PermissionLib.NO_CONDITION,
            permissionId: keccak256("VETO_PERMISSION")
        });
    }

    /// @inheritdoc IPluginSetup
    function implementation() external view returns (address) {
        return vetoPluginImplementation;
    }
}
