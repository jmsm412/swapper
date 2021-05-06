const { expect } = require("chai");
const { upgrades } = require("hardhat");

describe("EYSS Swap", function () {
	let SwapEYSS;
	let swapInstance;
	let owner;
	let addr1;
	let addr2;
	let addrs;

	beforeEach(async function () {
		SwapEYSS = await ethers.getContractFactory("SwapEYSS_V1");
		[owner, addr1, addr2, ...addrs] = await ethers.getSigners();
		swapInstance = await upgrades.deployProxy(SwapEYSS, [addr1.address])
		await swapInstance.deployed()
	});

	describe("Deployment", function () {
		it("Should set the right owner", async function () {
			expect(await swapInstance.owner()).to.equal(owner.address);
		});

		it("Should have the right fee recipient", async function () {
			expect(await swapInstance.feeRecipient()).to.equal(addr1.address);
		});

		it("Should change fee recipient", async function () {
			await swapInstance.changeRecipient(addr2.address);
			expect(await swapInstance.feeRecipient()).to.equal(addr2.address);
		});
	});

	describe("Transactions", function () {
		it("Should swap ETH for a token", async function () {
			let originalBalance = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))
			let originalBalanceFee = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))
			await swapInstance.swapTokens(
				['0xdac17f958d2ee523a2206206994597c13d831ec7'], // TetherUSD Address
				[10000],
				1,
				Number(new Date()) + 24 * 3600,
				{
					value: ethers.utils.parseEther("1.0"),
					gasLimit: 9999999
				})
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))).to.be.below(originalBalance);
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))).to.be.above(originalBalanceFee)
		});

		it("Should swap ETH for more than one token", async function () {
			let originalBalance = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))
			let originalBalanceFee = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))
			await swapInstance.swapTokens(
				['0xdac17f958d2ee523a2206206994597c13d831ec7', '0x00a8b738E453fFd858a7edf03bcCfe20412f0Eb0', '0x4fabb145d64652a948d72533023f6e7a623c7c53'], // TetherUSD Address
				[3333, 3333, 3333],
				1,
				Number(new Date()) + 24 * 3600,
				{
					value: ethers.utils.parseEther("1.0"),
					gasLimit: 9999999
				})
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))).to.be.below(originalBalance);
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))).to.be.above(originalBalanceFee)
		});
	});
});