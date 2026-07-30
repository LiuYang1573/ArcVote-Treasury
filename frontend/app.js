// Arc Testnet 配置
const ARC_TESTNET = {
    chainId: "0x4CEF52", // 5042002
    chainName: "Arc Testnet",
    rpcUrls: ["https://rpc.testnet.arc.io"],
    nativeCurrency: { name: "USDC", symbol: "USDC", decimals: 18 },
    blockExplorerUrls: ["https://testnet.arcscan.app"]
};

// 部署后请替换成真实合约地址
const CONTRACT_ADDRESS = "0xYourDeployedContractAddressHere";

const ABI = [
    "function createProposal(address _recipient, uint256 _amount, string _description) returns (uint256)",
    "function vote(uint256 _id, bool _support)",
    "function executeProposal(uint256 _id)",
    "function getProposal(uint256 _id) view returns (address,address,uint256,string,uint256,uint256,uint256,bool,bool)",
    "function proposalCount() view returns (uint256)",
    "function getTreasuryBalance() view returns (uint256)",
    "function deposit(uint256 _amount)",
    "event ProposalCreated(uint256 indexed id, address indexed proposer, address recipient, uint256 amount, string description)"
];

let provider, signer, contract;

async function connectWallet() {
    if (!window.ethereum) {
        alert("Please install MetaMask");
        return;
    }
    try {
        await window.ethereum.request({ method: "eth_requestAccounts" });
        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        const address = await signer.getAddress();
        document.getElementById("walletAddress").innerText = `Connected: ${address.slice(0,6)}...${address.slice(-4)}`;
        document.getElementById("connectBtn").innerText = "Connected";

        // 尝试切换到 Arc Testnet
        try {
            await window.ethereum.request({
                method: "wallet_switchEthereumChain",
                params: [{ chainId: ARC_TESTNET.chainId }]
            });
        } catch (e) {
            if (e.code === 4902) {
                await window.ethereum.request({
                    method: "wallet_addEthereumChain",
                    params: [ARC_TESTNET]
                });
            }
        }

        contract = new ethers.Contract(CONTRACT_ADDRESS, ABI, signer);
        loadTreasuryBalance();
        loadProposals();
    } catch (err) {
        console.error(err);
        alert("Connection failed");
    }
}

async function loadTreasuryBalance() {
    try {
        const bal = await contract.getTreasuryBalance();
        document.getElementById("treasuryBalance").innerText = `Treasury: ${ethers.formatUnits(bal, 6)} USDC`;
    } catch (e) {
        document.getElementById("treasuryBalance").innerText = "Treasury: (deploy contract first)";
    }
}

async function createProposal() {
    const recipient = document.getElementById("recipient").value;
    const amount = document.getElementById("amount").value;
    const description = document.getElementById("description").value;
    if (!recipient || !amount || !description) return alert("Please fill all fields");

    try {
        const amountWei = ethers.parseUnits(amount, 6);
        const tx = await contract.createProposal(recipient, amountWei, description);
        await tx.wait();
        alert("Proposal created!");
        loadProposals();
    } catch (e) {
        console.error(e);
        alert("Failed: " + e.message);
    }
}

async function loadProposals() {
    const list = document.getElementById("proposalsList");
    try {
        const count = await contract.proposalCount();
        if (count == 0) {
            list.innerHTML = "<p>No proposals yet</p>";
            return;
        }
        let html = "";
        for (let i = Number(count); i >= 1; i--) {
            const p = await contract.getProposal(i);
            html += `
                <div class="proposal">
                    <strong>#${i}</strong> ${p[3]}<br>
                    To: ${p[1].slice(0,8)}... | Amount: ${ethers.formatUnits(p[2], 6)} USDC<br>
                    <span class="yes">Yes: ${p[4]}</span> | <span class="no">No: ${p[5]}</span><br>
                    <button onclick="vote(${i}, true)">Vote Yes</button>
                    <button onclick="vote(${i}, false)">Vote No</button>
                    <button onclick="execute(${i})">Execute</button>
                </div>
            `;
        }
        list.innerHTML = html;
    } catch (e) {
        list.innerHTML = "<p>Please deploy the contract and update CONTRACT_ADDRESS in app.js</p>";
    }
}

async function vote(id, support) {
    try {
        const tx = await contract.vote(id, support);
        await tx.wait();
        alert("Voted!");
        loadProposals();
    } catch (e) {
        alert(e.message);
    }
}

async function execute(id) {
    try {
        const tx = await contract.executeProposal(id);
        await tx.wait();
        alert("Executed!");
        loadProposals();
        loadTreasuryBalance();
    } catch (e) {
        alert(e.message);
    }
}

document.getElementById("connectBtn").onclick = connectWallet;
document.getElementById("createBtn").onclick = createProposal;
