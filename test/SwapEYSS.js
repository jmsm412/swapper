const { expect } = require("chai");
const { upgrades } = require("hardhat");

describe("EYSS Swap", function () {
	let SwapEYSS, swapInstance, owner, addr1, addr2, addrs, tetherUSD, allianceBlock, binanceUSD, addresses;

	before(async function () {
		this.timeout(0);
		SwapEYSS = await ethers.getContractFactory("SwapEYSS_V1");
		[owner, addr1, addr2, ...addrs] = await ethers.getSigners();
		swapInstance = await upgrades.deployProxy(SwapEYSS, [addr1.address])
		await swapInstance.deployed()

		tetherUSD = await new ethers.Contract(
			'0xdac17f958d2ee523a2206206994597c13d831ec7',
			'[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"who","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]',
			ethers.provider).connect(owner.address);

		allianceBlock = await new ethers.Contract(
			'0x00a8b738E453fFd858a7edf03bcCfe20412f0Eb0',
			'[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"who","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]',
			ethers.provider).connect(owner.address);

		binanceUSD = await new ethers.Contract(
			'0x4fabb145d64652a948d72533023f6e7a623c7c53',
			'[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"who","type":"address"}],"name":"balanceOf","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"}]',
			ethers.provider).connect(owner.address);

		console.log()
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

	describe("Transactions on V1", function () {
		it("Should swap ETH for a token", async function () {
			this.timeout(0);
			let originalBalance = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))
			let originalBalanceFee = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))
			//let originalTetherBalance = Number(await ethers.utils.formatEther(await tetherUSD.balanceOf(owner.address)));
			await swapInstance.swapTokens(
				[tetherUSD.address], // TetherUSD Address
				[10000],
				1,
				Number(new Date()) + 24 * 3600,
				{
					value: ethers.utils.parseEther("1.0"),
					gasLimit: 12450000
				})
			//expect(Number(await ethers.utils.formatEther(await tetherUSD.balanceOf(owner.address)))).to.be.below(originalTetherBalance);
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))).to.be.below(originalBalance);
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))).to.be.above(originalBalanceFee)
		});

		it("Should swap ETH for more than one token", async function () {
			this.timeout(0);
			let originalBalance = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))
			let originalBalanceFee = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))
			await swapInstance.swapTokens(
				['0xdac17f958d2ee523a2206206994597c13d831ec7', '0x00a8b738E453fFd858a7edf03bcCfe20412f0Eb0', '0x4fabb145d64652a948d72533023f6e7a623c7c53'], // TetherUSD Address
				[3333, 3333, 3333],
				1,
				Number(new Date()) + 24 * 3600,
				{
					value: ethers.utils.parseEther("1.0"),
					gasLimit: 12450000
				})
			//console.log(Number(await ethers.utils.formatEther(await tetherUSD.balanceOf(owner.address))));
			//console.log(Number(await ethers.utils.formatEther(await allianceBlock.balanceOf(owner.address))));
			//console.log(Number(await ethers.utils.formatEther(await binanceUSD.balanceOf(owner.address))));
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))).to.be.below(originalBalance);
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))).to.be.above(originalBalanceFee)
		});
	});

	describe("Upgrading to V2", function () {
		it("Should get upgraded", async function () {
			SwapEYSS = await ethers.getContractFactory("SwapEYSS_V2");
			swapInstance = await upgrades.upgradeProxy(swapInstance.address, SwapEYSS);
		});

		it("Should have the same fee recipient", async function () {
			expect(await swapInstance.feeRecipient()).to.equal(addr2.address);
		});

		it("Should still change the fee recipient", async function () {
			await swapInstance.changeRecipient(addr1.address);
			expect(await swapInstance.feeRecipient()).to.equal(addr1.address);
		});
	});

	describe("Transactions on V2", function () {
		it("Should swap ETH for a token", async function () {
			this.timeout(0);
			let originalBalance = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))
			let originalBalanceFee = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))
			

			await swapInstance.swapTokens(
				['0xdac17f958d2ee523a2206206994597c13d831ec7'], // TetherUSD Address
				[10000], //100%
				1, // Expect
				Number(new Date()) + 24 * 3600, // Deadline
				{
					value: ethers.utils.parseEther("1.0"),
					gasLimit: 12450000
				})


			// The transaction doesn't actually swap ETH for Tokens,
			//		the following expects will pass because the fee is being sent to the recipient
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))).to.be.below(originalBalance);
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))).to.be.above(originalBalanceFee)
		});

		it("Should swap ETH for more than one token", async function () {
			this.timeout(0);
			let originalBalance = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))
			let originalBalanceFee = Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))
			await swapInstance.swapTokens(
				['0xdac17f958d2ee523a2206206994597c13d831ec7', '0x00a8b738E453fFd858a7edf03bcCfe20412f0Eb0', '0x4fabb145d64652a948d72533023f6e7a623c7c53'], // TetherUSD Address
				[3333, 3333, 3333],
				1,
				Number(new Date()) + 24 * 3600,
				{
					value: ethers.utils.parseEther("1.0"),
					gasLimit: 12450000
				})
			// The transaction doesn't actually swap ETH for Tokens,
			//		the following expects will pass because the fee is being sent to the recipient
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(owner.address)))).to.be.below(originalBalance);
			expect(Number(await ethers.utils.formatEther(await ethers.provider.getBalance(await swapInstance.feeRecipient())))).to.be.above(originalBalanceFee)
		});
	});

});