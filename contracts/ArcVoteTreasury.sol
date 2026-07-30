// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/**
 * @title ArcVote Treasury
 * @notice DAO governance-driven treasury on Arc (USDC-native L1)
 * @dev Proposal → On-chain vote → Automatic USDC execution
 * Encode Club x Arc Programmable Money Hackathon - DeFi Track
 */
contract ArcVoteTreasury {
    // Arc Testnet USDC (ERC-20 interface, 6 decimals)
    address public constant USDC = 0x3600000000000000000000000000000000000000;

    struct Proposal {
        uint256 id;
        address proposer;
        address recipient;
        uint256 amount;          // 6 decimals
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 deadline;
        bool executed;
        bool canceled;
        mapping(address => bool) hasVoted;
    }

    uint256 public proposalCount;
    uint256 public votingPeriod = 3 days;
    uint256 public quorum = 2;               // 测试用最低票数
    address public owner;

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed id, address indexed proposer, address recipient, uint256 amount, string description);
    event Voted(uint256 indexed id, address indexed voter, bool support);
    event ProposalExecuted(uint256 indexed id, address recipient, uint256 amount);
    event ProposalCanceled(uint256 indexed id);
    event Deposited(address indexed from, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    // ========== 创建提案 ==========
    function createProposal(
        address _recipient,
        uint256 _amount,
        string calldata _description
    ) external returns (uint256) {
        require(_recipient != address(0), "Invalid recipient");
        require(_amount > 0, "Amount must be > 0");

        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.recipient = _recipient;
        p.amount = _amount;
        p.description = _description;
        p.deadline = block.timestamp + votingPeriod;

        emit ProposalCreated(proposalCount, msg.sender, _recipient, _amount, _description);
        return proposalCount;
    }

    // ========== 投票 ==========
    function vote(uint256 _id, bool _support) external {
        Proposal storage p = proposals[_id];
        require(block.timestamp <= p.deadline, "Voting ended");
        require(!p.executed && !p.canceled, "Proposal closed");
        require(!p.hasVoted[msg.sender], "Already voted");

        p.hasVoted[msg.sender] = true;
        if (_support) {
            p.yesVotes += 1;
        } else {
            p.noVotes += 1;
        }

        emit Voted(_id, msg.sender, _support);
    }

    // ========== 自动执行（任何人可调用） ==========
    function executeProposal(uint256 _id) external {
        Proposal storage p = proposals[_id];
        require(block.timestamp > p.deadline, "Voting not ended");
        require(!p.executed && !p.canceled, "Already processed");
        require(p.yesVotes > p.noVotes, "Proposal not passed");
        require(p.yesVotes + p.noVotes >= quorum, "Quorum not reached");

        uint256 balance = IERC20(USDC).balanceOf(address(this));
        require(balance >= p.amount, "Insufficient treasury balance");

        p.executed = true;
        require(IERC20(USDC).transfer(p.recipient, p.amount), "USDC transfer failed");

        emit ProposalExecuted(_id, p.recipient, p.amount);
    }

    // ========== 存入 USDC 到金库 ==========
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be > 0");
        require(IERC20(USDC).transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit Deposited(msg.sender, _amount);
    }

    // ========== 紧急取消 ==========
    function cancelProposal(uint256 _id) external onlyOwner {
        Proposal storage p = proposals[_id];
        require(!p.executed, "Already executed");
        p.canceled = true;
        emit ProposalCanceled(_id);
    }

    // ========== 查询 ==========
    function getProposal(uint256 _id) external view returns (
        address proposer,
        address recipient,
        uint256 amount,
        string memory description,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 deadline,
        bool executed,
        bool canceled
    ) {
        Proposal storage p = proposals[_id];
        return (
            p.proposer,
            p.recipient,
            p.amount,
            p.description,
            p.yesVotes,
            p.noVotes,
            p.deadline,
            p.executed,
            p.canceled
        );
    }

    function getTreasuryBalance() external view returns (uint256) {
        return IERC20(USDC).balanceOf(address(this));
    }

    function hasVoted(uint256 _id, address _voter) external view returns (bool) {
        return proposals[_id].hasVoted[_voter];
    }
}
