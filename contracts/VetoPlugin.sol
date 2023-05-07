// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.7;

import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import {IMembership} from "@aragon/osx/core/plugin/membership/IMembership.sol";
import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {RATIO_BASE, _applyRatioCeiled} from "@aragon/osx/plugins/utils/Ratio.sol";
import {MajorityVotingBase} from "@aragon/osx/plugins/governance/majority-voting/MajorityVotingBase.sol";
import {IMajorityVoting} from "@aragon/osx/plugins/governance/majority-voting/IMajorityVoting.sol";

import {TestVotingToken} from "./TestVotingToken.sol";

contract VetoPlugin is MajorityVotingBase, IMembership {
    using SafeCastUpgradeable for uint256;
    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
    bytes4 internal constant TOKEN_VOTING_INTERFACE_ID =
        this.initializeBuild.selector ^ this.getVotingToken.selector;

    /// @notice An [OpenZeppelin `Votes`](https://docs.openzeppelin.com/contracts/4.x/api/governance#Votes) compatible contract referencing the token being used for voting.
    TestVotingToken private votingToken;

    /// @notice An tax amount which would be setted by Governance Dao
    uint256 tax = 0;


    /// @notice Permissions
    bytes32 public constant VETO_PERMISSION_ID = keccak256("VETO_PERMISSION");
    bytes32 public constant TAX_PERMISSION_ID = keccak256("TAX_PERMISSION");


    /// @notice Thrown if the voting power is zero
    error NoVotingPower();


    /// @notice Emitted when proposal was canceled by Governance
    /// @param _proposalId Canceled proposal ID.
    event CancelVote(uint256 _proposalId);

    /// @notice Emitted when a token deposit has been made to the DAO.
    /// @param sender The address of the sender.
    /// @param token The address of the deposited token.
    /// @param amount The amount of tokens deposited.
    /// @param _reference The reference describing the deposit reason.
    event Deposited(
        address indexed sender,
        address indexed token,
        uint256 amount,
        string _reference
    );

    /// @notice Emitted when a token deposit has been made to the DAO.
    /// @param newTax New Tax Percentage
    /// @param oldTax Previous Tax Percentage
    event TaxChanged(
        uint256 newTax,
        uint256 oldTax
    );

    /// @notice Thrown if the deposit amount is zero.
    error ZeroAmount();


    /// @notice Initializes the component.
    /// @dev This method is required to support [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822).
    /// @param _dao The IDAO interface of the associated DAO.
    /// @param _votingSettings The voting settings.
    /// @param _token The [ERC-20](https://eips.ethereum.org/EIPS/eip-20) token used for voting.
    function initializeBuild(
        IDAO _dao,
        VotingSettings calldata _votingSettings,
        address _token
    ) external initializer {
        __MajorityVotingBase_init(_dao, _votingSettings);

        votingToken = TestVotingToken(_token);

        emit MembershipContractAnnounced({definingContract: _token});
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override(MajorityVotingBase) returns (bool) {
        return
            _interfaceId == TOKEN_VOTING_INTERFACE_ID ||
            _interfaceId == type(IMembership).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice getter function for the voting token.
    /// @dev public function also useful for registering interfaceId and for distinguishing from majority voting interface.
    /// @return The token used for voting.
    function getVotingToken() public view returns (address) {
        return address(votingToken);
    }

    /// @inheritdoc MajorityVotingBase
    function totalVotingPower(uint256 _blockNumber) public view override returns (uint256) {
        return votingToken.getPastTotalSupply(_blockNumber);
    }

    /// @inheritdoc MajorityVotingBase
    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap,
        uint64 _startDate,
        uint64 _endDate,
        VoteOption _voteOption,
        bool _tryEarlyExecution
    ) external override returns (uint256 proposalId) {
        uint256 snapshotBlock;
        unchecked {
            snapshotBlock = block.number - 1;
        }

        uint256 totalVotingPower_ = totalVotingPower(snapshotBlock);

        if (totalVotingPower_ == 0) {
            revert NoVotingPower();
        }

        if (votingToken.getPastVotes(_msgSender(), snapshotBlock) < minProposerVotingPower()) {
            revert ProposalCreationForbidden(_msgSender());
        }

        proposalId = _createProposal({
            _creator: _msgSender(),
            _metadata: _metadata,
            _startDate: _startDate,
            _endDate: _endDate,
            _actions: _actions,
            _allowFailureMap: _allowFailureMap
        });

        // Store proposal related information
        Proposal storage proposal_ = proposals[proposalId];

        (proposal_.parameters.startDate, proposal_.parameters.endDate) = _validateProposalDates(
            _startDate,
            _endDate
        );
        proposal_.parameters.snapshotBlock = snapshotBlock.toUint64();
        proposal_.parameters.votingMode = votingMode();
        proposal_.parameters.supportThreshold = supportThreshold();
        proposal_.parameters.minVotingPower = _applyRatioCeiled(
            totalVotingPower_,
            minParticipation()
        );

        // Reduce costs
        if (_allowFailureMap != 0) {
            proposal_.allowFailureMap = _allowFailureMap;
        }

        for (uint256 i; i < _actions.length; ) {
            proposal_.actions.push(_actions[i]);
            unchecked {
                ++i;
            }
        }

        if (_voteOption != VoteOption.None) {
            vote(proposalId, _voteOption, _tryEarlyExecution);
        }
    }

    /// @inheritdoc IMembership
    function isMember(address _account) external view returns (bool) {
        /// whatever condition
        return votingToken.getVotes(_account) > 0;
    }

    /// @inheritdoc MajorityVotingBase
    function _vote(
        uint256 _proposalId,
        VoteOption _voteOption,
        address _voter,
        bool _tryEarlyExecution
    ) internal override {
        Proposal storage proposal_ = proposals[_proposalId];

        // This could re-enter, though we can assume the governance token is not malicious
        uint256 votingPower = votingToken.getPastVotes(_voter, proposal_.parameters.snapshotBlock);
        VoteOption state = proposal_.voters[_voter];

        // If voter had previously voted, decrease count
        if (state == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes - votingPower;
        } else if (state == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no - votingPower;
        } else if (state == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain - votingPower;
        }

        // write the updated/new vote for the voter.
        if (_voteOption == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes + votingPower;
        } else if (_voteOption == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no + votingPower;
        } else if (_voteOption == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain + votingPower;
        }

        proposal_.voters[_voter] = _voteOption;

        emit VoteCast({
            proposalId: _proposalId,
            voter: _voter,
            voteOption: _voteOption,
            votingPower: votingPower
        });

        if (_tryEarlyExecution && _canExecute(_proposalId)) {
            _execute(_proposalId);
        }
    }

    /// @inheritdoc MajorityVotingBase
    function _canVote(
        uint256 _proposalId,
        address _account,
        VoteOption _voteOption
    ) internal view override returns (bool) {
        Proposal storage proposal_ = proposals[_proposalId];

        // The proposal vote hasn't started or has already ended.
        if (!_isProposalOpen(proposal_)) {
            return false;
        }

        // The voter votes `None` which is not allowed.
        if (_voteOption == VoteOption.None) {
            return false;
        }

        // The voter has no voting power.
        if (votingToken.getPastVotes(_account, proposal_.parameters.snapshotBlock) == 0) {
            return false;
        }

        // The voter has already voted but vote replacment is not allowed.
        if (
            proposal_.voters[_account] != VoteOption.None &&
            proposal_.parameters.votingMode != VotingMode.VoteReplacement
        ) {
            return false;
        }

        return true;
    }

    /// @notice Cancel the proposal. Caller needs VETO_PERMISSION_ID.
    /// @param _proposalId The proposal id which will be cancelled
    function cancelVote(uint256 _proposalId) external auth(VETO_PERMISSION_ID) returns (uint256) {
        // create a modifier here checking whether the proposal is still active, otherwise cancelling would make no point and transaction should be reverted
        Proposal storage proposal = proposals[_proposalId];
        proposal = proposals[_proposalId]; // `proposals` would be your mapping of proposals

        require(
            proposal.parameters.endDate >= uint64(block.timestamp),
            "Impossible to cancel already voted!"
        );

        emit CancelVote(_proposalId);
        proposal.parameters.endDate = uint64(block.timestamp);

        return _proposalId;
    }


    function deposit(
        uint256 _amount,
        string calldata _reference
    ) external payable {
        uint256 taxAmount = 0;
        if (_amount == 0) revert ZeroAmount();
        if (tax != 0) {
            taxAmount = _amount * tax / 100;
        }
        votingToken.transferFrom(msg.sender, address(this), _amount - taxAmount);
        emit Deposited(msg.sender, address(votingToken), _amount, _reference);
    }

    /// @notice Change the Tax percentage by Governance Dao
    function changeTax(uint256 _tax) external auth(TAX_PERMISSION_ID)  {
        emit TaxChanged(_tax, tax);
        tax = _tax;
    }
}
